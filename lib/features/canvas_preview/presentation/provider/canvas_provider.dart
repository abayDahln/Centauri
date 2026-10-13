import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_editor/domain/ai_response.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../../prompt_editor/presentation/preset_provider.dart';
import '../../../provider_config/data/datasources/ai_api_service.dart';
import '../../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../data/services/canvas_webview_service.dart';
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
    this.selectedNodeGeometry,
    this.outputMode = OutputMode.design,
    this.tool = BoardTool.select,
    this.generationStartedAt,
    this.showGrid = true,
    this.snapEnabled = true,
    this.snapGuidesX = const [],
    this.snapGuidesY = const [],
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
  /// Cache tampilan untuk overlay native (bbox CSS + computed style).
  /// HTML di WebView tetap source of truth.
  final NodeGeometry? selectedNodeGeometry;
  final OutputMode outputMode;
  final BoardTool tool;
  final DateTime? generationStartedAt;
  final bool showGrid;

  /// Smart snapping (Fase 2, board-level): snap frame ke grid + tepi frame
  /// lain. Guide digambar sebagai garis merah di board (koordinat board).
  final bool snapEnabled;
  final List<double> snapGuidesX;
  final List<double> snapGuidesY;

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
    NodeGeometry? selectedNodeGeometry,
    bool clearGeometry = false,
    OutputMode? outputMode,
    BoardTool? tool,
    DateTime? generationStartedAt,
    bool clearGenerationStart = false,
    bool? showGrid,
    bool? snapEnabled,
    List<double>? snapGuidesX,
    List<double>? snapGuidesY,
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
      selectedNodeGeometry: clearGeometry
          ? null
          : (selectedNodeGeometry ?? this.selectedNodeGeometry),
      outputMode: outputMode ?? this.outputMode,
      tool: tool ?? this.tool,
      generationStartedAt: clearGenerationStart
          ? null
          : (generationStartedAt ?? this.generationStartedAt),
      showGrid: showGrid ?? this.showGrid,
      snapEnabled: snapEnabled ?? this.snapEnabled,
      snapGuidesX: snapGuidesX ?? this.snapGuidesX,
      snapGuidesY: snapGuidesY ?? this.snapGuidesY,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }
}

final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(
  CanvasNotifier.new,
);

/// Snapshot immutable untuk undo/redo (Fase 5).
/// Hanya menyimpan referensi list (copy-on-write), jadi murah.
@immutable
class CanvasSnapshot {
  const CanvasSnapshot({
    required this.frames,
    required this.messages,
    required this.activeFrameId,
  });

  final List<BoardFrame> frames;
  final List<CanvasMessage> messages;
  final String? activeFrameId;

  static CanvasSnapshot of(CanvasState state) => CanvasSnapshot(
    frames: state.frames,
    messages: state.messages,
    activeFrameId: state.activeFrameId,
  );

  bool contentEquals(CanvasSnapshot other) =>
      identical(frames, other.frames) &&
      identical(messages, other.messages) &&
      activeFrameId == other.activeFrameId;
}

class CanvasNotifier extends Notifier<CanvasState> {
  static const double _gap = 80;
  /// frame terakhir (agar "ruang kosong" untuk frame berikutnya).

  int _frameCounter = 0;

  // ------------------------------------------------------- undo / redo (5a) --
  static const int _historyLimit = 60;
  final List<CanvasSnapshot> _undoStack = [];
  final List<CanvasSnapshot> _redoStack = [];
  CanvasSnapshot? _lastRecorded;
  bool _applyingHistory = false;

  /// Clipboard internal untuk copy/paste node (single node).
  NodeGeometry? _clipboard;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoDepth => _undoStack.length;
  int get redoDepth => _redoStack.length;

  @override
  CanvasState build() {
    // Baseline awal belum "tercatat" (null) agar perubahan pertama dari
    // board kosong tetap bisa di-undo/di-record.
    _lastRecorded = null;
    return const CanvasState();
  }

  /// Dipanggil dari UI setelah ada perubahan board: dorong snapshot SEBELUM
  /// perubahan ([previous]) ke stack undo bila kontennya berbeda dari
  /// snapshot terakhir yang tercatat.
  void recordHistory(CanvasState previous) {
    if (_applyingHistory) return;
    final snapshot = CanvasSnapshot.of(previous);
    if (_lastRecorded != null && _lastRecorded!.contentEquals(snapshot)) {
      // Konten sebelumnya sudah jadi baseline; perbarui baseline ke state
      // sekarang agar perubahan berikutnya tetap terdeteksi.
      _lastRecorded = CanvasSnapshot.of(state);
      return;
    }
    _undoStack.add(snapshot);
    if (_undoStack.length > _historyLimit) _undoStack.removeAt(0);
    _redoStack.clear();
    _lastRecorded = CanvasSnapshot.of(state);
  }

