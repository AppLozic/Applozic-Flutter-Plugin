package com.example.applozic_flutter;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.applozic.mobicomkit.Applozic;
import com.applozic.mobicomkit.api.account.register.RegistrationResponse;
import com.applozic.mobicomkit.api.account.user.AlUserUpdateTask;
import com.applozic.mobicomkit.api.account.user.User;
import com.applozic.mobicomkit.api.account.user.UserDetail;
import com.applozic.mobicomkit.api.account.user.UserService;
import com.applozic.mobicomkit.api.conversation.ApplozicConversation;
import com.applozic.mobicomkit.api.conversation.Message;
import com.applozic.mobicomkit.api.conversation.MessageBuilder;
import com.applozic.mobicomkit.api.conversation.database.MessageDatabaseService;
import com.applozic.mobicomkit.api.people.ChannelInfo;
import com.applozic.mobicomkit.channel.service.ChannelService;
import com.applozic.mobicomkit.exception.ApplozicException;
import com.applozic.mobicomkit.feed.ChannelFeedApiResponse;
import com.applozic.mobicomkit.listners.AlCallback;
import com.applozic.mobicomkit.listners.AlLoginHandler;
import com.applozic.mobicomkit.listners.AlLogoutHandler;
import com.applozic.mobicomkit.listners.AlPushNotificationHandler;
import com.applozic.mobicomkit.listners.MediaUploadProgressHandler;
import com.applozic.mobicomkit.listners.MessageListHandler;
import com.applozic.mobicomkit.uiwidgets.ApplozicSetting;
import com.applozic.mobicomkit.uiwidgets.async.AlChannelCreateAsyncTask;
import com.applozic.mobicomkit.uiwidgets.async.AlGroupInformationAsyncTask;
import com.applozic.mobicomkit.uiwidgets.async.ApplozicChannelAddMemberTask;
import com.applozic.mobicomkit.uiwidgets.async.ApplozicChannelRemoveMemberTask;
import com.applozic.mobicomkit.uiwidgets.conversation.ConversationUIService;
import com.applozic.mobicomkit.uiwidgets.conversation.activity.ConversationActivity;
import com.applozic.mobicommons.file.FileUtils;
import com.applozic.mobicommons.json.GsonUtils;
import com.applozic.mobicommons.people.channel.Channel;
import com.applozic.mobicomkit.api.account.user.MobiComUserPreference;
import com.applozic.mobicommons.task.AlTask;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * ApplozicFlutterPlugin
 * Flutter plugin for the Applozic-Android-SDK
 */
