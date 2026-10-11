import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_editor/domain/ai_response.dart';
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
    this.kind = ChatMessageKind.chat,
  });

  final ChatRole role;
  final String text;
  final ChatMessageKind kind;
}

enum ChatMessageKind { chat, ui }

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
    this.boardSize = const Size(1200, 1200),
    this.messages = const [],
    this.isGenerating = false,
    this.selectedToken,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.outputMode = OutputMode.design,
    this.tool = BoardTool.select,
    this.generationStartedAt,
    this.showGrid = true,
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

  /// Ukuran area board (otomatis tumbuh mengikuti frame, tidak pernah menyusut
  /// di bawah konten agar frame tidak "hilang").
  final Size boardSize;

  final List<CanvasMessage> messages;
  final bool isGenerating;
  final DesignTokenPreset? selectedToken;
  final String? selectedNodeId;
  final String? hoveredNodeId;
  final OutputMode outputMode;
  final BoardTool tool;
  final DateTime? generationStartedAt;
  final bool showGrid;

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
    Size? boardSize,
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
  }) {
    return CanvasState(
      frames: frames ?? this.frames,
      activeFrameId: clearActiveFrame
          ? null
          : (activeFrameId ?? this.activeFrameId),
      panOffset: panOffset ?? this.panOffset,
      scale: scale ?? this.scale,
      viewport: viewport ?? this.viewport,
      boardSize: boardSize ?? this.boardSize,
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
    );
  }
}

final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(
  CanvasNotifier.new,
);

class CanvasNotifier extends Notifier<CanvasState> {
  static const double _gap = 80;

  /// Padding di sekeliling konten agar frame tidak menempel di tepi board.
  static const double _boardPadding = 240;

  /// Ukuran minimum area board yang selalu tersedia di sebelah kanan/bawah
  /// frame terakhir (agar "ruang kosong" untuk frame berikutnya).
  static const double _boardRunway = 600;

  int _frameCounter = 0;

  @override
  CanvasState build() => CanvasState(boardSize: _boardSizeFor(const []));

  /// Hitung ukuran board dari bounding box semua frame + padding + runway.
  /// Board selalu tumbuh, tidak pernah menyusut di bawah konten.
  Size _boardSizeFor(List<BoardFrame> frames) {
    if (frames.isEmpty) {
      return const Size(_boardRunway, _boardRunway);
    }

    var maxRight = 0.0;
    var maxBottom = 0.0;
    for (final frame in frames) {
      final right = frame.offset.dx + frame.size.width;
      final bottom = frame.offset.dy + frame.size.height;
      if (right > maxRight) maxRight = right;
      if (bottom > maxBottom) maxBottom = bottom;
    }

    return Size(
      maxRight + _boardPadding + _boardRunway,
      maxBottom + _boardPadding + _boardRunway,
    );
  }

  /// Frame tidak boleh keluar dari batas board; clamp posisinya.
  Offset _clampFrameOffset(Offset offset, Size frameSize, Size boardSize) {
    final maxX = boardSize.width - frameSize.width - 40;
    final maxY = boardSize.height - frameSize.height - 40;
    return Offset(
      offset.dx.clamp(-40.0, maxX < -40 ? -40.0 : maxX),
      offset.dy.clamp(-40.0, maxY < -40 ? -40.0 : maxY),
    );
  }

  /// Terapkan clamp + recompute ukuran board untuk daftar frame.
  List<BoardFrame> _normalizeFrames(List<BoardFrame> frames) {
    var board = _boardSizeFor(frames);
    final normalized = frames
        .map(
          (f) => f.copyWith(
            offset: _clampFrameOffset(f.offset, f.size, board),
          ),
        )
        .toList();
    board = _boardSizeFor(normalized);
    return normalized
        .map(
          (f) => f.copyWith(
            offset: _clampFrameOffset(f.offset, f.size, board),
          ),
        )
        .toList();
  }

  void setViewport(ViewportMode mode) {
    if (mode == state.viewport) return;
    state = state.copyWith(viewport: mode);
    _updateActive((frame) => frame.copyWith(size: _sizeFor(mode)));
  }