  /// Simpan snapshot saat ini secara eksplisit (mis. sebelum edit inline yang
  /// tidak lewat provider). [snapshot] biasanya diambil dari state sekarang.
  void pushUndoSnapshot() {
    final snapshot = CanvasSnapshot.of(state);
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
    _redoStack.add(CanvasSnapshot.of(state));
    _applySnapshot(target);
    return true;
  }

  bool redo() {
    if (_redoStack.isEmpty) return false;
    final target = _redoStack.removeLast();
    _undoStack.add(CanvasSnapshot.of(state));
    _applySnapshot(target);
    return true;
  }

  void _applySnapshot(CanvasSnapshot snapshot) {
    _applyingHistory = true;
    state = state.copyWith(
      frames: snapshot.frames,
      messages: snapshot.messages,
      activeFrameId: snapshot.activeFrameId,
      clearActiveFrame: snapshot.activeFrameId == null,
      clearSelection: true,
      clearGeometry: true,
      snapGuidesX: const [],
      snapGuidesY: const [],
    );
    _lastRecorded = snapshot;
    _applyingHistory = false;
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _lastRecorded = CanvasSnapshot.of(state);
  }

  // ------------------------------------------------------- clipboard (5a) --

  /// Salin geometri node terpilih ke clipboard internal.
  bool copySelectedNode() {
    final geometry = state.selectedNodeGeometry;
    if (geometry == null) return false;
    _clipboard = geometry;
    return true;
  }

  bool get hasClipboard => _clipboard != null;

  /// Tempel node yang disalin sebagai duplikat via HTML (perlu service JS).
  /// Mengembalikan id node sumber + patch gaya untuk ditempel bila ada.
  NodeGeometry? get clipboard => _clipboard;


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

  void toggleSnap() => state = state.copyWith(snapEnabled: !state.snapEnabled);

