import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../data/code_export_service.dart';
import '../domain/code_transformer.dart';
import '../domain/export_format.dart';

class CodeExportView extends StatefulWidget {
  const CodeExportView({super.key, required this.htmlSource});

  final String htmlSource;

  @override
  State<CodeExportView> createState() => _CodeExportViewState();
}

/// Hasil konversi satu format: berisi kode, atau pesan gagal.
class _CodeResult {
  const _CodeResult._(this.code, this.error);

  factory _CodeResult.code(String code) => _CodeResult._(code, null);

  factory _CodeResult.error(String error) => _CodeResult._(null, error);

  final String? code;
  final String? error;

  bool get hasError => error != null;
}

class _CodeExportViewState extends State<CodeExportView> {
  final CodeExportService _exportService = CodeExportService();
  final Map<CodeFormat, _CodeResult> _cache = {};

  CodeFormat _format = CodeFormat.html;
  bool _isSaving = false;

  /// Konversi di-cache per format, termasuk kegagalannya. Output Alpha bisa
  /// berupa HTML yang tidak bisa diparse, jadi kegagalan tidak boleh
  /// menjatuhkan layar.
  _CodeResult _resultFor(CodeFormat format) => _cache.putIfAbsent(format, () {
    try {
      return _CodeResult.code(
        transformCode(htmlSource: widget.htmlSource, format: format),
      );
    } on CodeTransformException catch (e) {
      return _CodeResult.error(e.message);
    } catch (_) {
      return _CodeResult.error(
        context.mounted
            ? context.l10n.codeExportTransformErrorFallback(format.label)
            : 'Alpha code could not be transformed into ${format.label}.',
      );
    }
  });

  Future<void> _copy() async {
    final code = _resultFor(_format).code;
    if (code == null) return;
    await _exportService.copyToClipboard(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.codeExportCopied(_format.label)),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _save() async {
    final code = _resultFor(_format).code;
    if (code == null) return;
    setState(() => _isSaving = true);
    try {
      final path = await _exportService.saveToFile(
        fileName: 'centauri-ui.${_format.fileExtension}',
        code: code,
      );
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.exportSaved(path)),
              backgroundColor: AppColors.bgElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } on CodeExportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.bgElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _resultFor(_format);
    final code = result.code;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(l10n.codeExportTitle, style: AppText.panelTitle),
              const Spacer(),
              if (code != null)
                Text(
                  l10n.codeExportCharCount(code.length),
                  style: const TextStyle(
                    fontFamily: AppFonts.monoFamily,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 10,
                    color: AppColors.textDisabled,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 32,
            child: SegmentedButton<CodeFormat>(
              segments: CodeFormat.values
                  .map(
                    (format) => ButtonSegment<CodeFormat>(
                      value: format,
                      label: Text(
                        format.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
              selected: {_format},
              onSelectionChanged: (selection) =>
                  setState(() => _format = selection.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                side: WidgetStateProperty.all(
                  const BorderSide(color: AppColors.borderSubtle),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.accentPrimary;
                  }
                  return AppColors.bgSurface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppColors.textSecondary;
                }),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            _formatNotice(l10n),
            style: const TextStyle(
              fontSize: 10,
              height: 1.6,
              color: AppColors.textDisabled,
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF16181D),
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: AppRadius.sm,
            ),
            clipBehavior: Clip.antiAlias,
            child: code == null
                ? _TransformError(
                    message: result.error ?? l10n.codeExportTransformErrorTitle,
                    onUseHtml: _format == CodeFormat.html
                        ? null
                        : () => setState(() => _format = CodeFormat.html),
                  )
                : HighlightView(
                    code,
                    language: _format.highlightLanguage,
                    theme: atomOneDarkTheme,
                    padding: const EdgeInsets.all(14),
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.monoFamily,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: code == null ? null : _copy,
                  icon: const Icon(Icons.copy_all_outlined, size: 15),
                  label: Text(l10n.codeExportCopy, style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: code == null || _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_outlined, size: 15),
                  label: Text(
                    l10n.codeExportDownload,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNotice(AppLocalizations l10n) {
    switch (_format) {
      case CodeFormat.html:
        return l10n.codeExportNoticeHtml;
      case CodeFormat.reactJsx:
        return l10n.codeExportNoticeReact;
      case CodeFormat.flutterDart:
        return l10n.codeExportNoticeFlutter;
      case CodeFormat.tailwind:
        return l10n.codeExportNoticeTailwind;
    }
  }
}

/// Keadaan gagal: HTML dari Alpha tidak bisa dikonversi ke format ini.
class _TransformError extends StatelessWidget {
  const _TransformError({required this.message, this.onUseHtml});

  final String message;
  final VoidCallback? onUseHtml;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.report_gmailerrorred_outlined,
              size: 22,
              color: AppColors.statusError,
            ),
            const SizedBox(height: 10),
            Text(l10n.codeExportTransformErrorTitle, style: AppText.panelTitle),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (onUseHtml != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onUseHtml,
                child: Text(l10n.codeExportUseHtml, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
