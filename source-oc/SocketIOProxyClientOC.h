//
//  SocketIOProxyClientOC.h
//  ourtimes
//
//  Created by bleach on 16/2/8.
//  Copyright © 2016年 YY. All rights reserved.
//
#import <Foundation/Foundation.h>

extern NSString * const kAnonymousTag;

@protocol PushCallbackDelegate <NSObject>

@optional
- (void)log:(NSString*)level message:(NSString*)message;
- (void)onPush:(NSData*)nsdata;
- (void)onConnect:(NSString *)uid;               //收到pushId
- (void)onDisconnect;
@end

@interface SocketIOProxyClientOC : NSObject

@property(weak, nonatomic) id<PushCallbackDelegate> pushCallbackDelegate;
@property(strong, nonatomic) NSString* pushId;

+ (instancetype)initWith:(NSString *)url;
- (void)sendClickStats:(NSDictionary*) userInfo;
- (void)onApnToken:(NSData *)deviceToken;
- (void)setTags:(NSArray *)tags;
- (void)subscribeBroadcast:(NSString *)topic;
- (void)subscribeBroadcast:(NSString *)topic receiveTtlPackets:(BOOL)receiveTtlPackets;
- (void)unsubscribeBroadcast:(NSString *)topic;
- (void)keepInBackground;
- (void)request:(NSString*)path data:(NSData*)data;
- (void)unbindUid;
- (void)bindUid:(NSDictionary*)data;

@end
