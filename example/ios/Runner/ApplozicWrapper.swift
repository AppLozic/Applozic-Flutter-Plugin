//
//  ApplozicWrapper.swift
//  Runner
//
//  Created by Shubham Tewari on 29/12/20.
//  Copyright © 2020 shubham. All rights reserved.
//

import Foundation
import Applozic
import ApplozicSwift
import UserNotifications
import applozic_flutter

@objc public class ApplozicWrapper: NSObject {

    @objc public static let shared = ApplozicWrapper()

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("Device token data :: \(deviceToken.description)")
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count {
          deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        NSLog("Device token :: \(deviceTokenString)")
        if (ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString) {
        let alRegisterUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
        alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
        if error == nil {
            print("Error in Registration: " + error!.localizedDescription)
        }
        print("Registration Response :: \(response)")
        })
      }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForNotification()
        // Override point for customization after application launch.
        ALKPushNotificationHandler.shared.dataConnectionNotificationHandlerWith(ALChatManager.defaultConfiguration)
        let alApplocalNotificationHnadler : ALAppLocalNotifications =  ALAppLocalNotifications.appLocalNotificationHandler();
        alApplocalNotificationHnadler.dataConnectionNotificationHandler();
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

            print("APP_ENTER_IN_BACKGROUND")
          NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_BACKGROUND"), object: nil)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {

            ALPushNotificationService.applicationEntersForeground()
          print("APP_ENTER_IN_FOREGROUND")

          NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
          UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(application: UIApplication) {
        ALDBHandler.sharedInstance().saveContext()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let service = ALPushNotificationService()
          guard !service.isApplozicNotification(notification.request.content.userInfo) else {
      service.notificationArrived(to: UIApplication.shared, with: notification.request.content.userInfo)
           completionHandler([])
          return
        }
        completionHandler([.sound, .badge, .alert])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let service = ALPushNotificationService()
          let dict = response.notification.request.content.userInfo
          guard !service.isApplozicNotification(dict) else {
          switch UIApplication.shared.applicationState {
            case .active:
            service.processPushNotification(dict, updateUI: NSNumber(value: APP_STATE_ACTIVE.rawValue))
              case .background:
            service.processPushNotification(dict, updateUI: NSNumber(value: APP_STATE_BACKGROUND.rawValue))
              case .inactive:
            service.processPushNotification(dict, updateUI: NSNumber(value: APP_STATE_INACTIVE.rawValue))
          }
          completionHandler()
            return
        }
        completionHandler()
    }

    func registerForNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in

            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
