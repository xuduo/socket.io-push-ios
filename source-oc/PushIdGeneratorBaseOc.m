//
//  PushIdGeneratorBaseOc.m
//  ourtimes
//
//  Created by bleach on 16/2/6.
//  Copyright © 2016年 YY. All rights reserved.
//

#import "PushIdGeneratorBaseOc.h"
#import "SAMKeyChain.h"

@implementation PushIdGeneratorBaseOc

+ (NSString*)randomAlphaNumeric:(NSInteger)count {
    NSMutableString* randomStr = [[NSMutableString alloc] initWithCapacity:count];
    
    while (count-- >= 0) {
        [randomStr appendString:[PushIdGeneratorBaseOc oneRandomAlphaNumeric]];
    }
    return randomStr;
}

+ (NSString*)oneRandomAlphaNumeric {
    unichar randomVal = arc4random() % 5;
    if (0 == randomVal || 2 == randomVal || 4 == randomVal) {
        randomVal = 97 + (arc4random() % 26);
        return [NSString stringWithCharacters:&randomVal length:1];
    } else {
        randomVal = 48 + (arc4random() % 10);
        return [NSString stringWithCharacters:&randomVal length:1];
    }
}

+ (NSString*)generatePushId {
    
    NSString* pushId = [SAMKeychain passwordForService:@"socket.io-push" account:@"pushId"];
    NSLog(@"MiKeychainItemWrapper pushId %@", pushId);
    
    if (nil == pushId) {
        pushId = [PushIdGeneratorBaseOc randomAlphaNumeric:16];
        [SAMKeychain setPassword:pushId forService:@"socket.io-push" account:@"pushId"];
    }
    
    return pushId;
}

@end
