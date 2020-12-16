import 'package:applozic_flutter_example/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:applozic_flutter/applozic_flutter.dart';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);

  @override
  void initState() {
    try {} catch (e) {}
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Welcome to Applozic!'),
          ),
          body: HomePageWidget()),
    );
  }
}

class HomePageWidget extends StatelessWidget {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 14.0);
  bool isGroupInProgress = false;

  String getPlatformName() {
    if (Platform.isAndroid) {
      return "Android";
    } else if (Platform.isIOS) {
      return "iOS";
    } else {
      return "NOP";
    }
  }

  String getCurrentTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  int getTimeStamp() {
    return new DateTime.now().millisecondsSinceEpoch;
  }

  void createGroup(List<String> groupMemberList) {
    ApplozicFlutter.getLoggedInUserId().then((value) {
      if (!isGroupInProgress) {
        isGroupInProgress = true;

        if (!groupMemberList.contains(value)) {
          groupMemberList.add(value);
        }

        dynamic groupInfo = {
          'groupName': "FGroup-" + getCurrentTime() + "-" + getPlatformName(),
          'groupMemberList': groupMemberList,
          'imageUrl': 'https://www.applozic.com/favicon.ico',
          'type': 2,
          'admin': value,
          'metadata': {
            'plugin': "Flutter",
            'platform': getPlatformName(),
            'createdAt': getCurrentTime()
          }
        };

        ApplozicFlutter.createToast("Creating...");

        ApplozicFlutter.createGroup(groupInfo)
            .then((value) {
              print("Group created successfully: " + value);
              sendMessageGroupId(value);
              ApplozicFlutter.launchChatWithGroupId(value)
                  .then((value) => {print("Launched successfully : " + value)})
                  .catchError((error, stack) {
                print("Unable to launch group : " + error != null
                    ? error
                    : stack);
                ApplozicFlutter.createToast("Unable to launch group.");
              });
            })
            .catchError((error, stack) => {
                  print("Group created failed : " + error.toString()),
                  ApplozicFlutter.createToast(
                      "Group create failed. Check logs.")
                })
            .whenComplete(() => isGroupInProgress = false);
      }
    }).catchError((error, stack) {
      print("User get error : " + error);
    });
  }

  void addMemberToGroup(List<String> details) {
    dynamic detailsUser = {
      'userId': details[1],
      'groupId': int.parse(details[0])
    };
    ApplozicFlutter.addMemberToGroup(detailsUser)
        .then((value) => {
              print("Member added successfully."),
              ApplozicFlutter.createToast("Member added successfully.")
            })
        .catchError((e, s) => {
              print("Error adding member."),
              ApplozicFlutter.createToast("Error in adding member.")
            });
  }

  void removeMemberFromGroup(List<String> details) {
    dynamic detailsUser = {
      'userId': details[1],
      'groupId': int.parse(details[0])
    };
    ApplozicFlutter.removeMemberFromGroup(detailsUser)
        .then((value) => {
              print("Member removed successfully."),
              ApplozicFlutter.createToast("Member removed successfully.")
            })
        .catchError((e, s) => {
              print("Error removing member."),
              ApplozicFlutter.createToast("Error in removing member.")
            });
  }

  void addContacts(String userid) {
    dynamic user1 = {
      'userId': userid,
      'displayName': "FU-" + getCurrentTime() + "-" + userid,
      "metadata": {
        'plugin': "Flutter",
        'platform': getPlatformName(),
        'createdAt': getCurrentTime()
      }
    };

    dynamic userArray = [user1];

    ApplozicFlutter.addContacts(userArray)
        .then((value) => {
              print("Contact added successfully: " + value),
              ApplozicFlutter.createToast("Contact added.")
            })
        .catchError((e, s) => {
              print("Failed to add contacts: " + e.toString()),
              ApplozicFlutter.createToast("Error in adding contact.")
            });
  }

  void updateUserName(String userName) {
    dynamic user = {
      'displayName': userName,
      'metadata': {
        'plugin': "Flutter",
        'platform': getPlatformName(),
        'userUpdateTime': getCurrentTime()
      }
    };

    ApplozicFlutter.updateUserDetail(user)
        .then((value) => {print("Name updated successfully: " + value), ApplozicFlutter.createToast("Name updated successfully.")})
        .catchError((e, s) => {print("Error while updating name."), ApplozicFlutter.createToast("Error while updating name.")});
  }

  void sendTestMessage(String userId) {
    dynamic message = {
      'to': userId, // userId of the receiver
      'message': "This is a test message sent to " + userId + " at " + getCurrentTime() + ".", // message to send
      'type': 0 //(optional) DEFAULT(0),
    };

    ApplozicFlutter.sendMessage(message).then((value) => ApplozicFlutter.createToast("Message sent.")).catchError((e, s) => ApplozicFlutter.createToast("Error while sending message: " + e.toString()));
  }

  void sendMessageGroupId(String groupId) {
    dynamic message = {
      'groupId': groupId, // userId of the receiver
      'message': "GroupId is : " + groupId, // message to send
      'type': 0 //(optional) DEFAULT(0),
    };

    ApplozicFlutter.sendMessage(message).then((value) => ApplozicFlutter.createToast("Message sent with groupId.")).catchError((e, s) => ApplozicFlutter.createToast("Error while sending message."));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    ApplozicFlutter.launchChatScreen();
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Launch chat screen",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (userid) =>
                            {ApplozicFlutter.launchChatWithUser(userid)},
                        "Enter the user-id.",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Launch chat with user",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (groupId) => {
                              ApplozicFlutter.launchChatWithGroupId(groupId)
                                  .then((value) =>
                                      print("Launched successfully : " + value))
                                  .catchError((error, stack) {
                                print("Unable to launch group : " +
                                    error.toString());
                              })
                            },
                        "Enter the groupId.",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Launch chat with group",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (groupIds) => {createGroup(groupIds.split(" "))},
                        "Enter user-ids separated by space.",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Create group",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (userId) => {addContacts(userId)},
                        "Enter userId for contact.",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Add contact",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog((userName) => {updateUserName(userName)},
                        "Enter new name.", context, TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Update username",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (details) => {addMemberToGroup(details.split(" "))},
                        "groupId userId (separated by space)",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Add member to group",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (details) =>
                            {removeMemberFromGroup(details.split(" "))},
                        "groupId userId (separated by space)",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Remove member from group",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    openDialog(
                        (userId) => {sendTestMessage(userId)},
                        "Enter userId to send message to.",
                        context,
                        TextEditingController());
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Send test message to user",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    String resultMessage = "";
                    ApplozicFlutter.getTotalUnreadCount()
                        .then((value) => {
                              resultMessage = resultMessage +
                                  "Total unread messages: " +
                                  value.toString()
                            })
                        .then((value) => {
                              ApplozicFlutter.getUnreadChatsCount()
                                  .then((value) => {
                                        resultMessage = resultMessage +
                                            "\nUnread chats: " +
                                            value.toString()
                                      })
                                  .then((value) => {
                                        ApplozicFlutter.createToast(
                                            resultMessage)
                                      })
                            });
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Unread details",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 10),
            new Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: new MaterialButton(
                  onPressed: () {
                    ApplozicFlutter.logout()
                        .then((value) => {
                              print("Logout successful"),
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyApp()))
                            })
                        .catchError((error, stack) =>
                            print("Logout failed : " + error.toString()));
                  },
                  minWidth: 400,
                  padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                  child: Text("Logout",
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ))
          ],
        ),
      ),
    );
  }

  void openDialog(Function(String) onPress, String hintText,
      BuildContext context, TextEditingController textEditingController) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Container(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                        decoration: InputDecoration(
                            border: InputBorder.none, hintText: hintText),
                        controller: textEditingController),
                    SizedBox(
                      width: 320.0,
                      child: RaisedButton(
                        onPressed: () {
                          if (textEditingController.text.isNotEmpty) {
                            onPress(textEditingController.text);
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Done",
                          style: TextStyle(color: Colors.white),
                        ),
                        color: const Color(0xFF1BC0C5),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
