import 'dart:convert';

import 'package:commet/client/alert.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;

class UpdateChecker {
  static bool foundUpdate = false;

  static String get labelUpdateAvailable => Intl.message("Update Available",
      name: "labelUpdateAvailable",
      desc: "Label for the the info popup when an update is available");

  static String descriptionUpdateAvailable(String version) => Intl.message(
      "There is a newer version of Commet available: ${version}",
      name: "descriptionUpdateAvailable",
      args: [version],
      desc:
          "describes the update, showing the version code for the available update");

  static Future<void> checkForUpdates() async {
    if (foundUpdate) return;

    if (!shouldCheckForUpdates) {
      return;
    }

    if (preferences.checkForUpdates.value != true) {
      return;
    }

    const String key = "name";

    var url = Uri.parse(
        "https://api.github.com/repos/StefanW279/commet/releases/latest");

    var response = await http.get(url);

    if (response.statusCode == 200) {
      foundUpdate = true;
    }

    Log.i("Got update data: ${response.body}");

    var fields = jsonDecode(response.body) as Map<String, dynamic>;

    if (fields.containsKey(key)) {
      bool available = false;

      String a_version = fields[key];
      String b_version = BuildConfig.VERSION_TAG;

      final a_regex = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)\.(\d+)$');
      final a_match = a_regex.firstMatch(a_version);

      final b_regex = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)\.(\d+)$');
      final b_match = b_regex.firstMatch(b_version);

      if (a_match != null && b_match != null) {
        int a_major = int.parse(a_match.group(1)!); 
        int a_minor = int.parse(a_match.group(2)!); 
        int a_patch = int.parse(a_match.group(3)!); 
        int a_build = int.parse(a_match.group(4)!); 

        int b_major = int.parse(b_match.group(1)!); 
        int b_minor = int.parse(b_match.group(2)!); 
        int b_patch = int.parse(b_match.group(3)!); 
        int b_build = int.parse(b_match.group(4)!); 

        if (a_major > b_major ||
            a_minor > b_minor ||
            a_patch > b_patch ||
            a_build > b_build) {
          available = true;
        }
      }

      if (available) {
        var tag = fields[key];
        clientManager!.alertManager.addAlert(Alert(AlertType.info,
            messageGetter: () => descriptionUpdateAvailable(tag),
            titleGetter: () => labelUpdateAvailable));
      } else {
        Log.i(
            "Found an update, but it's version is not newer than the current one, current: ${b_version} remote: ${a_version}");
      }

      return;
    }
  }

  static bool get shouldCheckForUpdates {
    if (PlatformUtils.isWeb) {
      return false;
    }

    if (BuildConfig.VERSION_TAG == "v0.0.0-artifact") {
      return false;
    }

    return true;
  }
}
