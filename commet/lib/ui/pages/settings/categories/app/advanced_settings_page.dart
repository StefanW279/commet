import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  String get labelSettingsDeveloperMode => Intl.message("Developer mode",
      desc: "Header for the settings to enable developer mode",
      name: "labelSettingsDeveloperMode");

  String get labelSettingsDeveloperModeExplanation =>
      Intl.message("Shows extra information, useful for developers",
          desc: "Explains what developer mode does",
          name: "labelSettingsDeveloperModeExplanation");

  String get labelStickerCompatibility => Intl.message("Sticker compatibility",
      desc: "Header for the settings to enable sticker compatibility mode",
      name: "labelStickerCompatibility");

  String get labelSettingsStickerCompatibilityExplanation => Intl.message(
      "In some matrix clients, sending a sticker as 'm.sticker' will cause the sticker to not load correctly. Enabling this setting will send stickers as 'm.image' which will allow them to render correctly",
      desc: "Explains what sticker compatibility mode does",
      name: "labelSettingsStickerCompatibilityExplanation");

  String get labelOverrideLayout => Intl.message(
        "Override Layout",
        name: "labelOverrideLayout",
        desc: "",
      );

  String get labelOverrideLayoutDescription => Intl.message(
        "You may need to restart the app for this to take effect",
        name: "labelOverrideLayoutDescription",
        desc: "",
      );

  String get labelNoOverride => Intl.message(
        "No Override",
        name: "labelNoOverride",
        desc: "",
      );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: labelSettingsDeveloperMode,
          mode: TileType.surfaceContainerLow,
          child: BooleanPreferenceToggle(
            preference: preferences.developerMode,
            title: labelSettingsDeveloperMode,
            description: labelSettingsDeveloperModeExplanation,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
            header: labelStickerCompatibility,
            mode: TileType.surfaceContainerLow,
            child: BooleanPreferenceToggle(
              preference: preferences.stickerCompatibilityMode,
              title: labelStickerCompatibility,
              description: labelSettingsStickerCompatibilityExplanation,
            )),
        const SizedBox(
          height: 10,
        ),
        Panel(
            mode: tiamat.TileType.surfaceContainerLow,
            header: labelOverrideLayout,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.labelLow(labelOverrideLayoutDescription),
                tiamat.DropdownSelector(
                    items: [null, "desktop", "mobile"],
                    itemBuilder: (item) =>
                        tiamat.Text.label(item ?? labelNoOverride),
                    onItemSelected: (item) async {
                      await preferences.layoutOverride.set(item);
                      setState(() {});
                    },
                    value: preferences.layoutOverride.value)
              ],
            ))
      ],
    );
  }
}
