//
//  SocketIOProxyClientOC.h
//  ourtimes
//
//  Created by bleach on 16/2/8.
//  Copyright © 2016年 YY. All rights reserved.
//
#ifndef WeakSelf
#define WeakSelf() __weak typeof(self) weakSelf = self;
#endif

#import <Foundation/Foundation.h>

extern NSString * const kAnonymousTag;

@protocol PushCallbackDelegate <NSObject>

@optional
- (void)log:(NSString*)level message:(NSString*)message;
- (void)onPush:(NSData*)nsdata;
- (void)onConnect:(NSString *)uid tags:(NSArray *)tags;               //收到pushId
- (void)onDisconnect;
@end

@interface SocketIOProxyClientOC : NSObject

@property(weak, nonatomic) id<PushCallbackDelegate> pushCallbackDelegate;
@property(strong, nonatomic) NSString* pushId;

+ (instancetype)initWith:(NSString *)url;
- (void)onApnToken:(NSString *)deviceToken;
- (void)addTag:(NSString *)tag;
- (void)removeTag:(NSString *)tag;
- (void)subscribeBroadcast:(NSString *)topic;
- (void)subscribeBroadcast:(NSString *)topic receiveTtlPackets:(BOOL)receiveTtlPackets;
- (void)unsubscribeBroadcast:(NSString *)topic;
- (void)keepInBackground;
- (void)request:(NSString*)path data:(NSData*)data;
- (void)unbindUid;
- (void)bindUid:(NSDictionary*)data;

@end
