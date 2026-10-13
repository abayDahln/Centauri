import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_windows/webview_windows.dart';
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

  // Keduanya tahan-gagal dan tidak boleh menghentikan runApp(): dulu
  // exception di sini meninggalkan jendela kosong tanpa pesan apa pun.
  final storage = await LocalStorageService().init();
  if (!storage.isHealthy) {
    debugPrint('[storage] inisialisasi tidak lengkap: ${storage.error}');
  }
  if (Platform.isWindows) {
    await _prepareWebviewEnvironment();
  }

  runApp(const ProviderScope(child: CentauriApp()));
}

/// Siapkan environment WebView2 SATU kali untuk semua frame.
///
/// Tanpa ini, tiap `WebviewController.initialize()` membuat environment
/// sendiri dengan folder user-data default di samping exe — lambat untuk
/// board multi-frame dan gagal bila folder install tidak bisa ditulis.
Future<void> _prepareWebviewEnvironment() async {
  try {
    final version = await WebviewController.getWebViewVersion();
    if (version == null) {
      debugPrint(
        '[canvas] WebView2 Runtime tidak terpasang — canvas tidak akan tampil. '
        'Instal "Microsoft Edge WebView2 Runtime".',
      );
      return;
    }
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final sep = Platform.pathSeparator;
    await WebviewController.initializeEnvironment(
      userDataPath: localAppData == null || localAppData.isEmpty
          ? null
          : '$localAppData${sep}Centauri${sep}WebView2',
    );
  } catch (e) {
    // Sudah diinisialisasi sebelumnya, atau runtime menolak: biarkan tiap
    // frame mencoba initialize sendiri dan laporkan error per frame.
    debugPrint('[canvas] prepare environment WebView2: $e');
  }
}
