//
//  ProtoBufferDataMgr.m
//  ourtimes
//
//  Created by bleach on 16/3/18.
//  Copyright © 2016年 YY. All rights reserved.
//

#import "ProtoBufferDataMgr.h"
#import "Message.pb.h"
#import <objC/runtime.h>

@interface ProtoBufferDataMgr()

@end

/*
 注意:message.proto 在共享目录:小时代/开发文档/protobuf定义
 ./protoc --objc_out=./ ./message.proto
*/

@implementation ProtoBufferDataMgr

Implement_Singleton(ProtoBufferDataMgr)

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}

- (NSString*)messageDataProto:(NSData*)data {
    @try {
        MessageData* messageData = [MessageData parseFromData:data];
        if (messageData != nil) {
            MessageData_Type type = messageData.uri;
            switch (type) {
                case MessageData_TypeGiftRecvMessage:
                {
                    return [self onGiftRecvMessage:messageData];
                }
                    break;
                case MessageData_TypeBatchGiftRecvMessage:
                {
                    return [self onBatchGiftRecvMessage:messageData];
                }
                    break;
                default:
                    break;
            }
        }
    } @catch (NSException *exception) {
        GLLogi(@"messageDataProto error = %@", exception.name);
    } @finally {
        
    }
    
    return @"";
}

- (void)messageDataTest {
}

- (NSString*)onGiftRecvMessage:(MessageData*)messageData {
    if (![messageData hasBaseMsg] || ![messageData hasGiftRecvMsg]) {
        GLLogi(@"onGiftRecvMessage Parse Error");
    }
    
    BaseMessage* baseMessage = [messageData baseMsg];
    GiftRecvMessage* giftRecvMessage = [messageData giftRecvMsg];
    
    NSMutableDictionary* muteDictionary = [NSMutableDictionary dictionary];
    [self messageDataToDict:baseMessage muteDictionary:muteDictionary];
    [self messageDataToDict:giftRecvMessage muteDictionary:muteDictionary];
    
    NSString* jsonString = [self messageDataJsonString:muteDictionary];
    
    return jsonString;
}

- (NSString*)onBatchGiftRecvMessage:(MessageData*)messageData {
    if (![messageData hasBaseMsg] || ![messageData hasBatchGiftRecvMsg]) {
        GLLogi(@"onBatchGiftRecvMessage Parse Error");
    }
    
    BaseMessage* baseMessage = [messageData baseMsg];
    BatchGiftRecvMessage* batchGiftRecvMessage = [messageData batchGiftRecvMsg];
    
    NSMutableDictionary* muteDictionary = [NSMutableDictionary dictionary];
    [self messageDataToDict:baseMessage muteDictionary:muteDictionary];
    [self messageDataToDict:batchGiftRecvMessage muteDictionary:muteDictionary];
    
    NSString* jsonString = [self messageDataJsonString:muteDictionary];
    
    return jsonString;
}

- (void)baseMessageToDict:(BaseMessage*)baseMessage muteDictionary:(NSMutableDictionary*)muteDictionary {
    if ([baseMessage hasDataType] && baseMessage.dataType != nil) {
        [muteDictionary setObject:baseMessage.dataType forKey:@"dataType"];
    }
    if ([baseMessage hasPartialOrder]) {
        [muteDictionary setObject:@(baseMessage.partialOrder) forKey:@"partialOrder"];
    }
}
#pragma mark - giftRecvMessage
- (void)giftRecvMessageToDict:(GiftRecvMessage*)giftRecvMessage muteDictionary:(NSMutableDictionary*)muteDictionary {
    if ([giftRecvMessage hasUid]) {
        [muteDictionary setObject:@(giftRecvMessage.uid) forKey:@"uid"];
    }
    if ([giftRecvMessage hasNick] && giftRecvMessage.nick != nil) {
        [muteDictionary setObject:giftRecvMessage.nick forKey:@"nick"];
    }
    if ([giftRecvMessage hasHeaderUrl] && giftRecvMessage.headerUrl != nil) {
        [muteDictionary setObject:giftRecvMessage.headerUrl forKey:@"headerUrl"];
    }
    if ([giftRecvMessage hasSeq] && giftRecvMessage.seq != nil) {
        [muteDictionary setObject:giftRecvMessage.seq forKey:@"seq"];
    }
    if ([giftRecvMessage hasLid] && giftRecvMessage.lid != nil) {
        [muteDictionary setObject:giftRecvMessage.lid forKey:@"lid"];
    }
    if ([giftRecvMessage hasRecvUid]) {
        [muteDictionary setObject:@(giftRecvMessage.recvUid) forKey:@"recvUid"];
    }
    if ([giftRecvMessage hasUsedTime]) {
        [muteDictionary setObject:@(giftRecvMessage.usedTime) forKey:@"usedTime"];
    }
    if ([giftRecvMessage hasPropId]) {
        [muteDictionary setObject:@(giftRecvMessage.propId) forKey:@"propId"];
    }
    if ([giftRecvMessage hasPropCount]) {
        [muteDictionary setObject:@(giftRecvMessage.propCount) forKey:@"propCount"];
    }
    if ([giftRecvMessage income]) {
        [muteDictionary setObject:@(giftRecvMessage.income) forKey:@"income"];
    }
    if ([giftRecvMessage hasExpand] && giftRecvMessage.expand != nil) {
        [muteDictionary setObject:giftRecvMessage.expand forKey:@"expand"];
    }
}

