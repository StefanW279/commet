import 'dart:convert';
import 'dart:js_util' as js_util;

import 'package:commet/client/room.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/main.dart';

class WebPushNotifier implements Notifier {
  bool _initialized = false;

  dynamic get _global => js_util.globalThis;

  String get _server =>
      "https://${preferences.pushGateway}";

  Future<dynamic> _call(
    String function,
    List<Object?> args,
  ) async {
    final promise = js_util.callMethod<dynamic>(
      _global,
      function,
      args,
    );

    return js_util.promiseToFuture<dynamic>(promise);
  }

  @override
  bool get hasPermission {
    try {
      return js_util.getProperty<String>(
            _global,
            "commetWebPushPermission",
          ) ==
          "granted";
    } catch (_) {
      return false;
    }
  }

  @override
  bool get needsToken => true;

  @override
  bool get enabled =>
      preferences.webPushKey.value != null;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      await _call(
        "commetWebPushInit",
        [_server],
      );
    } catch (e) {
      print("Web Push initialization failed: $e");
    }
  }

  Future<String?> _registerExistingSubscription() async {
    final result = await _call(
      "commetWebPushGetExisting",
      [_server],
    );

    if (result == null) {
      return null;
    }

    final data =
        jsonDecode(result as String) as Map<String, dynamic>;

    final pushkey = data["pushkey"] as String?;

    if (pushkey != null) {
      await preferences.webPushKey.set(pushkey);
    }

    return pushkey;
  }

  @override
  Future<String?> getToken() async {
    final existing =
        preferences.webPushKey.value;

    if (existing != null) {
      return existing;
    }

    if (!hasPermission) {
      return null;
    }

    return _registerExistingSubscription();
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final result = await _call(
        "commetWebPushSubscribe",
        [_server],
      );

      if (result == null) {
        return false;
      }

      final data =
          jsonDecode(result as String)
              as Map<String, dynamic>;

      final pushkey =
          data["pushkey"] as String?;

      if (pushkey == null) {
        return false;
      }

      await preferences.webPushKey.set(pushkey);

      return true;
    } catch (e) {
      print("Web Push subscription failed: $e");
      return false;
    }
  }

  @override
  Map<String, dynamic>? extraRegistrationData() {
    return {
      "type": "webpush",
    };
  }

  @override
  Future<void> notify(
      NotificationContent notification) async {
    // Notifications are displayed by the service worker.
  }

  @override
  Future<void> clearNotifications(Room room) async {}

  @override
  Future<void> enableBadges() async {}

  @override
  Future<void> disableBadges() async {}
}