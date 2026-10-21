import 'dart:io';

import 'package:centauri/core/storage/sessions_root.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows root = <LOCALAPPDATA>\\Centauri\\sessions', () async {
    final stub = await Directory.systemTemp.createTemp('centauri_root_test_');
    try {
      final root = await defaultSessionsRoot(localAppDataOverride: stub.path);
      expect(
        root.path,
        '${stub.path}${Platform.pathSeparator}Centauri'
        '${Platform.pathSeparator}sessions',
      );
      expect(root.existsSync(), isTrue);
    } finally {
      if (stub.existsSync()) await stub.delete(recursive: true);
    }
  }, skip: Platform.isWindows ? false : 'Hanya Windows: memakai LOCALAPPDATA');

  test('root non-Windows = <app support>/sessions', () async {
    final stub = await Directory.systemTemp.createTemp('centauri_root_test_');
    try {
      final root = await defaultSessionsRoot(appSupportOverride: stub.path);
      expect(root.path, '${stub.path}${Platform.pathSeparator}sessions');
      expect(root.existsSync(), isTrue);
    } finally {
      if (stub.existsSync()) await stub.delete(recursive: true);
    }
  }, skip: Platform.isWindows ? 'Windows memakai LOCALAPPDATA' : false);
}
