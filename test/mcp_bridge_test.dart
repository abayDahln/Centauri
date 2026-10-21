import 'dart:io';

import 'package:centauri/features/canvas_preview/presentation/provider/workspace_provider.dart';
import 'package:centauri/features/history/data/project_repository.dart';
import 'package:centauri/features/history/data/session_folder_store.dart';
import 'package:centauri/features/history/domain/project.dart';
import 'package:centauri/features/history/presentation/history_provider.dart';
import 'package:centauri/features/mcp/data/mcp_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository folder-sesi murni (tanpa Hive) untuk pengujian bridge MCP.
class _TempRepo extends ProjectRepository {
  _TempRepo(this._store) : super(sessions: _store);

  final SessionFolderStore _store;
  String? _activeId;

  @override
  List<Project> getAll() => _store.loadAll();

  @override
  Project? loadSession(String id) => _store.load(id);

  @override
  bool get isPersisting => true;

  @override
  void save(Project project) => _store.save(project);

  @override
  Future<void> delete(String id) async => _store.delete(id);

  @override
  String? get activeProjectId => _activeId;

  @override
  Future<void> setActiveProjectId(String id) async => _activeId = id;

  @override
  Future<void> clearActiveProjectId() async => _activeId = null;
}

void main() {
  group('McpBridge level sesi (Fase 5)', () {
    late Directory dir;
    late SessionFolderStore store;
    late _TempRepo repo;
    late ProviderContainer container;
    late McpBridge bridge;
    final now = DateTime(2026, 10, 20);

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('mcp_bridge_test');
      store = SessionFolderStore(dir);
      repo = _TempRepo(store);
      store.save(
        Project(
          id: 's1',
          title: 'Sesi uji',
          messages: [
            const ProjectMessage(role: 'user', text: 'hai', kind: 'chat'),
            const ProjectMessage(role: 'assistant', text: 'halo', kind: 'chat'),
          ],
          pages: [
            const ProjectPage(
              id: 'p1',
              name: 'Home',
              slug: 'home.html',
              html: '<html><body><h1>Asli</h1></body></html>',
            ),
          ],
          activePageId: 'p1',
          createdAt: now,
          updatedAt: now,
        ),
      );
      container = ProviderContainer(
        overrides: [projectRepositoryProvider.overrideWithValue(repo)],
      );
      bridge = McpBridge(container);
      // Buka sesi uji di "board" agar jalur sesi-aktif ikut terlindungi.
      await container.read(historyProvider.notifier).open('s1');
    });

    tearDown(() {
      container.dispose();
      dir.deleteSync(recursive: true);
    });

    test('list_sessions hanya metadata, tanpa html maupun teks pesan', () {
      final result = bridge.listSessions();
      final session = (result['sessions'] as List<Map<String, dynamic>>).single;
      expect(
        session.keys,
        unorderedEquals([
          'id',
          'title',
          'createdAt',
          'updatedAt',
          'messageCount',
          'pageCount',
          'activePageId',
          'isActive',
        ]),
      );
      expect(session['isActive'], true);
    });

    test('get_session memotong teks panjang dan mempaginate pesan', () {
      final long = 'x' * 2000;
      repo.save(
        store
            .load('s1')!
            .copyWith(
              messages: [
                const ProjectMessage(role: 'user', text: 'hai', kind: 'chat'),
                ProjectMessage(role: 'assistant', text: long, kind: 'ui'),
              ],
            ),
      );
      final result = bridge.getSession('s1', limit: 1);
      expect(result['messageTotal'], 2);
      expect(result['nextOffset'], 1);
      expect((result['messages'] as List).length, 1);
      final second = bridge.getSession('s1', limit: 1, offset: 1);
      final text =
          ((second['messages'] as List).first as Map)['text'] as String;
      expect(text.length, lessThanOrEqualTo(801));
      expect(second['nextOffset'], null);
      expect((second['pages'] as List).length, 1);
    });

    test(
      'write_page mengganti halaman sesi aktif: file + workspace naik',
      () async {
        final result = await bridge.writePage(
          sessionId: 's1',
          pageId: 'p1',
          html: '<html><body><h1>Revisi</h1></body></html>',
        );
        expect(result['created'], false);
        final page = container
            .read(workspaceProvider)
            .pages
            .firstWhere((p) => p.id == 'p1');
        expect(page.html, contains('Revisi'));
        expect(page.html, contains('data-centauri-id'));
        expect(store.load('s1')!.pages.single.html, contains('Revisi'));
      },
    );

    test(
      'write_page membuat halaman baru dan langsung menampilkannya',
      () async {
        final result = await bridge.writePage(
          sessionId: 's1',
          name: 'Kontak',
          html: '<html><body><h1>Kontak</h1></body></html>',
        );
        expect(result['created'], true);
        expect(result['slug'], 'kontak.html');
        final state = container.read(workspaceProvider);
        expect(state.pages.length, 2);
        expect(state.activePageId, result['pageId']);
        expect(store.load('s1')!.pages.length, 2);
      },
    );

    test('delete_page menghapus dari file dan workspace', () {
      final result = bridge.deletePage('s1', 'p1');
      expect(result['ok'], true);
      expect(store.load('s1')!.pages, isEmpty);
      expect(container.read(workspaceProvider).pages, isEmpty);
      expect(container.read(workspaceProvider).activePageId, null);
    });

    test('post_to_chat menambah pesan assistant live di workspace', () {
      final before = container.read(workspaceProvider).messages.length;
      final result = bridge.postToChat('s1', 'Desain sudah diperbarui.');
      expect(result['ok'], true);
      final messages = container.read(workspaceProvider).messages;
      expect(messages.length, before + 1);
      final last = messages.last;
      expect(last.role, ChatRole.assistant);
      expect(last.shownText, 'Desain sudah diperbarui.');
      final saved = store.load('s1')!.messages.last;
      expect(saved.role, 'assistant');
      expect(saved.kind, 'chat');
    });

    test(
      'mutasi sesi non-aktif mengubah file tanpa menyentuh workspace',
      () async {
        container.read(historyProvider.notifier).startNew();
        expect(container.read(workspaceProvider).pages, isEmpty);
        final result = await bridge.writePage(
          sessionId: 's1',
          name: 'Tentang',
          html: '<html><body><h1>Tentang</h1></body></html>',
        );
        expect(result['ok'], true);
        expect(store.load('s1')!.pages.length, 2);
        // Workspace (sesi baru yang kosong) tidak boleh ikut berubah.
        expect(container.read(workspaceProvider).pages, isEmpty);
        expect(container.read(historyProvider).projects.length, 1);
      },
    );

    test('id/pageId tak dikenal melempar McpException -32602', () {
      expect(
        () => bridge.deletePage('nope', 'p1'),
        throwsA(isA<McpException>().having((e) => e.code, 'code', -32602)),
      );
      expect(
        () => bridge.getPageHtml('s1', 'nope'),
        throwsA(isA<McpException>().having((e) => e.code, 'code', -32602)),
      );
    });
  });
}
