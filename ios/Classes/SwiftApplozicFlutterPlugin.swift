import Flutter
import UIKit
import Applozic
import os.log

public class SwiftApplozicFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "applozic_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftApplozicFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "login") {
            guard let userDict = call.arguments as? Dictionary<String, Any> else {
                self.sendErrorResultWithCallback(result: result, message: "Unable to parse user JSON")
                return
            }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: userDict, options: .prettyPrinted)
                let jsonString = String(bytes: jsonData, encoding: .utf8)
                
                let alUser = ALUser.init(jsonString: jsonString)
                
                guard let user = alUser  else {
                    self.sendErrorResultWithCallback(result: result, message: "Unable to parse user JSON")
                    return
                }
                
                let chatManager = ALChatManager.init(applicationKey: user.applicationId as NSString)
                chatManager.connectUserWithCompletion(user) { (response, error) in
                    guard  error == nil else  {
                        self.sendErrorResultWithCallback(result: result, message: error!.localizedDescription)
                        return
                    }
                    
                    self.sendSuccessResultWithCallback(result: result, object: (response?.dictionary())!)
                }
            } catch {
                self.sendErrorResultWithCallback(result: result, message: error.localizedDescription)
            }
        } else if(call.method == "isLoggedIn") {
            result(ALUserDefaultsHandler.isLoggedIn())
        } else if(call.method == "logout") {
            let registerUserClientService = ALRegisterUserClientService()
            registerUserClientService.logout { (response, error) in
                if(error == nil) {
                    self.sendSuccessResultWithCallback(result: result, message: "Success")
                } else {
                    self.sendErrorResultWithCallback(result: result, message: error!.localizedDescription)
                }
            }
        } else if(call.method == "launchChatScreen") {
            self.getChatManager(result: result).launchChat(UIApplication.topViewController()!)
        } else if(call.method == "launchChatWithUser") {
            self.getChatManager(result: result).launchChatForUser(call.arguments as! String, fromViewController: UIApplication.topViewController()!)
            self.sendSuccessResultWithCallback(result: result, message: "Success")
        } else if(call.method == "launchChatWithGroupId") {
            var groupId = NSNumber(0)
            
            if let channelKey = call.arguments as? String {
                groupId = Int(channelKey)! as NSNumber
            } else if let channelKey = call.arguments as? Int {
                groupId = NSNumber(value: channelKey)
            } else {
                sendErrorResultWithCallback(result: result, message: "Invalid groupId")
                return
            }
            
            if(groupId == 0) {
                sendErrorResultWithCallback(result: result, message: "Invalid groupId")
                return
            }
            
            let channelService = ALChannelService()
            channelService.getChannelInformation(groupId, orClientChannelKey: nil) { (channel) in
                guard channel != nil else {
                    self.sendErrorResultWithCallback(result: result, message: "Channel is null, internal error occured")
                    return
                }
                self.getChatManager(result: result).launchChatForGroup((channel?.key!)!, fromController: UIApplication.topViewController()!)
                self.sendSuccessResultWithCallback(result: result, message: channel!.clientChannelKey!)
            }
        } else if(call.method == "createGroup") {
            guard let channelInfo = call.arguments as? Dictionary<String, Any> else {
                self.sendErrorResultWithCallback(result: result, message: "Unable to parse groupInfo object")
                return
            }
            var membersList = NSMutableArray();
            
            if(channelInfo["groupMemberList"] != nil) {
                membersList = channelInfo["groupMemberList"] as! NSMutableArray
            }
            
            let channelService = ALChannelService()
            channelService.createChannel(channelInfo["groupName"] as? String,orClientChannelKey: channelInfo["clientGroupId"] as? String, andMembersList: membersList, andImageLink: channelInfo["imageUrl"] as? String, channelType: channelInfo["type"] as! Int16, andMetaData: channelInfo["metadata"] as? NSMutableDictionary, adminUser: channelInfo["admin"] as? String, withGroupUsers: channelInfo["users"] as? NSMutableArray) {
                (alChannel, error) in
                if(error == nil) {
                    self.sendSuccessResultWithCallback(result: result, message: (alChannel?.key.stringValue)!)
                } else {
                    self.sendErrorResultWithCallback(result: result, message: error!.localizedDescription)
                }
            }
        } else if(call.method == "updateUserDetail") {
            guard let user = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: "Invalid kmUser object")
                return
            }
            if(ALUserDefaultsHandler.isLoggedIn()) {
                let userClientService = ALUserClientService()
                userClientService.updateUserDisplayName(user["displayName"] as? String, andUserImageLink: user["imageLink"] as? String, userStatus: user["status"] as? String, metadata: user["metadata"] as? NSMutableDictionary) { (_, error) in
                    guard error == nil else {
                        self.sendErrorResultWithCallback(result: result, message: error!.localizedDescription)
                        return
                    }
                    self.sendSuccessResultWithCallback(result: result, message: "Success")
                }
            } else {
                sendErrorResultWithCallback(result: result, message: "User not authorised. This usually happens when calling the function before login. Make sure you call either of the two functions before updating the user details")
            }
        } else if(call.method == "addContacts") {
            let contactService = ALContactService()
            guard let dictArray = call.arguments as? [Dictionary<String, Any>] else {
                sendErrorResultWithCallback(result: result, message: "Unable to parse contact data")
                return
            }
            
            if(dictArray.count > 0) {
                for userDict in dictArray {
                    let userDetail = ALContact(dict: userDict)
                    contactService.updateOrInsert(userDetail)
                }
                sendSuccessResultWithCallback(result: result, message: "Success")
            }
        } else if(call.method == "getLoggedInUserId") {
            if(ALUserDefaultsHandler.isLoggedIn()) {
                self.sendSuccessResultWithCallback(result: result, message: ALUserDefaultsHandler.getUserId()!)
            } else {
                self.sendErrorResultWithCallback(result: result, message: "User not authorised. UserId is empty")
            }
        } else if(call.method == "sendMessage") {
            do {
                guard let alMessageDict = call.arguments as? Dictionary<String, Any> else {
                    sendErrorResultWithCallback(result: result, message: "Invalid message object")
                    return
                }
                let jsonData = try JSONSerialization.data(withJSONObject: alMessageDict, options: .prettyPrinted)
                let jsonString = String(bytes: jsonData, encoding: .utf8)
                
                let alMessage = ALMessage.init(jsonString: jsonString)
                
                guard let message = alMessage  else {
                    self.sendErrorResultWithCallback(result: result, message: "Unable to parse message JSON")
                    return
                }
                let applicationKey = ALUserDefaultsHandler.getApplicationKey()
                if(applicationKey != nil) {
                    let alChatManager = ALChatManager.init(applicationKey: applicationKey! as NSString)
                    alChatManager.sendMessage(alMessage: message) { (response, error) in
                    if(error == nil) {
                        self.sendSuccessResultWithCallback(result: result, message: "Successfully sent message")
                        return
                    } else {
                        self.sendErrorResultWithCallback(result: result, message: "Error sending message")
                        return
                    }
                }
                } else {
                    sendErrorResultWithCallback(result: result, message: "Seems like you have not logged in!")
                    return
                }
            } catch {
                self.sendErrorResultWithCallback(result: result, message: error.localizedDescription)
            }
        } else if (call.method == "addMemberToGroup") {
            guard let alMessageDict = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
            if(alMessageDict.keys.contains("userId") && (alMessageDict.keys.contains("groupId") || alMessageDict.keys.contains("clientChannelKey"))) {
                let alChannelService = ALChannelService();
                guard let userId = alMessageDict["userId"] else {
                    sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                    return
                }
                let channelKey = alMessageDict["groupId"]
                let clientChannelKey = alMessageDict["clientGroupId"]
                guard channelKey != nil || clientChannelKey != nil else {
                    sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                    return
                }
                alChannelService.addMember(toChannel: (userId as! String), andChannelKey: (channelKey as? NSNumber), orClientChannelKey: (clientChannelKey as? String)) { (error, aLAPIResponse) in
                    if(error == nil && aLAPIResponse != nil && aLAPIResponse?.status == "success" ) {
                        self.sendSuccessResultWithCallback(result: result, message: "Added member successfully to channel")
                        print("Added member successfully in channel")
                        return
                    }
                    else {
                        self.sendErrorResultWithCallback(result: result, message: "Error adding member to channel")
                        print("Error adding member to channel")
                        return
                    }
                }
            } else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
        } else if (call.method == "removeMemberFromGroup") {
            guard let alMessageDict = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
            if(alMessageDict.keys.contains("userId") && (alMessageDict.keys.contains("groupId") || alMessageDict.keys.contains("clientChannelKey"))) {
                    let alChannelService = ALChannelService();
                guard let userId = alMessageDict["userId"] else {
                    sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                    return
                }
                let channelKey = alMessageDict["groupId"]
                let clientChannelKey = alMessageDict["clientGroupId"]
                guard channelKey != nil || clientChannelKey != nil else {
                    sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                    return
                }
                alChannelService.removeMember(fromChannel: (userId as! String), andChannelKey: (channelKey as? NSNumber), orClientChannelKey: (clientChannelKey as? String)) { (error, aLAPIResponse) in
                        if(error == nil && aLAPIResponse != nil && aLAPIResponse?.status == "success" ) {
                            self.sendSuccessResultWithCallback(result: result, message: "Removed member successfully from channel")
                            print("Removed member successfully from channel")
                            return
                        } else {
                            self.sendErrorResultWithCallback(result: result, message: "Error removing member from channel")
                            print("Error removing member from channel")
                            return
                        }
                    }
            } else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
        } else if (call.method == "getUnreadCountForContact") {
            let contactService = ALContactService()
            guard let userId = call.arguments else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
            let contact = contactService.loadContact(byKey: "userId", value: (userId as! String))
            let unreadCount = contact?.unreadCount
            sendSuccessResultWithCallback(result: result, message: unreadCount ?? 0)
        } else if (call.method == "getUnreadCountForChannel") {
            let channelService = ALChannelService()
            guard let detailsDict = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
            
            if (detailsDict.keys.contains("groupId")) {
                guard let groupId = detailsDict["groupId"] else {
                    sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                    return
                }
                let channel = channelService.getChannelByKey(groupId as? NSNumber)
                let unreadCount = channel?.unreadCount
                sendSuccessResultWithCallback(result: result, message: unreadCount ?? 0)
            } else {
                sendErrorResultWithCallback(result: result, message: "Invalid parameters")
                return
            }
        } else if (call.method == "getUnreadChatsCount") {
            var applozicClient = ApplozicClient()
            applozicClient = ApplozicClient(applicationKey: getApplicationKey() as String) as ApplozicClient
            var unreadChatCounts = NSNumber(0)
            applozicClient.getLatestMessages(false, withCompletionHandler: { messageList, error in
                        if error == nil {
                            for message in messageList! {
                                let message = message as! ALMessage
                                var unreadCount = NSNumber(0)
                                if(message.getGroupId() != nil) {
                                    let channelService = ALChannelService()
                                    let channel = channelService.getChannelByKey(message.getGroupId())
                                    unreadCount = channel?.unreadCount ?? 0
                                } else {
                                    let contactService = ALContactService()
                                    let contact = contactService.loadContact(byKey: "userId", value: message.to)
                                    unreadCount = contact?.unreadCount ?? 0
                                }
                                if(unreadCount.intValue > 0) {
                                    unreadChatCounts = NSNumber(value: unreadChatCounts.intValue + 1)
                                }
                            }
                            self.sendSuccessResultWithCallback(result: result, message: unreadChatCounts)
                        } else {
                            self.sendErrorResultWithCallback(result: result, message: "Error getting unread chats count")
                            return
                        }
                    })
        } else if (call.method == "getTotalUnreadCount") {
            let userService = ALUserService()
            let totalUnreadCount = userService.getTotalUnreadCount()
            if (totalUnreadCount != nil) {
                sendSuccessResultWithCallback(result: result, message: totalUnreadCount ?? 0)
            } else {
                sendErrorResultWithCallback(result: result, message: "Error getting total unread count")
                return
            }
        } else if (call.method == "createToast") {
            //not implemented for ios
            //this method will not be in public docs, it's used internally for android
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    func sendSuccessResultWithCallback(result: FlutterResult, message: Any) {
        result(message)
    }
    
    func sendErrorResultWithCallback(result: FlutterResult, message: String) {
        result(FlutterError(code: "Error", message: message, details: nil))
    }
    
    func sendSuccessResultWithCallback(result: FlutterResult, object: [AnyHashable : Any]) {
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            let jsonString = String(bytes: jsonData, encoding: .utf8)
            result(jsonString)
        } catch {
            sendSuccessResultWithCallback(result: result, message: "Success")
        }
    }
    
    func getChatManager(result: FlutterResult) -> ALChatManager {
        let applicationKey = ALUserDefaultsHandler.getApplicationKey()
        if(applicationKey != nil) {
            return ALChatManager.init(applicationKey: applicationKey! as NSString)
        } else {
            sendErrorResultWithCallback(result: result, message: "Seems like you have not logged in!")
        }
        return ALChatManager.init(applicationKey: applicationKey! as NSString)
    }
    
    func customBackAction() {
        UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }}
