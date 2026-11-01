import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/string_list_preference_editor.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:commet/ui/pages/setup/menus/check_for_updates.dart';
import 'package:commet/utils/update_checker.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => GeneralSettingsPageState();
}

class GeneralSettingsPageState extends State<GeneralSettingsPage> {
  String get labelThirdPartyServicesTitle =>
      Intl.message("Third party services",
          desc: "Header for the third party services section in settings",
          name: "labelThirdPartyServicesTitle");

  String get labelGifSearchToggle => Intl.message("Gif search",
      desc: "Label for the toggle for enabling and disabling gif search",
      name: "labelGifSearchToggle");

  String labelGifSearchDescriptionGeneric(proxyUrl, serviceName) => Intl.message(
      "Enable use of $serviceName GIF search. Requests will be proxied via $proxyUrl",
      desc: "Explains that gifs will be fetched via proxy",
      args: [proxyUrl, serviceName],
      name: "labelGifSearchDescriptionGeneric");

  String get labelUrlPreviewInEncryptedChatTitle => Intl.message(
      "URL Preview in Encrypted Chats",
      desc:
          "Label for the toggle for enabling and disabling use of url previews in encrypted chats",
      name: "labelUrlPreviewInEncryptedChatTitle");

  String get labelUrlPreviewInEncryptedChatDescription => Intl.message(
      "This will expose any URLs sent in your encrypted chats to your homeserver in order to fetch the preview",
      desc:
          "description for the toggle for enabling and disabling use of url previews in encrypted chats",
      name: "labelUrlPreviewInEncryptedChatDescription");

  String get labelAppBehaviourTitle => Intl.message("App Behaviour",
      desc: "Header for the app behaviour section in settings",
      name: "labelAppBehaviourTitle");

  String get labelAskBeforeDeletingMessageToggle => Intl.message(
      "Ask before deleting messages",
      desc:
          "Label for the toggle for enabling and disabling message deletion confirmation",
      name: "labelAskBeforeDeletingMessageToggle");

  String get labelAskBeforeDeletingMessageDescription => Intl.message(
      "Enables the pop-up asking for confirmation when deleting a message.",
      desc:
          "Label describing what 'asking before deleting messages' even means",
      name: "labelAskBeforeDeletingMessageDescription");

  String get labelMessageEffectsTitle => Intl.message("Message Effects",
      desc:
          "Header for the settings tile for message effects, such as confetti",
      name: "labelMessageEffectsTitle");

  String get labelMessageEffectsDescription => Intl.message(
      "Messages can be sent with additional effects, such as confetti",
      desc: "Label describing what message effects are",
      name: "labelMessageEffectsDescription");

  String get labelMediaPreviewSettingsTitle => Intl.message("Media Preview",
      desc: "Header for the settings tile for for media preview toggles",
      name: "labelMediaPreviewSettingsTitle");

  String get labelMediaSettings => Intl.message("Media",
      desc: "Header for the settings tile for for media",
      name: "labelMediaSettings");

  String get labelMediaPreviewPrivateRoomsToggle => Intl.message(
        "Private Rooms",
        desc:
            "Short label for the private rooms toggle in media previews section",
        name: "labelMediaPreviewPrivateRoomsToggle",
      );

  String get labelMediaPreviewPrivateRoomsToggleDescription => Intl.message(
      "Toggle previewing of images, videos, stickers and urls in private chats",
      desc: "Label describing toggle of media previews for private rooms",
      name: "labelMediaPreviewPrivateRoomsToggleDescription");

  String get labelMediaPreviewPublicRoomsToggle => Intl.message(
        "Public Rooms",
        desc:
            "Short label for the private rooms toggle in media previews section",
        name: "labelMediaPreviewPublicRoomsToggle",
      );

