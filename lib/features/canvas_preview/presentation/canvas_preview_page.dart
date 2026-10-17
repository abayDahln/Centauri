import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
import '../../../app/widgets/stitch_widgets.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../history/data/project_repository.dart';
import '../../history/presentation/history_provider.dart';
import '../../mcp/data/mcp_bridge.dart';
import '../../mcp/data/mcp_server.dart';
import '../../provider_config/presentation/providers/provider_config_provider.dart';
import '../data/services/canvas_service_registry.dart';
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
      await ref
          .read(mcpServerProvider)
          .start(bridge: McpBridge(ref.container));
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
  void _recordUndo(WidgetRef ref, WorkspaceState previous, WorkspaceState next) {
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

  /// Hapus node terpilih via service WebView (jalur yang sama seperti MCP).
  Future<void> _deleteSelectedNode() async {
    final state = ref.read(workspaceProvider);
    final pageId = state.activePageId;
    final nodeId = state.selectedNodeId;
    if (pageId == null || nodeId == null) return;
    final service = CanvasServiceRegistry.forFrame(pageId);
    if (service == null) return;
    await service.deleteNode(nodeId);
    await service.requestHtml();
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
  bool _showCode = false;
  bool _autoShownChat = false;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(workspaceProvider.select((s) => s.outputMode));
    final showChat = ref.watch(panelVisibleProvider);
    final hasUi = ref.watch(
      workspaceProvider.select((s) => s.hasRenderedPage || s.pages.isNotEmpty),
    );

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
            workspaceActive: hasUi,
            onTogglePrompt: () =>
                ref.read(panelVisibleProvider.notifier).toggle(),
            onToggleCode: () => setState(() => _showCode = !_showCode),
            promptVisible: showChat,
            codeVisible: showCode,
          ),
          const StorageBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showChat) ...[
                    const SizedBox(width: 320, child: ChatSidePanel()),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasUi) ...[
                          const PageSwitcherBar(),
                          const SizedBox(height: 8),
                        ],
                        Expanded(
                          child: Stack(
                            children: [
                              if (hasUi)
                                const PagePreview()
                              else if (!showChat)
                                const ChatLanding()
                              else
                                const _EmptyPreviewHint(),
                              if (hasUi)
                                const Positioned(
                                  left: 16,
                                  top: 16,
                                  child: _AiStatusPill(),
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
    required this.workspaceActive,
    required this.onTogglePrompt,
    required this.onToggleCode,
    required this.promptVisible,
    required this.codeVisible,
  });

  final bool workspaceActive;
  final VoidCallback onTogglePrompt;
  final VoidCallback onToggleCode;
  final bool promptVisible;
  final bool codeVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(providerConfigProvider).value?.activeProvider;
    final state = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);

    return SizedBox(
      height: AppColors.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SoftIconButton(
              icon: Icons.menu,
              tooltip: 'Panel Chat dan Riwayat',
              active: promptVisible,
              onPressed: onTogglePrompt,
            ),
            const SizedBox(width: 4),
            SoftIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Konfigurasi provider',
              onPressed: () => context.push(AppRoutes.providers),
            ),
            const SizedBox(width: 12),
            if (workspaceActive) ...[
              SoftIconButton(
                icon: Icons.code_outlined,
                tooltip: 'Kode',
                active: codeVisible,
                onPressed: onToggleCode,
              ),
              const SizedBox(width: 12),
            ],
            InkWell(
              onTap: () => context.push(AppRoutes.providers),
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
            if (workspaceActive) ...[
              SoftIconButton(
                icon: Icons.touch_app_outlined,
                tooltip: state.linkInterceptEnabled
                    ? 'Mode: navigasi link'
                    : 'Mode: seleksi elemen',
                active: state.linkInterceptEnabled,
                onPressed: notifier.toggleLinkIntercept,
              ),
              const SizedBox(width: 8),
              const PageExportButton(),
              const SizedBox(width: 8),
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
              SoftIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Bersihkan semua',
                onPressed: state.pages.isEmpty ? null : notifier.clearWorkspace,
              ),
            ],
          ],
        ),
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
          Tooltip(
            message: 'Hentikan generate',
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
                      'Hentikan',
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

class _EmptyPreviewHint extends StatelessWidget {
  const _EmptyPreviewHint();
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
                'Ketik pesan untuk mulai.',
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

class _MobileShell extends ConsumerWidget {
  const _MobileShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUi = ref.watch(
      workspaceProvider.select((s) => s.hasRenderedPage || s.pages.isNotEmpty),
    );

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(hasUi ? 'Prototype' : 'Centauri'),
        actions: [
          SoftIconButton(
            icon: Icons.menu,
            tooltip: 'Panel Chat dan Riwayat',
            onPressed: () =>
                _openSheet(context, const ChatSidePanel(), heightFactor: 0.75),
          ),
          SoftIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Konfigurasi provider',
            onPressed: () => context.push(AppRoutes.providers),
          ),
          if (hasUi) ...[
            SoftIconButton(
              icon: Icons.code_outlined,
              tooltip: 'Kode',
              onPressed: () =>
                  _openSheet(context, const CodePanel(), heightFactor: 0.8),
            ),
            const PageExportButton(compact: true),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const StorageBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasUi) ...[
                    const PageSwitcherBar(),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: Stack(
                      children: [
                        if (hasUi) const PagePreview() else const ChatLanding(),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: PromptBar(),
                        ),
                      ],
                    ),
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
                'Penyimpanan lokal gagal dibuka. '
                'Tutup Centauri lain lalu coba lagi.',
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
