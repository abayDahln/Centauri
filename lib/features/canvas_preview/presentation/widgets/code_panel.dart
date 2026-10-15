import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../code_exporter/data/code_export_service.dart';
import '../provider/workspace_provider.dart';

/// Panel kode read-only ala VS Code (Dev mode). Menampilkan HTML hasil AI
/// dengan nomor baris, breadcrumb file, dan aksi copy/simpan.
class CodePanel extends ConsumerStatefulWidget {
  const CodePanel({super.key});

  @override
  ConsumerState<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends ConsumerState<CodePanel> {
  final _exportService = CodeExportService();
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  static const double _lineHeight = 19.2; // 12px * 1.6

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _copy(String code) async {
    await _exportService.copyToClipboard(code);
    if (!mounted) return;
    _toast('HTML disalin ke clipboard');
  }

  Future<void> _save(String code) async {
    try {
      final path = await _exportService.saveToFile(
        fileName: 'centauri-ui.html',
        code: code,
      );
      if (!mounted || path == null) return;
      _toast('Disimpan: $path');
    } on CodeExportException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final html = ref.watch(workspaceProvider.select((s) => s.activePage?.html));

    return ColoredBox(
      color: AppColors.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CodeBreadcrumb(
            onCopy: html == null ? null : () => _copy(html),
            onSave: html == null ? null : () => _save(html),
          ),
          const Divider(height: 1),
          Expanded(
            child: html == null
                ? const _CodeEmptyState()
                : _CodeBody(
                    code: html,
                    lineHeight: _lineHeight,
                    verticalController: _verticalController,
                    horizontalController: _horizontalController,
                  ),
          ),
        ],
      ),
    );
  }
}

class _CodeBreadcrumb extends StatelessWidget {
  const _CodeBreadcrumb({required this.onCopy, required this.onSave});

  final VoidCallback? onCopy;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppColors.toolbarHeight,
      color: AppColors.bgBase,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 13),
          const SizedBox(width: 6),
          const Text('canvas', style: AppText.monoSmall),
          const Text('  ›  ', style: AppText.monoSmall),
          const Text(
            'index.html',
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _BarIcon(
            icon: Icons.copy_all_outlined,
            tooltip: 'Salin HTML',
            onPressed: onCopy,
          ),
          const SizedBox(width: 2),
          _BarIcon(
            icon: Icons.download_outlined,
            tooltip: 'Simpan sebagai .html',
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 24,
      child: IconButton(
        icon: Icon(icon, size: 15),
        tooltip: tooltip,
        splashRadius: 13,
        padding: EdgeInsets.zero,
        color: AppColors.textSecondary,
        onPressed: onPressed,
      ),
    );
  }
}

class _CodeBody extends StatelessWidget {
  const _CodeBody({
    required this.code,
    required this.lineHeight,
    required this.verticalController,
    required this.horizontalController,
  });

  final String code;
  final double lineHeight;
  final ScrollController verticalController;
  final ScrollController horizontalController;

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(code).length + 1;
    final gutterWidth = 16.0 + (lineCount.toString().length * 8);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: AppRadius.md,
        child: ColoredBox(
          color: const Color(0xFF16181D),
          child: Scrollbar(
            controller: verticalController,
            child: SingleChildScrollView(
              controller: verticalController,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LineGutter(lineCount: lineCount, width: gutterWidth),
                  Expanded(
                    child: Scrollbar(
                      controller: horizontalController,
                      notificationPredicate: (n) => n.depth == 1,
                      child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.sizeOf(context).width / 2,
                          ),
                          child: HighlightView(
                            code,
                            language: 'html',
                            theme: atomOneDarkTheme,
                            padding: const EdgeInsets.fromLTRB(8, 12, 16, 24),
                            textStyle: const TextStyle(
                              fontFamily: AppFonts.monoFamily,
                              fontFamilyFallback: AppFonts.monoFallback,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineGutter extends StatelessWidget {
  const _LineGutter({required this.lineCount, required this.width});

  final int lineCount;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFF13151A),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lineCount, (index) {
          return SizedBox(
            height: 19.2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CodeEmptyState extends StatelessWidget {
  const _CodeEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada kode.\nGenerate UI lebih dulu, lalu lihat HTML-nya di sini.',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ),
    );
  }
}
