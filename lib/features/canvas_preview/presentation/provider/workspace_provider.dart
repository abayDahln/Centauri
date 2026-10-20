import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/error_messages.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../core/errors/app_error.dart';
import '../../../prompt_editor/domain/ai_response.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../../provider_config/data/datasources/ai_api_service.dart';
import '../../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../data/services/canvas_service_registry.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../domain/dom_tree.dart';
import '../../domain/page.dart';
import '../../domain/page_slug.dart';
import '../../domain/prompt_mention.dart';

enum ChatRole { user, assistant, error }

/// Mode tampilan area kerja.
enum OutputMode { design, dev }

class CanvasMessage {
  const CanvasMessage({
    required this.role,
    required this.text,
    this.displayText,
    this.kind = ChatMessageKind.chat,
    this.attachmentNames = const [],
    this.attachments = const [],
  });

  final ChatRole role;
  final String text;

  /// Teks yang ditampilkan di UI. Bila null, pakai [text].
  /// Dipakai agar konteks internal yang di-append ke prompt tidak bocor ke
  /// bubble chat user.
  final String? displayText;

  /// Teks bersih untuk ditampilkan ke pengguna.
  String get shownText => displayText ?? text;

  final ChatMessageKind kind;

  /// Nama lampiran yang menyertai pesan ini (dipakai untuk persistensi).
  final List<String> attachmentNames;

  /// Lampiran lengkap (in-memory) agar bisa ditampilkan & dipratinjau di chat.
  final List<Attachment> attachments;
}

enum ChatMessageKind { chat, ui }

/// Status proses AI yang ditampilkan live ke pengguna.
///
/// Label yang terlihat pengguna tidak disimpan di sini — widget status yang
/// menerjemahkannya lewat l10n, supaya enum ini murni state.
enum AiStatus { idle, thinking, responding, rendering, done }

/// State workspace: daftar halaman hasil generate + seleksi/percakapan.
/// Tidak ada lagi board/pan/zoom — preview menampilkan satu halaman penuh.
class WorkspaceState {
  const WorkspaceState({
    this.pages = const [],
    this.activePageId,
    this.messages = const [],
    this.isGenerating = false,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.selectedNodeGeometry,
    this.outputMode = OutputMode.design,
    this.generationStartedAt,
    this.status = AiStatus.idle,
    this.attachments = const [],
    this.selectionMode = false,
    this.mentions = const [],
  });

  /// Semua halaman (urut kronologis).
  final List<AppPage> pages;

  /// Halaman aktif (yang ditampilkan di preview).
  final String? activePageId;

  final List<CanvasMessage> messages;
  final bool isGenerating;
  final String? selectedNodeId;
  final String? hoveredNodeId;

  /// Cache tampilan untuk overlay native (bbox CSS + computed style).
  /// HTML di WebView tetap source of truth.
  final NodeGeometry? selectedNodeGeometry;
  final OutputMode outputMode;
  final DateTime? generationStartedAt;

  /// Status proses AI saat ini (untuk indikator live).
  final AiStatus status;

  /// Lampiran yang menunggu dikirim bersama prompt berikutnya.
  final List<Attachment> attachments;

  /// Mode seleksi elemen. Default false: preview bisa dipakai langsung
  /// (klik tombol, isi input, hover) seperti halaman biasa.
  final bool selectionMode;

  /// Mention yang menempel di prompt berikutnya (elemen / halaman).
  final List<PromptMention> mentions;

  AppPage? get activePage {
    if (activePageId == null) return null;
    for (final page in pages) {
      if (page.id == activePageId) return page;
    }
    return null;
  }

  /// HTML halaman aktif (dipakai code panel & seleksi).
  String? get activeHtml => activePage?.html;

  bool get hasPages => pages.isNotEmpty;

  /// True bila ada halaman yang bisa ditampilkan.
  bool get hasRenderedPage => pages.any((p) => p.html.isNotEmpty);