  Size _sizeFor(ViewportMode mode) => switch (mode) {
    ViewportMode.mobile => const Size(390, 844),
    ViewportMode.tablet => const Size(820, 1000),
    ViewportMode.desktop => const Size(1280, 900),
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

  /// Clamp pan agar area board tidak bisa hilang sepenuhnya dari layar:
  /// minimal sebagian board selalu terlihat.
  Offset _clampPan(Offset pan, double scale) {
    final boardW = state.boardSize.width * scale;
    final boardH = state.boardSize.height * scale;

    const margin = 120.0;
    final minX = -(boardW - margin);
    final maxX = _viewport.width - margin;
    final minY = -(boardH - margin);
    final maxY = _viewport.height - margin;

    return Offset(
      pan.dx.clamp(minX, maxX < minX ? minX : maxX),
      pan.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  void panBy(Offset delta) {
    state = state.copyWith(
      panOffset: _clampPan(state.panOffset + delta, state.scale),
    );
  }

  void zoomAt(Offset focalScreen, double factor) {
    final newScale = (state.scale * factor).clamp(CanvasState.minScale, CanvasState.maxScale);
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
      boardSize: _boardSizeFor(frames),
    );
  }

  void deleteFrame(String id) {
    final frames = _normalizeFrames(
      state.frames.where((f) => f.id != id).toList(),
    );
    state = state.copyWith(
      frames: frames,
      boardSize: _boardSizeFor(frames),
      clearActiveFrame: state.activeFrameId == id,
      clearSelection: true,
    );
  }

  void clearBoard() {
    _frameCounter = 0;
    state = state.copyWith(
      frames: const [],
      boardSize: _boardSizeFor(const []),
      messages: const [],
      isGenerating: false,
      clearActiveFrame: true,
      clearSelection: true,
      clearHover: true,
      clearGenerationStart: true,
    );
  }

  void _updateActive(BoardFrame Function(BoardFrame) transform) {
    final id = state.activeFrameId;
    if (id == null) return;
    final frames = _normalizeFrames(
      state.frames.map((f) => f.id == id ? transform(f) : f).toList(),
    );
    state = state.copyWith(
      frames: frames,
      boardSize: _boardSizeFor(frames),
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

    final userText = designToken == null
        ? trimmed
        : '$trimmed\n\n[Design Token: ${designToken.label}] ${designToken.promptFragment}';

    // Jangan buat frame dulu: kita belum tahu apakah AI akan menjawab teks
    // (chat) atau membuat UI. Frame hanya dibuat setelah balasan terdeteksi UI,
    // supaya board tidak sempat tampil dengan placeholder yang batal.
    state = state.copyWith(
      isGenerating: true,
      generationStartedAt: DateTime.now(),
      messages: [
        ...state.messages,
        CanvasMessage(role: ChatRole.user, text: userText),
      ],
    );

    try {
      final payload = _buildMessagesPayload();
      final raw = await ref
          .read(aiApiServiceProvider)
          .generateUI(provider: activeProvider, messages: payload);
      final response = await classifyAiResponseInIsolate(raw);

      if (response.isChat) {
        // Bukan permintaan UI: cukup tampilkan di percakapan, board tak tersentuh.
        state = state.copyWith(
          isGenerating: false,
          clearGenerationStart: true,
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

      // Balasan UI: baru sekarang buat frame-nya di board.
      final tree = await buildDomTreeInIsolate(response.html!);
      final frameId = 'frame_${_frameCounter++}';
      final size = _sizeFor(viewport);
      final frame = BoardFrame(
        id: frameId,
        title: _titleFromPrompt(trimmed),
        html: tree.stampedHtml,
        offset: _nextFrameOffset(size),
        size: size,
        domTree: tree,
        isActive: true,
      );

      final seeded = _normalizeFrames([
        ...state.frames.map((f) => f.copyWith(isActive: false)),
        frame,
      ]);

      state = state.copyWith(
        frames: seeded,
        boardSize: _boardSizeFor(seeded),
        activeFrameId: frameId,
        isGenerating: false,
        clearGenerationStart: true,
        // Frame pertama: pusatkan board agar hasilnya langsung terlihat.
        panOffset: state.frames.isEmpty ? const Offset(60, 40) : null,
        messages: [
          ...state.messages,
          CanvasMessage(
            role: ChatRole.assistant,
            kind: ChatMessageKind.ui,
            text: response.html!,
          ),
        ],
      );
    } on ApiConnectionException catch (e) {
      _failGeneration(e.message);
    } catch (e) {
      _failGeneration('Terjadi kesalahan: $e');
    }
  }

  /// Gagal sebelum frame dibuat: cukup tambahkan pesan error ke percakapan.
  void _failGeneration(String message) {
    state = state.copyWith(isGenerating: false, clearGenerationStart: true);
    _appendMessage(CanvasMessage(role: ChatRole.error, text: message));
  }

  String _titleFromPrompt(String prompt) {
    final cleaned = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'Untitled';
    final words = cleaned.split(' ').take(5).join(' ');
    return words.length > 42 ? '${words.substring(0, 42)}...' : words;
  }

  List<Map<String, dynamic>> _buildMessagesPayload() {
    return [
      {'role': 'system', 'content': uiSystemPrompt},
      ...state.messages
          .where((m) => m.role != ChatRole.error)
          .map(
            (m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.text,
            },
          ),
    ];
  }

  void _appendMessage(CanvasMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }
}
