import 'dart:async';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/components/user_presence/user_presence_lifecycle_watcher.dart';
import 'package:commet/client/matrix/components/read_receipts/matrix_read_receipt_component.dart';
import 'package:commet/client/matrix/components/typing_indicators/matrix_typing_indicators_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:matrix/matrix.dart';

class MatrixUserPresenceComponent
    implements UserPresenceComponent<MatrixClient> {
  @override
  MatrixClient client;

  StreamController<(String, UserPresence)> _controller =
      StreamController.broadcast();

  MatrixUserPresenceComponent(this.client) {
    client.matrixClient.onPresenceChanged.stream.listen(changed);

    UserPresenceLifecycleWatcher().init();
  }

  @override
  bool get usePublicReadReceipts {
    var publicReadReceipts = client
        .matrixClient
        .accountData[MatrixReadReceiptComponent.publicReadReceiptsKey]
        ?.content["enabled"];
    return publicReadReceipts is bool ? publicReadReceipts : true;
  }

  @override
  Future<void> setUsePublicReadReceipts(bool value) async {
    await client.matrixClient.setAccountData(
      client.matrixClient.userID!,
      MatrixReadReceiptComponent.publicReadReceiptsKey,
      {"enabled": value},
    );
    client.matrixClient.receiptsPublicByDefault = value;
  }

  @override
  bool get typingIndicatorEnabled {
    var publicTypingIndicator = client
        .matrixClient
        .accountData[MatrixTypingIndicatorsComponent.publicTypingIndicatorKey]
        ?.content["enabled"];
    return publicTypingIndicator is bool ? publicTypingIndicator : true;
  }

  @override
  Future<void> setTypingIndicatorEnabled(bool value) async =>
      await client.matrixClient.setAccountData(
        client.matrixClient.userID!,
        MatrixTypingIndicatorsComponent.publicTypingIndicatorKey,
        {"enabled": value},
      );

  @override
  Future<UserPresence> getUserPresence(String userId) async {
    final presence = await client.matrixClient.fetchCurrentPresence(userId);

    return convertPresence(presence);
  }

  UserPresence convertPresence(CachedPresence presence) {
    final status = switch (presence.statusMsg) {
      commetDndPresenceMarker => UserPresenceStatus.doNotDisturb,
      commetIdlePresenceMarker => UserPresenceStatus.unavailable,
      _ => switch (presence.presence) {
          PresenceType.offline => UserPresenceStatus.offline,
          PresenceType.online => UserPresenceStatus.online,
          PresenceType.unavailable => UserPresenceStatus.unavailable,
        },
    };

    UserPresenceMessage? message = null;

    if (presence.statusMsg != null &&
        presence.statusMsg != commetDndPresenceMarker &&
        presence.statusMsg != commetIdlePresenceMarker) {
      message = UserPresenceMessage(
          presence.statusMsg!, PresenceMessageType.userCustom);
    }

    return UserPresence(status, message: message);
  }

  void changed(CachedPresence event) {
    _controller.add((event.userid, convertPresence(event)));
  }

  @override
  Stream<(String, UserPresence)> get onPresenceChanged => _controller.stream;

  @override
  Future<void> setStatus(UserPresenceStatus status,
      {String? message, bool clearMessage = false}) async {
    final self = client.self!.identifier;

    final current = await client.matrixClient.getPresence(
        self); /* TODO: fix this error, it is not a problem of the code, but of the network connection, only when running in background
                                                                    ClientException with SocketException: Failed host lookup: 'matrix.kantengewichte.de' (OS Error: No address associated with hostname, errno = 7), uri=https://matrix.kantengewichte.de/_matrix/client/v3/presence/%40stefan%3Akantengewichte.de/status (IOClient.send)
                                                                    #0      IOClient.send (package:http/src/io_client.dart:227)
                                                                    <asynchronous suspension>
                                                                    #1      TimeoutHttpClient.send (package:matrix/src/utils/http_timeout.dart:49)
                                                                    <asynchronous suspension>
                                                                    #2      Api.getPresence (package:matrix/matrix_api_lite/generated/api.dart:2824)
                                                                    <asynchronous suspension>
                                                                    #3      MatrixUserPresenceComponent.setStatus (package:commet/client/matrix/components/user_presence/matrix_user_presence.dart:116)
                                                                    <asynchronous suspension>
*/
    await client.matrixClient.setPresence(
        self,
        statusMsg: clearMessage ? null : message ?? current.statusMsg,
        switch (status) {
          UserPresenceStatus.offline => PresenceType.offline,
          UserPresenceStatus.unknown => PresenceType.offline,
          UserPresenceStatus.online => PresenceType.online,
          UserPresenceStatus.unavailable => PresenceType.unavailable,
          UserPresenceStatus.doNotDisturb => PresenceType.unavailable,
        });
  }

  void handleRoomMemberEvent(BasicEvent event) {}
}
