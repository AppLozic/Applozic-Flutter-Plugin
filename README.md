# Applozic flutter chat plugin
A flutter wraper for Applozic native android and iOS SDKs.

## Getting Started
[Sign up](https://console.applozic.com/login) for Applozic to get your application Id. This application Id is used to login user to applozic.

## Prerequisites
Apps using Applozic can target Xcode 11 or later and AndroidX is required.

## Installation
1) Add the below dependency in your pubspec.yaml file:
```yaml
 dependencies:
  # other dependencies
 applozic_flutter: ^0.0.4
```

2) Install the package as below:
```
  flutter pub get
```

3) For iOS, navigate to your App/iOS directory from terminal and run the below command:
```
pod install
```

> Note: Applozic iOS requires min iOS platform version 10 and uses dynamic frameworks. Make sure you have the below settings at the top of your iOS/Podfile:
```ruby
platform :ios, '10.0'
use_frameworks!
```

4) Import the applozic_flutter in your .dart file to use the methods from Applozic:
```dart
import 'package:applozic_flutter/applozic_flutter.dart';
```

## Authentication
### Login
Create Applozic user and pass user to login() function as below:
```dart
dynamic user = {
      'applicationId': "<APPLICATION_ID>",   //Mandatory
      'userId': userId.text,                 //Mandatory
      'displayName': displayName.text,
      'password': password.text,
      'authenticationTypeId': 1              //Mandatory
  };

ApplozicFlutter.login(user).then((response) {
      print("Login success : " + response)
    }).catchError((error, stack) =>
      print("Error while logging in : " + error.toString()));
```

> Note: Please remember you have to log in once and only after you log out you must log in again. Use below code to check if   the user is already logged in:

```dart
ApplozicFlutter.isLoggedIn().then((isLoggedIn) {
        if (isLoggedIn) {
          //The user is logged in
         } esle {
          //The user is not logged in
         }
     });
```

### Update logged in user details
You can update the logged in user details as below:

```dart
  dynamic user = {
                    'displayName': '<New name>'
                    'imageLink': '<New Image URL>'
                  }

  ApplozicFlutter.updateUserDetail(user)
                        .then(
                            (value) => print("User details updated : " + value))
                        .catchError((e, s) => print(
                            "Unable to update user details : " + e.toString()));
```

### Get logged in userId
You can get the userId of the logged in user as below:
```dart
  ApplozicFlutter.getLoggedInUserId().then((userId) {
      print("Logged in userId : " + userId);
    }).catchError((error, stack) {
      print("User get error : " + error);
   });
```

## Conversation
### Launch main chat screen
Launch the main chat screen as below:
```dart
  ApplozicFlutter.launchChatScreen();
```

### Launch Chat with a specific User
Launch the conversation with a user by passing the userId as below:
```dart
  ApplozicFlutter.launchChatWithUser("<USER_ID>");
```

### Launch Chat with a specific Group
Launch the conversation with a group by passing the groupId as below:
```dart
  ApplozicFlutter.launchChatWithGroupId(<GROUP_ID>)
                        .then((value) =>
                            print("Launched successfully : " + value))
                        .catchError((error, stack) {
                      print("Unable to launch group : " + error.toString());
                    });
```

## Create a group
To create a group, you need to create a groupInfo object and then pass it to the create group function as below:

```dart
  dynamic groupInfo = {
          'groupName': "My group",
          'groupMemberList': ['userId1', 'userId2'],
          'imageUrl': 'https://www.applozic.com/favicon.ico',
          'type': 2,
          'admin': 'userId1',
          'metadata': {
            'plugin': "Flutter",
            'platform': "Android"
          }
        };

  ApplozicFlutter.createGroup(groupInfo)
            .then((groupId) {
              print("Group created sucessfully: " + groupId);
              ApplozicFlutter.launchChatWithGroupId(groupId)
                  .then((value) => print("Launched successfully : " + value))
                  .catchError((error, stack) {
                print("Unable to launch group : " + error.toString());
              });
            })
            .catchError((error, stack) =>
                print("Group created failed : " + error.toString()));
```

