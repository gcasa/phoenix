//
//  Regex.h
//  swift2js
//
//  Created by Gregory Casamento on 10/20/14.
//  Copyright (c) 2014 swiftjs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Regex : NSObject
{
    NSString *pattern;
    NSRegularExpression *regex;
}

- (id) initWithPattern: (NSString *)pattern;

- (BOOL) test: (NSString *)data;

- (NSString *) firstMatch: (NSString *)data;

@end
