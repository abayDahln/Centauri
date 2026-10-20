import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_palette.dart';
import '../config/theme.dart';

/// Jenis pesan singkat. Menentukan ikon dan warna status.
enum AppToastKind { info, success, error }

OverlayEntry? _activeToast;

/// Menampilkan pesan singkat di tengah atas layar.
///
/// Satu toast aktif pada satu waktu: toast baru langsung menggantikan yang
/// lama. Lebarnya mengikuti isi dengan batas setengah lebar layar, dan
/// warnanya ikut palet tema yang sedang aktif.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastKind kind = AppToastKind.info,
  Duration? duration,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _dismissActiveToast();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToastView(
      message: message,
      kind: kind,
      duration:
          duration ??
          (kind == AppToastKind.error
              ? const Duration(seconds: 4)
              : const Duration(seconds: 3)),
      onDismissed: () {
        if (identical(_activeToast, entry)) _activeToast = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

void _dismissActiveToast() {
  final entry = _activeToast;
  _activeToast = null;
  if (entry != null && entry.mounted) entry.remove();
}

class _AppToastView extends StatefulWidget {
  const _AppToastView({
    required this.message,
    required this.kind,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppToastKind kind;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_AppToastView> createState() => _AppToastViewState();
}

class _AppToastViewState extends State<_AppToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 140),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -0.25),
    end: Offset.zero,
  ).animate(_opacity);

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final media = MediaQuery.of(context);
    // Maksimal setengah lebar layar; di layar lebar dibatasi lagi agar pesan
    // pendek tidak melebar tanpa guna.
    final maxWidth = math.min(media.size.width * 0.5, 420.0);

    final (icon, accent) = switch (widget.kind) {
      AppToastKind.success => (
        Icons.check_circle_outline,
        palette.statusSuccess,
      ),
      AppToastKind.error => (Icons.error_outline, palette.statusError),
      AppToastKind.info => (Icons.info_outline, palette.textSecondary),
    };

    return Positioned(
      top: media.padding.top + 16,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _offset,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bgElevated,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: palette.borderSubtle),
                    boxShadow: palette.shadowRaised,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: accent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: AppFonts.uiFamily,
                            fontFamilyFallback: AppFonts.uiFallback,
                            fontSize: 13,
                            height: 1.35,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
