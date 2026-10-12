import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_editor/domain/ai_response.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../../provider_config/data/datasources/ai_api_service.dart';
import '../../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../domain/board_frame.dart';
import '../../domain/dom_tree.dart';
import '../../domain/viewport_mode.dart';

enum ChatRole { user, assistant, error }

/// Mode tampilan area kerja.
enum OutputMode { design, dev }

/// Alat aktif di board (mirip toolbar Figma/Stitch).
enum BoardTool { select, hand, comment }

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
  /// Dipakai agar konteks internal (mis. `[CANVAS TARGET]`, design token)
  /// yang di-append ke prompt tidak bocor ke chat bubble user.
  final String? displayText;

  /// Teks bersih untuk ditampilkan ke pengguna.
  String get shownText => displayText ?? text;

  final ChatMessageKind kind;

  /// Nama lampiran yang menyertai pesan ini (dipakai untuk persistensi).
  final List<String> attachmentNames;

  /// Lampiran lengkap (in-memory) agar bisa ditampilkan & dipratinjau di chat.
  /// Tidak disimpan ke riwayat untuk menghemat ruang.
  final List<Attachment> attachments;
}

enum ChatMessageKind { chat, ui }

/// Status proses AI yang ditampilkan live ke pengguna.
enum AiStatus {
  idle('', ''),
  thinking('Berpikir', 'Menghubungi model...'),
  responding('Menulis', 'Menerima respons'),
  rendering('Merender', 'Menyiapkan board UI'),
  done('Selesai', '');

  const AiStatus(this.label, this.detail);

  final String label;
  final String detail;
}

/// State board: daftar frame + transformasi pan/zoom.
class CanvasState {
  /// Batas zoom board.
  static const double minScale = 0.15;
  static const double maxScale = 2.5;

  const CanvasState({
    this.frames = const [],
    this.activeFrameId,
    this.panOffset = Offset.zero,
    this.scale = 0.6,
    this.viewport = ViewportMode.mobile,
    this.messages = const [],
    this.isGenerating = false,
    this.selectedToken,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.outputMode = OutputMode.design,
    this.tool = BoardTool.select,
    this.generationStartedAt,
    this.showGrid = true,
    this.status = AiStatus.idle,
    this.attachments = const [],
  });

  /// Semua frame di board (urut kronologis).
  final List<BoardFrame> frames;

  /// Frame aktif (untuk Layers/Dev panel).
  final String? activeFrameId;

  /// Pergeseran board (koordinat board).
  final Offset panOffset;

  /// Skala board.
  final double scale;

  /// Preset viewport untuk frame baru.
  final ViewportMode viewport;

  final List<CanvasMessage> messages;
  final bool isGenerating;
  final DesignTokenPreset? selectedToken;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final OutputMode outputMode;
  final BoardTool tool;
  final DateTime? generationStartedAt;
  final bool showGrid;

  /// Status proses AI saat ini (untuk indikator live).
  final AiStatus status;

  /// Lampiran yang menunggu dikirim bersama prompt berikutnya.
  final List<Attachment> attachments;
  BoardFrame? get activeFrame {
    if (activeFrameId == null) return null;
    for (final frame in frames) {
      if (frame.id == activeFrameId) return frame;
    }
    return null;
  }

  /// HTML frame aktif (dipakai code panel & layers).
  String? get activeHtml => activeFrame?.html;

  bool get hasCanvasContent => frames.isNotEmpty;

  /// True bila belum ada frame UI sama sekali di board.
  bool get isBoardEmpty => frames.isEmpty;

  /// True bila ada frame yang bisa ditampilkan di board.
  bool get hasRenderedFrame => frames.any((f) => f.html.isNotEmpty);

