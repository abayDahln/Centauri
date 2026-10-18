import 'dart:io';

import 'package:centauri/features/history/data/session_folder_store.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late SessionFolderStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('centauri_sessions_test_');
    store = SessionFolderStore(temp);
  });

  tearDown(() async {
    final dir = temp;
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  group('folder layout', () {
    test('folderFor maps project id to a subfolder of root', () {
      expect(store.folderFor('abc-123').path, endsWith('abc-123'));
    });

    test('fileNameFor uses the page slug as the file name', () {
      const page = ProjectPage(
        id: 'page_1',
        name: 'Home',
        slug: 'home.html',
        html: '<p>hi</p>',
      );
      expect(store.fileNameFor(page), 'home.html');
    });
  });
}
