import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/app_palette.dart';
import '../../../app/config/theme.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/appearance_menu.dart';
import '../../../app/widgets/language_menu.dart';
import '../../../app/widgets/stitch_widgets.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../history/data/project_repository.dart';
import '../../history/presentation/history_provider.dart';
import '../../mcp/data/mcp_bridge.dart';
import '../../history/presentation/history_panel.dart';
import '../../mcp/data/mcp_server.dart';
import '../../prompt_editor/presentation/prompt_chat_panel.dart';
import 'provider/layout_provider.dart';
import 'provider/workspace_provider.dart';
import 'widgets/ai_status_indicator.dart';
import 'widgets/chat_landing.dart';
import 'widgets/chat_side_panel.dart';
import 'widgets/code_panel.dart';
import 'widgets/page_export_button.dart';
import 'widgets/page_preview.dart';
import 'widgets/page_switcher.dart';
import 'widgets/prompt_bar.dart';

/// Halaman utama workspace (UI & prototype builder). Menangani:
/// - layout adaptif desktop/mobile,
/// - auto-save debounce ke penyimpanan lokal,
/// - restore sesi aktif saat aplikasi dibuka (offline-first).
class CanvasPreviewPage extends ConsumerStatefulWidget {
  const CanvasPreviewPage({super.key});

  @override
  ConsumerState<CanvasPreviewPage> createState() => _CanvasPreviewPageState();
}

class _CanvasPreviewPageState extends ConsumerState<CanvasPreviewPage> {
  bool _restored = false;
  final FocusNode _shortcutFocus = FocusNode(debugLabel: 'workspace-shortcuts');