  CanvasState copyWith({
    List<BoardFrame>? frames,
    String? activeFrameId,
    bool clearActiveFrame = false,
    Offset? panOffset,
    double? scale,
    ViewportMode? viewport,
    List<CanvasMessage>? messages,
    bool? isGenerating,
    DesignTokenPreset? selectedToken,
    bool clearToken = false,
    String? selectedNodeId,
    bool clearSelection = false,
    String? hoveredNodeId,
    bool clearHover = false,
    OutputMode? outputMode,
    BoardTool? tool,
    DateTime? generationStartedAt,
    bool clearGenerationStart = false,
    bool? showGrid,
    AiStatus? status,
    List<Attachment>? attachments,
  }) {
    return CanvasState(
      frames: frames ?? this.frames,
      activeFrameId: clearActiveFrame
          ? null
          : (activeFrameId ?? this.activeFrameId),
      panOffset: panOffset ?? this.panOffset,
      scale: scale ?? this.scale,
      viewport: viewport ?? this.viewport,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      selectedToken: clearToken ? null : (selectedToken ?? this.selectedToken),
      selectedNodeId: clearSelection
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      hoveredNodeId: clearHover ? null : (hoveredNodeId ?? this.hoveredNodeId),
      outputMode: outputMode ?? this.outputMode,
      tool: tool ?? this.tool,
      generationStartedAt: clearGenerationStart
          ? null
          : (generationStartedAt ?? this.generationStartedAt),
      showGrid: showGrid ?? this.showGrid,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }
}

final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(
  CanvasNotifier.new,
);

class CanvasNotifier extends Notifier<CanvasState> {
  static const double _gap = 80;
  /// frame terakhir (agar "ruang kosong" untuk frame berikutnya).

  int _frameCounter = 0;

  @override
  CanvasState build() => const CanvasState();

  /// Board kini tak terbatas, jadi frame tidak dibatasi posisinya.
  /// Dibiarkan sebagai hook agar mudah menambah aturan bila perlu.
  List<BoardFrame> _normalizeFrames(List<BoardFrame> frames) => frames;

  /// Target viewport untuk generate BERIKUTNYA (murni hint prompt).
  /// Sengaja TIDAK mengubah ukuran frame yang sudah ada di board — tombol
  /// viewport di prompt bar bukan editor layout. Resize diam-diam justru
  /// membuat UI "berubah" dan membingungkan (bug laporan user).
  void setViewport(ViewportMode mode) {
    if (mode == state.viewport) return;
    state = state.copyWith(viewport: mode);
  }

  /// Jika user menyebut viewport secara eksplisit di prompt ("mobile",
  /// "tablet", "desktop", "viewport: ...", "390px", "768px", "1280px"),
  /// itu MENANG atas tombol di prompt bar. Mengembalikan null bila user
  /// tidak menyebut apa pun (pakai tombol sebagai default/fallback).
  ViewportMode? _detectViewportOverride(String prompt) =>
      detectViewportOverride(prompt);

  Size _sizeFor(ViewportMode mode) => switch (mode) {
    // Lebar tetap (fixed) agar konsisten; tinggi lega agar konten muat
    // tanpa scrollbar di dalam frame.
    ViewportMode.mobile => const Size(390, 844),
    ViewportMode.tablet => const Size(768, 1024),
    ViewportMode.desktop => const Size(1280, 800),
  };

  void setOutputMode(OutputMode mode) {
    if (mode == state.outputMode) return;
    state = state.copyWith(outputMode: mode);
  }

  void setTool(BoardTool tool) {
    if (tool == state.tool) return;
    state = state.copyWith(tool: tool);
  }

  void toggleGrid() => state = state.copyWith(showGrid: !state.showGrid);

  // ------------------------------------------------------------- board view --

  /// Ukuran viewport board terakhir (dilaporkan widget) untuk clamping pan.
  Size _viewport = const Size(1000, 700);

  void reportViewport(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _viewport = size;
  }

  /// Clamp pan pada board TAK terbatas: user boleh pan ke mana saja, tetapi
  /// bounding box frame tidak boleh hilang sepenuhnya dari layar. Ini mencegah
  /// UI "tersesat" di luar viewport sekaligus tetap terasa infinite.
  Offset _clampPan(Offset pan, double scale) {
    // Tanpa frame: bebas menggeser (area kosong tak terbatas).
    if (state.frames.isEmpty) return pan;

    // Bounding box konten dalam koordinat board.
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;
    for (final frame in state.frames) {
      left = left < frame.offset.dx ? left : frame.offset.dx;
      top = top < frame.offset.dy ? top : frame.offset.dy;
      final frameRight = frame.offset.dx + frame.size.width;
      final frameBottom = frame.offset.dy + frame.size.height;
      right = right > frameRight ? right : frameRight;
      bottom = bottom > frameBottom ? bottom : frameBottom;
    }

    // Posisi konten di layar pada pan saat ini.
    final contentLeft = left * scale + pan.dx;
    final contentTop = top * scale + pan.dy;
    final contentRight = right * scale + pan.dx;
    final contentBottom = bottom * scale + pan.dy;

    // Wajib menyisakan minimal [keep] px konten terlihat di tiap sisi.
    const keep = 120.0;
    var dx = pan.dx;
    var dy = pan.dy;

    if (contentRight < keep) {
      dx += keep - contentRight;
    } else if (contentLeft > _viewport.width - keep) {
      dx -= contentLeft - (_viewport.width - keep);
    }
    if (contentBottom < keep) {
      dy += keep - contentBottom;
    } else if (contentTop > _viewport.height - keep) {
      dy -= contentTop - (_viewport.height - keep);
    }

    return Offset(dx, dy);
  }

