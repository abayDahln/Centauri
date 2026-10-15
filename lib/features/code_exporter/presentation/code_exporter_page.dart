import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';
import 'code_export_view.dart';

/// Screen standalone ekspor kode (route '/code-export').
/// Mengambil HTML aktif dari canvas provider.
class CodeExporterPage extends ConsumerWidget {
  const CodeExporterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final htmlSource = ref.watch(workspaceProvider).activePage?.html;

    return Scaffold(
      appBar: AppBar(title: const Text('Ekspor Kode')),
      body: SafeArea(
        child: htmlSource == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.code_off_outlined,
                      size: 32,
                      color: AppColors.textDisabled,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada UI untuk diekspor',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Generate UI di canvas terlebih dahulu.',
                      style: TextStyle(
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
