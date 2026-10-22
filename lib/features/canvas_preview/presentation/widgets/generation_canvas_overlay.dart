import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../provider/generation_stream_provider.dart';
import '../provider/workspace_provider.dart';

/// Overlay kanvas selama generate.
///
/// Sebelum ada HTML parsial: skeleton yang berdenyut pelan. Sesudahnya: garis
/// progres tipis + label halaman, sementara dokumen parsial sendiri sudah
/// tampil di WebView.
class GenerationCanvasOverlay extends ConsumerStatefulWidget {
  const GenerationCanvasOverlay({super.key});

  @override
  ConsumerState<GenerationCanvasOverlay> createState() =>
      _GenerationCanvasOverlayState();
}

class _GenerationCanvasOverlayState
    extends ConsumerState<GenerationCanvasOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gen = ref.watch(
      generationStreamProvider.select(
        (s) => (
          phase: s.phase,
          uiRequest: s.uiRequest,
          hasPreview: s.previewHtml != null,
          page: s.previewPageIndex,
          total: s.knownScreenCount,
        ),
      ),
    );
    // Percakapan biasa tidak menyentuh kanvas.
    if (!gen.phase.isActive || !gen.uiRequest) return const SizedBox.shrink();

    // Skeleton hanya bila belum ada desain sama sekali; untuk penyempurnaan,
    // desain lama tetap terlihat dan hanya diberi pill progres.
    final hasPages = ref.watch(
      workspaceProvider.select((s) => s.pages.isNotEmpty),
    );

    final l10n = context.l10n;
    final pageLabel = gen.page > 0
        ? (gen.total != null && gen.total! > 0
              ? l10n.generationPageProgress(gen.page, gen.total!)
              : l10n.generationPageProgressUnknown(gen.page))
        : null;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = MediaQuery.disableAnimationsOf(context)
              ? 0.5
              : _controller.value;
          if (!gen.hasPreview && !hasPages) return _skeleton(context, t);
          return _progress(
            context,
            t,
            l10n.generationCanvasBuilding,
            pageLabel,
          );
        },
      ),
    );
  }

  Widget _skeleton(BuildContext context, double t) {
    final palette = context.palette;

    Widget block({double height = 12, int index = 0, double? width}) {
      final phase = (t + index * 0.11) % 1.0;
      final wave = 1 - (2 * phase - 1).abs();
      return Opacity(
        opacity: 0.55 + 0.45 * wave,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: palette.bgSunken,
            borderRadius: AppRadius.sm,
          ),
        ),
      );
    }

    return ColoredBox(
      color: palette.bgSurface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: block(height: 12, index: 0, width: 120),
            ),
            const SizedBox(height: 20),
            // Proporsional: skeleton tidak boleh meluber di kanvas pendek.
            Expanded(flex: 3, child: block(height: double.infinity, index: 1)),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: block(height: double.infinity, index: 2)),
                  const SizedBox(width: 12),
                  Expanded(child: block(height: double.infinity, index: 3)),
                  const SizedBox(width: 12),
                  Expanded(child: block(height: double.infinity, index: 4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            block(height: 10, index: 5),
            const SizedBox(height: 8),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.6,
              child: block(height: 10, index: 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(
    BuildContext context,
    double t,
    String label,
    String? pageLabel,
  ) {
    final palette = context.palette;
    final text = pageLabel == null ? label : '$label · $pageLabel';
    return Stack(
      children: [
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            height: 2,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bar = constraints.maxWidth * 0.32;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(
                      start: (constraints.maxWidth + bar) * t - bar,
                      top: 0,
                      width: bar,
                      height: 2,
                      child: ColoredBox(color: palette.primary),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: palette.bgElevated,
                borderRadius: AppRadius.sm,
                border: Border.all(color: palette.borderSubtle),
                boxShadow: palette.shadowRaised,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: palette.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.uiFamily,
                      fontFamilyFallback: AppFonts.uiFallback,
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
