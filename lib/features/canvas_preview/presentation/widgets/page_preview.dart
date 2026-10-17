import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/theme.dart';
import '../../data/services/canvas_service_registry.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../data/services/canvas_webview_service_factory.dart';
import '../../domain/page.dart';
import '../../domain/page_slug.dart';
import '../provider/workspace_provider.dart';

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
    } catch (e) {
      debugPrint('[workspace] retry render gagal: $e');
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Registrasi service di bawah id halaman aktif (agar MCP/exporter bisa
  /// menemukannya) dan muat HTML-nya.
  Future<void> _renderPage(String? pageId, String? html) async {
    if (_registeredPageId != null && _registeredPageId != pageId) {
      CanvasServiceRegistry.unregister(_registeredPageId!);
      _registeredPageId = null;
    }
    if (pageId != null) {
      CanvasServiceRegistry.register(pageId, _service);
      _registeredPageId = pageId;
    }
    try {
      await _service.renderHtml(html == null || html.isEmpty ? null : html);
      if (mounted && _error != null) setState(() => _error = null);
    } catch (e) {
      debugPrint('[workspace] renderHtml gagal: $e');
      if (mounted) setState(() => _error = '$e');
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
        final message = event.errorMessage ?? 'Terjadi kesalahan pada pratinjau.';
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
      case 'hover':
        ref.read(workspaceProvider.notifier).hoverNode(event.id);
        return;
    }
  }

  Future<void> _onNavigate(String href) async {
    final pages = ref.read(workspaceProvider).pages;
    final resolved = resolveLink(href, pages);
    switch (resolved.kind) {
      case LinkKind.internal:
        final id = resolved.pageId;
        if (id != null) ref.read(workspaceProvider.notifier).setActivePage(id);
      case LinkKind.external:
        final uri = Uri.tryParse(href.startsWith('//') ? 'https:$href' : href);
        if (uri == null) {
          _toast('Link tidak valid: $href');
          return;
        }
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) _toast('Tidak bisa membuka: $href');
        } catch (_) {
          _toast('Tidak bisa membuka: $href');
        }
      case LinkKind.unknown:
        _toast('Halaman tidak ditemukan: $href');
      case LinkKind.anchor:
        break;
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    final html = ref.watch(
      workspaceProvider.select((s) => s.activePage?.html),
    );

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
      workspaceProvider.select((s) => s.linkInterceptEnabled),
      (_, enabled) => _service.setLinkIntercept(enabled),
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

    return ClipRRect(
      borderRadius: AppRadius.lg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: RepaintBoundary(child: content),
      ),
    );
  }
}

class _PreviewEmptyState extends StatelessWidget {
  const _PreviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.web_asset_outlined,
                size: 30,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada halaman',
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
                'Ketik pesan untuk membuat halaman.',
                style: AppText.caption,
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
      color: AppColors.bgSunken,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.web_asset_off_outlined,
                size: 26,
                color: AppColors.statusError,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pratinjau gagal dimuat',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.length > 220 ? '${message.substring(0, 220)}…' : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 10.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jika tetap gagal, instal Microsoft Edge WebView2 Runtime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.textDisabled),
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
    return const ColoredBox(
      color: AppColors.bgSurface,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPrimary,
          ),
        ),
      ),
    );
  }
}
