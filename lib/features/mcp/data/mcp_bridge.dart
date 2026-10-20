import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../canvas_preview/domain/dom_tree.dart';
import '../../canvas_preview/domain/page.dart';
import '../../canvas_preview/domain/page_slug.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';
import '../../history/data/project_repository.dart';
import '../../history/domain/project.dart';
import '../../history/presentation/history_provider.dart';

class McpException implements Exception {
  McpException(this.message, {this.code = -32603});
  final String message;
  final int code;

  @override
  String toString() => message;
}

/// Jembatan antara MCP server dan state aplikasi (level sesi, bukan node).
///
/// Baca hemat token: listing hanya metadata sesi, detail per halaman diminta
/// terpisah. Tulis: folder sesi (`ProjectRepository`) selalu sumber kebenaran;
/// bila sesi terdampak sedang aktif di board, perubahan juga didorong ke
/// [workspaceProvider] agar WebView/chat/history naik tanpa refresh aplikasi.
/// Urutan tiap mutasi: simpan file → sinkron workspace (bila aktif) →
/// refresh daftar riwayat. Auto-save debounce men-snapshot workspace yang
/// sudah memuat perubahan, jadi tidak ada penimpaan basi.
class McpBridge {
  McpBridge(this._container);

  final ProviderContainer _container;

  /// Batas panjang teks pesan pada respons `get_session` — pesan `ui`
  /// memuat HTML penuh dan akan memboroskan token agen.
  static const int _messageTextLimit = 800;

  WorkspaceState get _state => _container.read(workspaceProvider);
  WorkspaceNotifier get _notifier =>
      _container.read(workspaceProvider.notifier);
  ProjectRepository get _repo => _container.read(projectRepositoryProvider);

  bool _isActiveSession(String sessionId) =>
      _container.read(historyProvider).activeProjectId == sessionId;

  Project _loadSession(String sessionId) {
    final project = _repo.loadSession(sessionId);
    if (project == null) {
      if (!_repo.isPersisting) {
        throw McpException(
          'Penyimpanan sesi tidak tersedia di perangkat ini.',
          code: -32603,
        );
      }
      throw McpException('Sesi "$sessionId" tidak ditemukan.', code: -32602);
    }
    return project;
  }

  ProjectPage _findPage(Project project, String pageId) {
    for (final p in project.pages) {
      if (p.id == pageId) return p;
    }
    throw McpException(
      'Halaman "$pageId" tidak ditemukan di sesi "${project.id}".',
      code: -32602,
    );
  }

  void _refreshHistoryList() =>
      _container.read(historyProvider.notifier).refresh();

  // ---------------------------------------------------------------- baca --

  Map<String, dynamic> snapshot() {
    final state = _state;
    return {
      'activeSessionId': _container.read(historyProvider).activeProjectId,
      'pages': [
        for (final p in state.pages)
          {
            'id': p.id,
            'name': p.name,
            'slug': p.slug,
            'nodeCount': p.domTree?.nodeCount ?? 0,
          },
      ],
      'activePageId': state.activePageId,
      'selectedNodeId': state.selectedNodeId,
    };
  }

  /// Daftar sesi hanya dengan metadata — tanpa isi chat maupun HTML.
  Map<String, dynamic> listSessions() {
    final activeId = _container.read(historyProvider).activeProjectId;
    return {
      'ok': true,
      'sessions': [
        for (final p in _repo.getAll())
          {
            'id': p.id,
            'title': p.title,
            'createdAt': p.createdAt.toIso8601String(),
            'updatedAt': p.updatedAt.toIso8601String(),
            'messageCount': p.messages.length,
            'pageCount': p.pages.length,
            'activePageId': p.activePageId,
            'isActive': p.id == activeId,
          },
      ],
    };
  }

  /// Detail satu sesi: pesan (ter-paginate + ter-truncate) dan indeks
  /// halaman tanpa html — ambil konten per halaman via [getPageHtml].
  Map<String, dynamic> getSession(
    String sessionId, {
    int limit = 50,
    int offset = 0,
  }) {
    final project = _loadSession(sessionId);
    final total = project.messages.length;
    final start = offset.clamp(0, total);
    final end = (start + limit).clamp(0, total);
    return {
      'ok': true,
      'session': {
        'id': project.id,
        'title': project.title,
        'createdAt': project.createdAt.toIso8601String(),
        'updatedAt': project.updatedAt.toIso8601String(),
        'activePageId': project.activePageId,
      },
      'messages': [
        for (final m in project.messages.sublist(start, end))
          {
            'role': m.role,
            'kind': m.kind,
            'text': _clip(m.displayText ?? m.text),
          },
      ],
      'messageTotal': total,
      'nextOffset': end < total ? end : null,
      'pages': [
        for (final p in project.pages)
          {'id': p.id, 'name': p.name, 'slug': p.slug},
      ],
    };
  }