  String get labelMediaPreviewPublicRoomsToggleDescription => Intl.message(
      "Toggle previewing of images, videos, stickers and urls in public chat rooms",
      desc: "Label describing toggle of media previews for public rooms",
      name: "labelMediaPreviewPublicRoomsToggleDescription");

  String get labelPauseAnimationsWhenNotFocused => Intl.message(
        "Pause animations when unfocused",
        desc:
            "Description for the toggle for pausing animations when the app is in the background",
        name: "labelPauseAnimationsWhenNotFocused",
      );

  String get labelPauseAnimationsWhenNotFocusedDescription => Intl.message(
      "When the app is in the background, pause animations to reduce CPU usage",
      desc:
          "Label describing toggle of pausing animations when the app is in the background",
      name: "labelPauseAnimationsWhenNotFocusedDescription");

  String get labelOpenRoomsAtLastReadMessage => Intl.message(
        "Open at last read message",
        desc:
            "Description for the toggle for opening a room at the last read message",
        name: "labelOpenRoomsAtLastReadMessage",
      );

  String get labelOpenRoomsAtLastReadMessageDescription => Intl.message(
      "When opening a room, jump to the last message you read",
      desc:
          "Label describing toggle of opening a room at the last read message",
      name: "labelOpenRoomsAtLastReadMessageDescription");

  String get labelAutomaticallyOpenSpace => Intl.message(
        "Always open space",
        desc:
            "Description for the toggle for automatically opening a space when navigating to a room",
        name: "labelAutomaticallyOpenSpace",
      );

  String get labelAutomaticallyOpenSpaceDescription => Intl.message(
        "When navigating to a room from outside of a space, also open the space the room is in, if any",
        desc:
            "Label describing the toggle for automatically opening a space when navigating to a room",
        name: "labelAutomaticallyOpenSpaceDescription",
      );

  String get labelSelectAutoCompleteSuggestion => Intl.message(
        "Select first auto-complete suggestion",
        desc:
            "Description for the toggle for selecting the first auto-complete suggestion when typing a message",
        name: "labelSelectAutoCompleteSuggestion",
      );

  String get labelSelectAutoCompleteSuggestionDescription => Intl.message(
        "When typing a message, if there are any auto-complete suggestions, the first one will be highlighted by default",
        desc:
            "Label describing the toggle for selecting the first auto-complete suggestion when typing a message",
        name: "labelSelectAutoCompleteSuggestionDescription",
      );

  String get labelAutofocusMessageTextBox => Intl.message(
        "Autofocus Message Input",
        desc:
            "Description for the toggle for automatically focusing on the message input text field when opening a chat",
        name: "labelAutofocusMessageTextBox",
      );

  String get labelAutofocusMessageTextBoxDescription => Intl.message(
        "Automatically focus on the message input text field when opening a chat",
        desc:
            "Label describing the toggle for automatically focusing on the message input text field when opening a chat",
        name: "labelAutofocusMessageTextBoxDescription",
      );

  String get labelRotateImages => Intl.message(
        "Rotate Images",
        desc: "",
        name: "labelRotateImages",
      );

  String get labelRotateImagesDescription => Intl.message(
        "When showing images in fullscreen, automatically rotate the image to best fill the screen",
        desc: "",
        name: "labelRotateImagesDescription",
      );

  String get labelRotateVideos => Intl.message(
        "Rotate Videos",
        desc: "",
        name: "labelRotateVideos",
      );

  String get labelRotateVideosDescription => Intl.message(
        "When showing videos in fullscreen, automatically rotate the video to best fill the screen",
        desc: "",
        name: "labelRotateVideosDescription",
      );

  String get labelAllowedVideoHosts => Intl.message(
        "Allowed Video Hosts",
        desc: "",
        name: "labelAllowedVideoHosts",
      );

