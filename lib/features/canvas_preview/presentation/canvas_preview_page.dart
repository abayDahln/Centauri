import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/theme.dart';
import '../../../app/widgets/stitch_widgets.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../history/data/project_repository.dart';
import '../../history/presentation/history_provider.dart';
import '../../mcp/data/mcp_bridge.dart';
import '../../mcp/data/mcp_server.dart';
import '../../provider_config/presentation/providers/provider_config_provider.dart';
import '../data/services/canvas_service_registry.dart';
import 'frame_preview_page.dart';
import 'provider/canvas_provider.dart';
import 'widgets/ai_status_indicator.dart';
import 'widgets/board_canvas.dart';
import 'widgets/chat_landing.dart';
import 'widgets/chat_side_panel.dart';
import 'widgets/code_panel.dart';
import 'widgets/frame_export_button.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/layers_panel.dart';
import 'widgets/prompt_bar.dart';

/// Halaman utama board. Menangani:
/// - layout adaptif desktop/mobile,
/// - auto-save debounce ke penyimpanan lokal (Fase 3),
/// - restore sesi aktif saat aplikasi dibuka (offline-first).
class CanvasPreviewPage extends ConsumerStatefulWidget {
  const CanvasPreviewPage({super.key});

  @override
  ConsumerState<CanvasPreviewPage> createState() => _CanvasPreviewPageState();
}

class _CanvasPreviewPageState extends ConsumerState<CanvasPreviewPage> {
  bool _restored = false;
  final FocusNode _shortcutFocus = FocusNode(debugLabel: 'canvas-shortcuts');
  bool _spaceHeld = false;

  @override
  void dispose() {
    _shortcutFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Restore sesi aktif (proyek terakhir) sekali saat halaman dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
    // MCP server lokal (Fase 4): hanya desktop, background, idempoten.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMcpServer());
  }

