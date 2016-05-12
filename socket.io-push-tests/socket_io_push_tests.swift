//
//  Socket_io_pushTests.swift
//  Socket.io-pushTests
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

class Socket_io_pushTests: XCTestCase ,PushCallback ,ConnectCallback{
    
    
    var socketIOClient : SocketIOProxyClient!
    let url = "http://spush.yy.com/api/push?pushId=%@&topic=chatRoom&json=%@&timeToLive="
    let host = "http://spush.yy.com"
    
    
    var chatDic : NSDictionary?
    
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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //        vc.sendChat("Chat From Test")
        expectation = self.expectationWithDescription("Async request")
        
        
        socketIOClient = SocketIOProxyClient(host:host)
        socketIOClient.pushCallback = self
        socketIOClient.connectCallback = self
        
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
        socketIOClient.subscribeBroadcast("chatRoom")
        
    }

    
    func onPush(topic: String, data: NSData?) {
        guard let hasData = data else{
            NSLog("on Push , data equals nil")
            return
        }
        
        var dataDic : NSDictionary?
        do{
            dataDic = try NSJSONSerialization.JSONObjectWithData(hasData, options: .AllowFragments) as? NSDictionary
        }catch _{
            return
        }
        
        XCTAssertNotNil(self.chatDic != nil, "chatDic shouldn't be nil")
        
        XCTAssertNotNil(dataDic, "dataDic shouldn't be nil")
        
        NSLog("\nLogFromTest:\nChatDic:\(self.chatDic!),\nDataDic:\(dataDic!)")
        
        
        XCTAssertTrue(self.chatDic!.isEqualToDictionary(dataDic! as Dictionary<NSObject,AnyObject>), "Equal")
        
        expectation?.fulfill()
    }
    
    func onConnect(uid: String) {
        self.sendChat("This is a test message")
    }
    
    func onDisconnect() {
        
    }
    
    func sendChat(msg:String?){
        
        let message = msg == nil ? "" : msg!
        
        let chatDic = [
            "nickName" : "Socket-io test",
            "message" : message,
            "color": -16776961
        ]
        
        self.chatDic = chatDic.copy() as? NSDictionary
        
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
        
        let jsonUrl = String(format: url, socketIOClient.getPushId(), encodedStr)
        
        guard let reqUrl = NSURL(string: jsonUrl)  else{
            return
        }
        let urlReq = NSURLRequest(URL: reqUrl)
        
        let manager = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask = manager.dataTaskWithRequest(urlReq)
        
        dataTask.resume()
    }
    
}