  String get labelAllowedVideoHostsDescription => Intl.message(
        "Allowed web hosts for displaying external videos, such as in URL Previews. Your IP address will be revealed to these servers when accessing the video",
        desc: "",
        name: "labelAllowedVideoHostsDescription",
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
          header: labelThirdPartyServicesTitle,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            BooleanPreferenceToggle(
              preference: preferences.tenorGifSearchEnabled,
              title: labelGifSearchToggle,
              description: labelGifSearchDescriptionGeneric(
                  preferences.proxyUrl.value, "KLIPY"),
            ),
            const SizedBox(
              height: 10,
            ),
            BooleanPreferenceToggle(
              preference: preferences.urlPreviewInE2EEChat,
              title: labelUrlPreviewInEncryptedChatTitle,
              description: labelUrlPreviewInEncryptedChatDescription,
            ),
            if (UpdateChecker.shouldCheckForUpdates)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: CheckForUpdatesSettingWidget(),
              ),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelAppBehaviourTitle,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            BooleanPreferenceToggle(
              preference: preferences.use24HourTime,
              title: Intl.message("Use 24-hour time", name: "use24HourTime"),
              description: Intl.message(
                "Display times using the 24-hour clock instead of the 12-hour clock",
                name: "use24HourTimeDescription",
              ),
            ),
            BooleanPreferenceToggle(
              preference: preferences.askBeforeDeletingMessageEnabled,
              title: labelAskBeforeDeletingMessageToggle,
              description: labelAskBeforeDeletingMessageDescription,
            ),
            BooleanPreferenceToggle(
              preference: preferences.autoFocusMessageTextBox,
              title: labelAutofocusMessageTextBox,
              description: labelAutofocusMessageTextBoxDescription,
            ),
            BooleanPreferenceToggle(
              preference: preferences.selectAutoCompleteSuggestion,
              title: labelSelectAutoCompleteSuggestion,
              description: labelSelectAutoCompleteSuggestion,
            ),
            BooleanPreferenceToggle(
              preference: preferences.automaticallyOpenSpace,
              title: labelAutomaticallyOpenSpace,
              description: labelAutomaticallyOpenSpaceDescription,
            ),
            BooleanPreferenceToggle(
              preference: preferences.openRoomsAtLastReadMessage,
              title: labelOpenRoomsAtLastReadMessage,
              description: labelOpenRoomsAtLastReadMessageDescription,
            ),
            BooleanPreferenceToggle(
              preference: preferences.pauseAnimationsWhenNotFocused,
              title: labelPauseAnimationsWhenNotFocused,
              description: labelPauseAnimationsWhenNotFocusedDescription,
            )
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelMessageEffectsTitle,
          mode: TileType.surfaceContainerLow,
          child: BooleanPreferenceToggle(
            preference: preferences.messageEffectsEnabled,
            title: labelMessageEffectsTitle,
            description: labelMessageEffectsDescription,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelMediaSettings,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            BooleanPreferenceToggle(
              preference: preferences.previewMediaInPrivateRooms,
              title: labelMediaPreviewPrivateRoomsToggle,
              description: labelMediaPreviewPrivateRoomsToggleDescription,
            ),
            BooleanPreferenceToggle(
              preference: preferences.previewMediaInPublicRooms,
              title: labelMediaPreviewPublicRoomsToggle,
              description: labelMediaPreviewPublicRoomsToggleDescription,
            ),
            if (MediaQuery.of(context).mobile) ...[
              Seperator(),
              BooleanPreferenceToggle(
                preference: preferences.autoRotateImages,
                title: labelRotateImages,
                description: labelRotateImagesDescription,
              ),
              BooleanPreferenceToggle(
                preference: preferences.autoRotateVideos,
                title: labelRotateVideos,
                description: labelRotateVideosDescription,
              ),
            ],
            Seperator(),
            StringListPreferenceEditor(
              preference: preferences.allowedRemoteVideoHosts,
              title: labelAllowedVideoHosts,
              description: labelAllowedVideoHostsDescription,
            )
          ]),
        ),
      ],
    );
  }
}