  void panBy(Offset delta) {
    state = state.copyWith(
      panOffset: _clampPan(state.panOffset + delta, state.scale),
    );
  }

  void zoomAt(Offset focalScreen, double factor) {
    final newScale = (state.scale * factor).clamp(
      CanvasState.minScale,
      CanvasState.maxScale,
    );
    if (newScale == state.scale) return;

    // Jaga titik fokus tetap di bawah kursor saat zoom.
    final boardPoint = (focalScreen - state.panOffset) / state.scale;
    final newPan = focalScreen - boardPoint * newScale;

    state = state.copyWith(
      scale: newScale,
      panOffset: _clampPan(newPan, newScale),
    );
  }

  void setScale(double scale) {
    final newScale = scale.clamp(CanvasState.minScale, CanvasState.maxScale);
    if (newScale == state.scale) return;
    state = state.copyWith(
      scale: newScale,
      panOffset: _clampPan(state.panOffset, newScale),
    );
  }

  /// Apakah boleh zoom in / zoom out (dipakai untuk menonaktifkan tombol).
  bool get canZoomIn => state.scale < CanvasState.maxScale - 0.0001;
  bool get canZoomOut => state.scale > CanvasState.minScale + 0.0001;

  void resetView() {
    state = state.copyWith(scale: 0.6, panOffset: Offset.zero);
  }
  void centerOnFrames(Size viewport) {
    if (state.frames.isEmpty) return;
    final bounds = _framesBounds();
    final scale = _fitScale(bounds, viewport);
    final pan = Offset(
      viewport.width / 2 - (bounds.left + bounds.width / 2) * scale,
      viewport.height / 2 - (bounds.top + bounds.height / 2) * scale,
    );
    state = state.copyWith(scale: scale, panOffset: pan);
  }

