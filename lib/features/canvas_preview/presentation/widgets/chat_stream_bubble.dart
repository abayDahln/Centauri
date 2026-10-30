import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../provider/generation_stream_provider.dart';
import 'chat_typing_bubble.dart';
import 'markdown_message.dart';

/// Bubble balasan AI yang sedang mengalir.
///
/// Teks ditulis per potongan token (provider yang mendukung streaming) supaya
/// terasa seperti chat AI biasa. Untuk permintaan UI, blok kode HTML dibuang
/// oleh [GenerationStreamNotifier]; yang tampil hanya kalimat penjelasan plus
/// status halaman yang sedang ditulis.
class ChatStreamBubble extends ConsumerWidget {
  const ChatStreamBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(generationStreamProvider);
    if (!stream.phase.isActive) return const SizedBox.shrink();

    final text = stream.streamedText;
    final status = _statusFor(context, stream);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alpha',
              style: context.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            // Permintaan UI punya baris progres sendiri; titik tunggu hanya
            // untuk percakapan biasa supaya tidak tampil dua indikator.
            if (text.isEmpty && status == null) const ChatTypingBubble(),
            if (text.isNotEmpty) ...[
              MarkdownMessage(
                text: text,
                baseColor: context.palette.textPrimary,
              ),
              const _StreamCursor(),
            ],
            if (status != null) ...[
              const SizedBox(height: 10),
              _StreamProgress(label: status),
            ],
          ],
        ),
      ),
    );
  }

  /// Status singkat untuk permintaan UI: halaman ke berapa / tahap perakitan.
  String? _statusFor(BuildContext context, GenerationStreamState stream) {
    if (!stream.uiRequest) return null;
    final l10n = context.l10n;
    if (stream.phase == GenerationPhase.assembling) {
      return l10n.chatStreamFinishing;
    }
    final page = stream.previewPageIndex < 1 ? 1 : stream.previewPageIndex;
    final total = stream.knownScreenCount;
    return total == null
        ? l10n.chatStreamPage(page)
        : l10n.chatStreamPageOf(page, total);
  }
}

/// Progres saat AI menulis satu halaman.
///
/// Sebelumnya tahap ini hanya teks status diam di bawah kursor yang berkedip,
/// jadi terlihat seperti macet. Sekarang ada spinner kecil plus garis yang
/// menyapu — pola yang sama dengan pill progres di kanvas.
class _StreamProgress extends StatefulWidget {
  const _StreamProgress({required this.label});

  final String label;

  @override
  State<_StreamProgress> createState() => _StreamProgressState();
}

class _StreamProgressState extends State<_StreamProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final track = constraints.maxWidth;
                final bar = track * 0.3;
                return Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: palette.bgSunken)),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = reduceMotion ? 0.5 : _controller.value;
                        return PositionedDirectional(
                          start: (track + bar) * t - bar,
                          top: 0,
                          width: bar,
                          height: 3,
                          child: ColoredBox(color: palette.primary),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Kursor kecil yang berkedip di ujung teks, penanda output masih mengalir.
class _StreamCursor extends StatefulWidget {
  const _StreamCursor();

  @override
  State<_StreamCursor> createState() => _StreamCursorState();
}

class _StreamCursorState extends State<_StreamCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: 2,
          height: 13,
          decoration: BoxDecoration(
            color: context.palette.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
