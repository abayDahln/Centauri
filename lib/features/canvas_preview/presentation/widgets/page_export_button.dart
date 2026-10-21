import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/error_messages.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_toast.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../../../code_exporter/data/figma_export_service.dart';
import '../../../code_exporter/data/page_export_service.dart';
import '../provider/workspace_provider.dart';

/// Tombol ekspor halaman aktif ke PNG/SVG/PDF dan payload Figma.
/// Dipakai di top bar desktop dan AppBar mobile.
class PageExportButton extends ConsumerStatefulWidget {
  const PageExportButton({
    super.key,
    this.compact = false,
    this.primary = false,
  });

  /// Bila true, tampil sebagai icon saja (mobile).
  final bool compact;

  /// Bila true, tampil sebagai tombol utama "Ekspor" (top bar desktop).
  final bool primary;

  @override
  ConsumerState<PageExportButton> createState() => _PageExportButtonState();
}

enum _PageExportKind { png, svg, pdf, figma }

class _PageExportButtonState extends ConsumerState<PageExportButton> {
  final PageExportService _service = PageExportService();
  final FigmaExportService _figma = FigmaExportService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final hasPage = ref.watch(
      workspaceProvider.select((s) => s.activePage != null),
    );
    final l10n = context.l10n;

    void snack(String message) {
      if (!mounted) return;
      showAppToast(context, message);
    }

    Future<void> run(_PageExportKind kind) async {
      final page = ref.read(workspaceProvider).activePage;
      if (page == null) {
        snack(l10n.exportNoPages);
        return;
      }
      setState(() => _busy = true);
      try {
        switch (kind) {
          case _PageExportKind.svg:
            final path = await _service.saveSvg(
              pageName: page.name,
              pageId: page.id,
              html: page.html,
            );
            if (path != null) snack(l10n.exportSaved(path));
          case _PageExportKind.png:
            final bytes = await _service.capturePngBytes(page.id);
            final path = await _service.savePng(
              pageName: page.name,
              pngBytes: bytes,
            );
            if (path != null) snack(l10n.exportSaved(path));
          case _PageExportKind.pdf:
            final bytes = await _service.capturePngBytes(page.id);
            final pdf = await _service.buildPdfFromPng(bytes);
            final path = await _service.savePdf(
              pageName: page.name,
              pdfBytes: pdf,
            );
            if (path != null) snack(l10n.exportSaved(path));
          case _PageExportKind.figma:
            final payload = await _figma.collectPayload(page.id);
            final json = _figma.buildFigmaJson(payload);
            await _figma.copyToClipboard(json);
            final path = await _figma.saveToFile(
              pageName: page.name,
              json: json,
            );
            final count = _figma.countNodes(payload);
            snack(
              path == null
                  ? l10n.exportFigmaCopied(count)
                  : l10n.exportFigmaSaved(count, path),
            );
        }
      } on PageExportException catch (e) {
        snack(l10n.appError(e));
      } on FigmaExportException catch (e) {
        snack(l10n.appError(e));
      } catch (_) {
        snack(l10n.exportFailed);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    if (widget.compact) {
      return PopupMenuButton<_PageExportKind>(
        enabled: hasPage && !_busy,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        tooltip: l10n.exportPageTooltip,
        onSelected: run,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _PageExportKind.png,
            child: Text(l10n.exportPng),
          ),
          PopupMenuItem(
            value: _PageExportKind.svg,
            child: Text(l10n.exportSvg),
          ),
          PopupMenuItem(
            value: _PageExportKind.pdf,
            child: Text(l10n.exportPdf),
          ),
          PopupMenuItem(
            value: _PageExportKind.figma,
            child: const Text('Figma'),
          ),
        ],
      );
    }

    return PopupMenuButton<_PageExportKind>(
      enabled: hasPage && !_busy,
      tooltip: l10n.exportPageTooltipCompact,
      onSelected: run,
      itemBuilder: (_) => [
        PopupMenuItem(value: _PageExportKind.png, child: Text(l10n.exportPng)),
        PopupMenuItem(value: _PageExportKind.svg, child: Text(l10n.exportSvg)),
        PopupMenuItem(value: _PageExportKind.pdf, child: Text(l10n.exportPdf)),
        PopupMenuItem(value: _PageExportKind.figma, child: const Text('Figma')),
      ],
      child: widget.primary
          ? _PrimaryExportButton(busy: _busy, enabled: hasPage)
          : SoftIconButton(
              icon: _busy ? Icons.hourglass_empty : Icons.download_outlined,
              tooltip: l10n.exportPageTooltip,
              onPressed: () {},
            ),
    );
  }
}

/// Tombol utama "Ekspor" pada top bar.
class _PrimaryExportButton extends StatelessWidget {
  const _PrimaryExportButton({required this.busy, required this.enabled});

  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    // Warna di atas aksen dipilih palet (onPrimary) supaya kontras tetap
    // terbaca untuk aksen terang maupun gelap.
    final onAccent = active
        ? context.palette.onPrimary
        : context.palette.textDisabled;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: active ? context.palette.primary : context.palette.bgSunken,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: onAccent),
            )
          else
            Icon(Icons.download_outlined, size: 16, color: onAccent),
          const SizedBox(width: 8),
          Text(
            context.l10n.exportAction,
            style: context.text.button.copyWith(color: onAccent),
          ),
        ],
      ),
    );
  }
}
