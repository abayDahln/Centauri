import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../provider/generation_stream_provider.dart';

/// Kartu langkah di panel chat selama generate.
///
/// Menampilkan urutan tahap + durasi berjalan, supaya pengguna tahu proses
/// masih hidup dan sedang di tahap apa.
class GenerationStepCard extends ConsumerStatefulWidget {
  const GenerationStepCard({super.key});

  @override
  ConsumerState<GenerationStepCard> createState() => _GenerationStepCardState();
}

class _GenerationStepCardState extends ConsumerState<GenerationStepCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (ref.read(generationStreamProvider).phase.isActive) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final gen = ref.watch(
      generationStreamProvider.select(
        (s) => (
          phase: s.phase,
          page: s.previewPageIndex,
          total: s.knownScreenCount,
          startedAt: s.startedAt,
        ),
      ),
    );

    final active = switch (gen.phase) {
      GenerationPhase.preparing => 0,
      GenerationPhase.waiting => 1,
      GenerationPhase.streaming => 2,
      GenerationPhase.assembling => 3,
      _ => 4,
    };

    final pageLabel = gen.page > 0
        ? (gen.total != null && gen.total! > 0
              ? l10n.generationPageProgress(gen.page, gen.total!)
              : l10n.generationPageProgressUnknown(gen.page))
        : null;

    final steps = <String>[
      l10n.generationStepPreparing,
      l10n.generationStepWaiting,
      l10n.generationStepWriting,
      l10n.generationStepBuilding,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.generationTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _elapsed(gen.startedAt),
                style: TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 10.5,
                  height: 1.2,
                  color: palette.textDisabled,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _StepRow(
                label: steps[i],
                state: i < active
                    ? _StepState.done
                    : (i == active ? _StepState.active : _StepState.pending),
                trailing: i == 2 ? pageLabel : null,
              ),
            ),
        ],
      ),
    );
  }

  String _elapsed(DateTime? startedAt) {
    if (startedAt == null) return '';
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}

enum _StepState { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state, this.trailing});

  final String label;
  final _StepState state;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (state) {
      _StepState.done => palette.textSecondary,
      _StepState.active => palette.textPrimary,
      _StepState.pending => palette.textDisabled,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: switch (state) {
            _StepState.done => Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: palette.statusSuccess,
            ),
            _StepState.active => Padding(
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: palette.primary,
              ),
            ),
            _StepState.pending => Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.borderStrong,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: context.text.caption.copyWith(
              color: color,
              fontWeight: state == _StepState.active
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 10,
              height: 1.4,
              color: palette.textDisabled,
            ),
          ),
        ],
      ],
    );
  }
}
