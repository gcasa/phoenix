//
//  Lexer.m
//
//  Created by Gregory Casamento.
//

#import "Lexer.h"
#import "Regex.h"

static TokenData *lastyylexToken = nil;

@implementation TokenData

- (id)initWithToken:(TOKEN)token
              value:(NSString *)value
{
    self = [super init];
    if(self != nil)
    {
        self.token = token;
        self.value = value;
    }
    return self;
}

- (id) copyWithZone: (NSZone *)zone
{
    TokenData *data = [[TokenData alloc] initWithToken:self.token
                                                 value:self.value];
    return data;
}

@end

@implementation Lexer

- (id) initWithSourceCode: (NSString *)theCode
{
    self = [super init];
    if(self != nil)
    {
        code = [theCode copy];
        lastParsed = @"";
        consumed = 0;
        tokenStack = [[NSMutableArray alloc] initWithCapacity:500];
        debugYYLex = NO;
        
        // Regular expressions...
        cleanRegex = [[Regex alloc] initWithPattern: @"^[\\s\r\n]+"];
        identifierRegex = [[Regex alloc] initWithPattern: @"^[a-zA-Z_]+[\\w]*"];
        binaryNumberRegex = [[Regex alloc] initWithPattern: @"^0b[01]+"];
        octalNumberRegex = [[Regex alloc] initWithPattern: @"^0o[0-7]+"];
        hexNumberRegex = [[Regex alloc] initWithPattern: @"^0x[\\da-f]+"];
        decimalNumberRegex = [[Regex alloc] initWithPattern: @"^\\d+\\.?\\d*(?:e[+-]?\\d+)?"];
        booleanRegex = [[Regex alloc] initWithPattern: @"^true|^false"];
        stringRegex = [[Regex alloc] initWithPattern: @"^\"[^\"]*(?:\\[\\s\\S][^\"]*)*\""];
        lineCommentRegex = [[Regex alloc] initWithPattern: @"^//.*"];
        blockCommentRegex = [[Regex alloc] initWithPattern: @"^/[*].*?[*]/"];
        prefixOperatorRegex = [[Regex alloc] initWithPattern: @"^[^\\s,:;\\{\\(\\[]+"];
        postfixOperatorRegex = [[Regex alloc] initWithPattern: @"[^\\s,:;\\)\\}\\]]+$"];
        
        // Keywords...
        declarationKeywords = @{@"class":[NSNumber numberWithInt: CLASS],
                                @"deinit":[NSNumber numberWithInt: DEINIT],
                                @"enum":[NSNumber numberWithInt: ENUM],
                                @"extension":[NSNumber numberWithInt: EXTENSION],
                                @"func":[NSNumber numberWithInt: FUNC],
                                @"import":[NSNumber numberWithInt: IMPORT],
                                @"init":[NSNumber numberWithInt: INIT],
                                @"let":[NSNumber numberWithInt: LET],
                                @"protocol":[NSNumber numberWithInt: PROTOCOL],
                                @"static":[NSNumber numberWithInt: STATIC],
                                @"struct":[NSNumber numberWithInt: STRUCT],
                                @"subscript":[NSNumber numberWithInt: SUBSCRIPT],
                                @"typealias":[NSNumber numberWithInt: TYPEALIAS],
                                @"var":[NSNumber numberWithInt: VAR]};
        
        statementKeywords = @{
                              @"break":[NSNumber numberWithInt: BREAK],
                              @"case":[NSNumber numberWithInt: CASE],
                              @"continue":[NSNumber numberWithInt: CONTINUE],
                              @"default":[NSNumber numberWithInt: DEFAULT],
                              @"do":[NSNumber numberWithInt: DO],
                              @"else":[NSNumber numberWithInt: ELSE],
                              @"fallthrough":[NSNumber numberWithInt: FALLTHROUGH],
                              @"if":[NSNumber numberWithInt: IF],
                              @"in":[NSNumber numberWithInt: IN],
                              @"for":[NSNumber numberWithInt: FOR],
                              @"return":[NSNumber numberWithInt: RETURN],
                              @"switch":[NSNumber numberWithInt: SWITCH],
                              @"where":[NSNumber numberWithInt: WHERE],
                              @"while":[NSNumber numberWithInt: WHILE],
                              };
        
        expressionKeywords = @{
                               @"as":[NSNumber numberWithInt: AS],
                               @"dynamictype":[NSNumber numberWithInt: DYNAMICTYPE],
                               @"is":[NSNumber numberWithInt: IS],
                               @"new":[NSNumber numberWithInt: NEW],
                               @"super":[NSNumber numberWithInt: SUPER],
                               @"self":[NSNumber numberWithInt: SELF],
                               @"Self":[NSNumber numberWithInt: SELF_CLASS],
                               @"Type":[NSNumber numberWithInt: TYPE]
                               };
        
        particularKeywords = @{
                               @"associativity":[NSNumber numberWithInt: ASSOCIATIVITY],
                               @"didSet":[NSNumber numberWithInt: DIDSET],
                               @"get":[NSNumber numberWithInt: GET],
                               @"infix":[NSNumber numberWithInt: INFIX],
                               @"inout":[NSNumber numberWithInt: INOUT],
                               @"left":[NSNumber numberWithInt: LEFT],
                               @"mutating":[NSNumber numberWithInt: MUTATING],
                               @"none":[NSNumber numberWithInt: NONE],
                               @"nonmutating":[NSNumber numberWithInt: NONMUTATING],
                               @"operator":[NSNumber numberWithInt: OPERATOR],
                               @"override":[NSNumber numberWithInt: OVERRIDE],
                               @"postfix":[NSNumber numberWithInt: POSTFIX],
                               @"precedence":[NSNumber numberWithInt: PRECEDENCE],
                               @"prefix":[NSNumber numberWithInt: PREFIX],
                               @"right":[NSNumber numberWithInt: RIGHT],
                               @"set":[NSNumber numberWithInt: SET],
                               @"unowned":[NSNumber numberWithInt: UNOWNED],
                               @"unowned(safe)":[NSNumber numberWithInt: UNOWNED_SAFE],
                               @"unowned(unsafe)":[NSNumber numberWithInt: UNOWNED_UNSAFE],
                               @"weak":[NSNumber numberWithInt: WEAK],
                               @"willSet":[NSNumber numberWithInt: WILLSET],
                               };
        
        operatorSymbols = @{
                            @"/": [NSNumber numberWithInt: SLASH],       @"=": [NSNumber numberWithInt: EQUAL],
                            @"-": [NSNumber numberWithInt: MINUS],       @"+": [NSNumber numberWithInt: PLUS],
                            @"!": [NSNumber numberWithInt: EXCLAMATION], @"*": [NSNumber numberWithInt: ASTERISK],
                            @"%": [NSNumber numberWithInt: PERCENT],     @"<": [NSNumber numberWithInt: LT],
                            @">": [NSNumber numberWithInt: GT],          @"&": [NSNumber numberWithInt: AMPERSAND],
                            @"|": [NSNumber numberWithInt: OR],          @"^": [NSNumber numberWithInt: CARET],
                            @"~": [NSNumber numberWithInt: TILDE],       @".": [NSNumber numberWithInt: DOT],
                            //combined
                            @"==": [NSNumber numberWithInt: EQUAL2],     @"===": [NSNumber numberWithInt: EQUAL3],
                            @"++": [NSNumber numberWithInt: PLUSPLUS],   @"--": [NSNumber numberWithInt: MINUSMINUS],
                            @"...":[NSNumber numberWithInt: DOT3],       @"->": [NSNumber numberWithInt: ARROW],
                            @"<<": [NSNumber numberWithInt: LT2],        @">>": [NSNumber numberWithInt: GT2],
                            @"&&": [NSNumber numberWithInt: AMPERSAND2], @"||": [NSNumber numberWithInt: OR2],
                            @"+=": [NSNumber numberWithInt: PLUS_EQ],    @"-=": [NSNumber numberWithInt: MINUS_EQ],
                            @"*=": [NSNumber numberWithInt: ASTERISK_EQ], @"%=": [NSNumber numberWithInt: PERCENT_EQ],
                            @"/=": [NSNumber numberWithInt: SLASH_EQ],   @"|=": [NSNumber numberWithInt: OR_EQ],
                            @"&=": [NSNumber numberWithInt: AMPERSAND_EQ], @"^=": [NSNumber numberWithInt: CARET_EQ],
                            @"~=": [NSNumber numberWithInt: TILDE_EQ],
                            };
        
        grammarSymbols = @{
                           @"(": [NSNumber numberWithInt: LPAR],        @")": [NSNumber numberWithInt: RPAR],
                           @"[": [NSNumber numberWithInt: LBRACKET],    @"]": [NSNumber numberWithInt: RBRACKET],
                           @"{": [NSNumber numberWithInt: LBRACE],      @"}": [NSNumber numberWithInt: RBRACE],
                           @",": [NSNumber numberWithInt: COMMA],       @":": [NSNumber numberWithInt: COLON],
                           @";": [NSNumber numberWithInt: SEMICOLON],   @"@": [NSNumber numberWithInt: AT],
                           @"_": [NSNumber numberWithInt: UNDERSCORE],  @"#": [NSNumber numberWithInt: HASH],
                           @"$": [NSNumber numberWithInt: DOLLAR],      @"?": [NSNumber numberWithInt: QUESTION],
                           };
        
    }
    return self;
}