  static String _clip(String text) => text.length > _messageTextLimit
      ? '${text.substring(0, _messageTextLimit)}…'
      : text;

  Map<String, dynamic> getPageHtml(String sessionId, String pageId) {
    final project = _loadSession(sessionId);
    final page = _findPage(project, pageId);
    return {
      'ok': true,
      'pageId': page.id,
      'name': page.name,
      'slug': page.slug,
      'html': page.html,
    };
  }

  // --------------------------------------------------------------- tulis --

  /// Buat halaman baru (perlu [name]) atau ganti HTML halaman [pageId] pada
  /// sesi mana pun. HTML di-stamp agar id node konsisten dengan app.
  Future<Map<String, dynamic>> writePage({
    required String sessionId,
    String? pageId,
    String? name,
    required String html,
  }) async {
    if (html.trim().isEmpty || !html.contains('<')) {
      throw McpException('"html" harus dokumen HTML yang valid.', code: -32602);
    }
    final cleanedName = name?.trim() ?? '';
    if (pageId == null && cleanedName.isEmpty) {
      throw McpException(
        'Sertakan "pageId" (ganti halaman) atau "name" (halaman baru).',
        code: -32602,
      );
    }
    final project = _loadSession(sessionId);
    final tree = await buildDomTreeInIsolate(html);

    ProjectPage page;
    final created = pageId == null;
    if (!created) {
      final existing = _findPage(project, pageId);
      page = ProjectPage(
        id: existing.id,
        name: cleanedName.isEmpty ? existing.name : cleanedName,
        slug: existing.slug,
        html: tree.stampedHtml,
      );
    } else {
      page = ProjectPage(
        id: const Uuid().v4(),
        name: cleanedName,
        slug: uniqueSlug(
          slugify(cleanedName),
          project.pages.map((p) => p.slug),
        ),
        html: tree.stampedHtml,
      );
    }

    final pages = <ProjectPage>[
      for (final p in project.pages)
        if (p.id == page.id) page else p,
      if (created) page,
    ];
    _repo.save(project.copyWith(pages: pages, updatedAt: DateTime.now()));

    if (_isActiveSession(sessionId)) {
      final appPage = AppPage(
        id: page.id,
        name: page.name,
        slug: page.slug,
        html: tree.stampedHtml,
        domTree: tree,
      );
      if (created) {
        _notifier.upsertExternalPage(page: appPage, makeActive: true);
      } else {
        _notifier.updatePageHtml(
          pageId: page.id,
          stampedHtml: tree.stampedHtml,
          tree: tree,
        );
      }
    }
    _refreshHistoryList();
    return {
      'ok': true,
      'pageId': page.id,
      'slug': page.slug,
      'created': created,
    };
  }

  Map<String, dynamic> deletePage(String sessionId, String pageId) {
    final project = _loadSession(sessionId);
    final page = _findPage(project, pageId);
    final remaining = project.pages.where((p) => p.id != pageId).toList();
    var activePageId = project.activePageId;
    if (activePageId == pageId) {
      activePageId = remaining.isEmpty ? null : remaining.first.id;
    }
    _repo.save(
      project.copyWith(
        pages: remaining,
        activePageId: activePageId,
        clearActivePage: activePageId == null,
        updatedAt: DateTime.now(),
      ),
    );
    if (_isActiveSession(sessionId)) {
      _notifier.deletePage(pageId);
    }
    _refreshHistoryList();
    return {
      'ok': true,
      'pageId': pageId,
      'name': page.name,
      'activePageId': activePageId,
    };
  }

  /// Kirim teks agen ke chat sesi — tampil sebagai pesan assistant biasa.
  Map<String, dynamic> postToChat(String sessionId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw McpException('"text" tidak boleh kosong.', code: -32602);
    }
    final project = _loadSession(sessionId);
    final messages = [
      ...project.messages,
      ProjectMessage(role: 'assistant', text: trimmed, kind: 'chat'),
    ];
    _repo.save(project.copyWith(messages: messages, updatedAt: DateTime.now()));
    if (_isActiveSession(sessionId)) {
      _notifier.appendExternalMessage(
        CanvasMessage(
          role: ChatRole.assistant,
          kind: ChatMessageKind.chat,
          text: trimmed,
        ),
      );
    }
    _refreshHistoryList();
    return {'ok': true, 'messageCount': messages.length};
  }
}
