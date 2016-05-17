//
//  SocketIOProxyClient.swift
//  MisakaKeepAlive
//
//  Created by crazylhf on 15/10/26.
//  Copyright © 2015年 crazylhf. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol PushCallback {
    func onPush(data : String)
}

@objc public protocol LogCallback {
optional
    func log(level:String ,message:String)
}

@objc public protocol ConnectCallback {
    func onConnect(uid:String)
    func onDisconnect()
}

@objc public protocol PushIdCallback {
    func onPushId(pushId : String)
}

@objc public protocol PushSerializer {
    func serialize(topic:String,data : NSData)
}

@objc public protocol PushHandler {
    func onPush(topic:String, data : AnyObject)
}

public enum TTLReceiveType : Int{
    case Receive = 1
    case DoNotReceive = 0
}

public class SocketIOProxyClient : NSObject {
    
    private let lastUnicastId = "lastUnicastId"
    
    public weak var pushCallback:PushCallback?
    public weak var connectCallback:ConnectCallback?
    public weak var logCallback :LogCallback?
    private var socket:SocketIOClient?
    private var pushId:String?
    private var apnToken:String?
    private var connected = false
    private var broadcastTopicsMap = Dictionary<String ,TTLReceiveType>()
    private var topicToLastPacketId = Dictionary<String ,String>()
    
    
    
    public init(host:String){
        super.init()
        pushId = PushIdGeneratorBase().generatePushId()
        let https = host.containsString("https://")
        socket = SocketIOClient(socketURL: host, options: [.Log(true), .ForceWebsockets(true), .Secure(https), .SelfSigned(https),  .ForceNew(true), .ReconnectWait(3)])
        
        socket!.on("connect") {
            [unowned self]
            data, ack in
            print("socket connect ")
            self.connected = true
            self.sendPushIdAndTopicToServer()
        }
        
        socket!.on("pushId") {
            [unowned self]
            data, ack in
            print("socket pushId ")
            self.connected = true
            var values = data[0] as! Dictionary<String, AnyObject>
            var uid = values["uid"] as? String
            if(uid == nil){
                uid = "";
            }
            self.connectCallback?.onConnect(uid!)
            self.sendApnTokenToServer()
        }
        
        socket!.on("disconnect") {
            [unowned self]
            data, ack in
            print("socket disconnect")
            self.connected = false
            self.connectCallback?.onDisconnect()
        }
        
        socket!.on("error") {
            [unowned self]
            data, ack in
            print("socket error")
            self.connected = false
            self.connectCallback?.onDisconnect()
        }
        
        socket!.on("push") {
            [unowned self]
            data, ack in
            self.handlePush(data, ack: ack)
        }
        socket!.on("p"){
            [unowned self]
            data, ack in
            self.handleVersion2Push(data, ack: ack)
        }
        socket!.connect()
    }
    
    public func keepInBackground() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
            
