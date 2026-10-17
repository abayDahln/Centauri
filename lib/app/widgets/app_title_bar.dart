import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../config/theme.dart';

/// Title bar kustom untuk shell desktop (Windows). Gaya lembut ala Stitch:
/// latar putih, teks gelap, tombol window minimalis.
class AppTitleBar extends StatefulWidget {
  const AppTitleBar({super.key, this.title = 'Centauri'});

  final String title;

  static bool get isSupported => Platform.isWindows || Platform.isLinux;

  @override
  State<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends State<AppTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    try {
      windowManager.addListener(this);
      _syncMaximized();
    } catch (_) {
      // Platform channel tidak tersedia (mis. widget test): abaikan.
    }
  }

  Future<void> _syncMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = maximized);
    } catch (_) {
      // Abaikan bila window manager tidak tersedia.
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void dispose() {
    try {
      windowManager.removeListener(this);
    } catch (_) {
      // Abaikan.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _safe(windowManager.startDragging),
      onDoubleTap: _toggleMaximize,
      child: SizedBox(
        height: AppColors.titleBarHeight,
        child: ColoredBox(
          color: AppColors.bgSurface,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'C',
                  style: TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              _WindowButton(
                icon: Icons.remove,
                tooltip: 'Perkecil',
                onTap: () => _safe(windowManager.minimize),
              ),
              _WindowButton(
                icon: _isMaximized
                    ? Icons.filter_none
                    : Icons.crop_square_outlined,
                tooltip: _isMaximized ? 'Kembalikan' : 'Perbesar',
                onTap: _toggleMaximize,
              ),
              _WindowButton(
                icon: Icons.close,
                tooltip: 'Tutup',
                isClose: true,
                onTap: () => _safe(windowManager.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {
      // Abaikan bila window manager tidak tersedia.
    }
  }

  static void _safe(Future<void> Function() action) {
    try {
      action();
    } catch (_) {
      // Abaikan bila window manager tidak tersedia.
    }
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isClose
        ? AppColors.statusError
        : AppColors.hoverBg;

    return Semantics(
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 46,
            height: AppColors.titleBarHeight,
            alignment: Alignment.center,
            color: _hovered ? hoverColor : Colors.transparent,
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered && widget.isClose
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
