import 'dart:io';
import 'dart:typed_data';

import 'package:xrinet/core/utility/constant.dart';
import 'package:xrinet/data/data_sources/remote/chat/group_chat.dart';
import 'package:xrinet/data/data_sources/remote/firebase_storage.dart';
import 'package:xrinet/data/data_sources/remote/notification/firebase_notification.dart';
import 'package:xrinet/data/data_sources/remote/chat/single_chat.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/message.dart';
import 'package:xrinet/data/models/child_classes/post/post.dart';
import 'package:xrinet/domain/entities/sender_info.dart';
import 'package:xrinet/domain/entities/specific_users_info.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import '../../domain/repositories/user_repository.dart';
import '../data_sources/remote/user/firestore_user_info.dart';

class FirebaseUserRepoImpl implements FirestoreUserRepository {
  // Add new user
  @override
  Future<void> addNewUser(UserPersonalInfo newUserInfo) async {
    // First create the Firestore user profile.
    await FireStoreUser.createUser(newUserInfo);

    // Then try to create the device token.
    // Device token failure will not stop signup.
    await FireStoreNotification.createNewDeviceToken(
      userId: newUserInfo.userId,
      myPersonalInfo: newUserInfo,
    );
  }

  // Get personal information
  @override
  Future<UserPersonalInfo> getPersonalInfo({
    required String userId,
    bool getDeviceToken = false,
  }) async {
    try {
      UserPersonalInfo myPersonalInfo =
          await FireStoreUser.getUserInfo(userId);

      if (isThatMobile && getDeviceToken) {
        UserPersonalInfo updateInfo =
            await FireStoreNotification.createNewDeviceToken(
          userId: userId,
          myPersonalInfo: myPersonalInfo,
        );

        myPersonalInfo = updateInfo;
      }

      return myPersonalInfo;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Update user information
  @override
  Future<UserPersonalInfo> updateUserInfo({
    required UserPersonalInfo userInfo,
  }) async {
    try {
      await FireStoreUser.updateUserInfo(userInfo);

      return await getPersonalInfo(
        userId: userInfo.userId,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Update user posts information
  @override
  Future<UserPersonalInfo> updateUserPostsInfo({
    required String userId,
    required Post postInfo,
  }) async {
    try {
      await FireStoreUser.updateUserPosts(
        userId: userId,
        postInfo: postInfo,
      );

      return await getPersonalInfo(
        userId: userId,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Upload profile image
  @override
  Future<String> uploadProfileImage({
    required Uint8List photo,
    required String userId,
    required String previousImageUrl,
  }) async {
    try {
      String imageUrl = await FirebaseStoragePost.uploadData(
        data: photo,
        folderName: 'personalImage',
      );

      await FireStoreUser.updateProfileImage(
        imageUrl: imageUrl,
        userId: userId,
      );

      await FirebaseStoragePost.deleteImageFromStorage(
        previousImageUrl,
      );

      return imageUrl;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Get followers and followings information
  @override
  Future<FollowersAndFollowingsInfo> getFollowersAndFollowingsInfo({
    required List<dynamic> followersIds,
    required List<dynamic> followingsIds,
    required String userUid,
  }) async {
    try {
      List<UserPersonalInfo> followersInfo =
          await FireStoreUser.getSpecificUsersInfo(
        usersIds: followersIds,
        fieldName: "followers",
        userUid: userUid,
      );

      List<UserPersonalInfo> followingsInfo =
          await FireStoreUser.getSpecificUsersInfo(
        usersIds: followingsIds,
        fieldName: "following",
        userUid: userUid,
      );

      return FollowersAndFollowingsInfo(
        followersInfo: followersInfo,
        followingsInfo: followingsInfo,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Follow user
  @override
  Future<void> followThisUser(
    String followingUserId,
    String myPersonalId,
  ) async {
    try {
      return await FireStoreUser.followThisUser(
        followingUserId,
        myPersonalId,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Unfollow user
  @override
  Future<void> unFollowThisUser(
    String followingUserId,
    String myPersonalId,
  ) async {
    try {
      return await FireStoreUser.unFollowThisUser(
        followingUserId,
        myPersonalId,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  /// [fieldName], [userUid]:
  /// If one of these users does not exist,
  /// it will be deleted from the list in Firestore.

  // Get specific users information
  @override
  Future<List<UserPersonalInfo>> getSpecificUsersInfo({
    required List<dynamic> usersIds,
  }) async {
    try {
      return await FireStoreUser.getSpecificUsersInfo(
        usersIds: usersIds,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Get all users who are not followed
  @override
  Future<List<UserPersonalInfo>> getAllUnFollowersUsers(
    UserPersonalInfo myPersonalInfo,
  ) async {
    try {
      return await FireStoreUser.getAllUnFollowersUsers(
        myPersonalInfo,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Get my personal information in real time
  @override
  Stream<UserPersonalInfo> getMyPersonalInfo() =>
      FireStoreUser.getMyPersonalInfoInReelTime();

  // Get all users
  @override
  Stream<List<UserPersonalInfo>> getAllUsers() =>
      FireStoreUser.getAllUsers();

  // Get user by username
  @override
  Future<UserPersonalInfo?> getUserFromUserName({
    required String userName,
  }) async {
    try {
      return await FireStoreUser.getUserFromUserName(
        userName: userName,
      );
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Search users
  @override
  Stream<List<UserPersonalInfo>> searchAboutUser({
    required String name,
    required bool searchForSingleLetter,
  }) =>
      FireStoreUser.searchAboutUser(
        name: name,
        searchForSingleLetter: searchForSingleLetter,
      );

  // Send message
  @override
  Future<Message> sendMessage({
    required Message messageInfo,
    Uint8List? pathOfPhoto,
    required File? recordFile,
  }) async {
    try {
      if (pathOfPhoto != null) {
        String imageUrl = await FirebaseStoragePost.uploadData(
          data: pathOfPhoto,
          folderName: "messagesFiles",
        );

        messageInfo.imageUrl = imageUrl;
      }

      if (recordFile != null) {
        String recordedUrl = await FirebaseStoragePost.uploadFile(
          folderName: "messagesFiles",
          postFile: recordFile,
        );

        messageInfo.recordedUrl = recordedUrl;
      }

      Message myMessageInfo = await FireStoreSingleChat.sendMessage(
        userId: messageInfo.senderId,
        chatId: messageInfo.receiversIds[0],
        message: messageInfo,
      );

      await FireStoreSingleChat.sendMessage(
        userId: messageInfo.receiversIds[0],
        chatId: messageInfo.senderId,
        message: messageInfo,
      );

      await FireStoreUser.sendNotification(
        userId: messageInfo.receiversIds[0],
        message: messageInfo,
      );

      return myMessageInfo;
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Get messages
  @override
  Stream<List<Message>> getMessages({
    required String receiverId,
  }) =>
      FireStoreSingleChat.getMessages(
        receiverId: receiverId,
      );

  // Delete message
  @override
  Future<void> deleteMessage({
    required Message messageInfo,
    Message? replacedMessage,
    required bool isThatOnlyMessageInChat,
  }) async {
    try {
      String senderId = messageInfo.senderId;
      String receiverId = messageInfo.receiversIds[0];

      for (int i = 0; i < 2; i++) {
        String userId = i == 0 ? senderId : receiverId;
        String chatId = i == 0 ? receiverId : senderId;

        await FireStoreSingleChat.deleteMessage(
          userId: userId,
          chatId: chatId,
          messageId: messageInfo.messageUid,
        );

        if (replacedMessage != null || isThatOnlyMessageInChat) {
          await FireStoreSingleChat.updateLastMessage(
            userId: userId,
            chatId: chatId,
            isThatOnlyMessageInChat: isThatOnlyMessageInChat,
            message: replacedMessage,
          );
        }
      }
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Get specific chat information
  @override
  Future<SenderInfo> getSpecificChatInfo({
    required String chatUid,
    required bool isThatGroup,
  }) async {
    try {
      if (isThatGroup) {
        SenderInfo coverChatInfo =
            await FireStoreGroupChat.getChatInfo(
          chatId: chatUid,
        );

        SenderInfo messageDetails =
            await FireStoreUser.extractUsersForGroupChatInfo(
          coverChatInfo,
        );

        return messageDetails;
      } else {
        SenderInfo coverChatInfo =
            await FireStoreUser.getChatOfUser(
          chatUid: chatUid,
        );

        SenderInfo messageDetails =
            await FireStoreUser.extractUsersForSingleChatInfo(
          coverChatInfo,
        );

        return messageDetails;
      }
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  // Get chat users information
  @override
  Future<List<SenderInfo>> getChatUserInfo({
    required UserPersonalInfo myPersonalInfo,
  }) async {
    try {
      List<SenderInfo> allChatsOfGroupsInfo =
          await FireStoreGroupChat.getSpecificChatsInfo(
        chatsIds: myPersonalInfo.chatsOfGroups,
      );

      List<SenderInfo> allChatsInfo =
          await FireStoreUser.getMessagesOfChat(
        userId: myPersonalInfo.userId,
      );

      List<SenderInfo> allChats =
          allChatsInfo + allChatsOfGroupsInfo;

      List<SenderInfo> allUsersInfo =
          await FireStoreUser.extractUsersChatInfo(
        messagesDetails: allChats,
      );

      return allUsersInfo;
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
