import Flutter
import UIKit
import Applozic
import os.log

var ERROR = "Error"
var SUCCESS = "Success"
var ERROR_INTERNAL = "Some internal error occurred."
var ERROR_ILLEGAL_ARGUMENTS = "Invalid arguments."

public class SwiftApplozicFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "applozic_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftApplozicFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "login") {
            guard let userDict = call.arguments as? Dictionary<String, Any> else {
                self.sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: userDict, options: .prettyPrinted)
                let jsonString = String(bytes: jsonData, encoding: .utf8)
                
                let alUser = ALUser.init(jsonString: jsonString)
                
                guard let user = alUser  else {
                    self.sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                
                let chatManager = ALChatManager.init(applicationKey: user.applicationId as NSString)
                chatManager.connectUser(user) { (response, error) in
                    guard  error == nil else  {
                        self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + error!.localizedDescription)
                        return
                    }
                    
                    self.sendSuccessResultWithCallback(result: result, object: (response?.dictionary())!)
                }
            } catch {
                self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + error.localizedDescription)
            }
        } else if(call.method == "isLoggedIn") {
            result(ALUserDefaultsHandler.isLoggedIn())
        } else if(call.method == "logout") {
            let registerUserClientService = ALRegisterUserClientService()
            registerUserClientService.logout { (response, error) in
                if(error == nil) {
                    self.sendSuccessResultWithCallback(result: result, message: SUCCESS)
                } else {
                    self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + error!.localizedDescription)
                }
            }
        } else if(call.method == "launchChatScreen") {
            self.getChatManager(result: result).launchChatList(from: UIApplication.topViewController()!, with: ALChatManager.defaultConfiguration)
        } else if(call.method == "launchChatWithUser") {
            self.getChatManager(result: result).launchChatWith(contactId: call.arguments as! String, from: UIApplication.topViewController()!, configuration: ALChatManager.defaultConfiguration, prefilledMessage: nil)
            self.sendSuccessResultWithCallback(result: result, message: SUCCESS)
        } else if(call.method == "launchChatWithGroupId") {
            var groupId = NSNumber(0)
            
            if let channelKey = call.arguments as? String {
                groupId = Int(channelKey)! as NSNumber
            } else if let channelKey = call.arguments as? Int {
                groupId = NSNumber(value: channelKey)
            } else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            
            if(groupId == 0) {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            
            let channelService = ALChannelService()
            channelService.getChannelInformation(groupId, orClientChannelKey: nil) { (channel) in
                guard channel != nil else {
                    self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
                    return
                }
                self.getChatManager(result: result).launchGroupWith(clientGroupId: (channel?.clientChannelKey!)!, from: UIApplication.topViewController()!, configuration: ALChatManager.defaultConfiguration, prefilledMessage: nil)
                self.sendSuccessResultWithCallback(result: result, message: (channel?.dictionary())!)
            }
        } else if(call.method == "createGroup") {
            guard let channelInfo = call.arguments as? Dictionary<String, Any> else {
                self.sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
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
                    self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + error!.localizedDescription)
                }
            }
        } else if(call.method == "updateUserDetail") {
            guard let user = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            if(ALUserDefaultsHandler.isLoggedIn()) {
                let userClientService = ALUserClientService()
                userClientService.updateUserDisplayName(user["displayName"] as? String, andUserImageLink: user["imageLink"] as? String, userStatus: user["status"] as? String, metadata: user["metadata"] as? NSMutableDictionary) { (_, error) in
                    guard error == nil else {
                        self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + error!.localizedDescription)
                        return
                    }
                    self.sendSuccessResultWithCallback(result: result, message: SUCCESS)
                }
            } else {
                sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + "User not authorised. This usually happens when calling the function before login. Make sure you call either of the two functions before updating the user details.")
            }
        } else if(call.method == "addContacts") {
            let contactService = ALContactService()
            guard let contactDetailsDict = call.arguments as? [Dictionary<String, Any>] else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            
            if(contactDetailsDict.count > 0) {
                for userDict in contactDetailsDict {
                    let userDetail = ALContact(dict: userDict)
                    contactService.updateOrInsert(userDetail)
                }
                sendSuccessResultWithCallback(result: result, message: SUCCESS)
            }
        } else if(call.method == "getLoggedInUserId") {
            if(ALUserDefaultsHandler.isLoggedIn()) {
                self.sendSuccessResultWithCallback(result: result, message: ALUserDefaultsHandler.getUserId()!)
            } else {
                self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + "User not authorised. UserId is empty")
            }
        } else if(call.method == "sendMessage") {
            do {
                guard let alMessageDict = call.arguments as? Dictionary<String, Any> else {
                    sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                let jsonData = try JSONSerialization.data(withJSONObject: alMessageDict, options: .prettyPrinted)
                let jsonString = String(bytes: jsonData, encoding: .utf8)
                
                let alMessage = ALMessage.init(jsonString: jsonString)
                
                guard let message = alMessage  else {
                    self.sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                let applicationKey = ALUserDefaultsHandler.getApplicationKey()
                if(applicationKey != nil) {
                    let alChatManager = ALChatManager.init(applicationKey: applicationKey! as NSString)
                    alChatManager.sendMessage(alMessage: message) { (response, error) in
                    if(error == nil && response != nil) {
                        self.sendSuccessResultWithCallback(result: result, message: (response?.dictionary()))
                        return
                    } else {
                        self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
                        return
                    }
                }
                } else {
                    sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + "Seems like you have not logged in!")
                    return
                }
            } catch {
                self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + error.localizedDescription)
            }
        } else if (call.method == "addMemberToGroup") {
            guard let addMemberDetails = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            if(addMemberDetails.keys.contains("userId") && (addMemberDetails.keys.contains("groupId") || addMemberDetails.keys.contains("clientChannelKey"))) {
                let alChannelService = ALChannelService();
                guard let userId = addMemberDetails["userId"] else {
                    sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                let channelKey = addMemberDetails["groupId"]
                let clientChannelKey = addMemberDetails["clientGroupId"]
                guard channelKey != nil || clientChannelKey != nil else {
                    sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                alChannelService.addMember(toChannel: (userId as! String), andChannelKey: (channelKey as? NSNumber), orClientChannelKey: (clientChannelKey as? String)) { (error, aLAPIResponse) in
                    if(error == nil && aLAPIResponse != nil && aLAPIResponse?.status == "success" ) {
                        self.sendSuccessResultWithCallback(result: result, message: SUCCESS)
                        print("Added member successfully in channel")
                        return
                    }
                    else {
                        self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
                        print("Error adding member to channel")
                        return
                    }
                }
            } else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
        } else if (call.method == "removeMemberFromGroup") {
            guard let removeMemberDetails = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            if(removeMemberDetails.keys.contains("userId") && (removeMemberDetails.keys.contains("groupId") || removeMemberDetails.keys.contains("clientChannelKey"))) {
                    let alChannelService = ALChannelService();
                guard let userId = removeMemberDetails["userId"] else {
                    sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                let channelKey = removeMemberDetails["groupId"]
                let clientChannelKey = removeMemberDetails["clientGroupId"]
                guard channelKey != nil || clientChannelKey != nil else {
                    sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                alChannelService.removeMember(fromChannel: (userId as! String), andChannelKey: (channelKey as? NSNumber), orClientChannelKey: (clientChannelKey as? String)) { (error, aLAPIResponse) in
                        if(error == nil && aLAPIResponse != nil && aLAPIResponse?.status == "success" ) {
                            self.sendSuccessResultWithCallback(result: result, message: SUCCESS)
                            print("Removed member successfully from channel")
                            return
                        } else {
                            self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
                            print("Error removing member from channel")
                            return
                        }
                    }
            } else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
        } else if (call.method == "getUnreadCountForContact") {
            let contactService = ALContactService()
            guard let userId = call.arguments else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            let contact = contactService.loadContact(byKey: "userId", value: (userId as! String))
            let unreadCount = contact?.unreadCount
            sendSuccessResultWithCallback(result: result, message: unreadCount ?? 0)
        } else if (call.method == "getUnreadCountForChannel") {
            let channelService = ALChannelService()
            guard let channelDetailsDict = call.arguments as? Dictionary<String, Any> else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
            
            if (channelDetailsDict.keys.contains("groupId")) {
                guard let groupId = channelDetailsDict["groupId"] else {
                    sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                    return
                }
                let channel = channelService.getChannelByKey(groupId as? NSNumber)
                let unreadCount = channel?.unreadCount
                sendSuccessResultWithCallback(result: result, message: unreadCount ?? 0)
            } else {
                sendErrorResultWithCallback(result: result, message: ERROR_ILLEGAL_ARGUMENTS)
                return
            }
        } else if (call.method == "getUnreadChatsCount") {
            var applozicClient = ApplozicClient()
            guard let applicationKey = ALUserDefaultsHandler.getApplicationKey() else {
                sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
                return
            }
            applozicClient = ApplozicClient(applicationKey: applicationKey) as ApplozicClient
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
                            self.sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
                            return
                        }
                    })
        } else if (call.method == "getTotalUnreadCount") {
            let userService = ALUserService()
            let totalUnreadCount = userService.getTotalUnreadCount()
            if (totalUnreadCount != nil) {
                sendSuccessResultWithCallback(result: result, message: totalUnreadCount ?? 0)
            } else {
                sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL)
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
        result(FlutterError(code: ERROR, message: message, details: nil))
    }
    
    func sendSuccessResultWithCallback(result: FlutterResult, object: [AnyHashable : Any]) {
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            let jsonString = String(bytes: jsonData, encoding: .utf8)
            result(jsonString)
        } catch {
            sendSuccessResultWithCallback(result: result, message: SUCCESS)
        }
    }
    
    func getChatManager(result: FlutterResult) -> ALChatManager {
        let applicationKey = ALUserDefaultsHandler.getApplicationKey()
        if(applicationKey != nil) {
            return ALChatManager.init(applicationKey: applicationKey! as NSString)
        } else {
            sendErrorResultWithCallback(result: result, message: ERROR_INTERNAL + " : " + "Seems like you have not logged in!")
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
    }
}