  WorkspaceState copyWith({
    List<AppPage>? pages,
    String? activePageId,
    bool clearActivePage = false,
    List<CanvasMessage>? messages,
    bool? isGenerating,
    String? selectedNodeId,
    bool clearSelection = false,
    String? hoveredNodeId,
    bool clearHover = false,
    NodeGeometry? selectedNodeGeometry,
    bool clearGeometry = false,
    OutputMode? outputMode,
    DateTime? generationStartedAt,
    bool clearGenerationStart = false,
    AiStatus? status,
    List<Attachment>? attachments,
    bool? selectionMode,
    List<PromptMention>? mentions,
  }) {
    return WorkspaceState(
      pages: pages ?? this.pages,
      activePageId: clearActivePage
          ? null
          : (activePageId ?? this.activePageId),
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      selectedNodeId: clearSelection
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      hoveredNodeId: clearHover ? null : (hoveredNodeId ?? this.hoveredNodeId),
      selectedNodeGeometry: clearGeometry
          ? null
          : (selectedNodeGeometry ?? this.selectedNodeGeometry),
      outputMode: outputMode ?? this.outputMode,
      generationStartedAt: clearGenerationStart
          ? null
          : (generationStartedAt ?? this.generationStartedAt),
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      selectionMode: selectionMode ?? this.selectionMode,
      mentions: mentions ?? this.mentions,
    );
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);

/// Snapshot immutable untuk undo/redo.
@immutable
class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.pages,
    required this.messages,
    required this.activePageId,
  });

  final List<AppPage> pages;
  final List<CanvasMessage> messages;
  final String? activePageId;

  static WorkspaceSnapshot of(WorkspaceState state) => WorkspaceSnapshot(
    pages: state.pages,
    messages: state.messages,
    activePageId: state.activePageId,
  );

  bool contentEquals(WorkspaceSnapshot other) =>
      identical(pages, other.pages) &&
      identical(messages, other.messages) &&
      activePageId == other.activePageId;
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  int _pageCounter = 0;

  // ------------------------------------------------------- undo / redo --
  static const int _historyLimit = 60;
  final List<WorkspaceSnapshot> _undoStack = [];
  final List<WorkspaceSnapshot> _redoStack = [];
  WorkspaceSnapshot? _lastRecorded;
  bool _applyingHistory = false;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoDepth => _undoStack.length;
  int get redoDepth => _redoStack.length;

  @override
  WorkspaceState build() {
    _lastRecorded = null;
    return const WorkspaceState();
  }

  /// Dorong snapshot SEBELUM perubahan ([previous]) ke stack undo bila
  /// kontennya berbeda dari snapshot terakhir yang tercatat.
  void recordHistory(WorkspaceState previous) {
    if (_applyingHistory) return;
    final snapshot = WorkspaceSnapshot.of(previous);
    if (_lastRecorded != null && _lastRecorded!.contentEquals(snapshot)) {
      _lastRecorded = WorkspaceSnapshot.of(state);
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    _redoStack.clear();
    _lastRecorded = WorkspaceSnapshot.of(state);
  }

  void pushUndoSnapshot() {
    final snapshot = WorkspaceSnapshot.of(state);
    if (_lastRecorded != null && _lastRecorded!.contentEquals(snapshot)) {
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    _redoStack.clear();
    _lastRecorded = snapshot;
  }

  bool undo() {
    if (_undoStack.isEmpty) return false;
    final target = _undoStack.removeLast();
    _redoStack.add(WorkspaceSnapshot.of(state));
    _applySnapshot(target);
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    final target = _redoStack.removeLast();
    _undoStack.add(WorkspaceSnapshot.of(state));
    _applySnapshot(target);
    return true;
  }

  void _applySnapshot(WorkspaceSnapshot snapshot) {
    _applyingHistory = true;
    state = state.copyWith(
      pages: snapshot.pages,
      messages: snapshot.messages,
      activePageId: snapshot.activePageId,
      clearActivePage: snapshot.activePageId == null,
      clearSelection: true,
      clearGeometry: true,
    );
    _lastRecorded = snapshot;
    _applyingHistory = false;
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _lastRecorded = WorkspaceSnapshot.of(state);
  }

  void setOutputMode(OutputMode mode) {
    if (mode == state.outputMode) return;
    state = state.copyWith(outputMode: mode);
  }

  /// Nyalakan/matikan mode seleksi elemen. Saat dimatikan, seleksi dibuang
  void toggleSelectionMode() {
    final next = !state.selectionMode;
    state = state.copyWith(
      selectionMode: next,
      clearSelection: !next,
      clearGeometry: !next,
    );
  }

  /// Mention elemen untuk prompt berikutnya (dari menu "Edit dengan AI").
  void addElementMention({required String nodeId, required String label}) {
    final page = state.activePage;
    final mention = PromptMention(
      kind: PromptMentionKind.element,
      label: label.trim().isEmpty
          ? l10nOf(ref).canvasMentionElementFallback
          : label.trim(),
      nodeId: nodeId,
      pageId: page?.id,
      pageName: page?.name,
    );
    state = state.copyWith(
      mentions: [
        ...state.mentions.where((m) => m.kind != PromptMentionKind.element),
        mention,
      ],
    );
  }

  void addPageMention(AppPage page) {
    if (state.mentions.any(
      (m) => m.kind == PromptMentionKind.page && m.pageId == page.id,
    )) {
      return;
    }
    state = state.copyWith(
      mentions: [
        ...state.mentions,
        PromptMention(
          kind: PromptMentionKind.page,
          label: page.name,
          pageId: page.id,
          pageName: page.name,
        ),
      ],
    );
  }

  void addAllPagesMention() {
    if (state.mentions.any((m) => m.kind == PromptMentionKind.allPages)) {
      return;
    }
    state = state.copyWith(
      mentions: [
        ...state.mentions,
        PromptMention(
          kind: PromptMentionKind.allPages,
          label: l10nOf(ref).commonAllPages,
        ),
      ],
    );
  }

  void removeMention(PromptMention mention) {
    state = state.copyWith(
      mentions: state.mentions.where((m) => m != mention).toList(),
    );
  }

  // ---------------------------------------------------------------- pages --

  void setActivePage(String? id) {
    if (id == state.activePageId) return;
    state = state.copyWith(
      activePageId: id,
      clearActivePage: id == null,
      clearSelection: true,
      clearGeometry: true,
    );
  }

  void deletePage(String id) {
    final pages = state.pages.where((p) => p.id != id).toList();
    String? nextActive = state.activePageId;
    if (nextActive == id) {
      nextActive = pages.isEmpty ? null : pages.first.id;
    }
    state = state.copyWith(
      pages: pages,
      activePageId: nextActive,
      clearActivePage: nextActive == null,
      clearSelection: true,
      clearGeometry: true,
    );
  }

  void renamePage(String id, String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    final pages = state.pages
        .map((p) => p.id == id ? p.copyWith(name: cleaned) : p)
        .toList();
    state = state.copyWith(pages: pages);
  }

  /// Sinkronisasi ulang HTML halaman pasca-mutasi eksternal (MCP bridge).
  /// [stampedHtml] harus sudah melalui `buildDomTreeInIsolate` agar id stabil.
  void updatePageHtml({
    required String pageId,
    required String stampedHtml,
    required DomTreeResult tree,
  }) {
    final pages = state.pages
        .map(
          (p) =>
              p.id == pageId ? p.copyWith(html: stampedHtml, domTree: tree) : p,
        )
        .toList();
    final selectedId = state.selectedNodeId;
    final keepSelection =
        selectedId != null && tree.findById(selectedId) != null;
    state = state.copyWith(
      pages: pages,
      clearSelection: !keepSelection && selectedId != null,
      clearGeometry: true,
    );
  }

  /// Sisipkan/perbarui satu halaman dari sumber eksternal (MCP bridge).
  /// Pencocokan tetap per slug lewat [_upsertPages]; [makeActive] langsung
  /// menampilkannya di preview.
  void upsertExternalPage({required AppPage page, bool makeActive = false}) {
    final merged = _upsertPages(state.pages, [page]);
    final nextActive = makeActive ? merged.firstId : state.activePageId;
    state = state.copyWith(
      pages: merged.pages,
      activePageId: nextActive,
      clearActivePage: nextActive == null,
    );
  }

  /// Tambah pesan chat dari sumber eksternal (MCP bridge) — tampil live di
  /// panel chat seperti pesan assistant biasa.
  void appendExternalMessage(CanvasMessage message) => _appendMessage(message);

  /// Muat ulang halaman & percakapan dari data proyek tersimpan.
  Future<void> loadSession({
    required List<CanvasMessage> messages,
    required List<AppPage> pages,
    String? activePageId,
  }) async {
    final rebuilt = <AppPage>[];
    for (final page in pages) {
      if (page.html.isEmpty) {
        rebuilt.add(page);
        continue;
      }
      try {
        final tree = await buildDomTreeInIsolate(page.html);
        rebuilt.add(page.copyWith(html: tree.stampedHtml, domTree: tree));
      } catch (_) {
        rebuilt.add(page);
      }
    }

    _pageCounter = rebuilt.length;
    for (final page in rebuilt) {
      final match = RegExp(r'page_(\d+)').firstMatch(page.id);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value >= _pageCounter) _pageCounter = value + 1;
    }

    state = WorkspaceState(
      pages: rebuilt,
      activePageId: activePageId,
      messages: messages,
      outputMode: state.outputMode,
      selectionMode: state.selectionMode,
    );
  }

  void clearWorkspace() {
    _pageCounter = 0;
    state = state.copyWith(
      pages: const [],
      messages: const [],
      isGenerating: false,
      clearActivePage: true,
      clearSelection: true,
      clearHover: true,
      clearGenerationStart: true,
    );
  }

  /// Konteks node terpilih untuk inline edit.
  String _selectedNodeContext() {
    final nodeId = state.selectedNodeId;
    final geometry = state.selectedNodeGeometry;
    final page = state.activePage;
    if (nodeId == null || geometry == null || page == null) return '';
    return buildSelectedNodeContext(geometry: geometry, pageName: page.name);
  }

  // ---------------------------------------------------------- attachments --

  /// Tambah lampiran (abaikan duplikat berdasarkan nama + ukuran).
  /// Mengembalikan pesan error bila kuota/ukuran tidak valid, null bila sukses.
  String? addAttachment(Attachment attachment) {
    final duplicate = state.attachments.any(
      (a) => a.name == attachment.name && a.sizeBytes == attachment.sizeBytes,
    );
    if (duplicate) return null;
    if (state.attachments.length >= 6) {
      return l10nOf(ref).promptAttachmentLimit;
    }
    state = state.copyWith(attachments: [...state.attachments, attachment]);
    return null;
  }

  void removeAttachment(String id) {
    state = state.copyWith(
      attachments: state.attachments.where((a) => a.id != id).toList(),
    );
  }

  void clearAttachments() {
    if (state.attachments.isEmpty) return;
    state = state.copyWith(attachments: const []);
  }

  void selectNode(String? id) {
    if (id == null) {
      if (state.selectedNodeId == null) return;
      state = state.copyWith(clearSelection: true, clearGeometry: true);
      return;
    }
    if (id == state.selectedNodeId) return;
    state = state.copyWith(selectedNodeId: id, clearGeometry: true);
  }

  void selectNodeFromCanvas(String? id) => selectNode(id);

  /// Update cache geometri dari event `geometry` JS bridge.
  void updateNodeGeometry(NodeGeometry geometry) {
    if (state.selectedNodeId != geometry.id) return;
    state = state.copyWith(selectedNodeGeometry: geometry);
  }

  void hoverNode(String? id) {
    if (id == null) {
      if (state.hoveredNodeId == null) return;
      state = state.copyWith(clearHover: true);
      return;
    }
    if (id == state.hoveredNodeId) return;
    state = state.copyWith(hoveredNodeId: id);
  }

  /// Hapus satu node di halaman aktif lewat WebView, lalu sinkronkan HTML.
  /// Mengembalikan false bila WebView halaman belum siap atau gagal.
  Future<bool> deleteNode(String nodeId) async {
    final pageId = state.activePageId;
    if (pageId == null) return false;
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) return false;
    try {
      final htmlFuture = service.selectionEvents
          .firstWhere((e) => e.type == 'html')
          .timeout(const Duration(seconds: 12));
      await service.deleteNode(nodeId);
      await service.requestHtml();
      final html = (await htmlFuture).html;
      if (html == null || html.trim().isEmpty) return false;
      final tree = await buildDomTreeInIsolate(html);
      updatePageHtml(pageId: pageId, stampedHtml: tree.stampedHtml, tree: tree);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------- generate --

  /// Generate halaman dari prompt. Satu blok HTML = satu halaman.
  /// Halaman baru di-upsert berdasarkan slug (link antar-halaman tetap stabil
  /// saat halaman yang sama di-generate ulang).
  Future<void> submitPrompt(String prompt) async {
    if (state.isGenerating) return;
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final activeProvider = await ref
        .read(apiProviderRepositoryProvider)
        .getActiveProvider();

    if (activeProvider == null) {
      _appendMessage(
        CanvasMessage(role: ChatRole.error, text: l10nOf(ref).canvasNoProvider),
      );
      return;
    }

    final pendingAttachments = state.attachments;

    // Mention (elemen / halaman) selalu berarti permintaan perubahan UI.
    final wantsUi =
        state.mentions.isNotEmpty ||
        isUiRequestPrompt(
          trimmed,
          hasAttachments: pendingAttachments.isNotEmpty,
          hasSelectedNode:
              state.selectedNodeId != null &&
              state.selectedNodeGeometry != null,
        );

    final userText = wantsUi
        ? '$trimmed${_uiContext()}${_selectedNodeContext()}${_mentionContext()}'
        : trimmed;

    state = state.copyWith(
      isGenerating: true,
      generationStartedAt: DateTime.now(),
      status: AiStatus.thinking,
      // Mention sudah masuk ke teks prompt, chip tidak perlu bertahan.
      mentions: const [],
      messages: [
        ...state.messages,
        CanvasMessage(
          role: ChatRole.user,
          text: userText,
          displayText: trimmed,
          attachmentNames: pendingAttachments.map((a) => a.name).toList(),
          attachments: pendingAttachments,
        ),
      ],
    );

    try {
      final payload = _buildMessagesPayload(attachments: pendingAttachments);
      final raw = await ref
          .read(aiApiServiceProvider)
          .generateUI(provider: activeProvider, messages: payload);
      if (!state.isGenerating) return;
      _setStatus(AiStatus.responding);
      final response = await classifyAiResponseInIsolate(raw);
      if (!state.isGenerating) return;

      state = state.copyWith(attachments: const []);

      if (response.isChat) {
        state = state.copyWith(
          isGenerating: false,
          clearGenerationStart: true,
          status: AiStatus.idle,
          messages: [
            ...state.messages,
            CanvasMessage(
              role: ChatRole.assistant,
              kind: ChatMessageKind.chat,
              text: response.text ?? '',
            ),
          ],
        );
        return;
      }

      _setStatus(AiStatus.rendering);
      final baseTitle = _titleFromPrompt(trimmed);
      final newPages = await _buildPagesFromScreens(
        screens: response.screens,
        baseTitle: baseTitle,
        existing: state.pages,
      );
      if (!state.isGenerating) return;

      final note = response.note?.trim();
      final messages = [...state.messages];
      if (note != null && note.isNotEmpty) {
        messages.add(
          CanvasMessage(
            role: ChatRole.assistant,
            kind: ChatMessageKind.chat,
            text: note,
          ),
        );
      }
      messages.add(
        CanvasMessage(
          role: ChatRole.assistant,
          kind: ChatMessageKind.ui,
          text: response.screens.first.html,
        ),
      );

      final merged = _upsertPages(state.pages, newPages);

      state = state.copyWith(
        pages: merged.pages,
        activePageId: merged.firstId,
        clearActivePage: merged.firstId == null,
        messages: messages,
        isGenerating: false,
        clearGenerationStart: true,
        status: AiStatus.idle,
      );
    } on ApiConnectionException catch (e) {
      if (e.code == AppErrorCode.cancelled) {
        // Cancel dari tombol Stop sudah menutup state; jangan tambah pesan
        // "Generation stopped." untuk kedua kalinya.
        if (state.isGenerating) {
          _cancelGeneration(promptWasDiscarded: true);
        }
        return;
      }
      // Detail teknis (URL, status HTTP, pesan provider) hanya masuk log.
      debugPrint(e.debugLabel);
      if (!state.isGenerating) return;
      _failGeneration(localizedAppError(l10nOf(ref), e));
    } catch (e) {
      if (!state.isGenerating) return;
      _failGeneration(l10nOf(ref).commonGenericError);
    }
  }

  /// Bangun [AppPage] dari daftar layar AI. Satu layar = satu halaman.
  Future<List<AppPage>> _buildPagesFromScreens({
    required List<UiScreen> screens,
    required String baseTitle,
    required List<AppPage> existing,
  }) async {
    final pages = <AppPage>[];
    final usedSlugs = existing.map((p) => p.slug).toList();
    for (var i = 0; i < screens.length; i++) {
      final screen = screens[i];
      final tree = await buildDomTreeInIsolate(screen.html);
      final pageId = 'page_${_pageCounter++}';
      final fallbackTitle = screens.length > 1
          ? '$baseTitle ${i + 1}'
          : baseTitle;
      final name = _sanitizeScreenTitle(screen.title, fallbackTitle);
      final declared = screen.slug?.trim();
      final baseSlug = (declared != null && declared.isNotEmpty)
          ? declared
          : slugify(name);
      final slug = uniqueSlug(baseSlug, usedSlugs);
      usedSlugs.add(slug);
      pages.add(
        AppPage(
          id: pageId,
          name: name,
          slug: slug,
          html: tree.stampedHtml,
          domTree: tree,
        ),
      );
    }
    return pages;
  }

  /// Gabungkan [incoming] ke [existing] dengan mencocokkan slug: halaman yang
  /// slug-nya sama akan diperbarui (id & urutan dipertahankan), sisanya
  /// ditambahkan. Mengembalikan daftar baru + id halaman pertama incoming.
  ({List<AppPage> pages, String? firstId}) _upsertPages(
    List<AppPage> existing,
    List<AppPage> incoming,
  ) {
    final result = [...existing];
    String? firstId;
    for (final page in incoming) {
      final idx = result.indexWhere(
        (p) => p.slug.toLowerCase() == page.slug.toLowerCase(),
      );
      if (idx >= 0) {
        final merged = result[idx].copyWith(
          name: page.name,
          html: page.html,
          domTree: page.domTree,
        );
        result[idx] = merged;
        firstId ??= merged.id;
      } else {
        result.add(page);
        firstId ??= page.id;
      }
    }
    firstId ??= result.isNotEmpty ? result.first.id : null;
    return (pages: result, firstId: firstId);
  }

  /// Hentikan generate yang sedang berjalan (tombol Stop).
  void cancelGeneration() {
    if (!state.isGenerating) return;
    AiApiService.cancelAll();
    _cancelGeneration(promptWasDiscarded: true);
  }

  void _cancelGeneration({bool promptWasDiscarded = false}) {
    state = state.copyWith(
      isGenerating: false,
      clearGenerationStart: true,
      status: AiStatus.idle,
    );
    if (promptWasDiscarded) {
      _appendMessage(
        const CanvasMessage(
          role: ChatRole.assistant,
          kind: ChatMessageKind.chat,
          // Sengaja bahasa Inggris: pesan ini bukan bagian dari UI multi-bahasa.
          text: 'Generation stopped.',
        ),
      );
    }
  }

  void _failGeneration(String message) {
    state = state.copyWith(
      isGenerating: false,
      clearGenerationStart: true,
      status: AiStatus.idle,
    );
    _appendMessage(CanvasMessage(role: ChatRole.error, text: message));
  }

  /// Kirim ulang prompt user terakhir tanpa mengetik ulang.
  Future<void> retryLastPrompt() async {
    if (state.isGenerating) return;
    final messages = [...state.messages];
    while (messages.isNotEmpty && messages.last.role == ChatRole.error) {
      messages.removeLast();
    }
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role != ChatRole.user) return;
    final prompt = (last.displayText ?? last.text).trim();
    if (prompt.isEmpty) return;
    messages.removeLast();
    state = state.copyWith(messages: messages);
    await submitPrompt(prompt);
  }

  void _setStatus(AiStatus status) {
    if (state.status == status) return;
    state = state.copyWith(status: status);
  }

  String _titleFromPrompt(String prompt) {
    final cleaned = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return l10nOf(ref).canvasUntitledPage;
    final words = cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(4)
        .join(' ')
        .replaceAll(RegExp(r'[,.:;!?]+$'), '');
    if (words.isEmpty) return l10nOf(ref).canvasUntitledPage;
    final titled = words.length > 32
        ? '${words.substring(0, 32).trim()}...'
        : words;
    return titled
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _sanitizeScreenTitle(String candidate, String fallback) {
    final cleaned = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return fallback;
    // Judul yang layak tampil di tab: pendek, bukan kalimat penjelasan.
    if (cleaned.length > 40 || cleaned.contains('.')) return fallback;
    if (cleaned.contains(':') || cleaned.contains('—')) return fallback;
    if (cleaned.split(' ').length > 4) return fallback;
    return cleaned;
  }

  /// Blok konteks dari mention di prompt bar (elemen / halaman / semua).
  String _mentionContext() {
    if (state.mentions.isEmpty) return '';
    final lines = <String>[];
    for (final mention in state.mentions) {
      switch (mention.kind) {
        case PromptMentionKind.element:
          final page = mention.pageName ?? state.activePage?.name;
          final where = page == null ? '' : ' on page "$page"';
          final id = mention.nodeId;
          lines.add(
            '- Element "${mention.label}"$where'
            '${id == null ? '' : ' (data-centauri-id="$id")'} — change only '
            'this element and leave the rest of the page untouched.',
          );
        case PromptMentionKind.page:
          final page = mention.pageName ?? mention.label;
          lines.add('- Page "$page" — apply the change to this page only.');
        case PromptMentionKind.allPages:
          lines.add(
            '- All pages — apply the change consistently to every page.',
          );
      }
    }
    return '\n\n[USER MENTIONS]\n${lines.join('\n')}';
  }

  /// Konteks format UI: fluid/responsive wajib + konvensi link antar-halaman.
  String _uiContext() {
    return '\n\n[OUTPUT FORMAT — MUST FOLLOW]\n'
        '- The preview container width varies from ~320px (small phone) to '
        '~2560px (desktop/ultrawide). NEVER set a fixed page width. Build a '
        'fully fluid, responsive layout using flexbox/grid, percentage/'
        'clamp()/min()/max() sizing, and @media breakpoints, with ZERO '
        'horizontal overflow at ANY width.\n'
        '- Include in <head>: <meta name="viewport" content="width=device-width, '
        'initial-scale=1">.\n'
        '- Declare this page\'s filename in <head> with '
        '<meta name="centauri-page" content="home.html"> (lowercase, '
        'hyphenated, ends with .html).\n'
        '- One page = ONE complete self-contained HTML document (its own '
        '<style> and <script>).\n'
        '- To link between pages, use real anchors whose href equals the other '
        'page\'s declared filename, e.g. <a href="pricing.html">. Do NOT use '
        'tab bars or JS view-switching as a substitute for separate pages.\n'
        '- Sections must hug their content (no empty spacer divs, no blank '
        'bands, footer directly after the last section).\n'
        '- Ensure real interactive vanilla JS controls, crisp high-DPI '
        'imagery, and inline SVG icons.';
  }

  List<Map<String, dynamic>> _buildMessagesPayload({
    List<Attachment> attachments = const [],
    List<CanvasMessage>? historyOverride,
  }) {
    final history = (historyOverride ?? state.messages)
        .where((m) => m.role != ChatRole.error)
        .toList();

    const systemPrompt = uiSystemPrompt;

    final payload = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (var i = 0; i < history.length; i++) {
      final message = history[i];
      final isLastUser =
          i == history.length - 1 && message.role == ChatRole.user;

      if (isLastUser && attachments.isNotEmpty) {
        payload.add({
          'role': 'user',
          'content': _buildVisionContent(message.text, attachments),
        });
      } else {
        final content = message.role == ChatRole.user && !isLastUser
            ? (message.displayText ?? message.text)
            : message.text;
        payload.add({
          'role': message.role == ChatRole.user ? 'user' : 'assistant',
          'content': content,
        });
      }
    }

    return payload;
  }

  /// Susun content multimodal OpenAI: teks + image_url (data URL) untuk gambar,
  /// dan teks inline untuk format berbasis teks (svg/html).
  List<Map<String, dynamic>> _buildVisionContent(
    String text,
    List<Attachment> attachments,
  ) {
    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': text},
    ];

    for (final attachment in attachments) {
      if (attachment.isText) {
        content.add({
          'type': 'text',
          'text':
              '\n\n--- Attached file: ${attachment.name} ---\n'
              '${attachment.textContent}',
        });
      } else {
        content.add({
          'type': 'image_url',
          'image_url': {'url': attachment.dataUrl},
        });
      }
    }

    return content;
  }

  void _appendMessage(CanvasMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }
}

