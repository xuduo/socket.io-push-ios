//
//  ttl_server_single_test.swift
//  socket.io-push
//
//  Created by Gocy on 16/5/18.
//  Copyright © 2016年 Gocy. All rights reserved.
//

import XCTest
@testable import Socket_io_push

class ttl_server_single_test: XCTestCase ,PushCallback ,ConnectCallback {
    
    let host = "http://spush.yy.com"
    let pushUrl = "http://spush.yy.com/api/push?pushId=%@&topic=%@&json=%@&timeToLive=10000"
    let successCode = "{\"code\":\"success\"}"
    let confirmCode = "do not recieve after reconnect"
    var pushClient : SocketIOProxyClient?
    var firstTime = true
    var push = [2,3,4]
    var reconnect = false
    
    var expectation : XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        pushClient = SocketIOProxyClient(host: host)
        pushClient?.pushCallback = self
        pushClient?.connectCallback = self
        pushClient?.subscribeBroadcast("message")
        
        expectation = self.expectationWithDescription("Async request")
        
        self.waitForExpectationsWithTimeout(200, handler: nil)
    }
    
    //MARK : - PushCallback
    func onPush(dataStr: String) {
        guard let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding) else{return}
        
        var dataDic : NSDictionary?
        do{
            dataDic = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? NSDictionary
        }catch _{
            return
        }
        
        if firstTime {
            firstTime = false
            
            NSLog("receive first time")
            
            XCTAssertTrue(dataDic?["message"] as? Int == 1 , "receive first push is not equal to 1")
            
            pushClient?.disconnect()
            
            send((pushClient?.getPushId())!, topic: "message", msg: 2) {
                [unowned self] (data, response, error) in
                if let hasData = data{
                    let dataStr = NSString(data: hasData, encoding: NSUTF8StringEncoding)
                    
                    XCTAssertTrue(dataStr == self.successCode, "ret code is not success when sending message : 2")
                    
                    self.send((self.pushClient?.getPushId())!, topic: "message", msg: 3, completion: {
                        [unowned self](data, response, error) in
                        if let hasData = data{
                            let dataStr = NSString(data: hasData, encoding: NSUTF8StringEncoding)
                            
                            XCTAssertTrue(dataStr == self.successCode, "ret code is not success when sending message : 3")
                            
                            self.pushClient?.connect()
                        }
                        
                    })
                }
            }
        } //end of if firstTime
        else if !reconnect {
            
            NSLog("receive : \(dataDic?["message"])")
            
            if push.count > 0{
                
                XCTAssertTrue(dataDic?["message"] as? Int == push.removeAtIndex(0), "receive message : \(dataDic?["message"] as? Int) is not equal to push array.first ")
                
                if push.count == 1 {
                    send((pushClient?.getPushId())!, topic: "message", msg: 4, completion: {
                        (data, response, error) in
                    
                    })
                }
                
            }
            
            if push.count == 0 {
                pushClient?.disconnect()
                reconnect = true
                pushClient?.connect()
            }
        }
        else{//reconnect
            XCTAssertTrue(dataDic?["message"] as? String == confirmCode, "ret value after reconnect : \(dataDic?["message"] as? String) does not match ")
            
            expectation?.fulfill()
        }
        
        
    }
    
    
    //MARK : - ConnectCallback
    
    func onConnect(uid: String) {
        NSLog("on connect")
        
        if !reconnect {
            send((pushClient?.getPushId())!, topic: "message", msg: 1) {
                (data, response, error) in
                if let hasData = data{
                    let dataStr = NSString(data: hasData, encoding: NSUTF8StringEncoding)
                    
                    XCTAssertTrue(dataStr == self.successCode, "ret code is not success when sending message : 1")
                    
                    NSLog("call api success")
                }
            }
        }
        else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(5 * NSEC_PER_SEC)), dispatch_get_main_queue()){
                [unowned self] in
                self.pushClient?.disconnect()
            }
        }
        
        
    }
    
    func onDisconnect() {
        
    }
    
    
    //MARK: - Helpers
    
    func send(pushId:String,topic:String,msg:AnyObject,completion:(NSData?, NSURLResponse?, NSError?) -> Void){
        let dic : NSDictionary = [
            "message" : msg
        ]
        var jsonData : NSData! = nil
        do{
            jsonData = try NSJSONSerialization.dataWithJSONObject(dic, options: .PrettyPrinted)
        }catch _{
            return
        }
        
        guard let jsonStr = NSString(data: jsonData, encoding: NSUTF8StringEncoding) else{
            return
        }
        
        let set : NSMutableCharacterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        
        guard let encodedStr = jsonStr.stringByAddingPercentEncodingWithAllowedCharacters(set) else{
            return
        }
        
        let jsonUrl = String(format: pushUrl, pushId,topic,encodedStr)
        guard let reqUrl = NSURL(string: jsonUrl)  else{
            return
        }
        let urlReq = NSURLRequest(URL: reqUrl)
        
        let manager = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask = manager.dataTaskWithRequest(urlReq ,completionHandler: completion)
        dataTask.resume()
        
    }
    
}
