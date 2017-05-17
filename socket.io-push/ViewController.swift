//
//  ViewController.swift
//  misakaDemo
//
//  Created by crazylhf on 15/10/26.
//  Copyright © 2015年 crazylhf. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PushCallbackDelegate{
    
    let url = "http://spush.yy.com/api/push?pushAll=true&topic=chatRoom&json=%@&timeToLive="
    
    fileprivate var socketIOClient:SocketIOProxyClientOC!
    fileprivate var lastTimestamp = Date()
    
    fileprivate let msgType = "chat_message"
    
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var chatTableView: UITableView!
    weak var tapView : UIView?
    let reuseId = "chatContentCell"
    
    var userName : String!
    
    fileprivate var chats : [ChatInfo]!
    
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
        if AppDelegate.isTesting() {
            return
        }
        socketIOClient = (UIApplication.shared.delegate as! AppDelegate).socketIOClient
        socketIOClient.pushCallbackDelegate = self
        socketIOClient.subscribeBroadcast("chatRoom")
        
        self.chatTableView.separatorColor = UIColor.clear
        
        if #available(iOS 8.0, *) {
            let userNameInputAlert = UIAlertController(title: "用户名", message: "userName", preferredStyle: .alert)
            
            
            userNameInputAlert.addTextField(configurationHandler: { [unowned self](textField) in
                textField.placeholder = "Input user name"
                textField.delegate = self
                })
            
            let ok = UIAlertAction(title: "ok", style: .default, handler: { [unowned self] (action) in
                self.userName = userNameInputAlert.textFields?[0].text
                NSLog("\(userNameInputAlert.textFields![0].text)")
                })
            
            userNameInputAlert.addAction(ok)
            self.present(userNameInputAlert, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
            let userNameInputAlert = UIAlertView(title: "用户名", message: "userName", delegate: self, cancelButtonTitle: "ok")
            userNameInputAlert.alertViewStyle = .plainTextInput
            userNameInputAlert.textField(at: 0)?.delegate = self
            userNameInputAlert.show()
        }
        
        self.registerKeyboardNotifications()
        self.addTapView()
        
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        self.tapView?.frame = self.chatTableView.frame
    }
    
    
    func onDisconnect(){
        print("onDisconnect");
        self.navigationItem.title = "Disconnected"
    }
    
    func onConnect(_ uid: String!, tags: [AnyObject]!) {
        print("onConnect \(uid)");
        let data:[String:String] = [
            "uid" : "123",
            "token" : "test"
        ]
        
        (UIApplication.shared.delegate as! AppDelegate).socketIOClient.bindUid(data)
        self.navigationItem.title = "Connected"
    }
    
    func onPush(_ data: Data) {
        
        var dataDic : NSDictionary?
        do{
            dataDic = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary
        }catch _{
            return
        }
        
        self.parseChatDic(dataDic)
        
    }
    
    func log(_ level: String, message: String) {
        NSLog("Level : \(level) , message : \(message)")
    }
    
    //MARK: - Helpers
    
    func registerKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    
    func sendChat(_ msg:String){
        
        let message = msg
        
        
        let chatDic = [
            "nickName" : self.userName,
            "message" : message,
            "type" : msgType
        ]
        
        var jsonData : Data! = nil
        do{
            
            jsonData = try JSONSerialization.data(withJSONObject: chatDic, options: .prettyPrinted)
        }catch _{
            return
        }
        
        guard let jsonStr = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) else{
            return
        }
        
        let set : NSMutableCharacterSet = NSMutableCharacterSet.alphanumeric()
        
        guard let encodedStr = jsonStr.addingPercentEncoding(withAllowedCharacters: set as CharacterSet) else{
            return
        }
        
        let jsonUrl = String(format: url, encodedStr)
        
        guard let reqUrl = URL(string: jsonUrl)  else{
            return
        }
        let urlReq = URLRequest(url: reqUrl)
        
        let manager = URLSession(configuration: URLSessionConfiguration.default)
        let dataTask = manager.dataTask(with: urlReq)
        
        dataTask.resume()
    }
    
    
    func parseChatDic(_ dic:NSDictionary?){
        if let dataDic = dic {
            
            let chatInfo = ChatInfo()
            chatInfo.nickName = dataDic["nickName"] as? String
            chatInfo.message = dataDic["message"] as? String
            chatInfo.type = dataDic["type"] as? String
            
            if chatInfo.type != msgType {
                return
            }
            
            if chats == nil {
                chats = [ChatInfo]()
            }
            
            let idx = IndexPath(row: chats.count, section: 0)
            chats.append(chatInfo)
            self.chatTableView.insertRows(at: [idx], with: .fade)
            self.chatTableView.scrollToRow(at: idx, at: .bottom, animated: true)
        }
    }
    
    func addTapView(){
        if self.tapView == nil {
            let view = UIView()
            self.view.addSubview(view)
            self.tapView = view
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
            self.tapView?.addGestureRecognizer(tap)
        }
    }
    
    func hideKeyboard(){
        self.chatTextField.resignFirstResponder()
    }
    
    
}


//MARK: - TableView Data Source
extension ViewController:UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats == nil ?  0 :chats!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: reuseId)
        if cell == nil {
            cell = UITableViewCell(style: .default , reuseIdentifier: reuseId)
        }
        
        let chat = chats[indexPath.row]
        cell.textLabel?.text = chat.nickName + ":" + chat.message
        
        
        return cell
    }
}

//MARK: - TableView Delegate
extension ViewController:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


//MARK: - UITextField Delegate

extension ViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == self.chatTextField{
            
            sendChat(textField.text!)
            
            textField.text = ""
        }
            
        else{
            if textField.text == nil || textField.text == "" {
                return false
            }
            self.userName = textField.text
        }
        
        //        textField.resignFirstResponder()
        return true
    }
    
}



//MARK: - Notification Callbacks

extension ViewController{
    func keyboardWillChange(_ noti:Notification){
        
        if !self.chatTextField.isFirstResponder{
            return
        }
        if let height = (noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height{
            if height > 0 {
                self.tapView?.isHidden = false
            }
            self.textFieldBottomConstraint.constant = height
            self.chatTextField.setNeedsLayout()
            var idx = -1
            if self.chats != nil && self.chats.count > 0 {
                idx = self.chats.count - 1
            }
            UIView.animate(withDuration: 0.25, animations: {
                [unowned self] in
                self.view.layoutIfNeeded()
                if idx  >= 0{
                    let index = IndexPath(row: idx, section: 0)
                    
                    self.chatTableView.scrollToRow(at: index, at: .bottom, animated: true)
                }
                
            })
            
        }
    }
    
    func keyboardWillHide(_ noti:Notification){
        self.tapView?.isHidden = true
        UIView.animate(withDuration: 0.25, animations: {
            [unowned self] in
            self.textFieldBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
            
        })
    }
}