public class ApplozicFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private static final String TAG = "ApplozicFlutterPlugin";
    private static final String PLUGIN_NAME = "applozic_flutter";
    private static final String SUCCESS = "Success";
    private static final String ERROR = "Error";

    private Activity context;
    private MethodChannel methodChannel;

    private void initPlugin(BinaryMessenger messenger, Activity context) {
        methodChannel = new MethodChannel(messenger, PLUGIN_NAME);
        methodChannel.setMethodCallHandler(this);
        if (context != null) {
            this.context = context;
        }
    }

    public static void registerWith(Registrar registrar) {
        ApplozicFlutterPlugin applozicFlutterPlugin = new ApplozicFlutterPlugin();
        applozicFlutterPlugin.initPlugin(registrar.messenger(), registrar.activity());
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        initPlugin(binding.getBinaryMessenger(), null);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
        }
        methodChannel = null;
        context = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.context = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        context = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.context = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.context = null;
    }

    private void registerForPushNotification(final Result result) {
        if (context == null) {
            return;
        }
        Applozic.registerForPushNotification(context, new AlPushNotificationHandler() {
            @Override
            public void onSuccess(RegistrationResponse registrationResponse) {
                result.success(registrationResponse);
            }

            @Override
            public void onFailure(RegistrationResponse registrationResponse, Exception exception) {
                result.error(ERROR, ResultMessages.Error.INTERNAL_ERROR, exception.getMessage());
            }
        });
    }

    @Override
    public void onMethodCall(final MethodCall call, @NonNull final Result result) {
        if (context == null) {
            result.error(ERROR, ResultMessages.Error.ACTIVITY_CONTEXT_NULL, null);
            return;
        }
        if (call.method.equals("login")) {
            User user = (User) GsonUtils.getObjectFromJson(GsonUtils.getJsonFromObject(call.arguments, Object.class), User.class);

            if (!TextUtils.isEmpty(user.getApplicationId())) {
                Applozic.init(context, user.getApplicationId());
            }
            Applozic.connectUser(context, user, new AlLoginHandler() {
                @Override
                public void onSuccess(RegistrationResponse registrationResponse, Context context) {
                    result.success(GsonUtils.getJsonFromObject(registrationResponse, RegistrationResponse.class));
                }

                @Override
                public void onFailure(RegistrationResponse registrationResponse, Exception exception) {
                    result.error(ERROR, GsonUtils.getJsonFromObject(registrationResponse != null ? registrationResponse : exception, registrationResponse != null ? RegistrationResponse.class : Exception.class), null);
                }
            });
        } else if (call.method.equals("isLoggedIn")) {
            result.success(Applozic.isConnected(context));
        } else if (call.method.equals("logout")) {
            Applozic.logoutUser(context, new AlLogoutHandler() {
                @Override
                public void onSuccess(Context context) {
                    result.success(SUCCESS);
                }

                @Override
                public void onFailure(Exception exception) {
                    result.error(ERROR, ResultMessages.Error.INTERNAL_ERROR, exception);
                }
            });
        } else if (call.method.equals("registerForPushNotification")) {
            registerForPushNotification(result);
        } else if (call.method.equals("launchChatScreen")) {
            Intent intent = new Intent(context, ConversationActivity.class);
            context.startActivity(intent);
        } else if (call.method.equals("launchChatWithUser")) {
            try {
                Intent intent = new Intent(context, ConversationActivity.class);
                intent.putExtra(ConversationUIService.USER_ID, (String) call.arguments);
                intent.putExtra(ConversationUIService.TAKE_ORDER, true);
                context.startActivity(intent);
                result.success(SUCCESS);
            } catch (Exception e) {
                result.error(ERROR, e.getLocalizedMessage(), null);
            }
        } else if (call.method.equals("launchChatWithGroupId")) {
            try {
                Integer groupId = 0;
                if (call.arguments instanceof Integer) {
                    groupId = (Integer) call.arguments;
                } else if (call.arguments instanceof String) {
                    groupId = Integer.valueOf((String) call.arguments);
                } else {
                    result.error(ERROR, "Invalid groupId.", null);
                }

                if (groupId == 0) {
                    result.error(ERROR, "Invalid groupId.", null);
                    return;
                }

                AlTask.execute(new AlGroupInformationAsyncTask(context, groupId, new AlGroupInformationAsyncTask.GroupMemberListener() {
                    @Override
                    public void onSuccess(Channel channel, Context context) {
                        Intent intent = new Intent(context, ConversationActivity.class);
                        intent.putExtra(ConversationUIService.GROUP_ID, channel.getKey());
                        intent.putExtra(ConversationUIService.TAKE_ORDER, true);
                        context.startActivity(intent);
                        result.success(GsonUtils.getJsonFromObject(channel, Channel.class));
                    }

                    @Override
                    public void onFailure(Channel channel, Exception e, Context context) {
                        result.error(ERROR, e != null ? e.getLocalizedMessage() : ResultMessages.Error.INTERNAL_ERROR, null);
                    }
                }));
            } catch (Exception e) {
                result.error(ERROR, e.getLocalizedMessage(), null);
            }
        } else if (call.method.equals("createGroup")) {
            ChannelInfo channelInfo = (ChannelInfo) GsonUtils.getObjectFromJson(GsonUtils.getJsonFromObject(call.arguments, Object.class), ChannelInfo.class);
            AlTask.execute(new AlChannelCreateAsyncTask(context, channelInfo, new AlChannelCreateAsyncTask.TaskListenerInterface() {
                @Override
                public void onSuccess(Channel channel, Context context) {
                    result.success(String.valueOf(channel.getKey()));
                }

                @Override
                public void onFailure(ChannelFeedApiResponse channelFeedApiResponse, Context context) {
                    result.error(ERROR, channelFeedApiResponse != null ? GsonUtils.getJsonFromObject(channelFeedApiResponse, ChannelFeedApiResponse.class) : "Some internal error occurred", null);
                }
            }));
        } else if (call.method.equals("updateUserDetail")) {
            try {
                if (Applozic.isConnected(context)) {
                    User user = (User) GsonUtils.getObjectFromJson(GsonUtils.getJsonFromObject(call.arguments, Object.class), User.class);
                    AlTask.execute(new AlUserUpdateTask(context, user, new AlCallback() {
                        @Override
                        public void onSuccess(Object message) {
                            result.success(SUCCESS);
                        }

                        @Override
                        public void onError(Object error) {
                            result.error(ERROR, "Unable to update user details.", null);
                        }
                    }));
                } else {
                    result.error(ERROR, "User not authorised. This usually happens when calling the function before conversationBuilder or loginUser. Make sure you call either of the two functions before updating the user details.", null);
                }
            } catch (Exception e) {
                result.error(ERROR, e.toString(), null);
            }
        } else if (call.method.equals("addContacts")) {
            UserDetail[] userDetails = (UserDetail[]) GsonUtils.getObjectFromJson(GsonUtils.getJsonFromObject(call.arguments, Object.class), UserDetail[].class);
            for (UserDetail userDetail : userDetails) {
                UserService.getInstance(context).processUser(userDetail);
            }
            result.success(SUCCESS);
        } else if (call.method.equals("getLoggedInUserId")) {
            String userId = MobiComUserPreference.getInstance(context).getUserId();
            if (!TextUtils.isEmpty(userId)) {
                result.success(userId);
            } else {
                result.error(ERROR, "User not authorised. UserId is empty.", null);
            }
        } else if (call.method.equals("addMemberToGroup")) {
            Integer channelKey = null;
            String userId;

            try {
                JSONObject config = new JSONObject(GsonUtils.getJsonFromObject(call.arguments, Object.class));
                userId = config.getString("userId");
                if (config.has("clientGroupId") && !TextUtils.isEmpty(config.getString("clientGroupId"))) {
                    Channel channel = ChannelService.getInstance(context).getChannelByClientGroupId(config.getString("clientGroupId"));
                    channelKey = channel != null ? channel.getKey() : null;

                } else if (config.has("groupId") && !TextUtils.isEmpty(config.getString("groupId"))) {
                    channelKey = config.getInt("groupId");
                }

                if (channelKey == null) {
                    result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, "Client Id/Group Id not passed.");
                    return;
                }
            } catch (JSONException jsonException) {
                jsonException.printStackTrace();
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, null);
                return;
            }

            ApplozicChannelAddMemberTask.ChannelAddMemberListener channelAddMemberListener = new ApplozicChannelAddMemberTask.ChannelAddMemberListener() {
                @Override
                public void onSuccess(String response, Context context) {
                    //Response will be "success" if user is added successfully
                    result.success(SUCCESS);
                }

                @Override
                public void onFailure(String response, Exception e, Context context) {
                    result.error(ERROR, response, null);
                }
            };

            ApplozicChannelAddMemberTask applozicChannelAddMemberTask = new ApplozicChannelAddMemberTask(context, channelKey, userId, channelAddMemberListener);//pass channel key and userId whom you want to add to channel
            AlTask.execute(applozicChannelAddMemberTask);
        } else if (call.method.equals("removeMemberFromGroup")) {
            Integer channelKey = null;
            String userId = null;
            try {
                JSONObject config = new JSONObject(GsonUtils.getJsonFromObject(call.arguments, Object.class));
                userId = config.getString("userId");

                if (config.has("clientGroupId") && !TextUtils.isEmpty(config.getString("clientGroupId"))) {
                    Channel channel = ChannelService.getInstance(context).getChannelByClientGroupId(config.getString("clientGroupId"));
                    channelKey = channel != null ? channel.getKey() : null;

                } else if (config.has("groupId") && !TextUtils.isEmpty(config.getString("groupId"))) {
                    channelKey = config.getInt("groupId");
                }

                if (channelKey == null) {
                    result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, "GroupId/clientGroupId not passed.");
                    return;
                }
            } catch (JSONException jsonException) {
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, null);
                return;
            }

            ApplozicChannelRemoveMemberTask.ChannelRemoveMemberListener channelRemoveMemberListener = new ApplozicChannelRemoveMemberTask.ChannelRemoveMemberListener() {
                @Override
                public void onSuccess(String response, Context context) {
                    result.success(SUCCESS);
                    Log.i(TAG, "Remove member response:" + response);
                }

                @Override
                public void onFailure(String response, Exception e, Context context) {
                    result.error(ERROR, ResultMessages.Error.INTERNAL_ERROR, "Failure from remove member API.");
                }
            };

            if (TextUtils.isEmpty(userId)) {
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, "UserId is null/empty.");
                return;
            }
            AlTask.execute(new ApplozicChannelRemoveMemberTask(context, channelKey, userId, channelRemoveMemberListener));//pass channelKey and userId whom you want to remove from channel
        } else if (call.method.equals("getUnreadCountForContact")) {
            if (call.arguments instanceof String) {
                int contactUnreadCount = new MessageDatabaseService(context).getUnreadMessageCountForContact((String) call.arguments);
                result.success(contactUnreadCount);
            } else {
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, "UserId is null/empty.");
            }
        } else if (call.method.equals("getUnreadCountForChannel")) {
            AlGroupInformationAsyncTask.GroupMemberListener listener = new AlGroupInformationAsyncTask.GroupMemberListener() {
                @Override
                public void onSuccess(Channel channel, Context context) {
                    if (channel == null) {
                        result.error(ERROR, "Channel does not exist.", null);
                    } else {
                        result.success(new MessageDatabaseService(context).getUnreadMessageCountForChannel(channel.getKey()));
                    }
                }

                @Override
                public void onFailure(Channel channel, Exception e, Context context) {
                    e.printStackTrace();
                    result.error(ERROR, ResultMessages.Error.INTERNAL_ERROR, e != null ? e.getMessage() : null);
                }
            };

            try {
                JSONObject params = new JSONObject(GsonUtils.getJsonFromObject(call.arguments, Object.class));
                if (params.has("clientGroupId")) {
                    AlTask.execute(new AlGroupInformationAsyncTask(context, params.getString("clientGroupId"), listener));
                } else if (params.has("groupId")) {
                    AlTask.execute(new AlGroupInformationAsyncTask(context, params.getInt("groupId"), listener));
                } else {
                    result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, null);
                }
            } catch (JSONException jsonException) {
                jsonException.printStackTrace();
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, null);
            }
        } else if (call.method.equals("getUnreadChatsCount")) {
            ApplozicConversation.getLatestMessageList(context, false, new MessageListHandler() {
                int unreadChatsCount = 0;

                @Override
                public void onResult(List<Message> messageList, ApplozicException e) {
                    if (e == null) {
                        MessageDatabaseService messageDatabaseService = new MessageDatabaseService(context);
                        for (Message message : messageList) {
                            int unreadCount = 0;
                            if (message.getGroupId() != null) {
                                unreadCount = messageDatabaseService.getUnreadMessageCountForChannel(message.getGroupId());
                            } else {
                                if (!TextUtils.isEmpty(message.getTo())) {
                                    unreadCount = messageDatabaseService.getUnreadMessageCountForContact(message.getTo());
                                }
                            }
                            if (unreadCount > 0) {
                                unreadChatsCount++;
                            }
                        }
                        result.success(unreadChatsCount);
                    } else {
                        result.error(ERROR, ResultMessages.Error.INTERNAL_ERROR, "Error in fetching messages from server.");
                    }
                }
            });
        } else if (call.method.equals("getTotalUnreadCount")) {
            int totalUnreadCount = new MessageDatabaseService(context).getTotalUnreadCount();
            result.success(totalUnreadCount);
        } else if (call.method.equals("sendMessage")) {
            final Message message = (Message) GsonUtils.getObjectFromJson(GsonUtils.getJsonFromObject(call.arguments, Object.class), Message.class);

            if (message == null) {
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, "Unable to parse data for the applozic message.");
                return;
            }

            new MessageBuilder(context).setMessageObject(message).send(new MediaUploadProgressHandler() {
                @Override
                public void onUploadStarted(ApplozicException e, String oldMessageKey) {
                }

                @Override
                public void onProgressUpdate(int percentage, ApplozicException e, String oldMessageKey) {
                }

                @Override
                public void onCancelled(ApplozicException e, String oldMessageKey) {
                }

                @Override
                public void onCompleted(ApplozicException e, String oldMessageKey) {
                }

                @Override
                public void onSent(Message message, String oldMessageKey) {
                    result.success(GsonUtils.getJsonFromObject(message, Message.class));
                }
            });
        } else if (call.method.equals("createToast")) {
            if (call.arguments instanceof String) {
                Toast.makeText(context, (String) call.arguments, Toast.LENGTH_LONG).show();
                result.success(SUCCESS + " : " + (String) call.arguments);
            } else {
                result.error(ERROR, ResultMessages.Error.ILLEGAL_ARGUMENTS, null);
            }
        } else {
            result.notImplemented();
        }
    }
}
