import 'package:flutter/material.dart';

import '../config/app_motion.dart';

/// Panel samping yang muncul/hilang dengan animasi lebar (slide reveal).
///
/// Isi panel tetap selebar [width] selama animasi, lalu dipotong oleh
/// [ClipRect]. Dengan begitu teks dan kontrol tidak ikut mengempis saat panel
/// dibuka atau ditutup.
class AnimatedSidePanel extends StatelessWidget {
  const AnimatedSidePanel({
    super.key,
    required this.visible,
    required this.width,
    required this.alignment,
    required this.child,
  });

  final bool visible;
  final double width;

  /// Sisi tempat panel menempel: `centerStart` untuk panel kiri,
  /// `centerEnd` untuk panel kanan.
  final AlignmentGeometry alignment;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion ? Duration.zero : AppMotion.panel;
    // Panel kiri masuk dari kiri, panel kanan dari kanan. Posisi `start/end`
    // mengikuti arah baca supaya Arab juga benar.
    final fromLeft = alignment.resolve(Directionality.of(context)).x < 0;
    return ExcludeFocus(
      excluding: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.panelCurve,
            width: visible ? width : 0,
            child: ClipRect(
              child: OverflowBox(
                alignment: alignment,
                minWidth: width,
                maxWidth: width,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : Offset(fromLeft ? -1 : 1, 0),
                  duration: duration,
                  curve: AppMotion.panelCurve,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
