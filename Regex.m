//
//  Regex.m
//  swift2js
//
//  Created by Gregory Casamento on 10/20/14.
//  Copyright (c) 2014 swiftjs. All rights reserved.
//

#import "Regex.h"
#import <Foundation/NSRegularExpression.h>

@implementation Regex

- (id) initWithPattern: (NSString *)aPattern
{
    self = [super init];
    if(self != nil)
    {
        pattern = [aPattern copy];
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                            options:NSRegularExpressionCaseInsensitive
                                                           error:nil];
    }
    return self;
}

- (BOOL) test: (NSString *)data
{
    NSTextCheckingResult *match = [regex firstMatchInString: data
                                                    options: NSMatchingReportProgress
                                                      range: NSMakeRange(0, [data length])];
    return match != nil;
}

- (NSString *) firstMatch: (NSString *)data
{
    NSRange range = [regex rangeOfFirstMatchInString: data
                                             options: NSMatchingReportProgress
                                               range: NSMakeRange(0, [data length])];
    if(range.location != NSNotFound)
    {
        return [[data substringFromIndex: range.location] substringToIndex: range.length];
    }
    
    return nil;
}
@end
