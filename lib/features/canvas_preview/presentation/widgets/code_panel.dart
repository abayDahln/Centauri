import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/error_messages.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_toast.dart';
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
    _toast(context.l10n.codePanelCopied);
  }

  Future<void> _save(String code) async {
    try {
      final path = await _exportService.saveToFile(
        fileName: 'centauri-ui.html',
        code: code,
      );
      if (!mounted || path == null) return;
      _toast(context.l10n.exportSaved(path));
    } on CodeExportException catch (e) {
      if (mounted) _toast(localizedAppError(context.l10n, e));
    }
  }

  void _toast(String message) => showAppToast(context, message);

  @override
  Widget build(BuildContext context) {
    final html = ref.watch(workspaceProvider.select((s) => s.activePage?.html));
    // Output Alpha bisa kosong; jangan tampilkan panel kode yang hampa.
    final hasCode = html != null && html.trim().isNotEmpty;

    return ColoredBox(
      color: context.palette.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CodeBreadcrumb(
            onCopy: hasCode ? () => _copy(html) : null,
            onSave: hasCode ? () => _save(html) : null,
          ),
          const Divider(height: 1),
          Expanded(
            child: !hasCode
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
    final l10n = context.l10n;
    return Container(
      height: AppMetrics.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border(bottom: BorderSide(color: context.palette.borderSubtle)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 13),
          const SizedBox(width: 6),
          Text('canvas', style: context.text.monoSmall),
          Text('  ›  ', style: context.text.monoSmall),
          Text(
            'index.html',
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 11,
              color: context.palette.textPrimary,
            ),
          ),
          const Spacer(),
          _BarIcon(
            icon: Icons.copy_all_outlined,
            tooltip: l10n.codePanelCopyTooltip,
            onPressed: onCopy,
          ),
          const SizedBox(width: 2),
          _BarIcon(
            icon: Icons.download_outlined,
            tooltip: l10n.codePanelSaveTooltip,
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
        color: context.palette.textSecondary,
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
        borderRadius: AppRadius.sm,
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
      color: const Color(0xFF101216),
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
                style: TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 12,
                  height: 1.6,
                  color: context.palette.textDisabled,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.codePanelEmpty,
          textAlign: TextAlign.center,
          style: context.text.caption,
        ),
      ),
    );
  }
}
