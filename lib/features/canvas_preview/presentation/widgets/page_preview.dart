import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_toast.dart';
import '../../data/services/canvas_service_registry.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../data/services/canvas_webview_service_factory.dart';
import '../../domain/page.dart';
import '../../domain/page_slug.dart';
import '../provider/workspace_provider.dart';
import 'chat_side_panel.dart';
import 'page_switch_tracker.dart';

/// Host preview halaman: SATU WebView untuk seluruh app yang selalu
/// menampilkan halaman aktif. Fluid — mengisi penuh kontainer, tanpa lebar
/// CSS yang di-pin. Klik `<a href>` di-intercept oleh bridge JS lalu dipetakan
/// ke halaman yang cocok (atau dibuka di browser untuk link eksternal).
class PagePreview extends ConsumerStatefulWidget {
  const PagePreview({super.key});

  @override
  ConsumerState<PagePreview> createState() => _PagePreviewState();
}

class _PagePreviewState extends ConsumerState<PagePreview> {
  final CanvasWebviewService _service = createCanvasWebviewService();
  StreamSubscription<CanvasSelectEvent>? _subscription;
  bool _ready = false;
  String? _error;
  String? _registeredPageId;

  /// Overlay "Memuat…" hanya untuk pergantian halaman (bukan mutasi HTML
  /// halaman yang sama) — lihat [PageSwitchTracker].
  final PageSwitchTracker _switchTracker = PageSwitchTracker();
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.init();
      _subscription = _service.selectionEvents.listen(
        _onEvent,
        onError: (Object e) => debugPrint('[workspace] bridge error: $e'),
      );
      final page = ref.read(workspaceProvider).activePage;
      if (page != null) {
        _registeredPageId = page.id;
        CanvasServiceRegistry.register(page.id, _service);
        await _service.renderHtml(page.html.isEmpty ? null : page.html);
        await _service.setSelectionMode(
          ref.read(workspaceProvider).selectionMode,
        );
      } else {
        await _service.renderHtml(null);
      }
    } catch (e) {
      debugPrint('[workspace] WebView gagal init/render: $e');
      _error = '$e';
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _retryRender() async {
    if (mounted) setState(() => _error = null);
    try {
      final page = ref.read(workspaceProvider).activePage;
      await _service.renderHtml(
        page == null || page.html.isEmpty ? null : page.html,
      );
      await _service.setSelectionMode(
        ref.read(workspaceProvider).selectionMode,
      );
    } catch (e) {
      debugPrint('[workspace] retry render gagal: $e');
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Registrasi service di bawah id halaman aktif (agar MCP/exporter bisa
  /// menemukannya) dan muat HTML-nya.
  Future<void> _renderPage(String? pageId, String? html) async {
    // Berpindah halaman → tindih preview dengan indikator memuat selagi
    // WebView memuat dokumen baru (klik tab langsung terasa responsif).
    final switching = _switchTracker.isSwitching(pageId);
    if (switching && mounted && _ready) setState(() => _switching = true);
    if (_registeredPageId != null && _registeredPageId != pageId) {
      CanvasServiceRegistry.unregister(_registeredPageId!);
      _registeredPageId = null;
    }
    if (pageId != null) {
      CanvasServiceRegistry.register(pageId, _service);
      _registeredPageId = pageId;
    }
    // Error halaman sebelumnya tidak relevan lagi.
    if (mounted && _error != null) setState(() => _error = null);
    try {
      await _service.renderHtml(html == null || html.isEmpty ? null : html);
      // Dokumen baru selalu mulai di mode interaksi; terapkan ulang.
      await _service.setSelectionMode(
        ref.read(workspaceProvider).selectionMode,
      );
      if (mounted && _error != null) setState(() => _error = null);
    } catch (e) {
      debugPrint('[workspace] renderHtml gagal: $e');
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted && _switching) setState(() => _switching = false);
    }
  }

  void _onEvent(CanvasSelectEvent event) {
    switch (event.type) {
      case 'png':
      case 'pngError':
      case 'html':
      case 'outerHtml':
      case 'outerHtmlError':
        return; // dikonsumsi peminta via stream yang sama.
      case 'error':
        final message = event.errorMessage ?? context.l10n.previewGenericError;
        debugPrint('[workspace] bridge error: $message');
        if (mounted) setState(() => _error = message);
        return;
      case 'ready':
        if (mounted && _error != null) setState(() => _error = null);
        return;
      case 'navigate':
        _onNavigate(event.href ?? '');
        return;
      case 'geometry':
        final geometry = event.geometry;
        if (geometry != null) {
          ref.read(workspaceProvider.notifier).updateNodeGeometry(geometry);
        }
        return;
      case 'select':
        ref.read(workspaceProvider.notifier).selectNodeFromCanvas(event.id);
        return;
      case 'editWithAi':
        _editElementWithAi(event.id, event.label);
        return;
      case 'deleteNode':
        _deleteNodeFromCanvas(event.id);
        return;
      case 'hover':
        ref.read(workspaceProvider.notifier).hoverNode(event.id);
        return;
    }
  }

  Future<void> _onNavigate(String href) async {
    final pages = ref.read(workspaceProvider).pages;
    final resolved = resolveLink(href, pages);
    // Teks diambil sebelum ada `await` agar context tidak dipakai di celah async.
    final l10n = context.l10n;
    switch (resolved.kind) {
      case LinkKind.internal:
        final id = resolved.pageId;
        if (id != null) ref.read(workspaceProvider.notifier).setActivePage(id);
      case LinkKind.external:
        final uri = Uri.tryParse(href.startsWith('//') ? 'https:$href' : href);
        if (uri == null) {
          _toast(l10n.previewLinkInvalid(href));
          return;
        }
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) _toast(l10n.previewLinkOpenFailed(href));
        } catch (_) {
          _toast(l10n.previewLinkOpenFailed(href));
        }
      case LinkKind.unknown:
        _toast(l10n.previewPageNotFound(href));
      case LinkKind.anchor:
        break;
    }
  }

  /// "Edit dengan AI" dari menu elemen: tempel mention lalu buka chat.
  void _editElementWithAi(String? nodeId, String? label) {
    if (nodeId == null) return;
    ref
        .read(workspaceProvider.notifier)
        .addElementMention(nodeId: nodeId, label: label ?? '');
    ref.read(panelTabProvider.notifier).select(PanelTab.chat);
    ref.read(panelVisibleProvider.notifier).show();
  }

  /// "Hapus komponen" dari menu elemen: hapus node lalu sinkronkan HTML.
  Future<void> _deleteNodeFromCanvas(String? nodeId) async {
    if (nodeId == null) return;
    final l10n = context.l10n;
    final ok = await ref.read(workspaceProvider.notifier).deleteNode(nodeId);
    if (!ok) _toast(l10n.previewDeleteFailed);
  }

  void _toast(String message) {
    if (!mounted) return;
    showAppToast(context, message, kind: AppToastKind.error);
  }

  @override
  void dispose() {
    if (_registeredPageId != null) {
      CanvasServiceRegistry.unregister(_registeredPageId!);
    }
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final html = ref.watch(workspaceProvider.select((s) => s.activePage?.html));

    // Muat ulang saat halaman aktif berganti atau HTML-nya berubah.
    // `activePage` mengembalikan instance baru setiap halaman berubah, jadi
    // listener ini menangkap pergantian halaman DAN perubahan HTML.
    ref.listen<AppPage?>(
      workspaceProvider.select((s) => s.activePage),
      (_, page) => _renderPage(page?.id, page?.html),
    );

    ref.listen<String?>(
      workspaceProvider.select((s) => s.selectedNodeId),
      (_, id) => _service.selectNode(id),
    );
    ref.listen<String?>(
      workspaceProvider.select((s) => s.hoveredNodeId),
      (_, id) => _service.hoverNode(id),
    );
    ref.listen<bool>(
      workspaceProvider.select((s) => s.selectionMode),
      (_, enabled) => _service.setSelectionMode(enabled),
    );

    Widget content;
    if (!_ready) {
      content = const _WebviewLoading();
    } else if (html == null || html.isEmpty) {
      content = const _PreviewEmptyState();
    } else if (_error != null) {
      content = _WebviewError(message: _error!, onRetry: _retryRender);
    } else {
      content = _service.buildView();
    }

    // Bingkai (border, radius, bilah browser) disediakan pemanggil agar
    // WebView bisa mengisi penuh area tanpa clipping tambahan.
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: content),
          // Selagi dokumen baru dimuat, halaman lama tetap terlihat dan
          // ditindih scrim + spinner supaya pindah halaman terasa responsif.
          if (_switching) const _PageSwitchLoading(),
        ],
      ),
    );
  }
}

class _PageSwitchLoading extends StatelessWidget {
  const _PageSwitchLoading();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: context.palette.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.previewLoading,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewEmptyState extends StatelessWidget {
  const _PreviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.web_asset_outlined,
                size: 30,
                color: context.palette.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.previewNoPagesTitle,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.previewNoPagesBody,
                style: context.text.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebviewError extends StatelessWidget {
  const _WebviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSunken,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.web_asset_off_outlined,
                size: 26,
                color: context.palette.statusError,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.previewLoadFailedTitle,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.length > 220
                    ? '${message.substring(0, 220)}…'
                    : message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 10.5,
                  height: 1.5,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.previewWebView2Hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: context.palette.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebviewLoading extends StatelessWidget {
  const _WebviewLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSurface,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.palette.primary,
          ),
        ),
      ),
    );
  }
}