  Future<void> _startMcpServer() async {
    if (!mounted) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }
    // Saat flutter test, jangan nyalakan server: timer heartbeat background
    // membuat test "pending timer" gagal dan tidak relevan di lingkungan test.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      await ref
          .read(mcpServerProvider)
          .start(bridge: McpBridge(ref.container));
    } catch (_) {
      // Server opsional: kegagalan bind tidak boleh mengganggu board.
    }
  }

  Future<void> _restoreSession() async {
    if (_restored || !mounted) return;
    _restored = true;
    final canvas = ref.read(canvasProvider);
    // Bila board sudah berisi sesuatu (mis. hot reload), jangan sentuh.
    if (canvas.frames.isNotEmpty || canvas.messages.isNotEmpty) return;
    // Aplikasi harus selalu mulai dari sesi BARU yang kosong, bukan membuka
    // kembali percakapan terakhir. Hapus proyek aktif tersimpan & kosongkan
    // board agar riwayat tidak menyorot sesi lama.
    try {
      await ref.read(projectRepositoryProvider).clearActiveProjectId();
    } catch (_) {
      // Abaikan kegagalan storage: sesi baru tetap dibuat di bawah.
    }
    ref.read(historyProvider.notifier).startNew();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-save: setiap perubahan board (frames/pesan/frame aktif) disimpan
    // ke Hive setelah jeda 2,5 detik tanpa perubahan (Fase 3).
    // Live sync MCP (Fase 4): perubahan yang sama disiarkan ke klien SSE.
    // Undo/redo (Fase 5): snapshot konten SEBELUM perubahan masuk stack.
    ref.listen(canvasProvider, (previous, next) {
      if (previous != null) {
        _recordUndo(ref, previous, next);
      }
      _AutoSaveDebouncer.onChanged(ref, previous, next);
      _McpLiveSync.onChanged(ref, previous, next);
    });

    return Focus(
      focusNode: _shortcutFocus,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return const _DesktopShell();
          }
          return const _MobileShell();
        },
      ),
    );
  }

  /// Catat snapshot untuk undo bila perubahan menyentuh konten board
  /// (frames / messages / frame aktif) — bukan sekadar zoom/pan/seleksi.
  void _recordUndo(WidgetRef ref, CanvasState previous, CanvasState next) {
    final contentChanged =
        !identical(previous.frames, next.frames) ||
        !identical(previous.messages, next.messages) ||
        previous.activeFrameId != next.activeFrameId;
    if (!contentChanged) return;
    // Jangan catat saat AI sedang men-delete/rewrite board di tengah proses.
    if (next.isGenerating) return;
    ref.read(canvasProvider.notifier).recordHistory(previous);
  }

  /// Hotkey global desktop (Fase 5):
  /// Ctrl/Cmd+Z undo, Ctrl/Cmd+Shift+Z / Ctrl+Y redo, Delete/Backspace hapus
  /// frame aktif, Ctrl+C/V copy/paste node, Space (tahan) pan sementara.
  ///
  /// PENTING: hotkey ini TIDAK BOLEH menelan input saat pengguna sedang
  /// mengetik di TextField (prompt bar, dsb). Kita lepas kendali begitu ada
  /// field teks yang fokus, kecuali untuk tombol yang jelas milik board
  /// (mis. Escape). Tanpa ini, Backspace/Space/Ctrl+V tak sampai ke field.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_textFieldHasFocus()) {
      // Beri field teks kendali penuh atas keyboard.
      _releaseSpacePanIfHeld();
      return KeyEventResult.ignored;
    }

    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Space (tahan) = tool hand sementara (hanya saat fokus bukan di field).
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent && !_spaceHeld) {
        _spaceHeld = true;
        ref.read(canvasProvider.notifier).setTool(BoardTool.hand);
      } else if (event is KeyUpEvent && _spaceHeld) {
        _spaceHeld = false;
        ref.read(canvasProvider.notifier).setTool(BoardTool.select);
      }
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final notifier = ref.read(canvasProvider.notifier);

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        notifier.redo();
      } else {
        notifier.undo();
      }
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
      notifier.redo();
      return KeyEventResult.handled;
    }
    // Ctrl + '+' / '=' zoom in, Ctrl + '-' zoom out, Ctrl + '0' reset.
    if (isCtrl &&
        (event.logicalKey == LogicalKeyboardKey.equal ||
            event.logicalKey == LogicalKeyboardKey.add ||
            event.logicalKey == LogicalKeyboardKey.numpadAdd)) {
      notifier.zoomBy(1.2);
      return KeyEventResult.handled;
    }
    if (isCtrl &&
        (event.logicalKey == LogicalKeyboardKey.minus ||
            event.logicalKey == LogicalKeyboardKey.numpadSubtract)) {
      notifier.zoomBy(1 / 1.2);
      return KeyEventResult.handled;
    }
    if (isCtrl &&
        (event.logicalKey == LogicalKeyboardKey.digit0 ||
            event.logicalKey == LogicalKeyboardKey.numpad0)) {
      notifier.resetView();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
      // Hanya "curi" Ctrl+C bila memang ada node terpilih (copy komponen).
      // Jika tidak, biarkan sistem menangani (mis. copy teks lain).
      if (notifier.copySelectedNode()) return KeyEventResult.handled;
      return KeyEventResult.ignored;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyV) {
      // Hanya tempel-komponen bila ada node terpilih & clipboard node terisi.
      final state = ref.read(canvasProvider);
      if (state.selectedNodeId != null && notifier.hasClipboard) {
        _pasteNode();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      final state = ref.read(canvasProvider);
      // Prioritas: hapus node terpilih; bila tidak ada, hapus frame aktif.
      if (state.selectedNodeGeometry != null) {
        _deleteSelectedNode();
        return KeyEventResult.handled;
      } else if (state.activeFrameId != null) {
        notifier.deleteFrame(state.activeFrameId!);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// True bila ada editable text field yang sedang fokus.
  bool _textFieldHasFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    // FocusNode milik board kita sendiri bukan field teks.
    if (identical(focus, _shortcutFocus)) return false;
    final context = focus.context;
    if (context == null) return false;
    // Cek widget di sepanjang ancestor: EditableText menandakan TextField.
    var isEditable = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        isEditable = true;
        return false;
      }
      return true;
    });
    return isEditable;
  }

  /// Lepas tool hand bila space sempat tertahan lalu fokus pindah ke field.
  void _releaseSpacePanIfHeld() {
    if (!_spaceHeld) return;
    _spaceHeld = false;
    ref.read(canvasProvider.notifier).setTool(BoardTool.select);
  }

  /// Hapus node terpilih via service WebView (jalur yang sama seperti MCP).
  Future<void> _deleteSelectedNode() async {
    final state = ref.read(canvasProvider);
    final frameId = state.activeFrameId;
    final nodeId = state.selectedNodeId;
    if (frameId == null || nodeId == null) return;
    final service = CanvasServiceRegistry.forFrame(frameId);
    if (service == null) return;
    await service.deleteNode(nodeId);
    await service.requestHtml();
  }

  /// Tempel node yang disalin: ambil outerHTML node sumber, sisipkan sebagai
  /// saudara (afterend), lalu geser sedikit agar terlihat menumpuk.
  Future<void> _pasteNode() async {
    final notifier = ref.read(canvasProvider.notifier);
    final source = notifier.clipboard;
    final state = ref.read(canvasProvider);
    final frameId = state.activeFrameId;
    final sourceId = state.selectedNodeId;
    if (source == null || frameId == null || sourceId == null) return;
    final service = CanvasServiceRegistry.forFrame(frameId);
    if (service == null) return;

    try {
      final outer = await service.selectionEvents
          .firstWhere(
            (e) => e.type == 'outerHtml' || e.type == 'outerHtmlError',
          )
          .timeout(const Duration(seconds: 10));
      if (outer.type != 'outerHtml' || outer.html == null) return;
      // Sisipkan duplikat setelah node sumber, lalu geser sedikit.
      await service.addNode(sourceId, outer.html!, position: 'afterend');
      await service.moveResizeNode(sourceId, dx: 12, dy: 12);
      await service.requestHtml();
    } catch (_) {
      // Clipboard/JS gagal: abaikan, tidak ada yang rusak.
    }
  }
}