- (void) cleanCode
{
    NSString *match = nil;
    if((match = [cleanRegex firstMatch:code]) != nil)
    {
        code = [code substringFromIndex:[match lengthOfBytesUsingEncoding:NSUTF16StringEncoding]];
        lastParsed = match;
    }
}

- (TokenData *) nextToken
{
    
    if ([tokenStack count] == 0)
    {
        
        [self cleanCode]; //clean whitespaces
        
        //sorted token parser functions by precedence
        NSArray *checkFunctions = @[
                                    @"checkIdentifier",
                                    @"checkNumberLiteral",
                                    @"checkStringLiteral",
                                    @"checkComment",
                                    @"checkOperator",
                                    @"checkGrammarSymbol"
                                    ];
        
        
        // var parsedToken: (consumed:Int, token:TokenData)?;
        
        //call parser functions until a token is found
        for(NSString *checkFunc in checkFunctions)
        {
            SEL sel = NSSelectorFromString(checkFunc);
            [self performSelector:sel];
            if (consumed > 0) {
                lastParsed = [code substringToIndex: consumed];
                code = [code substringFromIndex: consumed];
                consumed = 0;
            }
            if ([tokenStack count] > 0)
            {
                break;
            }
        }
    }
    
    //return the found token and erase the parsed source code
    if([tokenStack count] > 0)
    {
        TokenData *foundToken = [tokenStack objectAtIndex: 0];
        
        [tokenStack removeObjectAtIndex:0];
        if ([foundToken token] == COMMENT)
        {
            //for now comment tokens are ommited and not pased to the parsed
            return [self nextToken];
        }
        
        return foundToken;
    }
    else
    {
        if ([code lengthOfBytesUsingEncoding:NSUTF16StringEncoding] > 0)
        {
            NSLog(@"Lexer Error, unknown token: %@", code);
        }
        
        return nil;
    }
}

