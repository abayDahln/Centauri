import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Folder root semua sesi proyek (sumber kebenaran berbasis file, konsep
/// "satu folder per sesi" ala VS Code).
///
/// Windows: `%LOCALAPPDATA%\Centauri\sessions` — hidup di dekat box Hive
/// agar pengaturan dan prototipe mudah dicari bareng. Platform lain: folder
/// pendukung aplikasi (`path_provider`).
///
/// [localAppDataOverride] untuk test: paksa lokasi Windows tanpa menyentuh
/// penyimpanan pengguna sungguhan. [appSupportOverride] melakukan hal yang sama
/// untuk platform non-Windows.
Future<Directory> defaultSessionsRoot({
  String? localAppDataOverride,
  String? appSupportOverride,
}) async {
  if (Platform.isWindows) {
    final env = localAppDataOverride ?? Platform.environment['LOCALAPPDATA'];
    if (env == null || env.isEmpty) {
      throw const FileSystemException('LOCALAPPDATA tidak tersedia');
    }
    final root = Directory(
      '$env${Platform.pathSeparator}Centauri${Platform.pathSeparator}sessions',
    );
    await root.create(recursive: true);
    return root;
  }
  final support =
      appSupportOverride ?? (await getApplicationSupportDirectory()).path;
  final root = Directory('$support${Platform.pathSeparator}sessions');
  await root.create(recursive: true);
  return root;
}