/// Live sync MCP di luar widget agar tidak ter-reset oleh rebuild.
/// Hanya menaikkan versi + broadcast ringan; no-op bila tak ada klien SSE.
class _McpLiveSync {
  static void onChanged(WidgetRef ref, CanvasState? previous, CanvasState next) {
    if (previous == null) return;
    if (identical(previous.frames, next.frames) &&
        identical(previous.messages, next.messages) &&
        previous.activeFrameId == next.activeFrameId &&
        previous.selectedNodeId == next.selectedNodeId) {
      return;
    }
    try {
      ref.read(mcpServerProvider).notifyState();
    } catch (_) {}
  }
}
/// Debounce auto-save di luar widget agar tidak ter-reset oleh rebuild.
class _AutoSaveDebouncer {
  static final _AutoSaveDebouncer _instance = _AutoSaveDebouncer._();
  _AutoSaveDebouncer._();

  Timer? _timer;

  static void onChanged(
    WidgetRef ref,
    CanvasState? previous,
    CanvasState next,
  ) {
    _instance._schedule(ref, previous, next);
  }

  void _schedule(WidgetRef ref, CanvasState? previous, CanvasState next) {
    // Abaikan perubahan yang tidak terkait konten board.
    if (previous != null &&
        identical(previous.frames, next.frames) &&
        identical(previous.messages, next.messages) &&
        previous.activeFrameId == next.activeFrameId) {
      return;
    }
    // Jangan simpan saat AI sedang generate; state akhir akan memicu lagi.
    if (next.isGenerating) return;
    if (next.frames.isEmpty && next.messages.isEmpty) return;

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      try {
        ref.read(historyProvider.notifier).persistCurrent();
      } catch (_) {
        // Penyimpanan lokal gagal: abaikan, user tetap bisa simpan manual.
      }
    });
  }
}

