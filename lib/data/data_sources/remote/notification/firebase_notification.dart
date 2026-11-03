import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:xrinet/core/utility/injector.dart';
import 'package:xrinet/data/data_sources/remote/notification/device_notification.dart';
import 'package:xrinet/data/data_sources/remote/user/firestore_user_info.dart';
import 'package:xrinet/data/models/child_classes/notification.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import 'package:xrinet/domain/entities/notification_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FireStoreNotification {
  static final _fireStoreUserCollection =
      FirebaseFirestore.instance.collection('users');

  // Create or update FCM device token
  static Future<UserPersonalInfo> createNewDeviceToken({
    required String userId,
    required UserPersonalInfo myPersonalInfo,
  }) async {
    try {
      final SharedPreferences sharePrefs =
          injector<SharedPreferences>();

      final String? token =
          await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        return myPersonalInfo;
      }

      if (myPersonalInfo.deviceToken != token) {
        await _fireStoreUserCollection.doc(userId).update({
          'deviceToken': token,
        });

        myPersonalInfo.deviceToken = token;

        await sharePrefs.setString('deviceToken', token);
      }

      return myPersonalInfo;
    } catch (e, stackTrace) {
      debugPrint('DEVICE TOKEN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      // Device token failure should not stop signup.
      return myPersonalInfo;
    }
  }

  // Delete device token
  static Future<void> deleteDeviceToken({
    required String userId,
  }) async {
    await _fireStoreUserCollection.doc(userId).update({
      'deviceToken': '',
    });
  }

  // Create notification
  static Future<String> createNotification(
    CustomNotification newNotification,
  ) async {
    final DocumentReference<Map<String, dynamic>> userCollection =
        _fireStoreUserCollection.doc(newNotification.receiverId);

    await userCollection.update({
      'numberOfNewNotifications': FieldValue.increment(1),
    });

    final UserPersonalInfo receiverInfo =
        await FireStoreUser.getUserInfo(
      newNotification.receiverId,
    );

    final String token = receiverInfo.deviceToken;

    if (token.isNotEmpty) {
      await DeviceNotification.pushNotification(
        customNotification: newNotification,
        token: token,
      );
    }

    return await _createNotification(newNotification);
  }

  // Save notification in Firestore
  static Future<String> _createNotification(
    CustomNotification newNotification,
  ) async {
    final DocumentReference<Map<String, dynamic>> userCollection =
        _fireStoreUserCollection.doc(newNotification.receiverId);

    final CollectionReference<Map<String, dynamic>> collection =
        userCollection.collection('notifications');

    final DocumentReference<Map<String, dynamic>> addingCollection =
        await collection.add(newNotification.toMap());

    newNotification.notificationUid = addingCollection.id;

    await addingCollection.update({
      'notificationUid': newNotification.notificationUid,
    });

    return newNotification.notificationUid;
  }

  // Get notifications
  static Future<List<CustomNotification>> getNotifications({
    required String userId,
  }) async {
    final DocumentReference<Map<String, dynamic>> userCollection =
        _fireStoreUserCollection.doc(userId);

    await userCollection.update({
      'numberOfNewNotifications': 0,
    });

    final QuerySnapshot<Map<String, dynamic>> snap =
        await userCollection.collection('notifications').get();

    final List<CustomNotification> notifications = [];

    for (final doc in snap.docs) {
      final notification =
          CustomNotification.fromJson(doc.data());

      notifications.add(notification);
    }

    return notifications;
  }

  // Delete notification
  static Future<void> deleteNotification({
    required NotificationCheck notificationCheck,
  }) async {
    final CollectionReference<Map<String, dynamic>> collection =
        _fireStoreUserCollection
            .doc(notificationCheck.receiverId)
            .collection('notifications');

    QuerySnapshot<Map<String, dynamic>> getDoc;

    if (notificationCheck.isThatPost) {
      getDoc = await collection
          .where(
            'isThatLike',
            isEqualTo: notificationCheck.isThatLike,
          )
          .where(
            'isThatPost',
            isEqualTo: notificationCheck.isThatPost,
          )
          .where(
            'senderId',
            isEqualTo: notificationCheck.senderId,
          )
          .where(
            'postId',
            isEqualTo: notificationCheck.postId,
          )
          .get();
    } else {
      getDoc = await collection
          .where(
            'senderId',
            isEqualTo: notificationCheck.senderId,
          )
          .where(
            'postId',
            isEqualTo: notificationCheck.postId,
          )
          .get();
    }

    for (final doc in getDoc.docs) {
      await collection.doc(doc.id).delete();
    }
  }
}