  Rect _framesBounds() {
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;
    for (final frame in state.frames) {
      left = left < frame.offset.dx ? left : frame.offset.dx;
      top = top < frame.offset.dy ? top : frame.offset.dy;
      final frameRight = frame.offset.dx + frame.size.width;
      final frameBottom = frame.offset.dy + frame.size.height;
      right = right > frameRight ? right : frameRight;
      bottom = bottom > frameBottom ? bottom : frameBottom;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _fitScale(Rect bounds, Size viewport) {
    if (bounds.width <= 0 || bounds.height <= 0) return 0.6;
    final scaleX = viewport.width / (bounds.width + _gap * 2);
    final scaleY = viewport.height / (bounds.height + _gap * 2);
    return (scaleX < scaleY ? scaleX : scaleY).clamp(CanvasState.minScale, 1.0);
  }

  // ---------------------------------------------------------------- frames --

  void selectFrame(String? id) {
    if (id == null) {
      if (state.activeFrameId == null) return;
      state = state.copyWith(clearActiveFrame: true, clearSelection: true);
      return;
    }
    final frames = state.frames
        .map((f) => f.copyWith(isActive: f.id == id))
        .toList();
    state = state.copyWith(frames: frames, activeFrameId: id);
  }

  void moveFrame(String id, Offset delta) {
    final moved = state.frames
        .map((f) => f.id == id ? f.copyWith(offset: f.offset + delta) : f)
        .toList();
    final frames = _normalizeFrames(moved);
    state = state.copyWith(
      frames: frames,
    );
  }

  /// Sesuaikan tinggi frame agar kontennya utuh (tanpa scrollbar).
  /// Lebar tetap (FIXED sesuai viewport); tinggi hanya TUMBUH mengikuti konten
  /// agar layout tidak "melompat" saat zoom atau saat gambar/font selesai load.
  /// Penyusutan diabaikan supaya frame stabil di semua tingkat zoom board.
  void setFrameContentHeight(String id, double contentHeight) {
    const minHeight = 200.0;
    const maxHeight = 6000.0;
    final height = contentHeight.clamp(minHeight, maxHeight);
    final frames = state.frames.map((f) {
      if (f.id != id) return f;
      // Beri sedikit ruang ekstra agar tepi konten tidak mepet.
      final target = height + 2;
      // Histeresis 4px + grow-only: abaikan perubahan kecil & penyusutan.
      if (target <= f.size.height + 4) return f;
      return f.copyWith(size: Size(f.size.width, target));
    }).toList();
    state = state.copyWith(frames: frames);
  }

  void deleteFrame(String id) {
    final frames = _normalizeFrames(
      state.frames.where((f) => f.id != id).toList(),
    );
    state = state.copyWith(
      frames: frames,
      clearActiveFrame: state.activeFrameId == id,
      clearSelection: true,
    );
  }

  void clearBoard() {
    _frameCounter = 0;
    state = state.copyWith(
      frames: const [],
      messages: const [],
      isGenerating: false,
      clearActiveFrame: true,
      clearSelection: true,
      clearHover: true,
      clearGenerationStart: true,
      panOffset: Offset.zero,
      scale: 0.6,
    );
  }

  /// Muat ulang board & percakapan dari data proyek tersimpan.
  /// DOM tree dibangun ulang dari HTML (di isolate) agar layers tetap bekerja.
  Future<void> loadSession({
    required List<CanvasMessage> messages,
    required List<BoardFrame> frames,
    String? activeFrameId,
  }) async {
    final rebuilt = <BoardFrame>[];
    for (final frame in frames) {
      if (frame.html.isEmpty) {
        rebuilt.add(frame);
        continue;
      }
      try {
        final tree = await buildDomTreeInIsolate(frame.html);
        rebuilt.add(frame.copyWith(html: tree.stampedHtml, domTree: tree));
      } catch (_) {
        rebuilt.add(frame);
      }
    }

    // Pastikan id frame berikutnya tidak bentrok dengan yang sudah dimuat.
    _frameCounter = rebuilt.length;
    for (final frame in rebuilt) {
      final match = RegExp(r'frame_(\d+)').firstMatch(frame.id);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value >= _frameCounter) _frameCounter = value + 1;
    }

    final normalized = _normalizeFrames(rebuilt);
    state = CanvasState(
      frames: normalized,
      activeFrameId: activeFrameId,
      messages: messages,
      viewport: state.viewport,
      outputMode: state.outputMode,
      tool: state.tool,
      showGrid: state.showGrid,
    );
  }

  /// Posisi frame baru: di sebelah kanan frame terakhir.
  Offset _nextFrameOffset(Size size) {
    if (state.frames.isEmpty) return Offset.zero;
    var maxRight = -double.infinity;
    var top = double.infinity;
    for (final frame in state.frames) {
      final right = frame.offset.dx + frame.size.width;
      if (right > maxRight) {
        maxRight = right;
        top = frame.offset.dy;
      }
    }
    return Offset(maxRight + _gap, top == double.infinity ? 0 : top);
  }

  void setSelectedToken(DesignTokenPreset? token) {
    if (token == null) {
      if (state.selectedToken == null) return;
      state = state.copyWith(clearToken: true);
      return;
    }
    state = state.copyWith(selectedToken: token);
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
      return 'Maksimal 6 lampiran per prompt.';
    }
    state = state.copyWith(
      attachments: [...state.attachments, attachment],
    );
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
      state = state.copyWith(clearSelection: true);
      return;
    }
    state = state.copyWith(selectedNodeId: id);
  }

  void selectNodeFromCanvas(String? id) => selectNode(id);

  void hoverNode(String? id) {
    if (id == null) {
      if (state.hoveredNodeId == null) return;
      state = state.copyWith(clearHover: true);
      return;
    }
    if (id == state.hoveredNodeId) return;
    state = state.copyWith(hoveredNodeId: id);
  }

  // ------------------------------------------------------------- generate --