// ---------------------------------------------------------------- desktop --

class _DesktopShell extends ConsumerStatefulWidget {
  const _DesktopShell();

  @override
  ConsumerState<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<_DesktopShell> {
  bool _showCode = false;
  bool _showLayers = true;
  bool _autoShownChat = false;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(canvasProvider.select((s) => s.outputMode));
    final showChat = ref.watch(panelVisibleProvider);
    final hasUi = ref.watch(
      canvasProvider.select((s) => s.hasRenderedFrame || s.frames.isNotEmpty),
    );
    // Inspector kanan otomatis saat ada node terpilih (Fase 2).
    final hasSelection = ref.watch(
      canvasProvider.select((s) => s.selectedNodeId != null),
    );

    // Saat board pertama kali muncul, tampilkan panel chat otomatis.
    if (hasUi && !_autoShownChat) {
      _autoShownChat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(panelVisibleProvider.notifier).show();
      });
    }

    final showCode = hasUi && (mode == OutputMode.dev || _showCode);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          _TopBar(
            boardActive: hasUi,
            onTogglePrompt: () =>
                ref.read(panelVisibleProvider.notifier).toggle(),
            onToggleCode: () => setState(() => _showCode = !_showCode),
            onToggleLayers: () => setState(() => _showLayers = !_showLayers),
            promptVisible: showChat,
            codeVisible: showCode,
            layersVisible: _showLayers,
          ),
          const StorageBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Panel obrolan (Chat · History · Layers) di pojok kiri.
                  if (showChat) ...[
                    const SizedBox(width: 320, child: ChatSidePanel()),
                    const SizedBox(width: 12),
                  ],
                  // Layers tree frame aktif (menuju tengah, setelah chat).
                  if (hasUi && _showLayers) ...[
                    const SizedBox(
                      width: 260,
                      child: SoftPanel(
                        padding: EdgeInsets.zero,
                        clip: true,
                        child: LayersPanel(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Stack(
                      children: [
                        if (hasUi)
                          const BoardSurface()
                        else if (!showChat)
                          // Belum ada UI & panel chat tertutup: tampilkan
                          // percakapan besar di tengah sebagai landing.
                          const ChatLanding()
                        else
                          // Panel chat terbuka: tengah cukup latar netral.
                          const _EmptyCanvasHint(),
                        if (hasUi)
                          const Positioned(
                            right: 16,
                            top: 16,
                            bottom: 96,
                            child: _RightToolbar(),
                          ),
                        // Status live AI saat board aktif (generating frame baru).
                        if (hasUi)
                          const Positioned(
                            left: 16,
                            top: 16,
                            child: _BoardStatusPill(),
                          ),
                        const Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: PromptBar(),
                        ),
                      ],
                    ),
                  ),
                  if (showCode) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 420,
                      child: SoftPanel(
                        padding: EdgeInsets.zero,
                        clip: true,
                        child: CodePanel(),
                      ),
                    ),
                  ],
                  // Inspector Fase 2: kanan, berdampingan dengan Code bila ada.
                  if (hasUi && hasSelection) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 280,
                      child: SoftPanel(
                        padding: EdgeInsets.zero,
                        clip: true,
                        child: InspectorPanel(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.boardActive,
    required this.onTogglePrompt,
    required this.onToggleCode,
    required this.onToggleLayers,
    required this.promptVisible,
    required this.codeVisible,
    required this.layersVisible,
  });

  final bool boardActive;
  final VoidCallback onTogglePrompt;
  final VoidCallback onToggleCode;
  final VoidCallback onToggleLayers;
  final bool promptVisible;
  final bool codeVisible;
  final bool layersVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(providerConfigProvider).value?.activeProvider;

    return SizedBox(
      height: AppColors.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Menu: buka/tutup panel kiri (Chat · History · Layers).
            SoftIconButton(
              icon: Icons.menu,
              tooltip: 'Panel (Chat · History · Layers)',
              active: promptVisible,
              onPressed: onTogglePrompt,
            ),
            const SizedBox(width: 4),
            // Konfigurasi provider — selalu tersedia.
            SoftIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Konfigurasi provider',
              onPressed: () => context.push('/provider-config'),
            ),
            const SizedBox(width: 12),
            // Toggle panel Code (hanya relevan setelah ada UI).
            if (boardActive) ...[
              SoftIconButton(
                icon: Icons.layers_outlined,
                tooltip: 'Layers (kiri)',
                active: layersVisible,
                onPressed: onToggleLayers,
              ),
              const SizedBox(width: 4),
              SoftIconButton(
                icon: Icons.code_outlined,
                tooltip: 'Code',
                active: codeVisible,
                onPressed: onToggleCode,
              ),
              const SizedBox(width: 12),
            ],
            InkWell(
              onTap: () => context.push('/provider-config'),
              borderRadius: AppRadius.pill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active == null
                            ? AppColors.textDisabled
                            : AppColors.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(active?.name ?? 'Pilih provider', style: AppText.uiSmall),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (boardActive) const _CanvasViewControls(),
          ],
        ),
      ),
    );
  }
}