/// Blok konteks node terpilih untuk inline edit. Top-level agar bisa diuji
/// langsung tanpa ProviderContainer. Mengembalikan string kosong bila tidak
/// ada seleksi valid.
String buildSelectedNodeContext({
  required NodeGeometry geometry,
  required String pageName,
}) {
  String pick(String key) => geometry.styles[key]?.trim() ?? '';
  final styleBits = [
    if (pick('display').isNotEmpty) 'display:${pick('display')}',
    if (pick('color').isNotEmpty) 'color:${pick('color')}',
    if (pick('backgroundColor').isNotEmpty)
      'background:${pick('backgroundColor')}',
    if (pick('fontSize').isNotEmpty) 'font-size:${pick('fontSize')}',
    if (pick('fontWeight').isNotEmpty) 'font-weight:${pick('fontWeight')}',
    if (pick('borderRadius').isNotEmpty)
      'border-radius:${pick('borderRadius')}',
    if (pick('border').isNotEmpty) 'border:${pick('border')}',
    if (pick('opacity').isNotEmpty) 'opacity:${pick('opacity')}',
    if (pick('padding').isNotEmpty) 'padding:${pick('padding')}',
  ].join('; ');
  return '\n\n[SELECTED NODE] The user has selected an element on page '
      '"$pageName". Target primarily THIS element (keep the rest of the page '
      'consistent unless the request says otherwise). '
      'tag=<${geometry.tag}> '
      'box=${geometry.width.toStringAsFixed(0)}x'
      '${geometry.height.toStringAsFixed(0)}px '
      'at (${geometry.x.toStringAsFixed(0)},'
      '${geometry.y.toStringAsFixed(0)})'
      '${styleBits.isEmpty ? '' : ' styles=[$styleBits]'}.';
}

