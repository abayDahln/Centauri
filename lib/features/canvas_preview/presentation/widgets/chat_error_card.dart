import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../history/presentation/history_provider.dart';
import '../provider/workspace_provider.dart';

/// Kartu error percakapan dengan tombol coba lagi.
///
/// Dipakai oleh panel chat sidebar dan layar chat utama supaya pesan error
/// punya tampilan dan aksi yang sama di kedua tempat.
class ChatErrorCard extends ConsumerWidget {
  const ChatErrorCard({
    super.key,
    required this.text,
    required this.canRetry,
    required this.busy,
  });

  final String text;
  final bool canRetry;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.statusError.withValues(alpha: 0.05),
        border: Border.all(
          color: context.palette.statusError.withValues(alpha: 0.32),
        ),
        borderRadius: AppRadius.md,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                size: 14,
                color: context.palette.statusError,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 11.5,
                    height: 1.5,
                    color: context.palette.statusError,
                  ),
                ),
              ),
            ],
          ),
          // Kirim ulang prompt terakhir tanpa mengetik ulang.
          if (canRetry) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      // Notifier diambil sebelum await: widget ini bisa sudah
                      // di-unmount saat generate selesai, dan `ref` tidak boleh
                      // dipakai lagi setelah itu.
                      final workspace = ref.read(workspaceProvider.notifier);
                      final history = ref.read(historyProvider.notifier);
                      await workspace.retryLastPrompt();
                      history.persistCurrent();
                    },
              icon: const Icon(Icons.refresh, size: 14),
              label: Text(context.l10n.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.statusError,
                side: BorderSide(color: context.palette.statusError),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