## Add member to group
To add a member to a group you need to great a object with userId of the member to add and the groupId/clientGroupId (either one) of the group:
```dart
dynamic detailObject = {
      'userId': "userId", //userId of the user to add
      'groupId': 123456 //groupId of the group to add the user to
    };
```
Then pass the object to this function:
```dart
ApplozicFlutter.addMemberToGroup(detailObject)
        .then((value) => {
              print("Member added successfully."),
              ApplozicFlutter.createToast("Member added successfully.")
            })
        .catchError((e, s) => {
              print("Error adding member."),
              ApplozicFlutter.createToast("Error in adding member.")
            });
```

## Remove member from group
To add a member to a group you need to great a object with userId of the member to add and the groupId/clientGroupId (either one) of the group:
```dart
dynamic detailObject = {
      'userId': "userId", //userId of the user to remove
      'groupId': 123456 //groupId of the group to remove the user from
    };
```
Then pass the object to this function:
```dart
ApplozicFlutter.removeMemberFromGroup(detailObject)
        .then((value) => {
              print("Member removed successfully."),
              ApplozicFlutter.createToast("Member removed successfully.")
            })
        .catchError((e, s) => {
              print("Error removing member."),
              ApplozicFlutter.createToast("Error in removing member.")
            });
```

## Send message
To send a message to a contact or a group, you must first create a message object:
```dart
dynamic message = {
      'to': userId, // to send message to a contact pass the userId of the receiver (You can ignore the groupId in this case)
      'groupId': groupId, //to send message to a group pass the groupId (You can ingore the userId in this case)
      'message': "message text", // message to send
      'type': 0 //(optional) DEFAULT(0),
    };
```
**Note:** A message object can have more parameters. Refer to this link: https://docs.applozic.com/docs/android-chat-message-api#build-your-ui-from-scratch---message-api

Then pass the message object to this function:
```dart
ApplozicFlutter.sendMessage(message)
    .then((value) => print("Message sent."))
    .catchError((e, s) => print("Error while sending message: " + e.toString()));
```

## Unread message count for contact
To get the unread count for contact, pass the userId of the contact to the function:
```dart
ApplozicFlutter.getUnreadCountForContact(userId)
        .then((value) => print("Unread count : " + value.toString()))
        .catchError((e, s) => print("Error."));
```

## Unread message count for channel
To get the unread count for a channel, create a object with either the `groupId` or the `clientGroupId` (only one required):
```dart
dynamic channelDetails = { //you need to provide only one of the two
  'groupId' : 123456, 
  'clientGroupId' : "clientGroupId"
};
```
The pass the object to this function:
```dart
ApplozicFlutter.getUnreadCountForChannel(channelDetails)
        .then((value) => print("Unread count : " + value.toString()))
        .catchError((e, s) => print("Error."));
```

## Number of unread chats
Simply call the following function:
```dart
ApplozicFlutter.getUnreadChatsCount()
        .then((value) => print("Unread chats count : " + value.toString()))
        .catchError((e, s) => print("Error."));
```

## Total unread message count
Simply call the following function:
```dart
ApplozicFlutter.getTotalUnreadCount()
        .then((value) => print("Total unread count : " + value.toString()))
        .catchError((e, s) => print("Error."));
```

## Add contacts
Add contacts to applozic as below:

```dart
  dynamic user1 = {
      'userId': "user1",
      'displayName': ""User 1,
      "metadata": {
        'plugin': "Flutter",
        'platform': "Android"
      }
    };

  dynamic user2 = {
      'userId': "user2",
      'displayName': ""User 2,
      "metadata": {
        'plugin': "Flutter",
        'platform': "Android"
      }
    };

  ApplozicFlutter.addContacts([user1, user2])
        .then((value) => print("Contact added successfully: " + value))
        .catchError((e, s) => print("Failed to add contacts: " + e.toString()));
```

## Logout
Logout from applozic as below:

```dart
 ApplozicFlutter.logout()
                .then((value) =>
                  print("Logout successfull")
                .catchError((error, stack) =>
                  print("Logout failed : " + error.toString()));
```

## Sample app
You can checkout [Applozic Flutter sample app](https://github.com/AppLozic/Applozic-Flutter-Plugin/tree/master/example) that demonstrates the use of this plugin. 

In case of any queries regarding this plugin, write to us at support@applozic.com.

