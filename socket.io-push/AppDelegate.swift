//
//  AppDelegate.swift
//  misakaDemo
//
//  Created by crazylhf on 15/10/26.
//  Copyright © 2015年 crazylhf. All rights reserved.
//

import UIKit


@UIApplicationMain
open class AppDelegate: UIResponder, UIApplicationDelegate {
    
    open var window: UIWindow?
//    public var socketIOClient:SocketIOProxyClient!
    open var socketIOClient:SocketIOProxyClientOC!
    
    
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if(AppDelegate.isTesting()){
            return true
        }
    
        let url = "https://spush.yy.com"
        socketIOClient = SocketIOProxyClientOC.initWith(url)
        
        // Register for push in iOS 8
        if #available(iOS 8.0, *) {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            UIApplication.shared.registerForRemoteNotifications(matching: [.alert, .badge, .sound])
        }
        
        self.socketIOClient.sendClickStats(launchOptions);
        print("didFinishLaunchingWithOptions \(UIApplication.shared.applicationState == UIApplicationState.active)  \(launchOptions)");
//        let notification = UILocalNotification()
//        notification.alertBody = "Todo Item 1 Is Overdue" // text that will be displayed in the notification
//        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
//        notification.fireDate = NSDate(timeIntervalSinceNow: 10) // todo item due date (when notification will be fired) notification.soundName = UILocalNotificationDefaultSoundName // play default sound
//        notification.userInfo = ["title": "test", "UUID": "12344"] // assign a unique identifier to the notification so that we can retrieve it later
//        
//        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        
        return true
    }
    
    open func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    open func applicationDidEnterBackground(_ application: UIApplication) {
        
        self.socketIOClient.keepInBackground()
    }
    
    var taskId:UIBackgroundTaskIdentifier?
    
    func doUpdate () {
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            
            self.taskId = self.beginBackgroundUpdateTask()
            
            print(" application.backgroundTimeRemaining %d",UIApplication.shared.backgroundTimeRemaining)
            
        })
    }
    
    func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.shared.beginBackgroundTask(expirationHandler: {})
    }
    
    func endBackgroundUpdateTask(_ taskID: UIBackgroundTaskIdentifier) {
        UIApplication.shared.endBackgroundTask(taskID)
    }
    
    open func applicationWillEnterForeground(_ application: UIApplication) {
        //  self.endBackgroundUpdateTask(self.taskId!)
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    open func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    open func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        self.socketIOClient.onApnToken(deviceToken.description)
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError")
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification  \(UIApplication.shared.applicationState == UIApplicationState.active), \(userInfo.description)");
        self.socketIOClient.sendClickStats(userInfo);
    }
    
    open func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("2")
    }
    
    open func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], withResponseInfo responseInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        print("3")
    }
    
    static func isTesting() -> Bool{
        let dic = ProcessInfo.processInfo.environment
        let isInUnitTest = dic["IS_IN_UNIT_TEST"]
        NSLog("\(isInUnitTest)")
        
        return isInUnitTest == "YES"
    }
    
}

