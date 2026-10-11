import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../../../app/config/theme.dart';
import '../data/code_export_service.dart';
import '../domain/code_transformer.dart';
import '../domain/export_format.dart';

class CodeExportView extends StatefulWidget {
  const CodeExportView({super.key, required this.htmlSource});

  final String htmlSource;

  @override
  State<CodeExportView> createState() => _CodeExportViewState();
}

class _CodeExportViewState extends State<CodeExportView> {
  final CodeExportService _exportService = CodeExportService();
  final Map<CodeFormat, String> _cache = {};

  CodeFormat _format = CodeFormat.html;
  bool _isSaving = false;

  String get _code => _cache.putIfAbsent(
        _format,
        () => transformCode(
          htmlSource: widget.htmlSource,
          format: _format,
        ),
      );

  Future<void> _copy() async {
    await _exportService.copyToClipboard(_code);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Kode ${_format.label} disalin ke clipboard'),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final path = await _exportService.saveToFile(
        fileName: 'centauri-ui.${_format.fileExtension}',
        code: _code,
      );
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Disimpan: $path'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Ekspor Kode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_code.length} karakter',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
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
                  .map((format) => ButtonSegment<CodeFormat>(
                        value: format,
                        label: Text(
                          format.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ))
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
                backgroundColor:
                    WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.accentPrimary;
                  }
                  return AppColors.bgSurface;
                }),
                foregroundColor:
                    WidgetStateProperty.resolveWith((states) {
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
            _formatNotice,
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
              color: AppColors.bgBase,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: HighlightView(
              _code,
              language: _format.highlightLanguage,
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(
                fontFamily: 'JetBrainsMono',
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
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_all_outlined, size: 15),
                  label: const Text(
                    'Copy',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
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
                  label: const Text(
                    'Download',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _formatNotice {
    switch (_format) {
      case CodeFormat.html:
        return 'Format utama: satu file HTML lengkap - seluruh CSS di <style> dan JS vanilla di <script> inline. Tanpa CDN, tanpa framework, tanpa dependency eksternal. Bisa langsung disimpan sebagai .html dan dijalankan offline.';
      case CodeFormat.reactJsx:
        return 'Konversi bonus (heuristik): atribut className dan style object. Pindahkan isi tag <style> dokumen asli ke file CSS terpisah - class mengacu ke CSS hand-written, bukan Tailwind. Periksa kembali sebelum produksi.';
      case CodeFormat.flutterDart:
        return 'Konversi bonus (heuristik): HTML menjadi widget Flutter. Hanya inline style yang diterjemahkan; CSS di dalam <style> tidak dipetakan. Periksa kembali sebelum produksi.';
    }
  }
}
