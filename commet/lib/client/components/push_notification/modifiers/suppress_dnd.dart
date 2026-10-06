import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/main.dart';

class NotificationModifierSuppressDnd implements NotificationModifier {
  @override
  Future<NotificationContent?> process(NotificationContent content,
      {Function(String reason)? onNotificationRejected}) async {
    final clientId = switch (content) {
      MessageNotificationContent notification => notification.clientId,
      CallNotificationContent notification => notification.clientId,
      GenericRoomInviteNotificationContent notification =>
        notification.clientId,
      _ => null,
    };

    if (clientId == null) {
      return content;
    }

    final client = clientManager?.getClient(clientId);
    final isDnd =
        client?.currentPresenceStatus == PresenceStatus.doNotDisturb ||
            preferences.getPresenceStatus(clientId) ==
                PresenceStatus.doNotDisturb.name;

    if (!isDnd) {
      return content;
    }

    onNotificationRejected
        ?.call(Intl.message("Notifications are suppressed while Do Not Disturb is enabled", name: "notificationsSuppressedDoNotDisturb"));
    return null;
  }
}
