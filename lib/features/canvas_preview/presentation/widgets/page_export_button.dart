import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../../../code_exporter/data/figma_export_service.dart';
import '../../../code_exporter/data/page_export_service.dart';
import '../provider/workspace_provider.dart';

/// Tombol ekspor halaman aktif ke PNG/SVG/PDF dan payload Figma.
/// Dipakai di top bar desktop dan AppBar mobile.
class PageExportButton extends ConsumerStatefulWidget {
  const PageExportButton({super.key, this.compact = false});

  /// Bila true, tampil sebagai icon saja (mobile).
  final bool compact;

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

    void snack(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.bgElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    Future<void> run(_PageExportKind kind) async {
      final page = ref.read(workspaceProvider).activePage;
      if (page == null) {
        snack('Belum ada halaman untuk diekspor.');
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
            if (path != null) snack('Disimpan: $path');
          case _PageExportKind.png:
            final bytes = await _service.capturePngBytes(page.id);
            final path = await _service.savePng(
              pageName: page.name,
              pngBytes: bytes,
            );
            if (path != null) snack('Disimpan: $path');
          case _PageExportKind.pdf:
            final bytes = await _service.capturePngBytes(page.id);
            final pdf = await _service.buildPdfFromPng(bytes);
            final path = await _service.savePdf(
              pageName: page.name,
              pdfBytes: pdf,
            );
            if (path != null) snack('Disimpan: $path');
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
                  ? 'Data Figma ($count elemen) disalin.'
                  : 'Data Figma ($count elemen) tersimpan: $path',
            );
        }
      } on PageExportException catch (e) {
        snack(e.message);
      } on FigmaExportException catch (e) {
        snack(e.message);
      } catch (_) {
        snack('Ekspor gagal. Coba lagi.');
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
        tooltip: 'Ekspor halaman',
        onSelected: run,
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _PageExportKind.png,
            child: Text('PNG (gambar)'),
          ),
          PopupMenuItem(
            value: _PageExportKind.svg,
            child: Text('SVG (vektor)'),
          ),
          PopupMenuItem(
            value: _PageExportKind.pdf,
            child: Text('PDF (dokumen)'),
          ),
          PopupMenuItem(
            value: _PageExportKind.figma,
            child: Text('Figma'),
          ),
        ],
      );
    }

    return PopupMenuButton<_PageExportKind>(
      enabled: hasPage && !_busy,
      tooltip: 'Ekspor halaman (PNG/SVG/PDF/Figma)',
      onSelected: run,
      itemBuilder: (_) => const [
        PopupMenuItem(value: _PageExportKind.png, child: Text('PNG (gambar)')),
        PopupMenuItem(value: _PageExportKind.svg, child: Text('SVG (vektor)')),
        PopupMenuItem(
          value: _PageExportKind.pdf,
          child: Text('PDF (dokumen)'),
        ),
        PopupMenuItem(
          value: _PageExportKind.figma,
          child: Text('Figma'),
        ),
      ],
      child: SoftIconButton(
        icon: _busy ? Icons.hourglass_empty : Icons.download_outlined,
        tooltip: 'Ekspor halaman',
        onPressed: () {},
      ),
    );
  }
}