/// Heuristik MODE GATE sisi klien: apakah prompt user benar-benar meminta UI?
/// Top-level agar bisa diuji langsung tanpa ProviderContainer.
bool isUiRequestPrompt(
  String prompt, {
  bool hasAttachments = false,
  bool hasSelectedNode = false,
}) {
  final lower = prompt.trim().toLowerCase();
  if (lower.isEmpty) return false;

  // 1. Sapaan / small talk persis -> selalu chat, apa pun konteks lain.
  const greetings = {
    'hello',
    'hi',
    'hey',
    'halo',
    'hallo',
    'hai',
    'pagi',
    'siang',
    'sore',
    'malam',
    'test',
    'tes',
    'testing',
    'bisa?',
    'tolong',
    'makasih',
    'terima kasih',
    'thanks',
    'thank you',
    'apa kabar',
    'siapa kamu',
    'kamu siapa',
  };
  final compact = lower.replaceAll(RegExp(r'[!.,?~\s]+$'), '').trim();
  if (greetings.contains(compact)) return false;
  if (compact.length <= 24 &&
      RegExp(r'^(selamat\s+)?(pagi|siang|sore|malam)\b').hasMatch(compact)) {
    return false;
  }

  // 2. Kata kerja / kata benda UI eksplisit (ID + EN).
  const uiVerbs = [
    'buat',
    'buatkan',
    'bikin',
    'bikinin',
    'buatlah',
    'design',
    'desain',
    'generate',
    'build',
    'create',
    'scaffold',
    'redesign',
    'restyle',
    'revamp',
    'convert',
    'clone',
    'replicate',
    'replikasi',
    'tirukan',
    'tambah',
    'tambahkan',
    'edit',
    'ubah',
    'rubah',
    'ganti',
    'revisi',
    'perbaiki',
    'betulkan',
    'modif',
    'update',
    'tampilkan',
    'tunjuk',
  ];
  const uiNouns = [
    'landing page',
    'landingpage',
    'website',
    'situs',
    'halaman',
    'page',
    'screen',
    'layar',
    'layout',
    'tampilan',
    'dashboard',
    'login',
    'register',
    'signup',
    'profil',
    'profile',
    'navbar',
    'hero',
    'footer',
    'formulir',
    'form',
    'tombol',
    'button',
    'kartu',
    'card',
    'modal',
    'dialog',
    'tabel',
    'table',
    'chart',
    'grafik',
    'menu',
    'tab',
    'aplikasi',
    'app',
    'web',
    '\bui\b',
    'mockup',
    'wireframe',
    'komponen',
    'component',
    'html',
    'css',
    'prototype',
  ];
  bool containsWord(String src, String word) {
    if (word.startsWith(r'\b')) {
      return RegExp(word).hasMatch(src);
    }
    return RegExp('\\b${RegExp.escape(word)}\\w*').hasMatch(src);
  }

  final hasVerb = uiVerbs.any((w) => containsWord(lower, w));
  final hasNoun = uiNouns.any((w) => containsWord(lower, w));
  if (hasVerb || hasNoun) return true;

  // 3. Lampiran / node terpilih saja tanpa kata UI -> chat.
  if (hasAttachments) return false;
  if (hasSelectedNode) return false;

  // 4. Default: pesan pendek tanpa sinyal UI -> chat.
  return false;
}
