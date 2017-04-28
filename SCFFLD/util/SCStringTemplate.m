// Copyright 2017 InnerFunction Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Julian Goacher on 12/04/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "SCStringTemplate.h"
#import "SCRegExp.h"

/**
 * A block type used internally by the template engine to represent different nodes
 * of the compiled template.
 */
typedef NSString* (^SCStringTemplateBlock) (id context, BOOL uriEncode);

@interface SCStringTemplate()

- (void)parse:(NSString *)s;
- (SCStringTemplateBlock)textBlock:(NSString*)text;
- (SCStringTemplateBlock)refBlock:(NSString*)ref uriEncodeValue:(BOOL)uriEncodeValue;

@end

@implementation SCStringTemplate

- (id)initWithString:(NSString *)s {
    self = [super init];
    if (self) {
        blocks = [[NSMutableArray alloc] init];
        [self parse:s];
    }
    return self;
}

- (void)parse:(NSString *)s {
    SCRegExp *regex = [[SCRegExp alloc] initWithPattern:@"^([^{]*)([{]+)(%?[-a-zA-Z0-9_$.]+)([}]+)(.*)$"];
    NSMutableArray *refs = [[NSMutableArray alloc] init];
    while (s) {
        NSArray* r = [regex match:s];
        if (r) {
            NSString *leading   = r[1];
            NSString *lbraces   = r[2];
            NSString *reference = r[3];
            NSString *rbraces   = r[4];
            NSString *trailing  = r[5];
            // Append leading text to output.
            [blocks addObject:[self textBlock:leading]];
            // If just a single opening brace then we have a standard variable placeholder.
            if ([lbraces length] == 1 && [rbraces length] >= 1) {
                BOOL uriEncode = NO;
                // A % at the start of the variable reference means that the value result should
                // be URI encoded.
                if ([reference hasPrefix:@"%"]) {
                    uriEncode = YES;
                    reference = [reference substringFromIndex:1];
                }
                [blocks addObject:[self refBlock:reference uriEncodeValue:uriEncode]];
                [refs addObject:reference];
                // Edge case - more trailing braces than leading braces; just append what's left
                // as a text block.
                if ([rbraces length] > 1) {
                    [blocks addObject:[self textBlock:[rbraces substringFromIndex:1]]];
                }
            }
            else {
                // A nested (i.e. escaped) variable placeholder. Strip one each of the opening and
                // closing braces and append what's left as a plain text block.
                lbraces = [lbraces substringFromIndex:1];
                rbraces = [rbraces substringFromIndex:1];
                NSString *text = [NSString stringWithFormat:@"%@%@%@", lbraces, reference, rbraces];
                [blocks addObject:[self textBlock:text]];
            }
            s = trailing;
        }
        else {
            NSInteger i = [s rangeOfString:@"}"].location;
            if (i == NSNotFound) {
                [blocks addObject:[self textBlock:s]];
                s = nil;
            }
            else {
                [blocks addObject:[self textBlock:[s substringToIndex:i]]];
                s = [s substringFromIndex:i];
            }
        }
    }
    _refs = refs;
}

- (SCStringTemplateBlock)textBlock:(NSString *)text {
    return ^(id ctx, BOOL uriEncode) {
        return text;
    };
}

- (SCStringTemplateBlock)refBlock:(NSString *)ref uriEncodeValue:(BOOL)uriEncodeValue {
    return ^(id ctx, BOOL uriEncode) {
        id val = nil;
        if ([ctx respondsToSelector:@selector(valueForKeyPath:)]) {
            @try {
                val = [[ctx valueForKeyPath:ref] description];
            }
            @catch (NSException *e) {
                val = e;
            }
            if (val && (uriEncode || uriEncodeValue)) {
                val = [val stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            }
        }
        return val ? val : @"";
    };
}

- (NSString *)render:(id)context {
    return [self render:context uriEncode:NO];
}

- (NSString *)render:(id)context uriEncode:(BOOL)uriEncode {
    NSMutableString* result = [[NSMutableString alloc] init];
    for (SCStringTemplateBlock block in blocks) {
        [result appendString:block( context, uriEncode )];
    }
    return result;
}

+ (SCStringTemplate *)templateWithString:(NSString *)string {
    return [[SCStringTemplate alloc] initWithString:string];
}

+ (NSString *)render:(NSString *)template context:(id)context {
    return [[SCStringTemplate templateWithString:template] render:context];
}

+ (NSString *)render:(NSString *)template context:(id)context uriEncode:(BOOL)uriEncode {
    return [[SCStringTemplate templateWithString:template] render:context uriEncode:uriEncode];
}

@end