  /// Generate frame baru dari prompt. Setiap hasil menjadi frame baru di board.
  Future<void> submitPrompt(
    String prompt, {
    DesignTokenPreset? designToken,
    ViewportMode viewport = ViewportMode.mobile,
  }) async {
    if (state.isGenerating) return;
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final activeProvider = await ref
        .read(apiProviderRepositoryProvider)
        .getActiveProvider();

    if (activeProvider == null) {
      _appendMessage(
        const CanvasMessage(
          role: ChatRole.error,
          text:
              'Belum ada provider aktif. Buka Settings untuk mengonfigurasi API terlebih dahulu.',
        ),
      );
      return;
    }

    // User text menang atas tombol: bila prompt menyebut viewport eksplisit,
    // pakai itu sebagai target (dan sinkronkan tombol agar tidak membingungkan).
    final effectiveViewport = _detectViewportOverride(trimmed) ?? viewport;
    final size = _sizeFor(effectiveViewport);
    final viewportContext =
        '\n\n[CANVAS TARGET] Design for a FIXED viewport width of exactly '
        '${size.width.round()} CSS px (${effectiveViewport.name}). '
        'The layout MUST fit this width with NO horizontal overflow, NO '
        'horizontal scrollbar, and NO clipped text. '
        'Height starts at ${size.height.round()}px but the page may grow '
        'vertically as needed (min-height, natural document flow). '
        'Respect the user-requested style (e.g. minimal stays minimal, but '
        'never empty: keep full structure, real copy, working controls). '
        'Every interactive affordance you draw MUST work with vanilla JS '
        '(toggles, accordions, tabs, menus). Use real imagery with unique '
        'seeds so the page feels alive.';

    final baseText = designToken == null
        ? trimmed
        : '$trimmed\n\n[Design Token: ${designToken.label}] ${designToken.promptFragment}';

    final userText = '$baseText$viewportContext';

    // Lampiran yang dikirim bersama prompt ini.
    final pendingAttachments = state.attachments;

    // Jangan buat frame dulu: kita belum tahu apakah AI akan menjawab teks
    // (chat) atau membuat UI. Frame hanya dibuat setelah balasan terdeteksi UI,
    // supaya board tidak sempat tampil dengan placeholder yang batal.
    // Sinkronkan tombol viewport bila user meng-override via teks.
    state = state.copyWith(
      isGenerating: true,
      generationStartedAt: DateTime.now(),
      status: AiStatus.thinking,
      viewport: effectiveViewport,
      messages: [
        ...state.messages,
        CanvasMessage(
          role: ChatRole.user,
          text: userText,
          // Tampilkan hanya prompt asli user; `[CANVAS TARGET]` dan design token
          // tetap dikirim ke AI tapi tidak ditampilkan di bubble chat.
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
      _setStatus(AiStatus.responding);
      final response = await classifyAiResponseInIsolate(raw);

      // Lampiran sudah terpakai; kosongkan setelah permintaan dikirim.
      state = state.copyWith(attachments: const []);

      if (response.isChat) {
        // Bukan permintaan UI: cukup tampilkan di percakapan, board tak tersentuh.
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

      // Balasan UI: buat satu frame per layar.
      _setStatus(AiStatus.rendering);
      final baseTitle = _titleFromPrompt(trimmed);
      final isFirstOnBoard = state.frames.isEmpty;

      final newFrames = <BoardFrame>[];
      var offset = _nextFrameOffset(size);
      for (var i = 0; i < response.screens.length; i++) {
        final screen = response.screens[i];
        final tree = await buildDomTreeInIsolate(screen.html);
        final frameId = 'frame_${_frameCounter++}';
        final fallbackTitle = response.screens.length > 1
            ? '$baseTitle ${i + 1}'
            : baseTitle;
        final title = _sanitizeScreenTitle(screen.title, fallbackTitle);
        newFrames.add(
          BoardFrame(
            id: frameId,
            title: title,
            html: tree.stampedHtml,
            offset: offset,
            size: size,
            domTree: tree,
            isActive: i == 0,
          ),
        );
        offset = Offset(offset.dx + size.width + _gap, offset.dy);
      }

      final seeded = _normalizeFrames([
        ...state.frames.map((f) => f.copyWith(isActive: false)),
        ...newFrames,
      ]);

      // Catatan penjelasan AI (PART 1) tampil sebagai pesan chat.
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

      state = state.copyWith(
        frames: seeded,
        activeFrameId: newFrames.first.id,
        isGenerating: false,
        clearGenerationStart: true,
        status: AiStatus.idle,
        // Frame pertama di board: pusatkan agar hasilnya langsung terlihat.
        panOffset: isFirstOnBoard ? const Offset(60, 40) : null,
        messages: messages,
      );
    } on ApiConnectionException catch (e) {
      _failGeneration(e.message);
    } catch (e) {
      _failGeneration('Terjadi kesalahan: $e');
    }
  }

  /// Gagal sebelum frame dibuat: cukup tambahkan pesan error ke percakapan.
  void _failGeneration(String message) {
    state = state.copyWith(
      isGenerating: false,
      clearGenerationStart: true,
      status: AiStatus.idle,
    );
    _appendMessage(CanvasMessage(role: ChatRole.error, text: message));
  }

  void _setStatus(AiStatus status) {
    if (state.status == status) return;
    state = state.copyWith(status: status);
  }

  String _titleFromPrompt(String prompt) {
    final cleaned = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'Untitled';
    // Ambil 4 kata pertama agar judul frame pendek dan mudah dipindai.
    // Buang tanda baca trailing agar terlihat seperti judul Figma/Stitch.
    final words = cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(4)
        .join(' ')
        .replaceAll(RegExp(r'[,.:;!?]+$'), '');
    if (words.isEmpty) return 'Untitled';
    final titled = words.length > 32 ? '${words.substring(0, 32).trim()}...' : words;
    // Kapitalisasi huruf pertama tiap kata untuk tampilan frame yang rapi.
    return titled
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Judul layar dari AI hanya dipakai bila pendek dan layak tampil.
  /// Judul panjang (kalimat catatan PART 1) dibuang demi [fallback].
  String _sanitizeScreenTitle(String candidate, String fallback) {
    final cleaned = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return fallback;
    if (cleaned.length > 48 || cleaned.contains('.')) return fallback;
    if (cleaned.split(' ').length > 6) return fallback;
    return cleaned;
  }

  List<Map<String, dynamic>> _buildMessagesPayload({
    List<Attachment> attachments = const [],
  }) {
    final history = state.messages
        .where((m) => m.role != ChatRole.error)
        .toList();

    final payload = <Map<String, dynamic>>[
      {'role': 'system', 'content': uiSystemPrompt},
    ];

    for (var i = 0; i < history.length; i++) {
      final message = history[i];
      final isLastUser =
          i == history.length - 1 && message.role == ChatRole.user;

      if (isLastUser && attachments.isNotEmpty) {
        // Pesan terakhir dari user + lampiran -> bentuk multimodal content.
        payload.add({
          'role': 'user',
          'content': _buildVisionContent(message.text, attachments),
        });
      } else {
        payload.add({
          'role': message.role == ChatRole.user ? 'user' : 'assistant',
          'content': message.text,
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

/// Deteksi viewport yang diminta user dari teks prompt. Top-level (bukan
/// method) agar bisa diuji langsung tanpa ProviderContainer.
///
/// Prioritas:
///  1. Pola eksplisit `viewport: desktop` / `viewport=mobile`.
///  2. Kemunculan device/lebar px yang PALING AKHIR di prompt menang, sehingga
///     "build desktop and mobile version" mengikuti device terakhir.
///
/// Mengembalikan null bila user tidak menyebut apa pun — di situlah tombol
/// viewport dipakai sebagai default/fallback.
ViewportMode? detectViewportOverride(String prompt) {
  final lower = prompt.toLowerCase();

  // 1. Pola paling eksplisit.
  final explicit = RegExp(
    r'viewport\s*[:=]\s*(mobile|tablet|desktop)',
  ).firstMatch(lower);
  if (explicit != null) {
    return ViewportMode.values.byName(explicit.group(1)!);
  }

  // 2. Nama device yang disebut.
  final hits = <int, ViewportMode>{};
  for (final mode in ViewportMode.values) {
    final index = lower.lastIndexOf(mode.name);
    if (index >= 0) hits[index] = mode;
  }

  // 3. Lebar px yang disebut (spesifik).
  void scanPx(String pattern, ViewportMode mode) {
    for (final m in RegExp(pattern).allMatches(lower)) {
      hits[m.start] = mode;
    }
  }

  scanPx(r'\b(1280|1440|1920)(\s*px|p)?\b', ViewportMode.desktop);
  scanPx(r'\b768(\s*px|p)?\b', ViewportMode.tablet);
  scanPx(r'\b(390|375|414|844)(\s*px|p)?\b', ViewportMode.mobile);

  if (hits.isEmpty) return null;
  final lastIndex = hits.keys.reduce((a, b) => a > b ? a : b);
  return hits[lastIndex];
}
