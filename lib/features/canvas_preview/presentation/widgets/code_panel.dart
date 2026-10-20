import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/error_messages.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_toast.dart';
import '../../../code_exporter/data/code_export_service.dart';
import '../provider/workspace_provider.dart';
import 'code_highlighter.dart';

const double _codeFontSize = 12;
const double _codeLineHeightFactor = 1.6;
const double _codeLineHeight = _codeFontSize * _codeLineHeightFactor;
const Color _codeBackground = Color(0xFF16181D);
const Color _gutterBackground = Color(0xFF101216);
const Color _gutterBorder = Color(0xFF23262E);
const Color _gutterText = Color(0xFF5C6370);
const Color _rootText = Color(0xFFD4D7DD);

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

  Future<void> _save(String code, String fileName) async {
    try {
      final path = await _exportService.saveToFile(
        fileName: fileName,
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
    final page = ref.watch(workspaceProvider.select((s) => s.activePage));
    final html = page?.html;
    // Output Alpha bisa kosong; jangan tampilkan panel kode yang hampa.
    final hasCode = html != null && html.trim().isNotEmpty;
    final fileName = (page?.slug.isNotEmpty ?? false)
        ? page!.slug
        : 'index.html';

    return ColoredBox(
      color: context.palette.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CodeBreadcrumb(
            fileName: fileName,
            onCopy: hasCode ? () => _copy(html) : null,
            onSave: hasCode ? () => _save(html, fileName) : null,
          ),
          const Divider(height: 1),
          Expanded(
            child: !hasCode
                ? const _CodeEmptyState()
                : _CodeBody(
                    pageId: page?.id ?? fileName,
                    code: html,
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
  const _CodeBreadcrumb({
    required this.fileName,
    required this.onCopy,
    required this.onSave,
  });

  final String fileName;
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
          Icon(
            Icons.description_outlined,
            size: 13,
            color: context.palette.textSecondary,
          ),
          const SizedBox(width: 6),
          Text('canvas', style: context.text.monoSmall),
          Text('  ›  ', style: context.text.monoSmall),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 11,
                color: context.palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _LanguageBadge(label: 'HTML'),
          const SizedBox(width: 6),
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

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.bgBase,
        borderRadius: AppRadius.sm,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.monoFamily,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: 9,
          height: 1.2,
          letterSpacing: 0.4,
          color: context.palette.textSecondary,
        ),
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

class _CodeBody extends StatefulWidget {
  const _CodeBody({
    required this.pageId,
    required this.code,
    required this.verticalController,
    required this.horizontalController,
  });

  final String pageId;
  final String code;
  final ScrollController verticalController;
  final ScrollController horizontalController;

  @override
  State<_CodeBody> createState() => _CodeBodyState();
}

class _CodeBodyState extends State<_CodeBody> {
  CodeHighlight? _highlight;
  String? _highlightedSource;

  @override
  void initState() {
    super.initState();
    _ensureHighlight();
    _resetScroll();
  }

  @override
  void didUpdateWidget(covariant _CodeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _ensureHighlight();
    }
    // Ganti halaman = mulai dari baris pertama, bukan posisi scroll lama.
    if (oldWidget.pageId != widget.pageId) {
      _resetScroll();
    }
  }

  void _ensureHighlight() {
    if (_highlightedSource == widget.code) return;
    _highlightedSource = widget.code;
    _highlight = highlightHtmlDocument(widget.code);
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vertical = widget.verticalController;
      final horizontal = widget.horizontalController;
      if (vertical.hasClients) vertical.jumpTo(0);
      if (horizontal.hasClients) horizontal.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _highlight ??= highlightHtmlDocument(widget.code);
    final lineCount = highlight.lineCount;
    final gutterWidth = 18.0 + (lineCount.toString().length * 8);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: AppRadius.sm,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: _codeBackground),
          child: Scrollbar(
            controller: widget.horizontalController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: Scrollbar(
              controller: widget.verticalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: widget.verticalController,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LineGutter(lineCount: lineCount, width: gutterWidth),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: widget.horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 12, 24, 24),
                          child: Text.rich(
                            highlight.span,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              fontFamily: AppFonts.monoFamily,
                              fontFamilyFallback: AppFonts.monoFallback,
                              fontSize: _codeFontSize,
                              height: _codeLineHeightFactor,
                              color: _rootText,
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
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      decoration: const BoxDecoration(
        color: _gutterBackground,
        border: Border(right: BorderSide(color: _gutterBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lineCount, (index) {
          return SizedBox(
            height: _codeLineHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${index + 1}',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: _codeFontSize,
                  height: _codeLineHeightFactor,
                  color: _gutterText,
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
