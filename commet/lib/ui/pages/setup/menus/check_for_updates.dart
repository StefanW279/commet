import 'dart:async';

import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:commet/ui/pages/setup/setup_menu.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:intl/intl.dart';

String get promptCheckForUpdates => Intl.message("Check for updates",
    desc: "Title for the check for updates setting",
    name: "promptCheckForUpdates");

String get promptCheckForUpdatesDescription => Intl.message(
    "Automatically check if there is a newer version of Commet available",
    desc: "Description for the check for updates setting",
    name: "promptCheckForUpdatesDescription");

String get promptCheckForUpdatesDescriptionFirstLogin => Intl.message(
      "Would you like Commet to automatically check for new updates?",
      name: "promptCheckForUpdatesDescriptionFirstLogin",
      desc: "",
    );

class UpdateCheckerSetup implements SetupMenu {
  StreamController<SetupMenuState> controller = StreamController();

  GlobalKey key = GlobalKey();

  @override
  Widget builder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tiamat.Text.largeTitle(promptCheckForUpdates),
        tiamat.Text.label(promptCheckForUpdatesDescriptionFirstLogin),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              decoration: BoxDecoration(
                color: ColorScheme.of(context).surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CheckForUpdatesSettingWidget(),
              )),
        ),
      ],
    );
  }

  @override
  Stream<SetupMenuState> get onStateChanged => controller.stream;

  @override
  SetupMenuState state = SetupMenuState.canProgress;

  @override
  Future<void> submit() async {
    return;
  }
}

class CheckForUpdatesSettingWidget extends StatefulWidget {
  const CheckForUpdatesSettingWidget({super.key});

  @override
  State<CheckForUpdatesSettingWidget> createState() =>
      _CheckForUpdatesSettingWidgetState();
}

class _CheckForUpdatesSettingWidgetState
    extends State<CheckForUpdatesSettingWidget> {
  @override
  Widget build(BuildContext context) {
    return BooleanPreferenceToggle(
      preference: preferences.checkForUpdates,
      title: promptCheckForUpdates,
      description: promptCheckForUpdatesDescription,
    );
  }
}