  @override
  void dispose() {
    _shortcutFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMcpServer());
  }

  Future<void> _startMcpServer() async {
    if (!mounted) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      await ref.read(mcpServerProvider).start(bridge: McpBridge(ref.container));
    } catch (_) {
      // Server opsional: kegagalan bind tidak boleh mengganggu workspace.
    }
  }

  Future<void> _restoreSession() async {
    if (_restored || !mounted) return;
    _restored = true;
    final workspace = ref.read(workspaceProvider);
    if (workspace.pages.isNotEmpty || workspace.messages.isNotEmpty) return;
    try {
      await ref.read(projectRepositoryProvider).clearActiveProjectId();
    } catch (_) {
      // Abaikan kegagalan storage: sesi baru tetap dibuat di bawah.
    }
    ref.read(historyProvider.notifier).startNew();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workspaceProvider, (previous, next) {
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

  /// Catat snapshot untuk undo bila perubahan menyentuh konten workspace
  /// (pages / messages / halaman aktif) — bukan sekadar seleksi.
  void _recordUndo(
    WidgetRef ref,
    WorkspaceState previous,
    WorkspaceState next,
  ) {
    final contentChanged =
        !identical(previous.pages, next.pages) ||
        !identical(previous.messages, next.messages) ||
        previous.activePageId != next.activePageId;
    if (!contentChanged) return;
    if (next.isGenerating) return;
    ref.read(workspaceProvider.notifier).recordHistory(previous);
  }

  /// Hotkey global desktop:
  /// Ctrl/Cmd+Z undo, Ctrl/Cmd+Shift+Z / Ctrl+Y redo, Delete/Backspace hapus
  /// node terpilih (atau halaman aktif).
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_textFieldHasFocus()) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final notifier = ref.read(workspaceProvider.notifier);

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
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      final state = ref.read(workspaceProvider);
      if (state.selectedNodeId != null) {
        _deleteSelectedNode();
        return KeyEventResult.handled;
      } else if (state.activePageId != null && state.pages.length > 1) {
        notifier.deletePage(state.activePageId!);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  bool _textFieldHasFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    if (identical(focus, _shortcutFocus)) return false;
    final context = focus.context;
    if (context == null) return false;
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

  /// Hapus node terpilih via WebView (jalur yang sama seperti menu elemen).
  Future<void> _deleteSelectedNode() async {
    final nodeId = ref.read(workspaceProvider).selectedNodeId;
    if (nodeId == null) return;
    await ref.read(workspaceProvider.notifier).deleteNode(nodeId);
  }
}

/// Live sync MCP di luar widget agar tidak ter-reset oleh rebuild.
class _McpLiveSync {
  static void onChanged(
    WidgetRef ref,
    WorkspaceState? previous,
    WorkspaceState next,
  ) {
    if (previous == null) return;
    if (identical(previous.pages, next.pages) &&
        identical(previous.messages, next.messages) &&
        previous.activePageId == next.activePageId &&
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
    WorkspaceState? previous,
    WorkspaceState next,
  ) {
    _instance._schedule(ref, previous, next);
  }

  void _schedule(WidgetRef ref, WorkspaceState? previous, WorkspaceState next) {
    if (previous != null &&
        identical(previous.pages, next.pages) &&
        identical(previous.messages, next.messages) &&
        previous.activePageId == next.activePageId) {
      return;
    }
    if (next.isGenerating) return;
    if (next.pages.isEmpty && next.messages.isEmpty) return;

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
  bool _autoShownChat = false;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(workspaceProvider.select((s) => s.outputMode));
    final canvasVisible = ref.watch(canvasVisibleProvider);
    final historyVisible = ref.watch(historyVisibleProvider);
    // Mode fokus chat: tanpa kanvas, panel chat selalu tampil.
    final showChat = ref.watch(panelVisibleProvider) || !canvasVisible;
    final hasUi = ref.watch(
      workspaceProvider.select((s) => s.hasRenderedPage || s.pages.isNotEmpty),
    );

    if (hasUi && !_autoShownChat) {
      _autoShownChat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(panelVisibleProvider.notifier).show();
      });
    }

    // Mode Kode (dev) membuka panel kode; mode Desain menyembunyikannya.
    final showCode = canvasVisible && hasUi && mode == OutputMode.dev;

    return Scaffold(
      backgroundColor: context.palette.bgBase,
      body: Column(
        children: [
          _TopBar(
            workspaceActive: hasUi,
            canvasVisible: canvasVisible,
            historyVisible: historyVisible,
            onToggleCanvas: () {
              final next = !canvasVisible;
              ref.read(canvasVisibleProvider.notifier).set(next);
              // Saat kanvas dibuka lagi, panel chat tetap terlihat.
              if (!next) ref.read(panelVisibleProvider.notifier).show();
            },
            onToggleHistory: () =>
                ref.read(historyVisibleProvider.notifier).toggle(),
          ),
          const StorageBanner(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (historyVisible) const _HistorySidebar(),
                if (!canvasVisible)
                  // Mode fokus chat: kanvas dan panel kode ditutup.
                  const Expanded(child: _ChatOnlyPane())
                else ...[
                  if (showChat) ...[
                    SizedBox(
                      width: AppMetrics.sideBarWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.palette.bgSurface,
                          border: Border(
                            right: BorderSide(
                              color: context.palette.borderSubtle,
                            ),
                          ),
                        ),
                        child: PromptChatPanel(),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasUi) const _PreviewToolbar(),
                        Expanded(
                          child: Stack(
                            children: [
                              if (hasUi)
                                const _CanvasSurface(child: _PreviewFrame())
                              else if (!showChat)
                                const ChatLanding()
                              else
                                const _EmptyPreviewHint(),
                              if (hasUi)
                                const Positioned(
                                  left: 24,
                                  top: 24,
                                  child: _AiStatusPill(),
                                ),
                              const Positioned(
                                left: 24,
                                right: 24,
                                bottom: 24,
                                child: PromptBar(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCode) ...[
                    SizedBox(
                      width: 420,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.palette.bgSurface,
                          border: Border(
                            left: BorderSide(
                              color: context.palette.borderSubtle,
                            ),
                          ),
                        ),
                        child: CodePanel(),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar kiri: daftar percakapan tersimpan. Selalu tampil di desktop,
/// terpisah dari panel chat.
class _HistorySidebar extends ConsumerWidget {
  const _HistorySidebar();

  static const double width = 260;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border(
            right: BorderSide(color: context.palette.borderSubtle),
          ),
        ),
        child: HistoryPanel(
          // Buka proyek dari sidebar: pastikan percakapannya terlihat.
          onOpenProject: () => ref.read(panelVisibleProvider.notifier).show(),
        ),
      ),
    );
  }
}

/// Mode fokus chat: percakapan memenuhi jendela, tanpa kanvas pratinjau.
class _ChatOnlyPane extends StatelessWidget {
  const _ChatOnlyPane();

  /// Lebar baca nyaman agar percakapan tidak membentang di layar ultrawide.
  static const double maxContentWidth = 760;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Daftar pesan tetap selebar jendela supaya scrollbar menempel di
          // tepi kanan; isi percakapan sendiri yang dibatasi [maxContentWidth].
          Expanded(child: PromptChatPanel(contentMaxWidth: maxContentWidth)),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: PromptBar(),
          ),
        ],
      ),
    );
  }
}

/// Bar atas: identitas proyek, status layanan, mode, riwayat aksi, ekspor.
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.workspaceActive,
    required this.canvasVisible,
    required this.historyVisible,
    required this.onToggleCanvas,
    required this.onToggleHistory,
  });

  final bool workspaceActive;
  final bool canvasVisible;
  final bool historyVisible;
  final VoidCallback onToggleCanvas;
  final VoidCallback onToggleHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);
    final history = ref.watch(historyProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final l10n = context.l10n;

    var projectTitle = l10n.canvasUntitledProject;
    for (final project in history.projects) {
      if (project.id == history.activeProjectId) {
        final title = project.title.trim();
        if (title.isNotEmpty) projectTitle = title;
        break;
      }
    }

    return Container(
      height: AppMetrics.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border(bottom: BorderSide(color: context.palette.borderSubtle)),
      ),
      child: Row(
        children: [
          // Kiri: riwayat percakapan, pratinjau, riwayat aksi, identitas proyek.
          Expanded(
            child: Row(
              children: [
                SoftIconButton(
                  icon: Icons.view_sidebar_outlined,
                  tooltip: historyVisible
                      ? l10n.canvasHideHistory
                      : l10n.canvasShowHistory,
                  active: historyVisible,
                  onPressed: onToggleHistory,
                ),
                SoftIconButton(
                  icon: canvasVisible
                      ? Icons.close_fullscreen_outlined
                      : Icons.open_in_full_outlined,
                  tooltip: canvasVisible
                      ? l10n.canvasHidePreview
                      : l10n.canvasShowPreview,
                  onPressed: onToggleCanvas,
                ),
                if (workspaceActive) ...[
                  const SizedBox(width: 2),
                  SoftIconButton(
                    icon: Icons.undo,
                    tooltip: l10n.canvasUndoTooltip,
                    onPressed: notifier.undo,
                  ),
                  const SizedBox(width: 2),
                  SoftIconButton(
                    icon: Icons.redo,
                    tooltip: l10n.canvasRedoTooltip,
                    onPressed: notifier.redo,
                  ),
                ],
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    projectTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.ui.copyWith(fontSize: 14),
                  ),
                ),
                if (workspaceActive) ...[
                  const SizedBox(width: 10),
                  Text(
                    l10n.canvasPageCount(state.pages.length),
                    style: context.text.monoSmall.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Tengah: mode Desain / Kode (hanya saat kanvas terbuka).
          if (workspaceActive && canvasVisible)
            SoftSegmented<OutputMode>(
              selected: state.outputMode,
              onChanged: notifier.setOutputMode,
              segments: [
                SoftSegment(
                  value: OutputMode.design,
                  label: l10n.canvasModeDesign,
                ),
                SoftSegment(value: OutputMode.dev, label: l10n.canvasModeCode),
              ],
            ),
          // Kanan: ekspor halaman (bila ada) dan pengaturan.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (workspaceActive) ...[
                  PageExportButton(primary: true),
                  const SizedBox(width: 8),
                ],
                const AppearanceMenuButton(),
                const SizedBox(width: 2),
                const LanguageMenuButton(),
                const SizedBox(width: 2),
                SoftIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l10n.canvasServiceSettings,
                  onPressed: () => context.push(AppRoutes.providers),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toolbar kanvas: tab halaman bergaris bawah + kontrol seleksi.
class _PreviewToolbar extends ConsumerWidget {
  const _PreviewToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionMode = ref.watch(
      workspaceProvider.select((s) => s.selectionMode),
    );
    final l10n = context.l10n;
    return Container(
      height: AppMetrics.toolbarHeight,
      padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border(bottom: BorderSide(color: context.palette.borderSubtle)),
      ),
      child: Row(
        children: [
          const Expanded(child: PageSwitcherBar()),
          const SizedBox(width: 8),
          Text(
            '100%',
            style: context.text.monoSmall.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: context.palette.borderSubtle),
          const SizedBox(width: 4),
          SoftIconButton(
            icon: Icons.touch_app_outlined,
            tooltip: selectionMode
                ? l10n.canvasSelectionOff
                : l10n.canvasSelectionOn,
            active: selectionMode,
            size: 32,
            iconSize: 16,
            onPressed: () =>
                ref.read(workspaceProvider.notifier).toggleSelectionMode(),
          ),
        ],
      ),
    );
  }
}

/// Kanvas: latar titik halus dan bingkai pratinjau di tengah.
class _CanvasSurface extends StatelessWidget {
  const _CanvasSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.bgBase,
      child: CustomPaint(
        painter: _DotGridPainter(color: context.palette.borderStrong),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  /// Warna titik mengikuti palet agar kanvas gelap tidak bertitik terang.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 16.0;
    for (var x = 8.0; x < size.width; x += gap) {
      for (var y = 8.0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bingkai pratinjau: bilah browser + halaman.
class _PreviewFrame extends ConsumerWidget {
  const _PreviewFrame();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(workspaceProvider.select((s) => s.activePage));
    return Container(
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.xl,
        border: Border.all(color: context.palette.borderSubtle),
        boxShadow: context.palette.shadowSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.palette.bgBase,
              border: Border(
                bottom: BorderSide(color: context.palette.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: context.palette.borderStrong,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 6),
                Text(
                  'centauri / ${page?.slug ?? context.l10n.canvasBreadcrumbFallback}',
                  style: context.text.monoSmall.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: PagePreview()),
        ],
      ),
    );
  }
}

/// Pill status AI mengambang (muncul saat generating).
class _AiStatusPill extends ConsumerWidget {
  const _AiStatusPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      workspaceProvider.select((s) => s.status != AiStatus.idle),
    );
    if (!active) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: context.palette.borderSubtle),
        boxShadow: context.palette.shadowSoft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AiStatusIndicator(compact: true),
          const SizedBox(width: 10),
          Tooltip(
            message: l10n.canvasStopGenerating,
            child: InkWell(
              onTap: () =>
                  ref.read(workspaceProvider.notifier).cancelGeneration(),
              borderRadius: AppRadius.pill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.palette.statusError.withValues(alpha: 0.14),
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stop_rounded,
                      size: 14,
                      color: context.palette.statusError,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.canvasStopAction,
                      style: TextStyle(
                        fontFamily: AppFonts.uiFamily,
                        fontFamilyFallback: AppFonts.uiFallback,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.palette.statusError,
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

class _EmptyPreviewHint extends StatelessWidget {
  const _EmptyPreviewHint();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 30,
                color: context.palette.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.canvasEmptyTitle,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(context.l10n.canvasEmptyBody, style: context.text.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ mobile --

class _MobileShell extends ConsumerWidget {
  const _MobileShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUi = ref.watch(
      workspaceProvider.select((s) => s.hasRenderedPage || s.pages.isNotEmpty),
    );
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.palette.bgBase,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: context.palette.textPrimary,
                borderRadius: AppRadius.sm,
              ),
              alignment: Alignment.center,
              child: const Text(
                'C',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hasUi ? l10n.canvasPrototypeTitle : 'Centauri',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.panelTitle.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
        actions: [
          SoftIconButton(
            icon: Icons.view_sidebar_outlined,
            tooltip: l10n.canvasChatPanelTooltip,
            onPressed: () =>
                _openSheet(context, const ChatSidePanel(), heightFactor: 0.75),
          ),
          SoftIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.canvasServiceSettings,
            onPressed: () => context.push(AppRoutes.providers),
          ),
          const LanguageMenuButton(),
          if (hasUi) ...[
            SoftIconButton(
              icon: Icons.code_outlined,
              tooltip: l10n.canvasModeCode,
              onPressed: () =>
                  _openSheet(context, const CodePanel(), heightFactor: 0.8),
            ),
            const PageExportButton(compact: true),
          ],
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          const StorageBanner(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasUi)
                  Container(
                    color: context.palette.bgSurface,
                    child: const PageSwitcherBar(),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      if (hasUi)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.palette.bgSurface,
                              borderRadius: AppRadius.md,
                              border: Border.all(
                                color: context.palette.borderSubtle,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: const PagePreview(),
                          ),
                        )
                      else
                        const ChatLanding(),
                      const Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: PromptBar(),
                      ),
                    ],
                  ),
                ),
              ],
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
      backgroundColor: context.palette.bgSurface,
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

/// Peringatan bila penyimpanan lokal gagal dibuka (mis. box Hive di-lock
/// instance app lain). App tetap jalan penuh.
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
    final l10n = context.l10n;

    return Material(
      color: context.palette.statusWarning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              Icons.storage_rounded,
              size: 16,
              color: context.palette.statusWarning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.storageFailedTitle),
                    TextSpan(text: l10n.storageFailedBody),
                  ],
                ),
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
              TextButton(onPressed: _retry, child: Text(l10n.commonRetry)),
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