            print("SocketIOProxyClient begin background task \(UIApplication.sharedApplication().backgroundTimeRemaining)")
            
        })
    }
    
    public func request(path:String,data:NSData?) {
        if let base64DataStr = data?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) {
            self.socket!.emit("packetProxy", ["data": base64DataStr,"path":path,"sequenceId":PushIdGeneratorBase.randomAlphaNumeric(32)])
        } else {
            self.socket!.emit("packetProxy", ["path":path,"sequenceId":PushIdGeneratorBase.randomAlphaNumeric(32)])
        }
    }
    
    public func unbindUid() {
         self.socket!.emit("unbindUid")
    }
    
    public func onApnToken(token:String){
        apnToken = token
        sendApnTokenToServer()
    }
    
    private func subscribeBroadcast(topic:String ,receiveTtl:TTLReceiveType){
        broadcastTopicsMap[topic] = receiveTtl
        if (connected) {
            self.socket!.emit("subscribeTopic", ["topic": topic])
            let receiveStr = receiveTtl == .Receive ? "true":"false"
            log("info", format: "subscribe topic : %@ , receive ttl : %@", args: topic , receiveStr)
        }
    }
    
    
    public func subscribeBroadcast(topic:String){
        self.subscribeBroadcast(topic, receiveTtl: TTLReceiveType.DoNotReceive);
    }
    
    public func subscribeBroadcastReceiveTTL(topic:String){
        self.subscribeBroadcast(topic, receiveTtl: TTLReceiveType.Receive);
    }
    
    public func unsubscribeBroadcast(topic:String){
        broadcastTopicsMap.removeValueForKey(topic)
        if (connected) {
            self.socket!.emit("unsubscribeTopic", ["topic": topic])
        }
    }
    
    private func sendApnTokenToServer() {
        if (pushId != nil && apnToken != nil && connected) {
            let data = NSMutableDictionary()
            data.setValue(apnToken, forKey: "apnToken")
            data.setValue(pushId, forKey: "pushId")
            data.setValue("apn", forKey: "type")
            data.setValue(NSBundle.mainBundle().bundleIdentifier, forKey: "bundleId")
            self.socket!.emit("apnToken", data)
            log("info",format: "send ApnToken to server")
        }
    }
    
    private func sendPushIdAndTopicToServer() {
        if (pushId != nil && connected) {
            let data = NSMutableDictionary()
            data.setValue(pushId, forKey: "id")
            data.setValue(1, forKey: "version")
            data.setValue("ios", forKey: "platform")
            if(broadcastTopicsMap.count > 0){
                data.setValue(Array(broadcastTopicsMap.keys), forKey: "topics")
            }
            self.socket!.emit("pushId", data)
            log("info", format: "send pushId and topic to server")
        }
    }
    
    public func setPushId(pushId: String){
        self.pushId = pushId
        self.sendPushIdAndTopicToServer()
    }
    
    public func getPushId() -> String{
        return pushId!
    }
    
    public func connect(){
        socket?.connect()
    }
    
    public func disconnect(){
        socket?.disconnect()
    }
    
    private func handlePush(data:[AnyObject] ,ack:SocketAckEmitter){
        
        var str : String?
        if let values = data[0] as? Dictionary<String, AnyObject>{
            let dataStr = values["d"] as? String ?? values["data"] as? String
            
            
            if(dataStr != nil){
                str = dataStr
            } else {
                if let json = values["j"]{
                    var jsonStr : String?
                    var jsonData : NSData?
                    do{
                        jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                    }catch let parseError{
                        log("error", format: "error parsing json data , error:%@", args: String(parseError))
                    }
                    jsonStr = NSString(data: jsonData!, encoding: NSUTF8StringEncoding) as? String
                    str = jsonStr
                }
            }
        }
        
        if str == nil{
            log("error", format: "server push data parse error")
            return
        }
        
        self.pushCallback?.onPush(str!)
        log("info", format: "server push with version1 data = %@ " ,args :data )
    }
    
    private func handleVersion2Push(data:[AnyObject] ,ack:SocketAckEmitter){
        var str : String?
        if let values = data[0] as? Dictionary<String, AnyObject>{
            
            
            var jsonStr : String?
            var jsonData : NSData?
            do{
                jsonData = try NSJSONSerialization.dataWithJSONObject(values, options: .PrettyPrinted)
            }catch let parseError{
                log("error", format: "error parsing json data , error:%@", args: String(parseError))
            }
            jsonStr = NSString(data: jsonData!, encoding: NSUTF8StringEncoding) as? String
            str = jsonStr
            
            
        }
        else if let value = data[0] as? String{
            str = value
        }
        else if let valueArr = data[0] as? NSArray{
            var jsonData : NSData?
            
            do{
                jsonData = try NSJSONSerialization.dataWithJSONObject(valueArr, options: .PrettyPrinted)
            }catch let parseError{
                log("error", format: "error parsing json data , error:%@", args: String(parseError))
            }
            str = NSString(data: jsonData!, encoding: NSUTF8StringEncoding) as? String
        }
        
        if str == nil{
            log("error", format: "server push data parse error")
            return
        }

        
        log("info", format: "server push with version2 data = %@ " ,args :str! )
        
        self.pushCallback?.onPush(str!)
        
        if data.count > 1 {
            if let ttl = data[1] as? NSArray{
                updateLastPacketId(ttl[0] as? String, data: [["id":ttl[1], "unicast":ttl[2] ,"ttl" : 1]])
            }
        }
        
        
        
        
    }
    
    func updateLastPacketId(topic:String! ,data:[AnyObject]){
        guard let values = data[0] as? Dictionary<String, AnyObject>
            else{
                return
        }
        let id : String! = values["id"] as? String ?? values["i"] as? String
      
        let ttl : NSNumber? = values["ttl"] as? NSNumber ?? values["t"] as? NSNumber
        
        let unicast : NSNumber? = values["unicast"] as? NSNumber ?? values["u"] as? NSNumber
        
        if(id != nil && ttl != nil){
            log("info", format: "update last packetId : on push topic = %@ , pushId = %@", args:topic,id )
            if unicast != nil{
                StorageUtil.sharedInstance().setItem(id, forKey: lastUnicastId)
            }else if topic != nil && broadcastTopicsMap[topic] != nil && broadcastTopicsMap[topic] == .Receive{
                topicToLastPacketId[topic] = id
            }
        }
        
    }
    

    func log(level:String ,format:String ,args:CVarArgType...){
        
        let formatStr = String(format: format, arguments: args)
        
        if let callbackLog = self.logCallback?.log {
            callbackLog(level, message: formatStr)
        }else{
            NSLog("SocketIOProxyClient Log:\(level),\(formatStr)")
        }
        
    }
    
    
    
}
