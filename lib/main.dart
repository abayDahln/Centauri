import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/storage/local_storage_service.dart';

/// Shell desktop (Windows) memakai title bar kustom, jadi window dijalankan
/// frameless. Target mobile tidak terpengaruh.
final bool _isDesktopShell = Platform.isWindows || Platform.isLinux;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_isDesktopShell) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1360, 860),
      minimumSize: Size(960, 640),
      center: true,
      backgroundColor: Color(0xFF181818),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await Hive.initFlutter();
  await LocalStorageService().init();

  runApp(const ProviderScope(child: CentauriApp()));
}
