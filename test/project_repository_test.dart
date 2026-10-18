import 'dart:io';

import 'package:centauri/core/storage/local_storage_service.dart';
import 'package:centauri/features/history/data/project_repository.dart';
import 'package:centauri/features/history/data/session_folder_store.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

Project _project(String id, {String title = 'Sesi uji'}) => Project(
  id: id,
  title: title,
  messages: const [ProjectMessage(role: 'user', text: 'halo', kind: 'chat')],
  pages: const [
    ProjectPage(id: 'page_1', name: 'Home', slug: 'home.html', html: 'x'),
  ],
  activePageId: 'page_1',
  createdAt: DateTime(2026, 10, 18),
  updatedAt: DateTime(2026, 10, 18),
);

void main() {
  late Directory tempRoot;
  late SessionFolderStore store;
  late LocalStorageService storage;
  late ProjectRepository repo;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('centauri_repo_test_');
    store = SessionFolderStore(tempRoot);
    storage = LocalStorageService();
    await storage.init(path: '${tempRoot.path}${Platform.pathSeparator}hive');
    repo = ProjectRepository(storage: storage, sessions: store);
  });

  tearDown(() async {
    // Tutup box Hive agar file di temp tidak terkunci saat dihapus.
    await Hive.close();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  group('ProjectRepository delegasi ke folder sesi', () {
    test('save lalu getAll membaca dari folder (sumber kebenaran disk)', () {
      repo.save(_project('p1'));

      // Buktikan sumbernya folder: manifest nyata di disk.
      expect(
        File(
          '${store.folderFor('p1').path}'
          '${Platform.pathSeparator}manifest.json',
        ).existsSync(),
        isTrue,
      );

      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'p1');
      expect(all.single.title, 'Sesi uji');
      expect(all.single.pages.single.html, 'x');
    });

    test('delete menghapus folder di disk dan kosongkan daftar', () {
      repo.save(_project('p1'));
      expect(store.folderFor('p1').existsSync(), isTrue);

      repo.delete('p1');

      expect(store.folderFor('p1').existsSync(), isFalse);
      expect(repo.getAll(), isEmpty);
    });

    test(
      'root sesi tidak tersedia -> penyimpanan nonaktif, bukan lokasi lain',
      () {
        // Simulasi root gagal di-resolve saat init.
        storage.debugSetSessionsRoot(null);
        final degraded = ProjectRepository(storage: storage);

        expect(degraded.isPersisting, isFalse);
        expect(degraded.getAll(), isEmpty);
        // Tidak melempar dan tidak menulis ke temp/manapun.
        expect(() => degraded.save(_project('p1')), returnsNormally);
        expect(
          store.folderFor('p1').existsSync(),
          isFalse,
          reason: 'harus tidak menulis ke folder sesi yang tersedia',
        );
        expect(() => degraded.delete('p1'), returnsNormally);
      },
    );
  });
}
