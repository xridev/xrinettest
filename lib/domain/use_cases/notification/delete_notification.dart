import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/domain/entities/notification_check.dart';
import 'package:xrinet/domain/repositories/firestore_notification.dart';

class DeleteNotificationUseCase implements UseCase<void, NotificationCheck> {
  final FireStoreNotificationRepository _notificationRepository;
  DeleteNotificationUseCase(this._notificationRepository);
  @override
  Future<void> call({required NotificationCheck params}) {
    return _notificationRepository.deleteNotification(
        notificationCheck: params);
  }
}
