import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/settings/app_settings_page.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class UserPanelSettings extends StatefulWidget {
  const UserPanelSettings({this.height = 30, this.client, super.key});
  final double height;
  final Client? client;

  @override
  State<UserPanelSettings> createState() => _UserPanelSettingsState();
}

class _UserPanelSettingsState extends State<UserPanelSettings> {
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
          if (client != null)
            SizedBox(
              width: height,
              height: height,
              child: PopupMenuButton<PresenceStatus>(
                tooltip: "Set presence",
                padding: EdgeInsets.zero,
                icon: Icon(
                  client!.currentPresenceStatus.icon,
                  size: iconHeight,
                ),
                onSelected: (status) async {
                  try {
                    await client!.setPresence(status);
                    if (mounted) setState(() {});
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Unable to update presence")),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  for (final status in PresenceStatus.values)
                    PopupMenuItem<PresenceStatus>(
                      value: status,
                      child: Row(
                        children: [
                          Icon(status.icon, size: 18),
                          const SizedBox(width: 12),
                          Text(status.label),
                          const Spacer(),
                          if (status == client!.currentPresenceStatus)
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