#pragma mark - json string utils
- (void)messageDataToDict:(id)obj muteDictionary:(NSMutableDictionary*)muteDictionary {
    unsigned int propertyCount = 0;
    objc_property_t* properties = class_copyPropertyList([obj class], &propertyCount);
    
    for (unsigned int index = 0; index < propertyCount; index++) {
        NSString* key = [NSString stringWithUTF8String:property_getName(properties[index])];
        id value = [obj valueForKey:key];
        if (value == nil) {
            continue;
        }
        if ([value isKindOfClass:[NSArray class]]) {
            NSString* realKey = [self messageDataArrayKey:key];
            if (realKey.length == 0) {
                continue;
            }
            NSArray* dictArray = [self messageDataArrayToArray:(NSArray*)value];
            [muteDictionary setObject:dictArray forKey:realKey];
        } else {
            [muteDictionary setObject:value forKey:key];
        }
    }
    
    free(properties);
}

- (NSArray*)messageDataArrayToArray:(NSArray*)messageDataArray {
    NSMutableArray* dictArray = [[NSMutableArray alloc] initWithCapacity:messageDataArray.count];
    for (NSUInteger index = 0; index < messageDataArray.count; index++) {
        id obj = [messageDataArray objectAtIndex:index];
        NSMutableDictionary* objDict = [[NSMutableDictionary alloc] initWithCapacity:10];
        [self messageDataPropertyToDict:obj muteDictionary:objDict];
        [dictArray addObject:objDict];
    }
    return dictArray;
}

- (NSString*)messageDataArrayToString:(NSArray*)messageDataArray {
    NSMutableString* arrayJsonString = [[NSMutableString alloc] init];
    [arrayJsonString appendString:@"["];
    for (NSUInteger index = 0; index < messageDataArray.count; index++) {
        id obj = [messageDataArray objectAtIndex:index];
        NSMutableDictionary* objDict = [[NSMutableDictionary alloc] initWithCapacity:10];
        [self messageDataPropertyToDict:obj muteDictionary:objDict];
        NSString* objJsonString = [self messageDataJsonString:objDict];
        if (objJsonString.length > 0) {
            [arrayJsonString appendString:objJsonString];
        } else {
            continue;
        }
        if (index != (messageDataArray.count - 1)) {
            [arrayJsonString appendString:@","];
        }
    }
    [arrayJsonString appendString:@"]"];
    
    return arrayJsonString;
}

- (NSString*)messageDataArrayKey:(NSString*)arrayKey {
    static NSString* muteFlagString = @"mutable";
    NSMutableString* resultArrayKey = [[NSMutableString alloc] init];
    if ([arrayKey hasPrefix:muteFlagString]) {
        if (arrayKey.length <= muteFlagString.length) {
            return resultArrayKey;
        }
        NSString* headerChar = [arrayKey substringWithRange:NSMakeRange(muteFlagString.length, 1)];
        NSString* key = [arrayKey substringFromIndex:muteFlagString.length + 1];
        [resultArrayKey appendString:[headerChar lowercaseString]];
        [resultArrayKey appendString:key];
    }
    
    return resultArrayKey;
}

- (void)messageDataPropertyToDict:(id)obj muteDictionary:(NSMutableDictionary*)muteDictionary {
    unsigned int propertyCount = 0;
    objc_property_t* properties = class_copyPropertyList([obj class], &propertyCount);
    
    for (unsigned int index = 0; index < propertyCount; index++) {
        NSString* key = [NSString stringWithUTF8String:property_getName(properties[index])];
        id value = [obj valueForKey:key];
        if (value != nil) {
            [muteDictionary setObject:value forKey:key];
        }
    }
    
    free(properties);
}

- (NSString*)messageDataJsonString:(NSDictionary*)muteDictionary {
    if (muteDictionary.count == 0) {
        return @"";
    }
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:muteDictionary options:0 error:&error];
    if (error) {
        return @"";
    }
    NSString* messageDataJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return messageDataJson;
}

@end