/// Pill status AI mengambang di board (muncul saat generating).
class _BoardStatusPill extends ConsumerWidget {
  const _BoardStatusPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      canvasProvider.select((s) => s.status != AiStatus.idle),
    );
    if (!active) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppColors.shadowRaised,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiStatusIndicator(compact: true),
          const SizedBox(width: 10),
          // Tombol Stop: hentikan generate yang berjalan.
          Tooltip(
            message: 'Hentikan generate',
            child: InkWell(
              onTap: () =>
                  ref.read(canvasProvider.notifier).cancelGeneration(),
              borderRadius: AppRadius.pill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.14),
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stop_rounded,
                      size: 14,
                      color: AppColors.statusError,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stop',
                      style: TextStyle(
                        fontFamily: AppFonts.uiFamily,
                        fontFamilyFallback: AppFonts.uiFallback,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusError,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kontrol kanan atas: zoom, grid, fit, bersihkan.
/// (Viewport dipilih lewat toggle di PromptBar.)
class _CanvasViewControls extends ConsumerWidget {
  const _CanvasViewControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);

    return Row(
      children: [
        _ZoomChip(scale: state.scale),
        const SizedBox(width: 8),
        // Ekspor frame aktif (PNG/SVG/PDF, Fase 3).
        const FrameExportButton(),
        const SizedBox(width: 4),
        SoftIconButton(
          icon: Icons.grid_4x4,
          tooltip: 'Dot grid',
          active: state.showGrid,
          onPressed: notifier.toggleGrid,
        ),
        const SizedBox(width: 4),
        // Snap Fase 2: magnet ke grid + frame lain.
        SoftIconButton(
          icon: Icons.align_horizontal_center,
          tooltip: state.snapEnabled ? 'Snap: aktif' : 'Snap: mati',
          active: state.snapEnabled,
          onPressed: notifier.toggleSnap,
        ),
        const SizedBox(width: 4),
        SoftIconButton(
          icon: Icons.fit_screen_outlined,
          tooltip: 'Fit ke frame',
          onPressed: state.frames.isEmpty
              ? null
              : () => notifier.centerOnFrames(boardViewportSize(context)),
        ),
        const SizedBox(width: 4),
        // Undo/redo (Fase 5) — juga tersedia lewat Ctrl+Z / Ctrl+Y.
        SoftIconButton(
          icon: Icons.undo,
          tooltip: 'Undo (Ctrl+Z)',
          onPressed: notifier.undo,
        ),
        const SizedBox(width: 4),
        SoftIconButton(
          icon: Icons.redo,
          tooltip: 'Redo (Ctrl+Y)',
          onPressed: notifier.redo,
        ),
        const SizedBox(width: 4),
        // Pratinjau/prototype mode (Fase 5).
        SoftIconButton(
          icon: Icons.play_circle_outline,
          tooltip: 'Pratinjau (prototype)',
          onPressed: state.activeFrame == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FramePreviewPage(
                      html: state.activeFrame!.html,
                      title: state.activeFrame!.title,
                      width: state.activeFrame!.size.width,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 4),
        SoftIconButton(
          icon: Icons.delete_outline,
          tooltip: 'Bersihkan board',
          onPressed: state.frames.isEmpty ? null : notifier.clearBoard,
        ),
      ],
    );
  }
}

class _ZoomChip extends ConsumerWidget {
  const _ZoomChip({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(canvasProvider.notifier);
    final canZoomOut = scale > CanvasState.minScale + 0.0001;
    final canZoomIn = scale < CanvasState.maxScale - 0.0001;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            size: 28,
            iconSize: 15,
            onPressed: canZoomOut
                ? () => notifier.zoomBy(1 / 1.2)
                : null,
          ),
          InkWell(
            onTap: notifier.resetView,
            child: SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  '${(scale * 100).round()}%',
                  style: AppText.uiSmall,
                ),
              ),
            ),
          ),
          SoftIconButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            size: 28,
            iconSize: 15,
            onPressed: canZoomIn ? () => notifier.zoomBy(1.2) : null,
          ),
        ],
      ),
    );
  }
}

