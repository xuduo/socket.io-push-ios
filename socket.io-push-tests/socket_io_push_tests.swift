//
//  Socket_io_push_tests.swift
//  Socket.io-push_tests
//
//  Created by 蔡阳 on 16/5/12.
//  Copyright © 2016年 Gocy. All rights reserved.
//
//
//  misakaDemoTests.swift
//  misakaDemoTests
//
//  Created by 蔡阳 on 16/5/10.
//  Copyright © 2016年 crazylhf. All rights reserved.
//

import XCTest
@testable import Socket_io_push

class Socket_io_push_tests: XCTestCase ,PushCallback ,ConnectCallback{
    
    
    var socketIOClient : SocketIOProxyClient!
    let chatRoomUrl = "http://spush.yy.com/api/push?pushId=%@&topic=chatRoom&json=%@&timeToLive=10000"
    let messageUrl = "http://spush.yy.com/api/push?pushId=%@&topic=message&json=%@"
    let host = "http://spush.yy.com"
    
    private let expectedType = "chat_message"
    
    var lastPushDic : NSDictionary?
    var lastPushArray : NSArray?
    var lastPushString : String?
    
    var expectationForDic : XCTestExpectation?
    var expectationForArr : XCTestExpectation?
    var expectationForStr : XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //        vc.sendChat("Chat From Test")
        expectationForDic = self.expectationWithDescription("Async request for dic")
        expectationForArr = self.expectationWithDescription("Async request for arr")
        expectationForStr = self.expectationWithDescription("Async request for str")
        
        
        socketIOClient = SocketIOProxyClient(host:host)
        socketIOClient.pushCallback = self
        socketIOClient.connectCallback = self
        
        socketIOClient.subscribeBroadcast("chatRoom")
        socketIOClient.subscribeBroadcast("message")
        
        self.waitForExpectationsWithTimeout(150, handler: nil)
    }

    func onPush(dataStr: String) {
        
        if dataStr == self.lastPushString && self.lastPushString != nil {
            NSLog("String test passed")
            expectationForStr?.fulfill()
            return
        }
        
        guard let data = dataStr.dataUsingEncoding(NSUTF8StringEncoding)
            else{
                XCTAssert(false, "data str encoding is not utf-8")
                return
        }
        
        var dataDic : NSDictionary?
        var dataArr : NSArray?
        do{
            dataDic = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? NSDictionary
            dataArr = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? NSArray
        }catch _{
            
        }
        
        if dataDic != nil{
            XCTAssertTrue(dataDic == self.lastPushDic, "received dic is not equal to last push dic")
            NSLog("Dictionary test passed")
            expectationForDic?.fulfill()
            return
        }
        
        if dataArr != nil{
            XCTAssertTrue(dataArr == self.lastPushArray, "received array is not equal to last push array")
            NSLog("Array test passed")
            expectationForArr?.fulfill()
            return
        }
        
        XCTAssertTrue(false, "received data doesn't match any pushed data")
        
    }
    func onConnect(uid: String) {
        self.sendChat("This is a test message")
        self.sendString()
        self.sendArray()
    }
    
    func onDisconnect() {
        
    }
    
    func sendChat(msg:String?){
        
        let message = msg == nil ? "" : msg!
        
        let chatDic : NSDictionary = [
            "nickName" : "Socket-io test",
            "message" : message,
            "type" : expectedType
        ]
        
        self.lastPushDic = chatDic.copy() as? NSDictionary
        
        var jsonData : NSData! = nil
        do{
            
            jsonData = try NSJSONSerialization.dataWithJSONObject(chatDic, options: .PrettyPrinted)
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
        
        let jsonUrl = String(format: chatRoomUrl, socketIOClient.getPushId(), encodedStr)
        
        sendToUrl(jsonUrl)
    }
    
    func sendString(){
        let testString = "this is a test String"
        
        self.lastPushString = testString
        
        let jsonString = "\"\(testString)\""
        
        let set : NSMutableCharacterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        
        guard let encodedStr = jsonString.stringByAddingPercentEncodingWithAllowedCharacters(set) else{
            return
        }
        
        let jsonUrl = String(format: messageUrl, socketIOClient.getPushId(), encodedStr)
        
        sendToUrl(jsonUrl)
        
    }
    
    func sendArray(){
        let arr = [1,"2",3]
        
        self.lastPushArray = arr as NSArray
        
        var jsonData : NSData! = nil
        do{
            
            jsonData = try NSJSONSerialization.dataWithJSONObject(arr, options: .PrettyPrinted)
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
        
        let jsonUrl = String(format: messageUrl, socketIOClient.getPushId(), encodedStr)
        
        sendToUrl(jsonUrl)

    }
    
    func sendToUrl(url:String){
        guard let reqUrl = NSURL(string: url)  else{
            return
        }
        let urlReq = NSURLRequest(URL: reqUrl)
        let manager = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask = manager.dataTaskWithRequest(urlReq)         
        dataTask.resume()
    }
    
}
