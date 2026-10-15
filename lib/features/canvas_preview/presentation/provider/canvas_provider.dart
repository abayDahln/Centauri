import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_editor/domain/ai_response.dart';
import '../../../prompt_editor/domain/attachment.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../../provider_config/data/datasources/ai_api_service.dart';
import '../../../provider_config/domain/entities/api_provider.dart';
import '../../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../domain/board_frame.dart';
import '../../domain/dom_tree.dart';
import '../../domain/viewport_mode.dart';

enum ChatRole { user, assistant, error }

/// Mode tampilan area kerja.
enum OutputMode { design, dev }

/// Alat aktif di board (mirip toolbar Figma/Stitch).
enum BoardTool { select, hand }

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
  /// Dipakai agar konteks internal (mis. `[CANVAS TARGET]`)
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
    this.messages = const [],
    this.isGenerating = false,
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

  final List<CanvasMessage> messages;
  final bool isGenerating;
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
    List<CanvasMessage>? messages,
    bool? isGenerating,
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

  /// Board kini tak terbatas, jadi frame tidak dibatasi posisinya.
  /// Dibiarkan sebagai hook agar mudah menambah aturan bila perlu.
  List<BoardFrame> _normalizeFrames(List<BoardFrame> frames) => frames;

  /// Sesuaikan lebar frame secara manual (resize handle di sisi frame).
  /// WebView viewport otomatis me-reflow layout secara responsif.
  /// Ukuran awal frame sepenuhnya ditentukan AI (auto-layout / prompt user).
  void setFrameWidth(String id, double widthPx) {
    const minWidth = 280.0;
    const maxWidth = 3840.0;
    final clamped = widthPx.clamp(minWidth, maxWidth);
    final frames = state.frames.map((f) {
      if (f.id != id) return f;
      return f.copyWith(size: Size(clamped, f.size.height));
    }).toList();
    state = state.copyWith(frames: frames);
  }

  /// Jika user menyebut viewport secara eksplisit di prompt ("mobile",
  /// "tablet", "desktop", "viewport: ...", "390px", "768px", "1280px"),
  /// itu dipakai langsung. Bila tidak menyebut apa pun, AI memilih otomatis
  /// via [detectAutoViewport].
  ViewportMode? _detectViewportOverride(String prompt) =>
      detectViewportOverride(prompt);

  Size _sizeFor(ViewportMode mode) => switch (mode) {
    // Lebar tetap (fixed) agar konsisten; tinggi lega agar konten muat
    // tanpa scrollbar di dalam frame.
    ViewportMode.mobile => const Size(390, 844),
    ViewportMode.tablet => const Size(768, 1024),
    ViewportMode.desktop => const Size(1280, 800),
    ViewportMode.hd => const Size(1920, 1080),
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

  /// Geser board sebesar [delta] **dalam piksel layar**.
  /// Delta dipakai apa adanya (pan adalah offset layar), jadi scroll wheel,
  /// drag, maupun pan programatik semuanya konsisten di semua tingkat zoom.
  void panBy(Offset delta) {
    if (delta == Offset.zero) return;
    state = state.copyWith(
      panOffset: _clampPan(state.panOffset + delta, state.scale),
    );
  }

  /// Zoom di sekitar titik [focalScreen] (koordinat layar) sebesar [factor].
  ///
  /// Titik board di bawah kursor dipertahankan tepat di bawah kursor. Pan
  /// di-clamp HANYA sebagai jaring pengaman (agar konten tak hilang), dan
  /// clamping dilakukan setelah fokus dihitung sehingga tidak "merusak" fokus
  /// selama konten masih dalam batas wajar.
  void zoomAt(Offset focalScreen, double factor) {
    if (factor <= 0 || !factor.isFinite) return;
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

  /// Zoom **relatif** dari tombol +/- dan hotkey.
  ///
  /// Jangkar zoom = pusat **frame aktif** (bila ada), bukan pusat viewport.
  /// Ini membuat frame yang sedang dilihat tetap di tempatnya saat zoom,
  /// bukan tergelincir ke arah tengah layar (bug "frame berpindah saat zoom").
  /// Bila tak ada frame aktif, jangkar ke pusat viewport.
  void zoomBy(double factor) {
    if (factor <= 0 || !factor.isFinite) return;
    final focal = _zoomFocalScreen();
    zoomAt(focal, factor);
  }

  /// Titik jangkar (koordinat layar) untuk zoom tombol/hotkey.
  Offset _zoomFocalScreen() {
    final frame = state.activeFrame;
    if (frame != null) {
      // Pusat frame aktif di layar.
      final cx = frame.offset.dx + frame.size.width / 2;
      final cy = frame.offset.dy + frame.size.height / 2;
      return Offset(
        cx * state.scale + state.panOffset.dx,
        cy * state.scale + state.panOffset.dy,
      );
    }
    return Offset(_viewport.width / 2, _viewport.height / 2);
  }

  /// Pan + zoom sekaligus dalam SATU update state (dipakai gesture pinch).
  ///
  /// Menggabungkan keduanya menghindari dua rebuild berturut-turut yang
  /// membuat frame/grid "bergetar" saat mencubit. [focalScreen] adalah titik
  /// jangkar (koordinat layar); [panDelta] pergeseran layar; [scaleFactor]
  /// faktor zoom relatif.
  void panAndZoomAt(
    Offset focalScreen, {
    Offset panDelta = Offset.zero,
    double scaleFactor = 1.0,
  }) {
    final hasZoom = scaleFactor != 1.0 && scaleFactor > 0 && scaleFactor.isFinite;
    if (!hasZoom && panDelta == Offset.zero) return;

    final newScale = hasZoom
        ? (state.scale * scaleFactor).clamp(
            CanvasState.minScale,
            CanvasState.maxScale,
          )
        : state.scale;

    if (newScale == state.scale) {
      // Hanya pan: fokus tidak relevan, cukup geser.
      if (panDelta != Offset.zero) {
        state = state.copyWith(
          panOffset: _clampPan(state.panOffset + panDelta, state.scale),
        );
      }
      return;
    }

    // Titik board di bawah fokus, lalu re-posisi dengan skala baru + delta pan.
    final boardPoint = (focalScreen - state.panOffset) / state.scale;
    final newPan = focalScreen + panDelta - boardPoint * newScale;

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
  /// Lebar tetap (FIXED sesuai viewport); tinggi mengikuti tinggi dokumen
  /// konten agar frame PAS dengan UI (tidak ada ruang kosong di bawah).
  ///
  /// Boleh tumbuh DAN menyusut. Histeresis 4px meredam perubahan kecil supaya
  /// frame tidak "bergetar" saat font/gambar selesai dimuat. Dulu grow-only,
  /// yang membuat frame selalu setinggi viewport (mis. 844px) walau kontennya
  /// lebih pendek → terlihat ada area kosong di bawah (bug laporan user).
  void setFrameContentHeight(String id, double contentHeight) {
    const minHeight = 120.0;
    const maxHeight = 6000.0;
    const hysteresis = 4.0;
    final height = contentHeight.clamp(minHeight, maxHeight);
    final frames = state.frames.map((f) {
      if (f.id != id) return f;
      // Beri sedikit ruang ekstra agar tepi konten tidak mepet.
      final target = height + 2;
      if ((target - f.size.height).abs() <= hysteresis) return f;
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
  /// Layout sepenuhnya otomatis: bila user menyebut device/ukuran di prompt
  /// ("mobile", "tablet", "desktop", "390px", ...) itu dipakai; bila tidak,
  /// AI memilih layout terbaik via [detectAutoViewport] + deklarasi
  /// `<meta name="viewport-target">` di HTML. Tidak ada toggle manual.
  /// Gaya desain ditulis langsung di prompt oleh user, atau direkomendasikan
  /// AI sebagai design partner — tidak ada preset token manual.
  Future<void> submitPrompt(String prompt) async {
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

    // Sapaan / obrolan biasa JANGAN ditempeli [CANVAS TARGET].
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

    // Full otomatis ala Google Stitch: prompt user menang bila eksplisit,
    // selebihnya AI memilih layout terbaik dari semantik prompt.
    final explicitViewport = _detectViewportOverride(trimmed);
    final effectiveViewport =
        explicitViewport ?? detectAutoViewport(trimmed);
    final size = _sizeFor(effectiveViewport);
    // Multi-screen: bila user meminta beberapa layar (mis. "login, home sampai
    // profile", "5 screens"), tegaskan jumlah + format per-blok agar model tidak
    // menggabung semuanya ke satu dokumen. Pipeline sudah membuat 1 frame per
    // blok ```html (lihat _nextFrameOffset/cascade di bawah).
    final screenReq = detectScreenRequest(trimmed);
    final multiContext = screenReq.count > 1 || screenReq.names.length > 1
        ? '\n\n[OUTPUT FORMAT — MUST FOLLOW EXACTLY] The user asked for '
              '${screenReq.count} screens'
              '${screenReq.names.isEmpty ? '' : ' (${screenReq.names.join(', ')})'}. '
              'This is a HARD requirement, not a suggestion. Follow these steps:\n'
              '1. Output EXACTLY ${screenReq.count} separate ```html fenced code blocks.\n'
              '2. Each block is ONE complete self-contained HTML document for ONE screen only.\n'
              '3. Order: ${screenReq.names.isEmpty ? 'plan the screens yourself and keep that order' : screenReq.names.join(' -> ')}.\n'
              '4. Before each block, write a one-line heading with the screen name (e.g. `### Home`).\n'
              '5. FORBIDDEN: merging screens into one document (e.g. one app with tab switching '
              'between login/home/profile). FORBIDDEN: tab bars, nav links, or JS view-switching '
              'used as a substitute for separate documents. Each screen lives in its OWN block.\n'
              '6. If you output only ONE ```html block for this request, the task FAILS — '
              'do not do that. Two screens still means TWO separate blocks; '
              'never merge them into one document with in-page navigation.\n'
              'Example skeleton:\n'
              '### Login\n'
              '```html\n'
              '<!DOCTYPE html>...login screen only...\n'
              '```\n'
              '### Home\n'
              '```html\n'
              '<!DOCTYPE html>...home screen only...\n'
              '```'
        : '';

    final String viewportInstruction;
    if (explicitViewport != null) {
      viewportInstruction =
          '[USER TARGET VIEWPORT] The user explicitly requested layout: '
          '${size.width.round()} CSS px (${effectiveViewport.label}). '
          'You MUST design for this viewport width with ZERO horizontal overflow.';
    } else {
      viewportInstruction =
          '[AUTONOMOUS VIEWPORT SELECTION (GOOGLE STITCH)] '
          'Autonomously determine the best layout format based on the design context: '
          'mobile (390px) for phone apps/social/chat; tablet (768px) for POS/kiosk/restaurant menu; '
          'desktop (1280px) for SaaS/landing page/web apps/portals; hd (1920px) for wide analytics/dashboards/presentations. '
          'Recommended initial format: ${effectiveViewport.label} (${size.width.round()}px). '
          'Declare your chosen viewport in <head> as: <meta name="viewport-target" content="${effectiveViewport.name}">.';
    }

    final viewportContext =
        '\n\n$viewportInstruction '
        'The layout MUST be fully fluid and responsive (using modern flexbox/grid, percentage/fluid widths, and media queries) '
        'fitting this width with ZERO horizontal overflow and NO horizontal scrollbars, and dynamically adapting if resized. '
        'Height starts at ${size.height.round()}px (min-height: 100vh) and grows vertically with natural document flow. '
        'Sections must hug their content (no empty spacer divs, no blank bands, footer directly after the last section). '
        'Ensure real interactive vanilla JS controls, crisp high-DPI/HD open-source imagery, and inline SVG icons.'
        '$multiContext';

    final userText = wantsUi
        ? '$trimmed$viewportContext${_selectedNodeContext()}'
        : trimmed;

    // Jangan buat frame dulu: kita belum tahu apakah AI akan menjawab teks
    // (chat) atau membuat UI. Frame hanya dibuat setelah balasan terdeteksi UI,
    // supaya board tidak sempat tampil dengan placeholder yang batal.
    state = state.copyWith(
      isGenerating: true,
      generationStartedAt: DateTime.now(),
      status: AiStatus.thinking,
      messages: [
        ...state.messages,
        CanvasMessage(
          role: ChatRole.user,
          text: userText,
          // Tampilkan hanya prompt asli user; `[CANVAS TARGET]`
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

      final firstOffset = _nextFrameOffset(size);
      var newFrames = await _buildFramesFromScreens(
        screens: response.screens,
        explicitViewport: explicitViewport,
        effectiveViewport: effectiveViewport,
        baseTitle: baseTitle,
        startOffset: firstOffset,
      );

      // Bila dibatalkan saat build tree, jangan lanjut render.
      if (!state.isGenerating) return;

      // Catatan penjelasan AI (PART 1) + dokumen hasil masuk riwayat.
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

      // AI menggabung layar yang diminta terpisah ke 1 dokumen: JANGAN bebani
      // user untuk prompt ulang — app berinisiatif memecah otomatis dengan
      // satu follow-up call memakai dokumen gabungan sebagai konteks.
      if (screenReq.count > 1 && response.screens.length == 1) {
        final split = await _autoSplitMerged(
          screenReq: screenReq,
          activeProvider: activeProvider,
          explicitViewport: explicitViewport,
          effectiveViewport: effectiveViewport,
          baseTitle: baseTitle,
          startOffset: firstOffset,
          historyBeforeSplit: messages,
        );
        if (split != null && split.length > 1) {
          // Sukses: pesan follow-up + hasil pecahan sudah di-commit di dalam.
          newFrames = split;
        } else {
          // Dibatalkan saat split: hormati Stop, jangan commit apa pun lagi.
          if (!state.isGenerating) return;
          state = state.copyWith(
            messages: [
              ...messages,
              CanvasMessage(
                role: ChatRole.assistant,
                kind: ChatMessageKind.chat,
                text: _splitFallbackNote(screenReq),
              ),
            ],
          );
        }
      } else {
        state = state.copyWith(messages: messages);
      }

      final seeded = _normalizeFrames([
        ...state.frames.map((f) => f.copyWith(isActive: false)),
        ...newFrames,
      ]);

      state = state.copyWith(
        frames: seeded,
        activeFrameId: newFrames.first.id,
        isGenerating: false,
        clearGenerationStart: true,
        status: AiStatus.idle,
        // Frame pertama di board: pusatkan agar hasilnya langsung terlihat.
        panOffset: isFirstOnBoard ? const Offset(60, 40) : null,
        messages: state.messages,
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

  /// Bangun [BoardFrame] dari daftar layar AI mulai di [startOffset].
  /// Satu layar = satu frame. Id selalu unik via [_frameCounter].
  Future<List<BoardFrame>> _buildFramesFromScreens({
    required List<UiScreen> screens,
    required ViewportMode? explicitViewport,
    required ViewportMode effectiveViewport,
    required String baseTitle,
    required Offset startOffset,
  }) async {
    final frames = <BoardFrame>[];
    var offset = startOffset;
    for (var i = 0; i < screens.length; i++) {
      final screen = screens[i];
      final tree = await buildDomTreeInIsolate(screen.html);
      final frameId = 'frame_${_frameCounter++}';
      final fallbackTitle = screens.length > 1
          ? '$baseTitle ${i + 1}'
          : baseTitle;
      final title = _sanitizeScreenTitle(screen.title, fallbackTitle);

      // Ukuran frame ditentukan oleh: instruksi eksplisit user -> deklarasi otonom AI -> deteksi prompt
      final aiDeclared = detectViewportFromHtml(screen.html);
      final screenViewport = explicitViewport ?? aiDeclared ?? effectiveViewport;
      final screenSize = _sizeFor(screenViewport);

      frames.add(
        BoardFrame(
          id: frameId,
          title: title,
          html: tree.stampedHtml,
          offset: offset,
          size: screenSize,
          domTree: tree,
          isActive: i == 0,
        ),
      );
      offset = Offset(offset.dx + screenSize.width + _gap, offset.dy);
    }
    return frames;
  }

  /// Pecah otomatis dokumen gabungan menjadi frame terpisah TANPA user
  /// mengetik ulang: satu follow-up call memakai dokumen gabungan + riwayat
  /// sebagai konteks. Meng-commit pesan follow-up + hasil ke state bila
  /// berhasil (atau bila model tetap menggabung). Mengembalikan daftar frame
  /// pecahan, atau null bila dibatalkan / gagal (caller pakai hasil gabungan
  /// + catatan singkat sebagai fallback).
  Future<List<BoardFrame>?> _autoSplitMerged({
    required ({int count, List<String> names}) screenReq,
    required ApiProvider activeProvider,
    required ViewportMode? explicitViewport,
    required ViewportMode effectiveViewport,
    required String baseTitle,
    required Offset startOffset,
    required List<CanvasMessage> historyBeforeSplit,
  }) async {
    if (!state.isGenerating) return null;
    _setStatus(AiStatus.responding);

    final want = screenReq.names.isEmpty
        ? '${screenReq.count} layar'
        : screenReq.names.join(', ');
    final followUp = CanvasMessage(
      role: ChatRole.user,
      text: buildSplitFollowUpPrompt(
        count: screenReq.count,
        names: screenReq.names,
      ),
      // Transparan di bubble chat: user melihat app berinisiatif memecah.
      displayText: 'Pecah otomatis menjadi $want…',
    );
    final history = [...historyBeforeSplit, followUp];
    // Lampiran prompt asal tetap disertakan agar konteks visual tidak hilang.
    final lastAttachments = historyBeforeSplit
        .where((m) => m.role == ChatRole.user && m.attachments.isNotEmpty)
        .expand((m) => m.attachments)
        .toList();

    try {
      final payload = _buildMessagesPayload(
        attachments: lastAttachments,
        historyOverride: history,
      );
      final raw = await ref
          .read(aiApiServiceProvider)
          .generateUI(provider: activeProvider, messages: payload);
      // Bila user menekan Stop saat split, hasil yang telat diabaikan.
      if (!state.isGenerating) return null;
      final split = await classifyAiResponseInIsolate(raw);
      if (!state.isGenerating) return null;
      if (split.isChat || split.screens.length <= 1) return null;

      final committed = [...history];
      final splitNote = split.note?.trim();
      if (splitNote != null && splitNote.isNotEmpty) {
        committed.add(
          CanvasMessage(
            role: ChatRole.assistant,
            kind: ChatMessageKind.chat,
            text: splitNote,
          ),
        );
      }
      committed.add(
        CanvasMessage(
          role: ChatRole.assistant,
          kind: ChatMessageKind.ui,
          text: split.screens.first.html,
        ),
      );
      committed.add(
        CanvasMessage(
          role: ChatRole.assistant,
          kind: ChatMessageKind.chat,
          text: 'Dokumen gabungan otomatis dipecah menjadi '
              '${split.screens.length} frame ($want).',
        ),
      );
      state = state.copyWith(messages: committed);

      final splitFrames = await _buildFramesFromScreens(
        screens: split.screens,
        explicitViewport: explicitViewport,
        effectiveViewport: effectiveViewport,
        baseTitle: baseTitle,
        startOffset: startOffset,
      );
      if (!state.isGenerating) return null;
      return splitFrames;
    } catch (_) {
      // Jaringan gagal saat split: caller fallback ke hasil gabungan.
      return null;
    }
  }

  /// Catatan singkat bila auto-split pun gagal (2x percobaan): hasil gabungan
  /// tetap dipakai, user cukup menyebut tiap layar eksplisit bila mau pecah.
  String _splitFallbackNote(({int count, List<String> names}) screenReq) {
    final want = screenReq.names.isEmpty
        ? '${screenReq.count} layar'
        : screenReq.names.join(', ');
    return 'Catatan: kamu meminta $want, tapi AI tetap menggabung semuanya '
        'ke 1 dokumen setelah 2x percobaan. Sebutkan tiap layar lebih '
        'eksplisit bila ingin frame terpisah, mis. "buatkan $want sebagai '
        'file HTML terpisah, satu per layar".';
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

  /// Kirim ulang prompt user terakhir tanpa mengetik ulang (tombol "Coba lagi"
  /// pada bubble error). Pesan error trailing dibuang agar tidak menumpuk,
  /// prompt user terakhir dipakai ulang — tidak ada duplikasi bubble user.
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
    List<CanvasMessage>? historyOverride,
  }) {
    final history = (historyOverride ?? state.messages)
        .where((m) => m.role != ChatRole.error)
        .toList();

    // System prompt bawaan Centauri (Alpha).
    const systemPrompt = uiSystemPrompt;

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
        // Riwayat user lama cukup memakai displayText (teks asli pengguna yang
        // bersih dari [CANVAS TARGET] dan konteks internal) agar riwayat tidak
        // bertele-tele dan tidak mencemari konteks percakapan. Hanya giliran aktif
        // yang memakai teks lengkap dengan konteks canvas saat ini.
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
    r'viewport\s*[:=]\s*(mobile|tablet|desktop|windows|hd|fhd)',
  ).firstMatch(lower);
  if (explicit != null) {
    final raw = explicit.group(1)!;
    if (raw == 'windows') return ViewportMode.desktop;
    if (raw == 'fhd') return ViewportMode.hd;
    return ViewportMode.values.byName(raw);
  }

  // 2. Nama device yang disebut.
  final hits = <int, ViewportMode>{};
  for (final mode in ViewportMode.values) {
    final index = lower.lastIndexOf(mode.name);
    if (index >= 0) hits[index] = mode;
  }
  final windowsIndex = lower.lastIndexOf('windows');
  if (windowsIndex >= 0) hits[windowsIndex] = ViewportMode.desktop;

  for (final word in ['1080p', 'full hd', 'fullhd', 'fhd']) {
    final idx = lower.lastIndexOf(word);
    if (idx >= 0) hits[idx] = ViewportMode.hd;
  }
  for (final m in RegExp(r'\bhd\b').allMatches(lower)) {
    hits[m.start] = ViewportMode.hd;
  }

  // 3. Lebar px yang disebut (spesifik).
  void scanPx(String pattern, ViewportMode mode) {
    for (final m in RegExp(pattern).allMatches(lower)) {
      hits[m.start] = mode;
    }
  }

  scanPx(r'\b(1920|1080|2560)(\s*px|p)?\b', ViewportMode.hd);
  scanPx(r'\b(1280|1440)(\s*px|p)?\b', ViewportMode.desktop);
  scanPx(r'\b(768|820|834)(\s*px|p)?\b', ViewportMode.tablet);
  scanPx(r'\b(390|375|412|414|844)(\s*px|p)?\b', ViewportMode.mobile);

  if (hits.isEmpty) return null;
  final lastIndex = hits.keys.reduce((a, b) => a > b ? a : b);
  return hits[lastIndex];
}

/// Otomatis memilih layout viewport terbaik berdasarkan semantik prompt
/// (AI auto-layout selection ala Google Stitch).
ViewportMode detectAutoViewport(String prompt) {
  final explicit = detectViewportOverride(prompt);
  if (explicit != null) return explicit;

  final lower = prompt.toLowerCase();

  // 1. Keyword widescreen / HD
  if (RegExp(
    r'\b(wallboard|cinema|presentation|widescreen|ultra\s*wide|2k|4k)\b',
  ).hasMatch(lower)) {
    return ViewportMode.hd;
  }

  // 2. Keyword desktop / web / windows / dashboard
  if (RegExp(
    r'\b(dashboard|admin|crm|erp|saas|desktop|portal|table|analytics|monitoring|backoffice|cms|spreadsheet|kanban|console|landing\s*page|website|web\s*app|ecommerce\s*web|toko\s*online)\b',
  ).hasMatch(lower)) {
    return ViewportMode.desktop;
  }

  // 3. Keyword tablet / kiosk / POS
  if (RegExp(
    r'\b(tablet|ipad|pos|kasir|cashier|kiosk|katalog|restaurant\s*menu|menu\s*restoran|order\s*display)\b',
  ).hasMatch(lower)) {
    return ViewportMode.tablet;
  }

  // 4. Keyword mobile / smartphone
  if (RegExp(
    r'\b(mobile|hp|android|ios|iphone|smartphone|app|aplikasi|chat|story|stories|feed|reels|shorts|tiktok|instagram|gojek|grab|uber|delivery|food|tinder|dating|wallet|ewallet|bottom\s*nav|splash|onboarding)\b',
  ).hasMatch(lower)) {
    return ViewportMode.mobile;
  }

  // Default cerdas: jika menyebut web/page/halaman -> desktop, selain itu mobile
  if (RegExp(r'\b(page|halaman|web|site)\b').hasMatch(lower)) {
    return ViewportMode.desktop;
  }

  return ViewportMode.mobile;
}

/// Ekstrak viewport yang dipilih oleh AI dari dokumen HTML via meta tag atau komentar.
ViewportMode? detectViewportFromHtml(String html) {
  final metaMatch = RegExp(
    "<meta\\s+[^>]*name=[\"']viewport-target[\"']\\s+[^>]*content=[\"']([^\"']+)[\"']",
    caseSensitive: false,
  ).firstMatch(html) ?? RegExp(
    "<meta\\s+[^>]*content=[\"']([^\"']+)[\"']\\s+[^>]*name=[\"']viewport-target[\"']",
    caseSensitive: false,
  ).firstMatch(html);

  if (metaMatch != null) {
    final val = metaMatch.group(1)!.trim().toLowerCase();
    if (val == 'windows') return ViewportMode.desktop;
    if (val == 'fhd') return ViewportMode.hd;
    for (final mode in ViewportMode.values) {
      if (mode.name == val) return mode;
    }
  }

  final widthMatch = RegExp(
    "<meta\\s+[^>]*name=[\"']viewport-width[\"']\\s+[^>]*content=[\"'](\\d+)[\"']",
    caseSensitive: false,
  ).firstMatch(html);
  if (widthMatch != null) {
    final w = int.tryParse(widthMatch.group(1)!);
    if (w != null) {
      if (w >= 1600) return ViewportMode.hd;
      if (w >= 1100) return ViewportMode.desktop;
      if (w >= 600) return ViewportMode.tablet;
      return ViewportMode.mobile;
    }
  }

  final commentMatch = RegExp(
    r'<!--\s*viewport\s*:\s*(mobile|tablet|desktop|windows|hd)\s*-->',
    caseSensitive: false,
  ).firstMatch(html);
  if (commentMatch != null) {
    final val = commentMatch.group(1)!.trim().toLowerCase();
    if (val == 'windows') return ViewportMode.desktop;
    for (final mode in ViewportMode.values) {
      if (mode.name == val) return mode;
    }
  }

  return null;
}

/// Hasil deteksi permintaan layar: jumlah blok ```html yang diharapkan + nama
/// layar yang disebut user (urutan kemunculan). `count == 1` + `names` kosong
/// berarti single screen. Top-level agar bisa diuji langsung.
///
/// Contoh:
/// - "buatkan login, home sampai profile" -> (count: 3, names: [login, home, profile])
/// - "buatkan 5 screen" -> (count: 5, names: [])
/// - "buatkan landing page" -> (count: 1, names: [])
({int count, List<String> names}) detectScreenRequest(String prompt) {
  final lower = prompt.toLowerCase();

  // 1. Jumlah eksplisit: "5 screen(s)", "3 halaman", "2 page", "4 layar".
  var count = 1;
  final countMatch = RegExp(
    r'(\d+)\s*(screen|layar|halaman|page)s?\b',
  ).firstMatch(lower);
  if (countMatch != null) {
    count = int.tryParse(countMatch.group(1)!) ?? 1;
    if (count < 1) count = 1;
    if (count > 20) count = 20; // batas waras: 1 request = max 20 frame.
  }

  // 2. Nama layar yang disebut (urutan kemunculan, tanpa duplikat).
  const screenKeywords = [
    'splash',
    'onboarding',
    'login',
    'register',
    'signup',
    'sign up',
    'home',
    'beranda',
    'feed',
    'explore',
    'jelajah',
    'search',
    'pencarian',
    'detail',
    'cart',
    'keranjang',
    'checkout',
    'payment',
    'pembayaran',
    'profile',
    'profil',
    'settings',
    'pengaturan',
    'notifications',
    'notifikasi',
    'chat',
    'message',
    'pesan',
    'dashboard',
    'pricing',
    'harga',
    'landing',
    'portfolio',
    'gallery',
    'galeri',
    'blog',
    'product',
    'produk',
    'order',
    'pesanan',
    'history',
    'riwayat',
    'wallet',
    'dompet',
    'contact',
    'kontak',
    'about',
    'tentang',
  ];
  final hits = <int, String>{};
  for (final kw in screenKeywords) {
    final idx = lower.indexOf(kw);
    if (idx >= 0) hits[idx] = kw;
  }
  // Rentang "dari X sampai/s/dan Y" / daftar koma: nama sudah tertangkap di
  // atas lewat keywords; yang penting urutannya. Samakan ejaan ID/EN agar
  // instruksi ke AI konsisten (profile, bukan profil).
  const canonical = {
    'profil': 'profile',
    'beranda': 'home',
    'jelajah': 'explore',
    'pencarian': 'search',
    'keranjang': 'cart',
    'pembayaran': 'payment',
    'pengaturan': 'settings',
    'notifikasi': 'notifications',
    'harga': 'pricing',
    'galeri': 'gallery',
    'produk': 'product',
    'pesanan': 'order',
    'riwayat': 'history',
    'dompet': 'wallet',
    'kontak': 'contact',
    'tentang': 'about',
  };
  final ordered = hits.keys.toList()..sort();
  final names = <String>[];
  for (final i in ordered) {
    final n = canonical[hits[i]!] ?? hits[i]!;
    if (!names.contains(n)) names.add(n);
  }

  // 3. Frasa multi-screen tanpa angka/nama jelas ("semua screen", "banyak
  // halaman", "dari ... sampai ..." termasuk daftar koma
  // "dari login, home sampai profile", "lengkap dengan").
  final multiPhrase = RegExp(
    r'(semua\s+(screen|layar|halaman|page)|banyak\s+(screen|layar|halaman|page)|'
    r'dari\s+[\w\s,]+\s+(sampai|s/d|hingga|dan|to)\s+\w+|lengkap\s+dengan|'
    r'setiap\s+(screen|layar|halaman|page))',
  ).hasMatch(lower);
  if (multiPhrase && count == 1 && names.length < 2) {
    // Minimal 3 layar agar model tidak hanya mengembalikan 1 dokumen.
    count = names.length > 3 ? names.length : 3;
  }

  if (names.length > count) count = names.length;
  if (count == 1 && names.length == 1) return (count: 1, names: const []);
  return (count: count, names: names);
}

/// Instruksi follow-up OTOMATIS saat AI menggabung layar yang diminta terpisah
/// ke 1 dokumen: pecah memakai dokumen gabungan sebelumnya sebagai konteks,
/// tanpa user mengetik ulang. Top-level agar bisa diuji langsung.
///
/// Contoh: buildSplitFollowUpPrompt(count: 2, names: ['pricing', 'payment'])
/// -> instruksi tegas "EXACTLY 2 separate ```html blocks (pricing -> payment)".
String buildSplitFollowUpPrompt({
  required int count,
  required List<String> names,
}) {
  final order = names.isEmpty
      ? 'plan the screen order yourself and keep it'
      : names.join(' -> ');
  final scope = names.isEmpty ? '$count screens' : names.join(', ');
  return '[AUTO-SPLIT — USE YOUR PREVIOUS MERGED DOCUMENT AS CONTEXT] '
      'You merged the requested screens into ONE document. Now split it into '
      'EXACTLY $count separate complete self-contained HTML documents '
      '($scope). Follow these steps:\n'
      '1. Output EXACTLY $count separate ```html fenced code blocks, one per '
      'screen, in this order: $order.\n'
      '2. REUSE the design system, sections, content, and copy from your '
      'previous document — do not redesign from scratch, just separate it '
      'per screen (each screen keeps full detail: nav, content, actions, '
      'footer).\n'
      '3. Each block is ONE complete self-contained HTML document '
      '(<!DOCTYPE html>, ONE inline <style>, inline vanilla JS, inline SVG '
      'icons, zero horizontal overflow).\n'
      '4. Before each block, write a one-line heading with the screen name '
      '(e.g. `### Home`).\n'
      '5. FORBIDDEN: merging screens into one document, tab bars, nav links, '
      'or JS view-switching as a substitute for separate documents.\n'
      'Declare each screen\u2019s viewport with '
      '<meta name="viewport-target" content="mobile|tablet|desktop|hd">.';
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
