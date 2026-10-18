import 'dart:convert';
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

  group('save', () {
    Project project({
      List<ProjectPage> pages = const [],
      String? activePageId,
    }) {
      return Project(
        id: 'sess-1',
        title: 'Toko Online',
        messages: [
          const ProjectMessage(
            role: 'user',
            text: 'Buat prototype toko',
            kind: 'chat',
          ),
        ],
        pages: pages.isEmpty
            ? const [
                ProjectPage(
                  id: 'page_1',
                  name: 'Home',
                  slug: 'home.html',
                  html: '<html><body>beranda</body></html>',
                ),
                ProjectPage(
                  id: 'page_2',
                  name: 'Cart',
                  slug: 'cart.html',
                  html: '<html><body>keranjang</body></html>',
                ),
              ]
            : pages,
        activePageId: activePageId ?? 'page_2',
        createdAt: DateTime(2026, 10, 18, 9),
        updatedAt: DateTime(2026, 10, 18, 10),
      );
    }

    String manifestPath() =>
        '${temp.path}${Platform.pathSeparator}sess-1'
        '${Platform.pathSeparator}manifest.json';

    test('writes manifest.json and one html file per page', () {
      store.save(project());

      final manifest = File(manifestPath());
      expect(manifest.existsSync(), isTrue);
      final json =
          jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
      expect(json['schemaVersion'], 1);
      expect(json['id'], 'sess-1');
      expect(json['title'], 'Toko Online');
      expect(json['activePageId'], 'page_2');
      final messages = json['messages'] as List<dynamic>;
      expect(
        (messages.first as Map<String, dynamic>)['text'],
        'Buat prototype toko',
      );
      final pages = json['pages'] as List<dynamic>;
      expect(pages, hasLength(2));
      expect((pages.first as Map<String, dynamic>)['file'], 'home.html');
      expect((pages.last as Map<String, dynamic>)['slug'], 'cart.html');

      // Manifest hanya metadata — konten halaman ada di file HTML.
      expect(manifest.readAsStringSync(), isNot(contains('"html"')));

      final base = store.folderFor('sess-1').path;
      final home = File('$base${Platform.pathSeparator}home.html');
      final cart = File('$base${Platform.pathSeparator}cart.html');
      expect(home.existsSync(), isTrue);
      expect(home.readAsStringSync(), contains('beranda'));
      expect(cart.existsSync(), isTrue);
      expect(cart.readAsStringSync(), contains('keranjang'));
    });

    test('case-insensitive slug collisions get sequenced file names', () {
      final p = project(
        pages: const [
          ProjectPage(id: 'page_1', name: 'Home', slug: 'Home.html', html: 'a'),
          ProjectPage(
            id: 'page_2',
            name: 'Home dup',
            slug: 'home.html',
            html: 'b',
          ),
        ],
      );
      store.save(p);

      final dir = store.folderFor('sess-1');
      expect(
        File('${dir.path}${Platform.pathSeparator}home.html').existsSync(),
        isTrue,
      );
      expect(
        File('${dir.path}${Platform.pathSeparator}home-2.html').existsSync(),
        isTrue,
      );
      final manifest = jsonDecode(
        File(manifestPath()).readAsStringSync(),
      ) as Map<String, dynamic>;
      final files = (manifest['pages'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['file'])
          .toList();
      expect(files, containsAll(['home.html', 'home-2.html']));
    });

    test('windows-reserved slug is written with a safe name', () {
      final p = project(
        pages: const [
          ProjectPage(
            id: 'page_1',
            name: 'Console',
            slug: 'con.html',
            html: 'c',
          ),
        ],
      );
      store.save(p);

      final dir = store.folderFor('sess-1');
      // reserved: con tidak boleh jadi nama file biasa
      expect(
        File('${dir.path}${Platform.pathSeparator}con.html').existsSync(),
        isFalse,
      );
      final safe = dir.listSync().whereType<File>().map(
        (f) => f.uri.pathSegments.last.toLowerCase(),
      );
      expect(safe, contains(endsWith('.html')));
    });

    test('save menghapus file html halaman yang sudah dihapus (orphan)', () {
      store.save(project()); // 2 halaman: home.html + cart.html
      final dir = store.folderFor('sess-1');
      expect(
        File('${dir.path}${Platform.pathSeparator}cart.html').existsSync(),
        isTrue,
      );

      // Halaman Cart dihapus — simpan ulang, file-nya tidak boleh tertinggal.
      store.save(
        project(
          pages: const [
            ProjectPage(
              id: 'page_1',
              name: 'Home',
              slug: 'home.html',
              html: 'a',
            ),
          ],
        ),
      );

      expect(
        File('${dir.path}${Platform.pathSeparator}cart.html').existsSync(),
        isFalse,
      );
      expect(
        File('${dir.path}${Platform.pathSeparator}home.html').existsSync(),
        isTrue,
      );
      final manifest = jsonDecode(
        File(manifestPath()).readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(manifest['pages'] as List<dynamic>, hasLength(1));
    });
  });

  group('load', () {
    /// Save proyek standar (2 halaman) lalu kembalikan hasil `loadAll`.
    List<Project> savedAndLoaded() {
      final saved = Project(
        id: 'sess-1',
        title: 'Toko Online',
        messages: [
          const ProjectMessage(
            role: 'user',
            text: 'Buat prototype toko',
            kind: 'chat',
          ),
        ],
        pages: const [
          ProjectPage(
            id: 'page_1',
            name: 'Home',
            slug: 'home.html',
            html: '<html><body>beranda</body></html>',
          ),
          ProjectPage(
            id: 'page_2',
            name: 'Cart',
            slug: 'cart.html',
            html: '<html><body>keranjang</body></html>',
          ),
        ],
        activePageId: 'page_2',
        createdAt: DateTime(2026, 10, 18, 9),
        updatedAt: DateTime(2026, 10, 18, 10),
      );
      store.save(saved);
      return store.loadAll();
    }

    test('roundtrip: metadata, pesan, dan HTML per halaman sama', () {
      final loaded = savedAndLoaded();
      expect(loaded, hasLength(1));
      final p = loaded.single;
      expect(p.id, 'sess-1');
      expect(p.title, 'Toko Online');
      expect(p.activePageId, 'page_2');
      expect(p.messages.single.text, 'Buat prototype toko');
      expect(p.pages, hasLength(2));
      expect(p.pages[0].slug, 'home.html');
      expect(p.pages[0].html, contains('beranda'));
      expect(p.pages[1].slug, 'cart.html');
      expect(p.pages[1].html, contains('keranjang'));
    });

    test('load: proyek ada -> Project; tidak ada -> null', () {
      savedAndLoaded();
      expect(store.load('sess-1')?.id, 'sess-1');
      expect(store.load('nope'), isNull);
    });

    test('folder tanpa manifest.json dilewati tanpa melempar', () {
      savedAndLoaded();
      // Folder sesi lain "rusak"/kosong: tanpa manifest.
      Directory(
        '${temp.path}${Platform.pathSeparator}broken'
        '${Platform.pathSeparator}',
      ).createSync(recursive: true);

      final loaded = store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'sess-1');
    });

    test(
      'manifest menyebut file hilang -> halaman terbaca dengan html kosong',
      () {
        savedAndLoaded();
        // User menghapus satu file HTML langsung di disk.
        File(
          '${store.folderFor('sess-1').path}'
          '${Platform.pathSeparator}cart.html',
        ).deleteSync();

        final p = store.load('sess-1')!;
        expect(p.pages[1].slug, 'cart.html');
        expect(p.pages[1].html, isEmpty);
      },
    );

    test('loadAll urut updatedAt terbaru dulu', () {
      store.save(
        Project(
          id: 'old',
          title: 'Lama',
          messages: const [],
          pages: const [
            ProjectPage(id: 'page_1', name: 'A', slug: 'a.html', html: 'a'),
          ],
          activePageId: 'page_1',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        ),
      );
      store.save(
        Project(
          id: 'new',
          title: 'Baru',
          messages: const [],
          pages: const [
            ProjectPage(id: 'page_1', name: 'B', slug: 'b.html', html: 'b'),
          ],
          activePageId: 'page_1',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 18),
        ),
      );

      final ids = store.loadAll().map((p) => p.id).toList();
      expect(ids, ['new', 'old']);
    });
  });
}
