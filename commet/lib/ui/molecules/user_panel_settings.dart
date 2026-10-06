import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/settings/app_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class UserPanelSettings extends StatefulWidget {
  const UserPanelSettings({this.height = 30, this.client, super.key});
  final double height;
  final Client? client;

  @override
  State<UserPanelSettings> createState() => _UserPanelSettingsState();
}

class _UserPanelSettingsState extends State<UserPanelSettings> {
  Color _presenceColor(PresenceStatus status) => switch (status) {
        PresenceStatus.online => const Color(0xFF23A55A),
        PresenceStatus.idle => const Color(0xFFF0B232),
        PresenceStatus.doNotDisturb => const Color(0xFFF23F42),
        PresenceStatus.invisible => const Color(0xFF80848E),
      };
  StreamSubscription? sub;

  @override
  void initState() {
    sub = WidgetComponent.currentSessions.onListUpdated.listen((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.height * 0.7;
    double iconHeight = height / 2.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        children: [
          if (widget.client != null)
            SizedBox(
              width: height,
              height: height,
              child: PopupMenuButton<PresenceStatus>(
                tooltip:
                    Intl.message("Set presence", name: "presenceSetTooltip"),
                padding: EdgeInsets.zero,
                icon: Icon(
                  widget.client!.currentPresenceStatus.icon,
                  size: iconHeight,
                  color: _presenceColor(widget.client!.currentPresenceStatus),
                ),
                onSelected: (status) async {
                  try {
                    await widget.client!.setPresence(status);
                    if (mounted) setState(() {});
                  } catch (error, stackTrace) {
                    Log.onError(error, stackTrace,
                        content: "Unable to update presence");
                  }
                },
                itemBuilder: (context) => [
                  for (final status in PresenceStatus.values)
                    PopupMenuItem<PresenceStatus>(
                      value: status,
                      child: Row(
                        children: [
                          Icon(status.icon,
                              size: 18, color: _presenceColor(status)),
                          const SizedBox(width: 12),
                          Text(status.label),
                          const Spacer(),
                          if (status == widget.client!.currentPresenceStatus)
                            const Icon(Icons.check, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            width: height,
            height: height,
            child: tiamat.IconButton(
              icon: Icons.settings,
              size: iconHeight,
              onPressed: () {
                NavigationUtils.navigateTo(context, const AppSettingsPage());
              },
            ),
          )
        ],
      ),
    );
  }
}
