import 'dart:io';

import 'package:collection/collection.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/space.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagement {
  static final TrayManager _trayManager = TrayManager.instance;

  static Future<void> init() async {
    if (!(PlatformUtils.isLinux || PlatformUtils.isWindows)) return;

    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);
    windowManager.addListener(_WindowListener());

    await _initTray();

    HardwareKeyboard.instance.addHandler(_onKeyEvent);

    EventBus.onSelectedRoomChanged.stream.listen(_onSelectedRoomChanged);
    EventBus.onSelectedSpaceChanged.stream.listen(_onSelectedSpaceChanged);

    if (commandLineArgs.contains("--minimize")) {
      await windowManager.hide();
    }
  }

  static Future<void> _initTray() async {
    _trayManager.addListener(_TrayListener());
    await _configureTray();
  }

  static String _trayIconPath() {
    final asset = PlatformUtils.isWindows
        ? "assets/images/app_icon/app_icon_rounded.ico"
        : "assets/images/app_icon/app_icon_filled.png";

    if (PlatformUtils.isLinux) {
      final isFlatpak = Platform.environment.containsKey('FLATPAK_ID');
      if (isFlatpak) {
        return 'chat.commet.commetapp';
      }
    }

    // tray_manager's Windows implementation expects an on-disk icon path.
    // Flutter bundles assets under data/flutter_assets next to the executable.
    final executable = File(Platform.resolvedExecutable);
    final resolvedExecutable = executable.resolveSymbolicLinksSync();
    final executableDirectory = File(resolvedExecutable).parent.path;
    return "$executableDirectory/data/flutter_assets/$asset";
  }

  static Future<void> _configureTray() async {
    // Linux tray_manager does not implement setToolTip in the 0.5.x API.
    if (PlatformUtils.isWindows) {
      await _trayManager.setToolTip("Commet");
    }
    await _trayManager.setIcon(_trayIconPath());
    await _trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: "show_window", label: "Open Commet"),
          MenuItem.separator(),
          MenuItem(key: "quit_app", label: "Quit"),
        ],
      ),
    );
  }

  static Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();

    // Re-register the icon after activation; KDE may drop the StatusNotifierItem.
    await _trayManager.setIcon(_trayIconPath());
  }

  static Future<void> quit() async {
    if (clientManager != null) {
      for (final client in clientManager!.clients) {
        await client.close();
      }
    }
    exit(0);
  }

  static bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
      return true;
    }
    return false;
  }

  static void _toggleFullscreen() async {
    final isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
  }

  static String? _currentSpaceName;
  static String? _currentRoomName;

  static void _onSelectedRoomChanged(Room? event) {
    _currentRoomName = event?.displayName;
    _updateTitle();
  }

  static void _onSelectedSpaceChanged(Space? event) {
    _currentSpaceName = event?.displayName;
    _updateTitle();
  }

  static void _updateTitle() {
    final result = [
      _currentRoomName,
      _currentSpaceName,
      "commet",
    ].whereNot((a) => a == null).join(" | ");
    windowManager.setTitle(result);
  }
}

class _TrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    WindowManagement.showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    WindowManagement._trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case "show_window":
        WindowManagement.showWindow();
        break;
      case "quit_app":
        WindowManagement.quit();
        break;
    }
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    super.onWindowClose();

    if (preferences.minimizeOnClose.value) {
      await windowManager.hide();
    } else {
      await WindowManagement.quit();
    }
  }
}