/// Toolbar vertikal kanan (select / pan / komentar / grid).
class _RightToolbar extends ConsumerWidget {
  const _RightToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(canvasProvider.select((s) => s.tool));
    final notifier = ref.read(canvasProvider.notifier);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppColors.shadowRaised,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(
              icon: Icons.near_me_outlined,
              tooltip: 'Pilih & geser frame',
              active: tool == BoardTool.select,
              onTap: () => notifier.setTool(BoardTool.select),
            ),
            _ToolButton(
              icon: Icons.pan_tool_outlined,
              tooltip: 'Geser board',
              active: tool == BoardTool.hand,
              onTap: () => notifier.setTool(BoardTool.hand),
            ),
            _ToolButton(
              icon: Icons.zoom_out_map,
              tooltip: 'Fit ke frame',
              onTap: () =>
                  notifier.centerOnFrames(boardViewportSize(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.active
        ? AppColors.accentSoft
        : _hovered
        ? AppColors.hoverBg
        : Colors.transparent;
    final color = widget.active
        ? AppColors.accentPrimary
        : AppColors.textSecondary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(widget.icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _EmptyCanvasHint extends StatelessWidget {
  const _EmptyCanvasHint();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                size: 30,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada UI',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tulis prompt di bar bawah untuk mulai.',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ------------------------------------------------------------------ mobile --

/// Toolbar vertikal mengambang di mobile (Fase 5): undo/redo + preview mode.
class _MobileFloatingToolbar extends ConsumerWidget {
  const _MobileFloatingToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canvasProvider.select((s) => s.frames.isNotEmpty));
    final notifier = ref.read(canvasProvider.notifier);
    final activeFrame = ref.watch(canvasProvider.select((s) => s.activeFrame));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatIconButton(
          icon: Icons.undo,
          tooltip: 'Undo',
          onTap: canUndo ? notifier.undo : null,
        ),
        const SizedBox(height: 6),
        _FloatIconButton(
          icon: Icons.redo,
          tooltip: 'Redo',
          onTap: canUndo ? notifier.redo : null,
        ),
        const SizedBox(height: 6),
        _FloatIconButton(
          icon: Icons.play_circle_outline,
          tooltip: 'Pratinjau (prototype)',
          onTap: activeFrame == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FramePreviewPage(
                      html: activeFrame.html,
                      title: activeFrame.title,
                      width: activeFrame.size.width,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Tombol ikon kecil bergaya kaca untuk toolbar mengambang.
class _FloatIconButton extends StatelessWidget {
  const _FloatIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.sm,
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.sm,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              icon,
              size: 17,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUi = ref.watch(
      canvasProvider.select((s) => s.hasRenderedFrame || s.frames.isNotEmpty),
    );
    final hasSelection = ref.watch(
      canvasProvider.select((s) => s.selectedNodeId != null),
    );

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(hasUi ? 'Board' : 'Centauri'),
        actions: [
          SoftIconButton(
            icon: Icons.menu,
            tooltip: 'Panel (Chat · History · Layers)',
            onPressed: () => _openSheet(
              context,
              const ChatSidePanel(),
              heightFactor: 0.75,
            ),
          ),
          SoftIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Konfigurasi provider',
            onPressed: () => context.push('/provider-config'),
          ),
          if (hasUi) ...[
            SoftIconButton(
              icon: Icons.code_outlined,
              tooltip: 'Code',
              onPressed: () =>
                  _openSheet(context, const CodePanel(), heightFactor: 0.8),
            ),
            // Ekspor frame (PNG/SVG/PDF, Fase 3) via bottom sheet menu.
            if (hasSelection)
              SoftIconButton(
                icon: Icons.tune_outlined,
                tooltip: 'Inspector',
                onPressed: () => _openSheet(
                  context,
                  const InspectorPanel(),
                  heightFactor: 0.7,
                ),
              ),
            const FrameExportButton(compact: true),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Peringatan storage (sama seperti desktop): app tetap jalan penuh.
          const StorageBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Stack(
                children: [
                  if (hasUi) const BoardSurface() else const ChatLanding(),
                  // Toolbar mengambang (Fase 5): undo/redo + preview.
                  if (hasUi)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: _MobileFloatingToolbar(),
                    ),
                  if (hasUi && hasSelection)
                    Positioned(
                      right: 8,
                      top: 56,
                      child: _FloatIconButton(
                        icon: Icons.tune_outlined,
                        tooltip: 'Inspector',
                        onTap: () => _openSheet(
                          context,
                          const InspectorPanel(),
                          heightFactor: 0.7,
                        ),
                      ),
                    ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: PromptBar(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _openSheet(
    BuildContext context,
    Widget child, {
    required double heightFactor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * heightFactor,
        child: child,
      ),
    );
  }
}

/// Ukuran viewport board saat ini (untuk perhitungan fit/center).
Size boardViewportSize(BuildContext context) {
  final box = BoardSurface.boardViewportKey.currentContext?.findRenderObject()
      as RenderBox?;
  if (box != null && box.hasSize) return box.size;
  return const Size(900, 600);
}

/// Peringatan bila penyimpanan lokal gagal dibuka (mis. box Hive di-lock
/// instance app lain). App tetap jalan penuh; tanpa ini kegagalan storage
/// hanya terlihat sebagai data hilang tanpa sebab.
class StorageBanner extends ConsumerStatefulWidget {
  const StorageBanner({super.key});

  @override
  ConsumerState<StorageBanner> createState() => _StorageBannerState();
}

class _StorageBannerState extends ConsumerState<StorageBanner> {
  bool _busy = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(storageStatusProvider);
    if (_dismissed || status.isHealthy) return const SizedBox.shrink();

    return Material(
      color: AppColors.statusWarning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(
              Icons.storage_rounded,
              size: 16,
              color: AppColors.statusWarning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Penyimpanan lokal tidak bisa dibuka (${status.error}). '
                'Riwayat & pengaturan tidak akan tersimpan. '
                'Tutup instance Centauri lain lalu coba lagi.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _retry,
                child: const Text('Coba lagi'),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    await ref.read(storageStatusProvider.notifier).retry();
    if (mounted) setState(() => _busy = false);
  }
}
