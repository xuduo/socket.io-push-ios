//
//  ttl_server_topic_test.swift
//  socket.io-push
//
//  Created by Gocy on 16/5/17.
//  Copyright © 2016年 Gocy. All rights reserved.
//

import XCTest
@testable import Socket_io_push

class ttl_server_topic_test: XCTestCase ,PushCallback,ConnectCallback{
    
    let host = "http://spush.yy.com"
    let pushUrl = "http://spush.yy.com/api/push?pushAll=%@&topic=%@&json=%@&timeToLive=10000"
    let successCode = "{\"code\":\"success\"}"
    var send = false
    var pushClient : SocketIOProxyClient?
    
    var expectation : XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        pushClient?.disconnect()
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        expectation = self.expectationWithDescription("Async Request for topic test")
        send(true, topic: "message", msg: 1) {
            [unowned self] (data, response, error) in
            if let hasData = data{
                let dataStr = NSString(data: hasData, encoding: NSUTF8StringEncoding)
                
                XCTAssertTrue(dataStr == self.successCode, "ret code is not success")
                
                self.pushClient = SocketIOProxyClient(host: self.host)
                self.pushClient?.pushCallback = self
                self.pushClient?.connectCallback = self
                self.pushClient?.subscribeBroadcastReceiveTTL("message")
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC)), dispatch_get_main_queue()){
                    [unowned self] in
                    self.send(true, topic: "message", msg: 2, completion: { (data, response, error) in
                        
                    })
                }
            }
        }
        
        
        self.waitForExpectationsWithTimeout(60, handler: nil)

    }
    
    
    
    
    func send(pushAll:Bool,topic:String,msg:AnyObject,completion:(NSData?, NSURLResponse?, NSError?) -> Void){
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
        
        let jsonUrl = String(format: pushUrl, pushAll ? "true":"false",topic,encodedStr)
        guard let reqUrl = NSURL(string: jsonUrl)  else{
            return
        }
        let urlReq = NSURLRequest(URL: reqUrl)
        
        let manager = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask = manager.dataTaskWithRequest(urlReq ,completionHandler: completion)
        dataTask.resume()
        
    }
    
    //MARK: - PushCallback
    func onPush(dataStr: String) {
        guard let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding) else{return}
        
        var dataDic : NSDictionary?
        do{
            dataDic = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? NSDictionary
        }catch _{
            return
        }
        
        if !send {
            //expect data == 2
            
            XCTAssertTrue(2 == dataDic?["message"] as? Int, "message should be 2 ,but returns : \(dataDic?["message"] as? String)")
            
            self.pushClient?.disconnect()
            
        }else{
            
            XCTAssertTrue(3 == dataDic?["message"] as? Int, "message should be 3 ,but returns : \(dataDic?["message"] as? String)")
            
            pushClient?.disconnect()
            
            expectation?.fulfill()

        }
        
    }
    
    
    //MARK: - ConnectCallback
    func onConnect(uid: String) {
        
    }
    
    func onDisconnect() {
        NSLog("pushClient.onDisconnect()")
        if !send{
            send = true
            send(true, topic: "message", msg: 3, completion: {
                [unowned self] (data, response, error) in
                if let hasData = data{
                    let dataStr = NSString(data: hasData, encoding: NSUTF8StringEncoding)
                    
                    XCTAssertTrue(dataStr == self.successCode, "ret code is not success")
                    
                    self.pushClient?.connect()
                    
                }
            })
        }
    }
}
