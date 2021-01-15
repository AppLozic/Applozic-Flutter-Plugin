import 'dart:async';

import 'package:flutter/services.dart';

class ApplozicFlutter {
  static const MethodChannel _channel = const MethodChannel('applozic_flutter');

  static Future<dynamic> login(dynamic user) async {
    return await _channel.invokeMethod('login', user);
  }

  static Future<bool> isLoggedIn() async {
    return await _channel.invokeMethod('isLoggedIn');
  }

  static Future<dynamic> logout() async {
    return await _channel.invokeMethod('logout');
  }

  static Future<dynamic> registerForPushNotification() async {
    return await _channel.invokeMethod('registerForPushNotification');
  }

  static Future<dynamic> launchChatScreen() async {
    return await _channel.invokeMethod('launchChatScreen');
  }

  static Future<dynamic> launchChatWithUser(dynamic userId) async {
    return await _channel.invokeMethod('launchChatWithUser', userId);
  }

  static Future<dynamic> launchChatWithGroupId(dynamic groupId) async {
    return await _channel.invokeMethod('launchChatWithGroupId', groupId);
  }

  static Future<dynamic> createGroup(dynamic groupInfo) async {
    return await _channel.invokeMethod('createGroup', groupInfo);
  }

  static Future<dynamic> addContacts(dynamic contactJson) async {
    return await _channel.invokeMethod('addContacts', contactJson);
  }

  static Future<dynamic> updateUserDetail(dynamic user) async {
    return await _channel.invokeMethod('updateUserDetail', user);
  }

  static Future<String> getLoggedInUserId() async {
    return await _channel.invokeMethod('getLoggedInUserId');
  }

  static Future<String> addMemberToGroup(dynamic addMemberDetails) async {
    return await _channel.invokeMethod('addMemberToGroup', addMemberDetails);
  }

  static Future<String> removeMemberFromGroup(dynamic removeMemberDetails) async {
    return await _channel.invokeMethod('removeMemberFromGroup', removeMemberDetails);
  }

  static Future<int> getUnreadCountForContact(dynamic userId) async {
    return await _channel.invokeMethod('getUnreadCountForContact', userId);
  }

  static Future<int> getUnreadCountForChannel(dynamic channelDetails) async {
    return await _channel.invokeMethod('getUnreadCountForChannel', channelDetails);
  }

  static Future<int> getUnreadChatsCount() async {
    return await _channel.invokeMethod('getUnreadChatsCount');
  }

  static Future<int> getTotalUnreadCount() async {
    return await _channel.invokeMethod('getTotalUnreadCount');
  }

  static Future<dynamic> sendMessage(dynamic message) async {
    return await _channel.invokeMethod('sendMessage', message);
  }

  static Future<String> createToast(dynamic text) async {
    return await _channel.invokeMethod('createToast', text);
  }
}
