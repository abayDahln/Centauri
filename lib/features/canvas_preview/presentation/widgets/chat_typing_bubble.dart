import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';

/// Bubble tunggu saat AI sedang menyiapkan balasan.
///
/// Sengaja sesederhana bubble chat: satu gelembung dengan tiga titik berdenyut,
/// tanpa daftar tahap. Tahap internal tidak perlu ditampilkan ke pengguna.
class ChatTypingBubble extends StatefulWidget {
  const ChatTypingBubble({super.key});

  @override
  State<ChatTypingBubble> createState() => _ChatTypingBubbleState();
}

class _ChatTypingBubbleState extends State<ChatTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Titik berdenyut bergantian: fase digeser 1/3 periode per titik.
  double _dotOpacity(int index) {
    final phase = (_controller.value + index / 3) % 1.0;
    final wave = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
    return 0.25 + 0.75 * wave;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const ValueKey('chat-typing-bubble'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderSubtle),
          borderRadius: AppRadius.md,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Opacity(
                  opacity: _dotOpacity(i),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.palette.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