- (int) yylex
{
    TokenData *data = nil;
    if((data = lastyylexToken))
    {
        return (int)data.token;
    }
    return 0;
}

- (NSString *) yylextstr
{
    TokenData *data = nil;
    if((data = lastyylexToken))
    {
        return (NSString *)data.value;
    }
    return @"";
}

- (void) checkIdentifier
{
    NSString *match = [identifierRegex firstMatch: code];
    if( match == nil )
    {
        return;
    }
    
    NSString *identifier = match;
    consumed += [identifier lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
    
    int declarationToken = 0; // [declarationKeywords[identifier] intValue];
    int statementToken = 0; // [statementKeywords[identifier] intValue];
    int expressionToken = 0; //  [expressionKeywords[identifier] intValue];
    int particularToken = [particularKeywords[identifier] intValue];
    
    if ((declarationToken = [declarationKeywords[identifier] intValue]))
    {
        TokenData *data = [[TokenData alloc] initWithToken:declarationToken
                                                     value:identifier];
        [tokenStack addObject: data];
    }
    else if ((statementToken = [statementKeywords[identifier] intValue]))
    {
        TokenData *data = [[TokenData alloc] initWithToken:statementToken
                                                     value:identifier];
        [tokenStack addObject: data];
    }
    else if ((expressionToken = [expressionKeywords[identifier] intValue]))
    {
        TokenData *data = [[TokenData alloc] initWithToken:expressionToken
                                                     value:identifier];
        [tokenStack addObject: data];
    }
    else if ((particularToken = [particularKeywords[identifier] intValue]))
    {
        //TODO: These keywords are only reserved in particular contexts
        //but outside the context in which they appear in the grammar, they can be used as identifiers.
        TokenData *data = [[TokenData alloc] initWithToken:particularToken
                                                     value:identifier];
        [tokenStack addObject: data];
    }
    else if([booleanRegex test: identifier])
    {
        TokenData *data = [[TokenData alloc] initWithToken:BOOLEAN_LITERAL
                                                     value:identifier];
        [tokenStack addObject: data];
    }
    else {
        //user defined identifier
        TokenData *data = [[TokenData alloc] initWithToken:IDENTIFIER
                                                     value:identifier];
        [tokenStack addObject: data];
    }
}

- (void) checkNumberLiteral
{
    for (Regex *regex in @[binaryNumberRegex, octalNumberRegex, hexNumberRegex, decimalNumberRegex])
    {
        NSString *match = [regex firstMatch:code];
        if (match)
        {
            consumed += [match lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
            TokenData *data = [[TokenData alloc] initWithToken:NUMBER_LITERAL
                                                         value:match];
            [tokenStack addObject:data];
            return;
        }
    }
}

- (void) checkStringLiteral
{
    NSString *match = [stringRegex firstMatch: code];
    if (match)
    {
        consumed+=[match lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
        TokenData *data = [[TokenData alloc] initWithToken:STRING_LITERAL
                                                     value:match];
        [tokenStack addObject:data];
    }
}

- (void) checkComment
{
    NSString *match = nil;
    if ((match = [lineCommentRegex firstMatch: code]))
    {
        consumed += [match lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
        TokenData *data = [[TokenData alloc] initWithToken:COMMENT
                                                     value:match];
        [tokenStack addObject:data];
    }
    else if ((match = [blockCommentRegex firstMatch: code]))
    {
        consumed += [match lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
        TokenData *data = [[TokenData alloc] initWithToken:COMMENT
                                                     value:match];
        [tokenStack addObject:data];
    }
}

- (void) checkOperator
{
    
    TOKEN found = 0;
    NSString *value = @"";
    //check operators by precedence (test combined operators first)
    int i = 0;
    for(i = 3; i > 0; --i)
    {
        if([code lengthOfBytesUsingEncoding:NSUTF16StringEncoding] < i)
        {
            continue;
        }
        value = [code substringToIndex:i];
        id match = nil;
        if((match = operatorSymbols[value]))
        {
            found = [match intValue];
            break;
        }
    }
    
    TOKEN token = 0;
    if ((token = found))
    {
        consumed += [value lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
        //check if the operator is prefix, postfix or binary
        BOOL prefix = [prefixOperatorRegex test: [code substringFromIndex: [value lengthOfBytesUsingEncoding:NSUTF16StringEncoding]]];
        BOOL postfix = [postfixOperatorRegex test: lastParsed];
        
        if (prefix == postfix) {
            //If an operator has whitespace around both sides or around neither side,
            //it is treated as a binary operator
            TokenData *data = [[TokenData alloc] initWithToken:token
                                                         value:value];
            [tokenStack addObject:data];
        }
        else if (prefix) {
            //prefix unary operator
            TokenData *data = [[TokenData alloc] initWithToken:PREFIX_OPERATOR
                                                         value:@""];
            [tokenStack addObject:data];
            TokenData *data2 = [[TokenData alloc] initWithToken:token
                                                         value:value];
            [tokenStack addObject:data2];
        }
        else if (postfix) {
            //postfix unary operator
            TokenData *data = [[TokenData alloc] initWithToken:POSTFIX_OPERATOR
                                                         value:@""];
            [tokenStack addObject:data];
            TokenData *data2 = [[TokenData alloc] initWithToken:token
                                                          value:value];
            [tokenStack addObject:data2];
        }
    }
}

- (void) checkGrammarSymbol
{
    if ([code lengthOfBytesUsingEncoding:NSUTF16StringEncoding] <= 0)
    {
        return;
    }
    
    NSString *firstChar = [code substringToIndex: 1];
    int match = [grammarSymbols[firstChar] intValue];
    
    if ((match))
    {
        consumed += [firstChar lengthOfBytesUsingEncoding:NSUTF16StringEncoding];
        TokenData *data = [[TokenData alloc] initWithToken:match
                                                     value:firstChar];
        [tokenStack addObject:data];
    }
}

//debug helper function
- (NSString *) tokenToString: (TOKEN)token
{
    switch (token) {
        case IDENTIFIER:
            return @"ID";
        case BOOLEAN_LITERAL:
            return @"bool";
        case STRING_LITERAL:
            return @"string";
        case NUMBER_LITERAL:
            return @"number";
        case PREFIX_OPERATOR:
            return @"prefix_op";
        case POSTFIX_OPERATOR:
            return @"postfix_op";
        default:
            break;
    }
    
    NSArray *dics = @[declarationKeywords,
                      statementKeywords,
                      expressionKeywords,
                      expressionKeywords,
                      particularKeywords,
                      operatorSymbols,
                      grammarSymbols];
    
    for(NSDictionary *dic in dics)
    {
        NSArray *allKeys = [dic allKeys];
        for(id key in allKeys)
        {
            id value = [dic objectForKey:key];
            if([value intValue] == token)
            {
                return key;
            }
        }
    }
    
    return @"unkown";
}

//debug function
- (void) debugTokens
{
    NSString *codeCopy = [code copy];
    
    TokenData *data = nil;
    while ((data = [self nextToken]))
    {
        NSString *tokenType = [self tokenToString: data.token];
        NSLog(@"TOKEN code: %lu type:%@ value:%@", (unsigned long)data.token, tokenType, data.value);
    }
    
    code = codeCopy;
}

//helper function to generate bison tokens
- (void) bisonTokens
{
    //autogenerated values from text editor
    NSArray *values = @[@"IDENTIFIER",
                        @"CLASS",@"DEINIT",@"ENUM",@"EXTENSION",@"FUNC",@"IMPORT",@"INIT",@"LET",@"PROTOCOL",@"STATIC",@"STRUCT",@"SUBSCRIPT",@"TYPEALIAS",@"VAR",
                        @"BREAK",@"CASE",@"CONTINUE",@"DEFAULT",@"DO",@"ELSE",@"FALLTHROUGH",@"IF",@"IN",@"FOR",@"RETURN",@"SWITCH",@"WHERE",@"WHILE",
                        @"AS",@"DYNAMICTYPE",@"IS",@"NEW",@"SUPER",@"SELF",@"SELF_CLASS",@"TYPE",
                        @"ASSOCIATIVITY",@"DIDSET",@"GET",@"INFIX",@"INOUT",@"LEFT",@"MUTATING",@"NONE",@"NONMUTATING",@"OPERATOR",@"OVERRIDE",
                        @"POSTFIX",@"PRECEDENCE",@"PREFIX",@"RIGHT",@"SET",@"UNOWNED",@"UNOWNED_SAFE",@"UNOWNED_UNSAFE",@"WEAK",@"WILLSET",
                        @"NUMBER_LITERAL",@"STRING_LITERAL",@"BOOLEAN_LITERAL",
                        @"SLASH",@"EQUAL",@"MINUS",@"PLUS",@"EXCLAMATION",@"ASTERISK",@"PERCENT",@"LT",@"GT",@"AMPERSAND",@"OR",@"CARET",@"TILDE",@"DOT",
                        @"EQUAL2",@"EQUAL3",@"PLUSPLUS",@"MINUSMINUS",@"DOT3",@"LT2",@"GT2",@"AMPERSAND2",@"OR2",@"ARROW",
                        @"PLUS_EQ",@"MINUS_EQ",@"ASTERISK_EQ",@"SLASH_EQ",@"PERCENT_EQ",@"AMPERSAND_EQ",@"CARET_EQ",@"TILDE_EQ",@"OR_EQ",
                        @"LPAR",@"RPAR",@"LBRACKET",@"RBRACKET",@"LBRACE",@"RBRACE",@"COMMA",@"COLON",@"SEMICOLON",@"AT",@"UNDERSCORE",@"HASH",@"DOLLAR",@"QUESTION",
                        @"PREFIX_OPERATOR",@"POSTFIX_OPERATOR",
                        @"COMMENT"];
    
    int index = 1;
    char percent = '%';
    for (NSString *value in values)
    {
        TOKEN token = (TOKEN)index; // TOKEN.fromRaw(index)!;
        NSString *str = [self tokenToString: token];
        NSString *outputString = [NSString stringWithFormat:@"%ctoken <val> %@ %ul %@",percent, value, index, str];
        
        printf("%s",[outputString cStringUsingEncoding:NSUTF8StringEncoding]);
        
        index++;
    }
}



@end
