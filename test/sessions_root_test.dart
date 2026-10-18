import 'dart:io';

import 'package:centauri/core/storage/sessions_root.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows root = <LOCALAPPDATA>\\Centauri\\sessions', () async {
    final stub = await Directory.systemTemp.createTemp('centauri_root_test_');
    try {
      final root = await defaultSessionsRoot(localAppDataOverride: stub.path);
      expect(root.path.endsWith('sessions'), isTrue);
      expect(root.path, contains('Centauri'));
      expect(root.existsSync(), isTrue);
    } finally {
      if (stub.existsSync()) await stub.delete(recursive: true);
    }
  });
}
