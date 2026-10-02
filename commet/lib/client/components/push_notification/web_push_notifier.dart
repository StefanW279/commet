import 'package:commet/client/room.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';

class WebPushNotifier implements Notifier {
  @override
  bool get hasPermission => false;

  @override
  bool get needsToken => true;

  @override
  bool get enabled => false;

  @override
  Future<void> init() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> notify(NotificationContent notification) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Map<String, dynamic>? extraRegistrationData() =>
      {"type": "webpush"};

  @override
  Future<void> clearNotifications(Room room) async {}

  @override
  Future<void> enableBadges() async {}

  @override
  Future<void> disableBadges() async {}
}