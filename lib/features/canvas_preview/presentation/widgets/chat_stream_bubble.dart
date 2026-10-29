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
            if (text.isEmpty)
              const ChatTypingBubble()
            else ...[
              MarkdownMessage(
                text: text,
                baseColor: context.palette.textPrimary,
              ),
              const _StreamCursor(),
            ],
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(status, style: context.text.caption),
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
