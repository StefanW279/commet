import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:commet/ui/pages/settings/categories/app/double_preference_slider.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings/notifier_debug_view.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Notifier? notifier;
  GlobalKey pushGatewayKey = GlobalKey();
  bool isPushGatewayLoading = false;

  Future<void> enableWebPush() async {
    final notifier = NotificationManager.notifier;

    if (notifier == null) {
      return;
    }

    setState(() {
      isPushGatewayLoading = true;
    });

    try {
      final success = await notifier.requestPermission();

      if (success) {
        await PushNotificationComponent.updateAllPushers();
      }
    } finally {
      setState(() {
        isPushGatewayLoading = false;
      });
    }
  }

  String get notificationSettingsNotSupported =>
      Intl.message("Push notifications are not supported on this system",
          name: "notificationSettingsNotSupported",
          desc: "Message to display when push notifications are not supported");

  String get labelPushNotifications => Intl.message(
        "Push Notifications",
        name: "labelPushNotifications",
        desc: "",
      );

  String get labelUnifiedPush => Intl.message(
        "Unified Push",
        name: "labelUnifiedPush",
        desc: "",
      );

  String get labelRegisteredPushers => Intl.message(
        "Registered Pushers",
        name: "labelRegisteredPushers",
        desc: "",
      );

  String get labelSilenceNotifications => Intl.message(
        "Silence Notifications",
        name: "labelSilenceNotifications",
        desc: "",
      );

  String get labelSilenceNotificationsDescription => Intl.message(
        "When another device or client is active, silence notifications on this device",
        name: "labelSilenceNotificationsDescription",
        desc: "",
      );

  String get labelShowNotifications => Intl.message(
        "Show notifications",
        name: "labelShowNotifications",
        desc: "",
      );

  String get labelShowNotificationsDescription => Intl.message(
        "Enable or disable the display of notifications entirely",
        name: "labelShowNotificationsDescription",
        desc: "",
      );

  String get labelHideNotificationsCurrentRoom => Intl.message(
        "Hide notifications for current room",
        name: "labelHideNotificationsCurrentRoom",
        desc: "",
      );

  String get labelHideNotificationsCurrentRoomDescription => Intl.message(
        "When receiving a message, if you have the chat selected and the app is in focus, dont show the notification",
        name: "labelHideNotificationsCurrentRoomDescription",
        desc: "",
      );

  String get labelNotificationBadges => Intl.message(
        "Notification Badges",
        name: "labelNotificationBadges",
        desc: "",
      );

  String get labelNotificationBadgesDescription => Intl.message(
        "Show a badge with the number of unread messages in the system taskbar",
        name: "labelNotificationBadgesDescription",
        desc: "",
      );

  String get labelMessageBodyFormatting => Intl.message(
        "Message Body Formatting",
        name: "labelMessageBodyFormatting",
        desc: "",
      );

  String get labelMessageBodyFormattingDescription => Intl.message(
        "Apply user formatting in message notifications",
        name: "labelMessageBodyFormattingDescription",
        desc: "",
      );

  String get labelShowImages => Intl.message(
        "Show Images",
        name: "labelShowImages",
        desc: "",
      );

  String get labelShowImagesDescription => Intl.message(
        "Show images in notifications, if allowed by 'General > Media Preview' settings",
        name: "labelShowImagesDescription",
        desc: "",
      );

  String get labelPreviewUrls => Intl.message(
        "Preview Urls",
        name: "labelPreviewUrls",
        desc: "",
      );

  String get labelPreviewUrlsDescription => Intl.message(
        "Fetch URL previews to show extra information about links in notifications",
        name: "labelPreviewUrlsDescription",
        desc: "",
      );

  String get labelNotificationVolume => Intl.message(
        "Notification volume",
        name: "labelNotificationVolume",
        desc: "",
      );

  String get labelNotificationVolumeDescription => Intl.message(
        "Controls the volume of notifications and ringtones",
        name: "labelNotificationVolumeDescription",
        desc: "",
      );

  @override
  void initState() {
    super.initState();
    notifier = NotificationManager.notifier;
  }

  bool get canConfigureNotifications =>
      PlatformUtils.isWeb || PlatformUtils.isAndroid || PlatformUtils.isLinux;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canConfigureNotifications)
          Column(
            children: [
              Panel(
                mode: tiamat.TileType.surfaceContainerLow,
                header: labelPushNotifications,
                child: buildNotificationSettings(),
              ),
              if (notifier is UnifiedPushNotifier)
                Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Panel(
                        mode: tiamat.TileType.surfaceContainerLow,
                        header: labelUnifiedPush,
                        child: Column(
                          children: [
                            UnifiedPushSetupView(
                              onToggled: (_) => setState(() {}),
                            ),
                            if (preferences.unifiedPushEnabled.value == true)
                              pushGatewaySelector(),
                          ],
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
            ],
          ),
        if (preferences.developerMode.value)
          Panel(
            mode: tiamat.TileType.surfaceContainerLow,
            header: labelRegisteredPushers,
            child: NotifierDebugView(),
          ),
      ],
    );
  }

  Widget buildNotificationSettings() {
    return Column(
      children: [
        if (PlatformUtils.isWeb)
          Column(
            children: [
              tiamat.Button(
                text: notifier?.hasPermission == true
                    ? Intl.message("Web Push enabled", name: "webPushEnabled")
                    : Intl.message("Enable Web Push", name: "enableWebPush"),
                onTap: enableWebPush,
              ),
              const SizedBox(height: 10),
              tiamat.Text.labelLow(
                Intl.message(
                  "Allow browser notifications to receive messages when Commet is closed.",
                  name: "webPushDescription",
                ),
              ),
            ],
          ),
        if (PlatformUtils.isAndroid)
          BooleanPreferenceToggle(
            preference: preferences.silenceNotifications,
            title: labelSilenceNotifications,
            description: labelSilenceNotificationsDescription,
          ),
        if (PlatformUtils.isLinux || PlatformUtils.isWindows)
          Column(
            children: [
              BooleanPreferenceToggle(
                preference: preferences.enableNotifications,
                title: labelShowNotifications,
                description: labelShowNotificationsDescription,
              ),
              BooleanPreferenceToggle(
                preference: preferences.suppressNotificationWhenRoomFocused,
                title: labelHideNotificationsCurrentRoom,
                description: labelHideNotificationsCurrentRoomDescription,
              ),
              if (PlatformUtils.isLinux)
                Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    BooleanPreferenceToggle(
                      preference: preferences.showNotificationBadgesInTaskbar,
                      title: labelNotificationBadges,
                      description: labelNotificationBadgesDescription,
                      onChanged: (enabled) {
                        if (enabled) {
                          NotificationManager.notifier?.enableBadges();
                        } else {
                          NotificationManager.notifier?.disableBadges();
                        }
                      },
                    ),
                    BooleanPreferenceToggle(
                      preference: preferences.formatNotificationBody,
                      title: labelMessageBodyFormatting,
                      description: labelMessageBodyFormattingDescription,
                    ),
                    AnimatedOpacity(
                      opacity:
                          preferences.formatNotificationBody.value ? 1 : 0.3,
                      duration: Durations.short4,
                      child: IgnorePointer(
                        ignoring:
                            preferences.formatNotificationBody.value == false,
                        child: Column(
                          children: [
                            BooleanPreferenceToggle(
                              preference: preferences.showMediaInNotifications,
                              title: labelShowImages,
                              description: labelShowImagesDescription,
                            ),
                            BooleanPreferenceToggle(
                              preference: preferences.previewUrlInNotifications,
                              title: labelPreviewUrls,
                              description: labelPreviewUrlsDescription,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(
                height: 20,
              ),
              DoublePreferenceSlider(
                preference: preferences.notificationsVolume,
                min: 0,
                max: 150,
                numDecimals: 0,
                units: "%",
                title: labelNotificationVolume,
                description: labelNotificationVolumeDescription,
                onChanged: (p0) {
                  Player p = NotificationManager.getSoundPlayer();
                  p.setVolume(p0);
                  p.open(Media("asset:///assets/sound/message.ogg"));
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget pushGatewaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        tiamat.DropdownTextField(
            key: pushGatewayKey,
            initialValue: preferences.pushGateway,
            textEditorPlaceholder: "push.example.com",
            editableEntryPlaceholder: "Custom push gateway",
            items: [
              "push.kantengewichte.de",
              if (notifier is UnifiedPushNotifier)
                "matrix.gateway.unifiedpush.org"
            ]),
        tiamat.Button(
          text: CommonStrings.promptApply,
          isLoading: isPushGatewayLoading,
          onTap: onPushGatewaySelected,
        )
      ],
    );
  }

  Future<void> onPushGatewaySelected() async {
    var value = (pushGatewayKey.currentState as DropdownTextFieldState).value;
    preferences.setPushGateway(value);

    setState(() {
      isPushGatewayLoading = true;
    });

    await PushNotificationComponent.updateAllPushers();

    setState(() {
      isPushGatewayLoading = false;
    });
  }
}