  /// Dipanggil saat drag frame selesai: bersihkan garis panduan.
  void endFrameDrag() {
    if (state.snapGuidesX.isEmpty && state.snapGuidesY.isEmpty) return;
    state = state.copyWith(snapGuidesX: const [], snapGuidesY: const []);
  }

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
      state = state.copyWith(
        clearActiveFrame: true,
        clearSelection: true,
        clearGeometry: true,
      );
      return;
    }
    final frames = state.frames
        .map((f) => f.copyWith(isActive: f.id == id))
        .toList();
    state = state.copyWith(
      frames: frames,
      activeFrameId: id,
      clearGeometry: state.activeFrameId != id,
    );
  }

  void moveFrame(String id, Offset delta) {
    final target = state.frames.where((f) => f.id == id).firstOrNull;
    if (target == null) return;
    var next = target.offset + delta;
    List<double> guidesX = const [];
    List<double> guidesY = const [];

    // Smart snapping board-level (Fase 2): grid 8px + tepi/tengah frame lain.
    // Murni hitungan Dart dari offset/size frame — tanpa layout engine.
    if (state.snapEnabled) {
      const threshold = 10.0;
      const grid = 8.0;
      var nx = next.dx;
      var ny = next.dy;

      // 1. Snap ke grid.
      final gridX = (nx / grid).round() * grid;
      final gridY = (ny / grid).round() * grid;
      if ((gridX - nx).abs() <= threshold) {
        nx = gridX;
      }
      if ((gridY - ny).abs() <= threshold) {
        ny = gridY;
      }

      // 2. Snap ke frame lain (kiri/tengah/kanan, atas/tengah/bawah).
      final w = target.size.width;
      final h = target.size.height;
      final candX = [nx, nx + w / 2, nx + w];
      final candY = [ny, ny + h / 2, ny + h];
      double? bestDx;
      double? bestGuideX;
      double? bestDy;
      double? bestGuideY;

      for (final other in state.frames) {
        if (other.id == id) continue;
        final ox = [other.offset.dx, other.offset.dx + other.size.width / 2,
          other.offset.dx + other.size.width];
        final oy = [other.offset.dy, other.offset.dy + other.size.height / 2,
          other.offset.dy + other.size.height];
        for (final c in candX) {
          for (final o in ox) {
            final d = o - c;
            if (d.abs() <= threshold &&
                (bestDx == null || d.abs() < bestDx.abs())) {
              bestDx = d;
              bestGuideX = o;
            }
          }
        }
        for (final c in candY) {
          for (final o in oy) {
            final d = o - c;
            if (d.abs() <= threshold &&
                (bestDy == null || d.abs() < bestDy.abs())) {
              bestDy = d;
              bestGuideY = o;
            }
          }
        }
      }

      if (bestDx != null) {
        nx += bestDx;
        guidesX = [bestGuideX!];
      }
      if (bestDy != null) {
        ny += bestDy;
        guidesY = [bestGuideY!];
      }
      next = Offset(nx, ny);
    }

    final moved = state.frames
        .map((f) => f.id == id ? f.copyWith(offset: next) : f)
        .toList();
    final frames = _normalizeFrames(moved);
    state = state.copyWith(
      frames: frames,
      snapGuidesX: guidesX,
      snapGuidesY: guidesY,
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

  /// Sinkronisasi ulang HTML frame pasca-mutasi eksternal (MCP bridge, Fase 4).
  /// [stampedHtml] harus sudah melalui `buildDomTreeInIsolate` agar id stabil.
  /// Meminta geometri ulang node terpilih bila masih ada di tree baru.
  void updateFrameHtml({
    required String frameId,
    required String stampedHtml,
    required DomTreeResult tree,
  }) {
    final frames = state.frames.map((f) {
      if (f.id != frameId) return f;
      return f.copyWith(html: stampedHtml, domTree: tree);
    }).toList();
    // Seleksi yang hilang dari tree baru dibersihkan.
    final selectedId = state.selectedNodeId;
    final keepSelection = selectedId != null && tree.findById(selectedId) != null;
    state = state.copyWith(
      frames: frames,
      clearSelection: !keepSelection && selectedId != null,
      clearGeometry: true,
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

  /// Konteks node terpilih untuk inline edit (Fase 4).
  /// Disisipkan ke prompt internal (tidak tampil di bubble chat) agar AI tahu
  /// elemen mana yang dimaksud ("ubah tombol ini...").
  /// Memakai cache Dart (tag, bbox, computed style) — tanpa round-trip JS.
  String _selectedNodeContext() {
    final nodeId = state.selectedNodeId;
    final geometry = state.selectedNodeGeometry;
    final frame = state.activeFrame;
    if (nodeId == null || geometry == null || frame == null) return '';
    return buildSelectedNodeContext(
      geometry: geometry,
      frameTitle: frame.title,
    );
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
      state = state.copyWith(clearSelection: true, clearGeometry: true);
      return;
    }
    // Node baru: geometri lama dibuang agar overlay tidak gambar box basi
    // sebelum event `geometry` dari JS tiba.
    if (id == state.selectedNodeId) return;
    state = state.copyWith(selectedNodeId: id, clearGeometry: true);
  }

  void selectNodeFromCanvas(String? id) => selectNode(id);

  /// Update cache geometri dari event `geometry` JS bridge.
  /// Diabaikan bila id tidak cocok dengan seleksi aktif (race antar frame).
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

    // Lampiran yang dikirim bersama prompt ini.
    final pendingAttachments = state.attachments;

    // Sapaan / obrolan biasa JANGAN ditempeli [CANVAS TARGET] + design token.
    // Konteks itu ("Design for a FIXED viewport...", "Every affordance MUST
    // work...") terbaca model sebagai instruksi UI dan mengalahkan MODE GATE
    // di system prompt, sehingga "hello" pun dibalas dengan ```html + frame.
    // Hanya permintaan UI eksplisit yang boleh membawa konteks canvas.
    final wantsUi = isUiRequestPrompt(
      trimmed,
      hasAttachments: pendingAttachments.isNotEmpty,
      hasSelectedNode:
          state.selectedNodeId != null && state.selectedNodeGeometry != null,
    );

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

    final baseText = designToken == null || !wantsUi
        ? trimmed
        : '$trimmed\n\n[Design Token: ${designToken.label}] ${designToken.promptFragment}';

    final userText = wantsUi
        ? '$baseText$viewportContext${_selectedNodeContext()}'
        : baseText;

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
      // Bila user menekan Stop saat menunggu, hasil yang telat diabaikan.
      if (!state.isGenerating) return;
      _setStatus(AiStatus.responding);
      final response = await classifyAiResponseInIsolate(raw);

      // Bila dibatalkan saat parsing/klasifikasi, jangan lanjut render.
      if (!state.isGenerating) return;

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
      // Force-stop via cancel dianggap normal, bukan error yang ditampilkan.
      if (e.message == '__CANCELLED__') {
        _cancelGeneration(promptWasDiscarded: true);
        return;
      }
      // Jangan timpa pesan error bila generate sudah dibatalkan user.
      if (!state.isGenerating) return;
      _failGeneration(e.message);
    } catch (e) {
      if (!state.isGenerating) return;
      _failGeneration('Terjadi kesalahan: $e');
    }
  }

  /// Hentikan generate yang sedang berjalan (tombol Stop).
  /// Membatalkan request HTTP + baca body, dan menandai status idle.
  void cancelGeneration() {
    if (!state.isGenerating) return;
    AiApiService.cancelAll();
    _cancelGeneration(promptWasDiscarded: true);
  }

  /// Bersihkan status generate tanpa menampilkan error (dipakai cancel).
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
          text: 'Generasi dihentikan.',
        ),
      );
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

    // Fase 4: system prompt bisa di-override pengguna (Custom Bebas).
    final systemPrompt = ref.read(presetProvider).effectiveSystemPrompt;

    final payload = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
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

