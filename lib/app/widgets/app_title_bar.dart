import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../config/theme.dart';
import '../l10n/l10n.dart';

/// Title bar kustom untuk shell desktop (Windows).
///
/// Latar panel putih, garis bawah 1 px, logo gelap, dan tombol window
/// minimalis. Mengikuti Centauri Design System.
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
      child: Container(
        height: AppColors.titleBarHeight,
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'C',
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: AppText.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _WindowButton(
              icon: Icons.remove,
              tooltip: context.l10n.windowMinimize,
              onTap: () => _safe(windowManager.minimize),
            ),
            _WindowButton(
              icon: _isMaximized
                  ? Icons.filter_none
                  : Icons.crop_square_outlined,
              tooltip: _isMaximized
                  ? context.l10n.windowRestore
                  : context.l10n.windowMaximize,
              onTap: _toggleMaximize,
            ),
            _WindowButton(
              icon: Icons.close,
              tooltip: context.l10n.windowClose,
              isClose: true,
              onTap: () => _safe(windowManager.close),
            ),
          ],
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
