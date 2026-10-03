import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:commet/client/matrix/database/matrix_database_io.dart';
import 'package:commet/debug/log.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';

final class MultiDatabaseServer {
  final Map<String, DriftIsolate> _activeIsolates = {};
  final ReceivePort _receiveConnections = ReceivePort();

  MultiDatabaseServer() {
    _receiveConnections.listen((message) {
      if (message is! List) {
        Log.e("Expected to receive a list");
        return;
      }

      if (message.length != 3) {
        Log.e("Received list of incorrect length");
        return;
      }

      final name = message[0];
      final port = message[1];
      final readOnly = message[2] as bool;

      if (name is! String) {
        Log.e("list[0] was not a string");
        return;
      }

      if (port is! SendPort) {
        Log.e("list[1] was not a SendPort");
        return;
      }

      final isolate = _activeIsolates.putIfAbsent(
        name,
        () {
          return DriftIsolate.inCurrent(
              serialize: true,
              // obviously you can pass a path instead of a name and use that to open the right NativeDatabase
              () => setupNativeDatabase(File(name), readOnly: readOnly));
        },
      );

      port.send(isolate.connectPort);
    });
  }
}

class DatabaseIsolate {
  static final receiveConnectPort = ReceivePort();
  static SendPort? connectToServer;
  static Future<void>? _startFuture;

  static const isolateName = "chat.commet.commetapp.database_isolate";

  static Future<void> start() {
    return _startFuture ??= _start();
  }

  static Future<void> _start() async {
    connectToServer = IsolateNameServer.lookupPortByName(isolateName);
    if (connectToServer != null) {
      return;
    }

    Isolate.spawn(
      (SendPort port) {
        final server = MultiDatabaseServer();
        port.send(server._receiveConnections.sendPort);
      },
      receiveConnectPort.sendPort,
      debugName: "Database Isolate",
    );

    connectToServer = await receiveConnectPort.first as SendPort;
    IsolateNameServer.registerPortWithName(connectToServer!, isolateName);
  }

  static Future<DatabaseConnection> connect(String databaseName,
      {bool readOnly = false}) async {
    await start();

    final response = ReceivePort();

    connectToServer!.send([databaseName, response.sendPort, readOnly]);

    final connectPort = await response.first as SendPort;
    response.close();

    return DriftIsolate.fromConnectPort(connectPort, serialize: true).connect();
  }
}
