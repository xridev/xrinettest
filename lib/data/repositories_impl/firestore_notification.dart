import 'package:xrinet/data/data_sources/remote/notification/firebase_notification.dart';
import 'package:xrinet/data/models/child_classes/notification.dart';
import 'package:xrinet/domain/entities/notification_check.dart';
import 'package:xrinet/domain/repositories/firestore_notification.dart';

class FireStoreNotificationRepoImpl implements FireStoreNotificationRepository {
  @override
  Future<String> createNotification(
      {required CustomNotification newNotification}) async {
    try {
      return await FireStoreNotification.createNotification(newNotification);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<CustomNotification>> getNotifications({required String userId}) {
    try {
      return FireStoreNotification.getNotifications(userId: userId);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> deleteNotification(
      {required NotificationCheck notificationCheck}) {
    try {
      return FireStoreNotification.deleteNotification(
          notificationCheck: notificationCheck);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
