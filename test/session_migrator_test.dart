import 'dart:convert';
import 'dart:io';

import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:centauri/features/history/data/session_folder_store.dart';
import 'package:centauri/features/history/data/session_migrator.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

Project _project(String id, {String title = 'Proyek lama'}) => Project(
  id: id,
  title: title,
  messages: const [
    ProjectMessage(role: 'user', text: 'pesan lama', kind: 'chat'),
  ],
  pages: const [
    ProjectPage(
      id: 'page_1',
      name: 'Home',
      slug: 'home.html',
      html: '<html><body>lama</body></html>',
    ),
    ProjectPage(
      id: 'page_2',
      name: 'Setting',
      slug: 'setting.html',
      html: '<html><body>setel</body></html>',
    ),
  ],
  activePageId: 'page_1',
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 2),
);

void main() {
  late Directory tempRoot;
  late String hivePath;
  late LocalStorageService storage;
  late SessionFolderStore store;
  late SessionMigrator migrator;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('centauri_migr_test_');
    final sep = Platform.pathSeparator;
    hivePath = '${tempRoot.path}${sep}hive';
    storage = LocalStorageService();
    await storage.init(path: hivePath, sessionsPath: tempRoot.path);
    store = SessionFolderStore(tempRoot);
    migrator = SessionMigrator(storage, store);
  });

  tearDown(() async {
    // Tutup box Hive agar file di temp tidak terkunci saat dihapus.
    await Hive.close();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  group('SessionMigrator', () {
    test('proyek Hive -> folder manifest + html, dan terbaca loadAll', () {
      storage.writeProjectJson(
        'legacy-1',
        jsonEncode(_project('legacy-1').toJson()),
      );

      migrator.migrateHiveProjects();

      final dir = store.folderFor('legacy-1');
      expect(
        File('${dir.path}${Platform.pathSeparator}manifest.json').existsSync(),
        isTrue,
      );
      expect(
        File('${dir.path}${Platform.pathSeparator}home.html')
            .readAsStringSync(),
        contains('lama'),
      );
      final loaded = store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'legacy-1');
      expect(loaded.single.pages, hasLength(2));
    });

    test('folder yang sudah punya manifest tidak pernah ditimpa dari Hive', () {
      storage.writeProjectJson(
        'legacy-1',
        jsonEncode(_project('legacy-1').toJson()),
      );
      migrator.migrateHiveProjects();

      // Simulasi folder yang lebih baru (mis. pengguna sudah menyimpan lagi).
      final manifestPath =
          '${store.folderFor('legacy-1').path}'
          '${Platform.pathSeparator}manifest.json';
      final manifest = jsonDecode(
        File(manifestPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      manifest['title'] = 'SUDAH BARU';
      File(manifestPath).writeAsStringSync(jsonEncode(manifest));

      // Hive sekarang berbeda — migrasi ulang harus membiarkan folder.
      storage.writeProjectJson(
        'legacy-1',
        jsonEncode(_project('legacy-1', title: 'PROYEK LAMA BEDA').toJson()),
      );
      migrator.migrateHiveProjects();

      final raw = File(manifestPath).readAsStringSync();
      expect(raw, contains('SUDAH BARU'));
      expect(raw, isNot(contains('PROYEK LAMA BEDA')));
    });

    test('entri Hive dipertahankan sebagai cadangan migrasi', () {
      storage.writeProjectJson(
        'legacy-1',
        jsonEncode(_project('legacy-1').toJson()),
      );

      migrator.migrateHiveProjects();

      expect(storage.readAllProjectsJson(), hasLength(1));
      // Entri masih proyek Hive asli (bukan hasil mutasi migrator).
      final json = jsonDecode(
        storage.readAllProjectsJson().single,
      ) as Map<String, dynamic>;
      expect(json['title'], 'Proyek lama');
    });
  });
}