/// Blok konteks node terpilih untuk inline edit (Fase 4, top-level agar
/// bisa diuji langsung tanpa ProviderContainer).
/// Mengembalikan string kosong bila tidak ada seleksi valid.
String buildSelectedNodeContext({
  required NodeGeometry geometry,
  required String frameTitle,
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
  return '\n\n[SELECTED NODE] The user has selected an element in frame '
      '"$frameTitle". Target primarily THIS element (keep the rest of the page '
      'consistent unless the request says otherwise). '
      'tag=<${geometry.tag}> '
      'box=${geometry.width.toStringAsFixed(0)}x'
      '${geometry.height.toStringAsFixed(0)}px '
      'at (${geometry.x.toStringAsFixed(0)},'
      '${geometry.y.toStringAsFixed(0)})'
      '${styleBits.isEmpty ? '' : ' styles=[$styleBits]'}.';
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

/// Heuristik MODE GATE sisi klien: apakah prompt user benar-benar meminta UI?
/// Top-level agar bisa diuji langsung tanpa ProviderContainer.
///
/// Aturan:
/// - Sapaan / small talk / pertanyaan singkat TANPA kata kerja UI
///   ("hello", "halo", "makasih", "apa kabar?") -> false.
/// - Mengandung kata kerja / kata benda UI eksplisit ("buatkan landing page",
///   "redesign dashboard", "ubah tombol ini", "tambah form login") -> true.
/// - Menyebut viewport/px ("mobile", "390px") atau melampirkan file dengan
///   instruksi rebuild ("replicate screenshot ini") -> true.
/// - Node terpilih saja TIDAK cukup; harus ada kata edit ("ubah", "ganti",
///   "pindah", "perbesar", dst.) agar "hello" dengan seleksi tidak jadi UI.
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
  // "selamat pagi/siang/sore/malam" + variasi pendek (< 24 char, tanpa kata UI).
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
  ];
  bool containsWord(String src, String word) {
    if (word.startsWith(r'\b')) {
      return RegExp(word).hasMatch(src);
    }
    // Kata kerja: cocok sebagai awalan kata (buat, buatkan, buatin...).
    return RegExp('\\b${RegExp.escape(word)}\\w*').hasMatch(src);
  }

  final hasVerb = uiVerbs.any((w) => containsWord(lower, w));
  final hasNoun = uiNouns.any((w) => containsWord(lower, w));
  if (hasVerb || hasNoun) return true;

  // 3. Menyebut target kanvas eksplisit -> hampir pasti ingin UI.
  if (detectViewportOverride(prompt) != null) return true;

  // 4. Lampiran + instruksi visual ("screenshot ini", "gambar ini" + kata kerja
  // di atas sudah true). Lampiran saja tanpa kata UI -> chat (analisa/feedback).
  if (hasAttachments) return false;

  // 5. Node terpilih saja tanpa kata edit -> chat.
  if (hasSelectedNode) return false;

  // 6. Default: pesan pendek tanpa sinyal UI -> chat (sesuai MODE GATE:
  // "when in doubt, choose MODE A").
  return false;
}
