//
//  ProtoBufferDataMgr.h
//  ourtimes
//
//  Created by bleach on 16/3/18.
//  Copyright © 2016年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProtoBufferDataMgr : NSObject

- (NSString*)messageDataProto:(NSData*)data;

- (void)messageDataTest;

Declare_Singleton()

@end
