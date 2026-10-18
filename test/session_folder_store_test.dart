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
  });
}
