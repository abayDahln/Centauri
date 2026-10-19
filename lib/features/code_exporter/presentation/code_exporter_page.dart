import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';
import 'code_export_view.dart';

/// Screen standalone ekspor kode (route '/code-export').
/// Mengambil HTML aktif dari canvas provider.
class CodeExporterPage extends ConsumerWidget {
  const CodeExporterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final htmlSource = ref.watch(workspaceProvider).activePage?.html;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.codeExportTitle)),
      body: SafeArea(
        child: htmlSource == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.code_off_outlined,
                      size: 32,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.codeExportEmptyTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.codeExportEmptyBody,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: CodeExportView(htmlSource: htmlSource),
              ),
      ),
    );
  }
}
