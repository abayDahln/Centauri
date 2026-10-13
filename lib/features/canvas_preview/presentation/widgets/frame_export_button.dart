import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/widgets/stitch_widgets.dart';
import '../../../code_exporter/data/frame_export_service.dart';
import '../provider/canvas_provider.dart';

/// Tombol ekspor frame aktif ke PNG/SVG/PDF (Fase 3).
/// Dipakai di top bar desktop dan AppBar mobile.
class FrameExportButton extends ConsumerStatefulWidget {
  const FrameExportButton({super.key, this.compact = false});

  /// Bila true, tampil sebagai icon saja (mobile).
  final bool compact;

  @override
  ConsumerState<FrameExportButton> createState() => _FrameExportButtonState();
}

enum _FrameExportKind { png, svg, pdf }

class _FrameExportButtonState extends ConsumerState<FrameExportButton> {
  final FrameExportService _service = FrameExportService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final hasFrame = ref.watch(
      canvasProvider.select((s) => s.activeFrame != null),
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

    Future<void> run(_FrameExportKind kind) async {
      final frame = ref.read(canvasProvider).activeFrame;
      if (frame == null) {
        snack('Belum ada frame untuk diekspor.');
        return;
      }
      setState(() => _busy = true);
      try {
        switch (kind) {
          case _FrameExportKind.svg:
            final path = await _service.saveSvg(
              frameTitle: frame.title,
              html: frame.html,
              width: frame.size.width,
              height: frame.size.height,
            );
            if (path != null) snack('Disimpan: $path');
          case _FrameExportKind.png:
            final bytes = await _service.capturePngBytes(frame.id);
            final path = await _service.savePng(
              frameTitle: frame.title,
              pngBytes: bytes,
            );
            if (path != null) snack('Disimpan: $path');
          case _FrameExportKind.pdf:
            final bytes = await _service.capturePngBytes(frame.id);
            final pdf = await _service.buildPdfFromPng(bytes);
            final path = await _service.savePdf(
              frameTitle: frame.title,
              pdfBytes: pdf,
            );
            if (path != null) snack('Disimpan: $path');
        }
      } on FrameExportException catch (e) {
        snack(e.message);
      } catch (_) {
        snack('Ekspor gagal. Coba lagi.');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    if (widget.compact) {
      return PopupMenuButton<_FrameExportKind>(
        enabled: hasFrame && !_busy,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        tooltip: 'Ekspor frame (PNG/SVG/PDF)',
        onSelected: run,
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _FrameExportKind.png,
            child: Text('PNG (gambar)'),
          ),
          PopupMenuItem(
            value: _FrameExportKind.svg,
            child: Text('SVG (vektor)'),
          ),
          PopupMenuItem(
            value: _FrameExportKind.pdf,
            child: Text('PDF (dokumen)'),
          ),
        ],
      );
    }

    return PopupMenuButton<_FrameExportKind>(
      enabled: hasFrame && !_busy,
      tooltip: 'Ekspor frame (PNG/SVG/PDF)',
      onSelected: run,
      itemBuilder: (_) => const [
        PopupMenuItem(value: _FrameExportKind.png, child: Text('PNG (gambar)')),
        PopupMenuItem(value: _FrameExportKind.svg, child: Text('SVG (vektor)')),
        PopupMenuItem(
          value: _FrameExportKind.pdf,
          child: Text('PDF (dokumen)'),
        ),
      ],
      child: SoftIconButton(
        icon: _busy ? Icons.hourglass_empty : Icons.download_outlined,
        tooltip: 'Ekspor frame (PNG/SVG/PDF)',
        onPressed: () {},
      ),
    );
  }
}
