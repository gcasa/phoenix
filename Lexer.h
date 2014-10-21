//
//  Lexer.h
//  swift2js
//
//  Created by Gregory Casamento on 10/19/14.
//  Copyright (c) 2014 swiftjs. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    IDENTIFIER = 1,
    //declaration keywords
    CLASS, DEINIT, ENUM, EXTENSION, FUNC, IMPORT, INIT, LET, PROTOCOL, STATIC, STRUCT, SUBSCRIPT, TYPEALIAS, VAR,
    //statement keywords
    BREAK, CASE, CONTINUE, DEFAULT, DO, ELSE, FALLTHROUGH, IF, IN, FOR, RETURN, SWITCH, WHERE, WHILE,
    //expression keywwords
    AS, DYNAMICTYPE, IS, NEW, SUPER, SELF, SELF_CLASS, TYPE,
    //particular keywords
    ASSOCIATIVITY, DIDSET, GET, INFIX, INOUT, LEFT, MUTATING, NONE, NONMUTATING, OPERATOR, OVERRIDE,
    POSTFIX, PRECEDENCE, PREFIX, RIGHT, SET, UNOWNED, UNOWNED_SAFE, UNOWNED_UNSAFE, WEAK, WILLSET,
    //value literals
    NUMBER_LITERAL, STRING_LITERAL, BOOLEAN_LITERAL,
    //operators /­  =­  -­  +­  !­  *­  %­  <­  >­  &­  |­  ^­  ~­  .­
    SLASH, EQUAL, MINUS, PLUS, EXCLAMATION, ASTERISK, PERCENT, LT, GT, AMPERSAND, OR, CARET, TILDE, DOT,
    //combined operators == === ++ -- ... << >> && || ->
    //+= -= *= %= /= &= |= ^= ~=
    EQUAL2, EQUAL3, PLUSPLUS, MINUSMINUS, DOT3, LT2, GT2, AMPERSAND2, OR2, ARROW,
    PLUS_EQ, MINUS_EQ, ASTERISK_EQ, SLASH_EQ, PERCENT_EQ, AMPERSAND_EQ, CARET_EQ, TILDE_EQ, OR_EQ,
    //grammar symbols ( ) [ ] { } , : ; @ _ # $ ?
    LPAR, RPAR, LBRACKET, RBRACKET, LBRACE, RBRACE, COMMA, COLON, SEMICOLON, AT, UNDERSCORE, HASH, DOLLAR, QUESTION,
    //helper tokens to resolve operator ambiguities
    PREFIX_OPERATOR, POSTFIX_OPERATOR,
    //line or block comment
    COMMENT
};
typedef NSUInteger TOKEN;

// Token data...
@interface TokenData : NSObject <NSObject, NSCopying>

@property (nonatomic,assign) TOKEN token;
@property (nonatomic,strong) NSString *value;

- (id)initWithToken:(TOKEN)token
              value:(NSString *)value;

@end

// Lexer

@class Regex;

@interface Lexer : NSObject
{
    NSString *code;
    NSString *lastParsed;
    NSUInteger consumed;
    NSMutableArray *tokenStack;
    BOOL debugYYLex;
    Regex *cleanRegex;
    Regex *identifierRegex;
    Regex *binaryNumberRegex;
    Regex *octalNumberRegex;
    Regex *hexNumberRegex;
    Regex *decimalNumberRegex;
    Regex *booleanRegex;
    Regex *stringRegex;
    Regex *lineCommentRegex;
    Regex *blockCommentRegex;
    Regex *prefixOperatorRegex;
    Regex *postfixOperatorRegex;
    NSDictionary *declarationKeywords;
    NSDictionary *statementKeywords;
    NSDictionary *expressionKeywords;
    NSDictionary *particularKeywords;
    NSDictionary *operatorSymbols;
    NSDictionary *grammarSymbols;
}

- (id) initWithSourceCode: (NSString *)theCode;

- (void) cleanCode;

- (TokenData *) nextToken;

- (int) yylex;

- (NSString *) yylextstr;

- (void) checkIdentifier;

- (void) checkNumberLiteral;

- (void) checkStringLiteral;

- (void) checkComment;

- (void) checkOperator;

- (void) checkGrammarSymbol;

//debug helper function
- (NSString *) tokenToString: (TOKEN)token;

//debug function
- (void) debugTokens;

//helper function to generate bison tokens
- (void) bisonTokens;
@end
