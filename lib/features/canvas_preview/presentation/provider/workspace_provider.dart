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
import 'generation_stream_provider.dart';

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
    this.undoDepth = 0,
    this.redoDepth = 0,
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

  /// Jumlah langkah undo/redo yang tersedia. Disimpan di state supaya tombol
  /// undo/redo ikut rebuild saat stack berubah.
  final int undoDepth;
  final int redoDepth;

  bool get canUndo => undoDepth > 0;
  bool get canRedo => redoDepth > 0;

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
    int? undoDepth,
    int? redoDepth,
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
      undoDepth: undoDepth ?? this.undoDepth,
      redoDepth: redoDepth ?? this.redoDepth,
    );
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);

/// Snapshot satu halaman untuk undo/redo.
///
/// Riwayat sengaja hanya menyimpan konten halaman (HTML + DOM tree), bukan
/// seluruh workspace: undo/redo hanya untuk mengembalikan komponen yang
/// dihapus dan teks yang diedit, bukan percakapan, nama halaman, atau
/// perubahan lain di luar kanvas.
@immutable
class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.pageId,
    required this.html,
    required this.domTree,
  });

  final String pageId;
  final String html;
  final DomTreeResult? domTree;

  static WorkspaceSnapshot fromPage(AppPage page) => WorkspaceSnapshot(
    pageId: page.id,
    html: page.html,
    domTree: page.domTree,
  );

  /// Snapshot halaman [pageId] (default halaman aktif) dari [state].
  static WorkspaceSnapshot? fromState(WorkspaceState state, {String? pageId}) {
    final id = pageId ?? state.activePageId;
    if (id == null) return null;
    for (final page in state.pages) {
      if (page.id == id) return fromPage(page);
    }
    return null;
  }

  /// Isi halaman sama = tidak perlu snapshot baru.
  bool contentEquals(WorkspaceSnapshot other) =>
      pageId == other.pageId && html == other.html;
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  int _pageCounter = 0;

  // ------------------------------------------------------- undo / redo --
  static const int _historyLimit = 60;
  final List<WorkspaceSnapshot> _undoStack = [];
  final List<WorkspaceSnapshot> _redoStack = [];
  bool _applyingHistory = false;

  /// Kedalaman stack dibaca dari state agar tombol undo/redo reaktif.
  bool get canUndo => state.canUndo;
  bool get canRedo => state.canRedo;
  int get undoDepth => _undoStack.length;
  int get redoDepth => _redoStack.length;

  @override
  WorkspaceState build() => const WorkspaceState();

  AppPage? _pageById(String? id) {
    if (id == null) return null;
    for (final page in state.pages) {
      if (page.id == id) return page;
    }
    return null;
  }

  /// Salin kedalaman stack ke state supaya UI ikut rebuild.
  void _publishHistory() {
    final undo = _undoStack.length;
    final redo = _redoStack.length;
    if (state.undoDepth == undo && state.redoDepth == redo) return;
    state = state.copyWith(undoDepth: undo, redoDepth: redo);
  }

  /// Catat snapshot konten halaman [previous]. Helper tingkat rendah untuk
  /// mensimulasikan satu mutasi kanvas; alur produksi memakai
  /// [pushUndoSnapshot] tepat sebelum HTML diubah lewat WebView.
  void recordHistory(WorkspaceState previous) {
    if (_applyingHistory) return;
    final snapshot = WorkspaceSnapshot.fromState(previous);
    if (snapshot != null) _pushSnapshot(snapshot);
  }

  /// Dorong kondisi halaman saat ini ke stack undo. Dipanggil SEBELUM HTML
  /// halaman diubah lewat WebView.
  void pushUndoSnapshot({String? pageId}) {
    if (_applyingHistory) return;
    final snapshot = WorkspaceSnapshot.fromState(state, pageId: pageId);
    if (snapshot != null) _pushSnapshot(snapshot);
  }

  void _pushSnapshot(WorkspaceSnapshot snapshot) {
    if (_undoStack.isNotEmpty && _undoStack.last.contentEquals(snapshot)) {
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    _redoStack.clear();
    _publishHistory();
  }

  bool undo() {
    while (_undoStack.isNotEmpty) {
      final target = _undoStack.removeLast();
      final current = _pageById(target.pageId);
      // Halaman sudah dihapus sejak snapshot dibuat: lewati entri basi.
      if (current == null) continue;
      _redoStack.add(WorkspaceSnapshot.fromPage(current));
      _applySnapshot(target);
      return true;
    }
    _publishHistory();
    return false;
  }

  bool redo() {
    while (_redoStack.isNotEmpty) {
      final target = _redoStack.removeLast();
      final current = _pageById(target.pageId);
      if (current == null) continue;
      _undoStack.add(WorkspaceSnapshot.fromPage(current));
      _applySnapshot(target);
      return true;
    }
    _publishHistory();
    return false;
  }

  void _applySnapshot(WorkspaceSnapshot snapshot) {
    final index = state.pages.indexWhere((p) => p.id == snapshot.pageId);
    if (index < 0) return;
    final current = state.pages[index];
    final pages = [...state.pages];
    // Pertahankan id/nama/slug terkini; undo hanya memulihkan isi halaman.
    pages[index] = AppPage(
      id: current.id,
      name: current.name,
      slug: current.slug,
      html: snapshot.html,
      domTree: snapshot.domTree,
    );
    _applyingHistory = true;
    state = state.copyWith(
      pages: pages,
      activePageId: snapshot.pageId,
      clearSelection: true,
      clearGeometry: true,
      undoDepth: _undoStack.length,
      redoDepth: _redoStack.length,
    );
    _applyingHistory = false;
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _publishHistory();
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
    // Selama generate, kanvas menampilkan pratinjau live: berpindah halaman
    // akan bertabrakan dengan render parsial.
    if (state.isGenerating) return;
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
    // Snapshot halaman yang dihapus tidak bisa dipulihkan lagi; buang supaya
    // tombol undo/redo langsung mencerminkan sisa langkah yang valid.
    _undoStack.removeWhere((snapshot) => snapshot.pageId == id);
    _redoStack.removeWhere((snapshot) => snapshot.pageId == id);
    state = state.copyWith(
      pages: pages,
      activePageId: nextActive,
      clearActivePage: nextActive == null,
      clearSelection: true,
      clearGeometry: true,
      undoDepth: _undoStack.length,
      redoDepth: _redoStack.length,
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

    // Sesi baru = riwayat komponen sesi lama tidak berlaku.
    _undoStack.clear();
    _redoStack.clear();

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
    _undoStack.clear();
    _redoStack.clear();
    state = state.copyWith(
      pages: const [],
      messages: const [],
      isGenerating: false,
      clearActivePage: true,
      clearSelection: true,
      clearHover: true,
      clearGenerationStart: true,
      undoDepth: 0,
      redoDepth: 0,
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
  ///
  /// Snapshot undo diambil SEBELUM DOM berubah, jadi hasilnya bisa
  /// dikembalikan lewat [undo].
  Future<bool> deleteNode(String nodeId) async {
    final pageId = state.activePageId;
    if (pageId == null) return false;
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) return false;
    try {
      final htmlFuture = _nextHtmlEvent(service);
      await service.deleteNode(nodeId);
      return await _syncPageHtmlFromCanvas(
        pageId: pageId,
        htmlFuture: htmlFuture,
        service: service,
      );
    } catch (_) {
      return false;
    }
  }

  /// Tulis teks baru hasil inline edit di kanvas, lalu sinkronkan HTML.
  /// Mengembalikan false bila WebView halaman belum siap atau gagal.
  ///
  /// [text] adalah teks final dari TextField Flutter; JS menulisnya sebagai
  /// `textContent` node supaya HTML tetap source of truth.
  Future<bool> commitCanvasTextEdit(String nodeId, String text) async {
    final pageId = state.activePageId;
    if (pageId == null) return false;
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) return false;
    try {
      final htmlFuture = _nextHtmlEvent(service);
      await service.setNodeText(nodeId, text);
      return await _syncPageHtmlFromCanvas(
        pageId: pageId,
        htmlFuture: htmlFuture,
        service: service,
      );
    } catch (_) {
      return false;
    }
  }

  /// Event dokumen penuh berikutnya dari bridge JS. Di-subscribe SEBELUM
  /// mutasi supaya respons tidak terlewat.
  Future<CanvasSelectEvent> _nextHtmlEvent(CanvasWebviewService service) =>
      service.selectionEvents
          .firstWhere((e) => e.type == 'html')
          .timeout(const Duration(seconds: 12));

  /// Minta dokumen terbaru dari WebView, lalu simpan sebagai HTML halaman.
  Future<bool> _syncPageHtmlFromCanvas({
    required String pageId,
    required Future<CanvasSelectEvent> htmlFuture,
    required CanvasWebviewService service,
  }) async {
    await service.requestHtml();
    final html = (await htmlFuture).html;
    if (html == null || html.trim().isEmpty) return false;
    final tree = await buildDomTreeInIsolate(html);
    // Tidak ada perubahan nyata: jangan kotori riwayat undo.
    final current = _pageById(pageId);
    if (current != null && current.html == tree.stampedHtml) return true;
    // State belum berubah di titik ini → snapshot = kondisi sebelum mutasi.
    pushUndoSnapshot(pageId: pageId);
    updatePageHtml(pageId: pageId, stampedHtml: tree.stampedHtml, tree: tree);
    return true;
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

    // Prompt baru = konten halaman akan dibuat ulang; riwayat undo/redo
    // langkah kanvas sebelumnya tidak berlaku lagi.
    clearHistory();

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
        ? '$trimmed${_uiContext(trimmed)}${_workspaceContext()}'
              '${_selectedNodeContext()}${_mentionContext()}'
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

    // Pratinjau live: state terpisah supaya token tidak mengotori snapshot
    // undo dan tidak merebuild panel lain.
    final stream = ref.read(generationStreamProvider.notifier);
    stream.begin(
      knownScreenCount: wantsUi ? explicitPageCount(trimmed) : null,
      uiRequest: wantsUi,
    );

    try {
      final payload = _buildMessagesPayload(attachments: pendingAttachments);
      var raw = '';
      await for (final event
          in ref
              .read(aiApiServiceProvider)
              .streamUI(provider: activeProvider, messages: payload)) {
        if (!state.isGenerating) return;
        switch (event) {
          case UiStreamStart(:final streaming):
            stream.onStart(streaming: streaming);
          case UiStreamDelta(:final text):
            stream.onDelta(text);
          case UiStreamDone(:final text):
            raw = text;
        }
      }
      if (!state.isGenerating) return;
      _setStatus(AiStatus.responding);
      stream.assembling();
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
        stream.finish();
        return;
      }

      _setStatus(AiStatus.rendering);
      final baseTitle = _titleFromPrompt(trimmed);

      // Jumlah halaman yang dikunci user: kalau AI tetap membuat lebih, sisa
      //-nya dibuang supaya sesuai permintaan.
      final lockedCount = wantsUi ? explicitPageCount(trimmed) : null;
      var screens = response.screens;
      var dropped = 0;
      if (lockedCount != null && screens.length > lockedCount) {
        dropped = screens.length - lockedCount;
        screens = screens.take(lockedCount).toList();
      }

      final newPages = await _buildPagesFromScreens(
        screens: screens,
        baseTitle: baseTitle,
        existing: state.pages,
        createIntent: requestsNewPage(trimmed),
      );
      if (!state.isGenerating) return;

      var note = response.note?.trim();
      if (dropped > 0) {
        final extra = l10nOf(ref).canvasPagesTrimmed;
        note = (note == null || note.isEmpty) ? extra : '$note\n\n$extra';
      }
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
          text: screens.first.html,
        ),
      );

      final merged = _upsertPages(state.pages, newPages);

      // Halaman yang terakhir tampil saat streaming menang, supaya pratinjau
      // tidak melompat mundur di detik terakhir.
      final previewSlug = stream.state.previewSlug?.toLowerCase();
      String? settledId;
      if (previewSlug != null) {
        for (final page in merged.pages) {
          if (page.slug.toLowerCase() == previewSlug) {
            settledId = page.id;
            break;
          }
        }
      }
      final activeId = settledId ?? merged.firstId;

      state = state.copyWith(
        pages: merged.pages,
        activePageId: activeId,
        clearActivePage: activeId == null,
        messages: messages,
        isGenerating: false,
        clearGenerationStart: true,
        status: AiStatus.idle,
      );
      stream.finish();
    } on ApiConnectionException catch (e) {
      if (e.code == AppErrorCode.cancelled) {
        // Cancel dari tombol Stop sudah menutup state; jangan tambah pesan
        // "Generation stopped." untuk kedua kalinya.
        stream.cancel();
        if (state.isGenerating) {
          _cancelGeneration(promptWasDiscarded: true);
        }
        return;
      }
      // Detail teknis (URL, status HTTP, pesan provider) hanya masuk log.
      debugPrint(e.debugLabel);
      stream.fail();
      if (!state.isGenerating) return;
      _failGeneration(localizedAppError(l10nOf(ref), e));
    } catch (e) {
      stream.fail();
      if (!state.isGenerating) return;
      _failGeneration(l10nOf(ref).commonGenericError);
    }
  }

  /// Bangun [AppPage] dari daftar layar AI. Satu layar = satu halaman.
  ///
  /// Layar yang dikenali sebagai revisi halaman yang sudah ada memakai ulang
  /// id, nama file, dan nama halamannya, sehingga link antar-halaman tetap
  /// menunjuk halaman versi baru, bukan halaman lama yang tertinggal.
  Future<List<AppPage>> _buildPagesFromScreens({
    required List<UiScreen> screens,
    required String baseTitle,
    required List<AppPage> existing,
    bool createIntent = false,
  }) async {
    final pages = <AppPage>[];
    final usedSlugs = existing.map((p) => p.slug).toList();
    final activeId = state.activePageId;
    for (var i = 0; i < screens.length; i++) {
      final screen = screens[i];
      final tree = await buildDomTreeInIsolate(screen.html);
      final target = matchRevisionTarget(
        screen: screen,
        index: i,
        screenCount: screens.length,
        existing: existing,
        activePageId: activeId,
        createIntent: createIntent,
      );
      final fallbackTitle =
          target?.name ??
          (screens.length > 1 ? '$baseTitle ${i + 1}' : baseTitle);
      final name = _sanitizeScreenTitle(screen.title, fallbackTitle);
      if (target != null) {
        pages.add(
          AppPage(
            id: target.id,
            name: name,
            slug: target.slug,
            html: _forcePageSlug(tree.stampedHtml, target.slug),
            domTree: tree,
          ),
        );
        continue;
      }
      final pageId = 'page_${_pageCounter++}';
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

  /// Paksa `<meta name="centauri-page">` memakai [slug], supaya nama file di
  /// dalam HTML sama dengan halaman yang mewakilinya setelah revisi.
  String _forcePageSlug(String html, String slug) {
    final patterns = [
      RegExp(
        "(<meta\\s+[^>]*name=[\"']centauri-page[\"']\\s+[^>]*content=[\"'])"
        "([^\"']*)([\"'])",
        caseSensitive: false,
      ),
      RegExp(
        "(<meta\\s+[^>]*content=[\"'])([^\"']*)"
        "([\"']\\s+[^>]*name=[\"']centauri-page[\"'])",
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      if (pattern.hasMatch(html)) {
        return html.replaceFirstMapped(pattern, (m) => '${m[1]}$slug${m[3]}');
      }
    }
    return html;
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
    ref.read(generationStreamProvider.notifier).cancel();
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

  /// Konteks prototype yang sudah ada di kanvas: daftar nama file halaman
  /// plus HTML halaman yang sedang dibuka.
  ///
  /// Tanpa ini AI memperlakukan prompt revisi sebagai proyek baru: ia
  /// mengarang nama file lain (`home-2.html`) sehingga halaman lama tetap
  /// ada, dan link di preview menuju halaman versi lama.
  String _workspaceContext() {
    final pages = state.pages;
    if (pages.isEmpty) return '';
    final activeId = state.activePageId;

    final buffer = StringBuffer('\n\n[CURRENT WORKSPACE]')
      ..write(
        '\nThe canvas already contains this prototype. This request revises '
        'it; it is not a new project.',
      )
      ..write('\nPages (filename → name):');
    for (final page in pages) {
      buffer.write(
        '\n- ${page.slug} → ${page.name}'
        '${page.id == activeId ? ' (open in the preview)' : ''}',
      );
    }
    buffer
      ..write(
        '\n\nReturn each page you change as a complete document that keeps '
        'its EXACT filename in <meta name="centauri-page"> and its <title>. '
        'Never create a second file for a page listed above, never rename '
        'one, and keep every <a href> pointing at a filename in this list.',
      )
      ..write(
        '\nThe HTML below is the current content, for reference only — do '
        'not repeat it back verbatim.',
      );

    // Halaman aktif lebih dulu; sisanya selama muat di anggaran karakter.
    final ordered = <AppPage>[
      if (state.activePage != null) state.activePage!,
      ...pages.where((p) => p.id != activeId),
    ];
    var budget = _workspaceHtmlBudget;
    for (final page in ordered) {
      if (page.html.trim().isEmpty) continue;
      final fits = page.id == activeId || page.html.length <= budget;
      if (!fits) continue;
      budget -= page.html.length;
      buffer.write(
        '\n\n--- ${page.slug} (current HTML) ---\n```html\n'
        '${page.html}\n```',
      );
    }
    return buffer.toString();
  }

  /// Batas karakter HTML yang dikirim sebagai konteks revisi. Cukup untuk
  /// beberapa halaman utuh, tapi tidak sampai membanjiri jendela konteks.
  static const int _workspaceHtmlBudget = 120000;

  /// Konteks format UI: fluid/responsive wajib + konvensi link antar-halaman.
  ///
  /// [userText] dipakai untuk mendeteksi jumlah halaman yang dikunci user:
  /// kalau user menyebut angkanya, AI diminta menghasilkan tepat segitu.
  String _uiContext([String? userText]) {
    final locked = userText == null ? null : explicitPageCount(userText);
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
        'imagery, and inline SVG icons.'
        '${locked == null ? '' : '\n- The user explicitly asked for exactly '
                  '$locked page(s). Output EXACTLY $locked HTML document(s) — no '
                  'more, no fewer. Do not add, split, or invent extra screens.'}';
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

/// Angka halaman yang ditegaskan user di prompt ("satu halaman", "3 halaman",
/// "just one page"). Null = user tidak menyebut jumlah halaman.
const Map<String, int> _pageCountWords = {
  'satu': 1,
  'seorang': 1,
  'single': 1,
  'one': 1,
  'dua': 2,
  'two': 2,
  'tiga': 3,
  'three': 3,
  'empat': 4,
  'four': 4,
  'lima': 5,
  'five': 5,
  'enam': 6,
  'six': 6,
  'tujuh': 7,
  'seven': 7,
  'delapan': 8,
  'eight': 8,
  'sembilan': 9,
  'nine': 9,
};

/// Jumlah halaman yang diminta user secara eksplisit, atau null kalau tidak.
///
/// Ini yang mengunci jumlah halaman: kalau user menyebut angkanya, AI tidak
/// boleh menambah halaman lain, dan kalau sampai lebih, app memangkas sisanya.
///
/// Top-level agar bisa diuji langsung tanpa ProviderContainer.
int? explicitPageCount(String prompt) {
  final lower = prompt.trim().toLowerCase();
  if (lower.isEmpty) return null;

  final match = RegExp(
    r'\b(\d{1,2}|satu|seorang|single|one|dua|two|tiga|three|empat|four|lima|'
    r'five|enam|six|tujuh|seven|delapan|eight|sembilan|nine)\s*[- ]?\s*'
    r'(halaman|halaman-halaman|layar|layar-layar|page|pages|screen|screens|'
    r'tab|tabs)\b',
  ).firstMatch(lower);
  if (match == null) return null;

  final token = match.group(1)!;
  final digits = int.tryParse(token);
  if (digits != null) return digits > 0 ? digits : null;
  return _pageCountWords[token];
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

/// Apakah user meminta halaman BARU, bukan perubahan halaman yang ada.
///
/// Dipakai untuk mematikan pemetaan revisi: kalau user memang minta halaman
/// tambahan, layar baru harus jadi halaman baru, bukan menimpa halaman aktif.
bool requestsNewPage(String prompt) {
  final lower = prompt.toLowerCase();
  return RegExp(
    r'\b(halaman|page|pages|screen|layar|tab)\s+(baru|new)\b'
    r'|\b(new|another|extra|additional)\s+(page|pages|screen|halaman|layar)\b'
    r'|\b(tambah|tambahkan|tambahlah|add)\b[^.]{0,30}?'
    r'\b(page|pages|screen|halaman|layar)\b',
  ).hasMatch(lower);
}

/// Halaman yang sudah ada yang menjadi sasaran revisi [screen], atau null
/// bila layar ini memang halaman baru.
///
/// AI kadang mengirim nama file baru untuk halaman yang sudah ada
/// (`home-2.html` padahal `home.html` sudah ada) walau user hanya minta
/// perubahan. Tanpa pemetaan ini hasilnya halaman duplikat, dan link di
/// preview kembali ke versi lama.
///
/// Urutan pencocokan: nama file persis, varian nama file, judul halaman,
/// posisi (hanya bila AI mengirim ulang seluruh prototype), lalu halaman
/// yang sedang dibuka (hanya bila AI tidak menyebut nama file).
///
/// Top-level agar bisa diuji langsung tanpa ProviderContainer.
AppPage? matchRevisionTarget({
  required UiScreen screen,
  required int index,
  required int screenCount,
  required List<AppPage> existing,
  String? activePageId,
  bool createIntent = false,
}) {
  if (existing.isEmpty || createIntent) return null;

  final declared = screen.slug?.trim().toLowerCase() ?? '';
  if (declared.isNotEmpty) {
    for (final page in existing) {
      if (page.slug.toLowerCase() == declared) return page;
    }
    // `home-2.html` / `home-3.html` untuk halaman `home.html`.
    final declaredStem = slugStem(declared);
    for (final page in existing) {
      final stem = slugStem(page.slug);
      if (declaredStem == stem ||
          RegExp('^${RegExp.escape(stem)}-[0-9]+\$').hasMatch(declaredStem)) {
        return page;
      }
    }
  }

  final titleKey = _pageNameKey(screen.title);
  if (titleKey.isNotEmpty) {
    for (final page in existing) {
      if (_pageNameKey(page.name) == titleKey) return page;
    }
  }

  // AI mengirim ulang seluruh prototype: petakan per urutan supaya nama file
  // dan id halaman tetap. Hanya untuk >1 layar — satu layar hampir selalu
  // halaman baru, bukan pengganti halaman pertama.
  if (screenCount > 1 && screenCount == existing.length) {
    return index < existing.length ? existing[index] : null;
  }

  // Satu layar tanpa nama file = revisi halaman yang sedang dibuka.
  if (screenCount == 1 && declared.isEmpty) {
    for (final page in existing) {
      if (page.id == activePageId) return page;
    }
  }
  return null;
}

/// Kunci pembanding judul halaman: lowercase, hanya huruf/angka.
String _pageNameKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
