import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import 'package:intl/intl.dart';

class ExperimentsSettingsPage extends StatefulWidget {
  const ExperimentsSettingsPage({super.key});

  @override
  State<ExperimentsSettingsPage> createState() =>
      _ExperimentsSettingsPageState();
}

class _ExperimentsSettingsPageState extends State<ExperimentsSettingsPage> {
  String get labelExperimentsUnderDevelopment => Intl.message(
        "These features are still under development, and may contain bugs or security issues. Enable at your own risk",
        name: "labelExperimentsUnderDevelopment",
        desc: "",
      );

  String get labelExperiments => Intl.message(
        "Experiments",
        name: "labelExperiments",
        desc: "",
      );

  String get labelExperimentsEncryptedElementCall => Intl.message(
        "Encrypted Element Call",
        name: "labelExperimentsEncryptedElementCall",
        desc: "",
      );

  String get labelExperimentsEncryptedElementCallDescription => Intl.message(
        "Allow use of the experimental support for end to end encryption in element call",
        name: "labelExperimentsEncryptedElementCallDescription",
        desc: "",
      );

  String get labelExperimentsMustRestart => Intl.message(
        "You must restart the app for changes to take effect",
        name: "labelExperimentsMustRestart",
        desc: "",
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.error(labelExperimentsUnderDevelopment),
        ),
        Panel(
          header: labelExperiments,
          mode: TileType.surfaceContainerLow,
          child: Column(
            children: [
              BooleanPreferenceToggle(
                preference: preferences.experimentEnableE2eeElementCall,
                title: labelExperimentsEncryptedElementCall,
                description: labelExperimentsEncryptedElementCallDescription,
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.error(labelExperimentsMustRestart),
        ),
      ],
    );
  }
}
