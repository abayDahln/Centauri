import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/theme.dart';
import '../../history/presentation/history_provider.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';
import '../../canvas_preview/presentation/widgets/ai_status_indicator.dart';
import '../../canvas_preview/presentation/widgets/attachment_preview_dialog.dart';
import '../../canvas_preview/presentation/widgets/markdown_message.dart';

/// Panel riwayat percakapan (read-only). Hanya menampilkan pesan user dan AI.
/// Input prompt ada di PromptBar (bawah tengah board).
class PromptChatPanel extends ConsumerStatefulWidget {
  const PromptChatPanel({super.key});

  @override
  ConsumerState<PromptChatPanel> createState() => _PromptChatPanelState();
}

class _PromptChatPanelState extends ConsumerState<PromptChatPanel> {
  final _scrollController = ScrollController();
  final Set<int> _expandedAssistant = <int>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(workspaceProvider);
    if (canvasState.messages.isNotEmpty) _scrollToBottom();

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: canvasState.messages.isEmpty
              ? (canvasState.isGenerating
                    ? _buildThinkingState()
                    : _buildEmptyState())
              : _buildMessageList(canvasState),
        ),
      ],
    );
  }

  /// Saat AI sedang memproses dan belum ada pesan: tampilkan indikator
  /// "thinking" agar jelas ada aktivitas, bukan layar kosong.
  Widget _buildThinkingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AiStatusIndicator(),
            SizedBox(height: 12),
            Text(
              'Sedang memproses...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: const Row(
        children: [
          Text('Riwayat', style: AppText.sectionTitle),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 28,
              color: AppColors.textDisabled,
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada percakapan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pesan Anda dan balasan AI akan tampil di sini. '
              'Tulis prompt di bar bawah board.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 11,
                height: 1.6,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(WorkspaceState state) {
    final extra = state.isGenerating ? 1 : 0;
    final hasUserMessage =
        state.messages.any((m) => m.role == ChatRole.user);
    return SelectionArea(
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: state.messages.length + extra,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.messages.length) {
            return const Align(
              alignment: Alignment.centerLeft,
              child: AiStatusIndicator(),
            );
          }
          return _buildMessageBubble(
            state.messages[index],
            index,
            busy: state.isGenerating,
            canRetry: hasUserMessage,
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    CanvasMessage message,
    int index, {
    bool busy = false,
    bool canRetry = false,
  }) {
    switch (message.role) {
      case ChatRole.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: AppRadius.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.attachments.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.attachments
                        .map(
                          (a) => GestureDetector(
                            onTap: () => showAttachmentPreview(context, a),
                            child: ClipRRect(
                              borderRadius: AppRadius.sm,
                              child: a.isText
                                  ? Container(
                                      width: 72,
                                      height: 52,
                                      color: Colors.white24,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.description_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Image.memory(
                                      a.bytes,
                                      width: 72,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 72,
                                        height: 52,
                                        color: Colors.white24,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message.shownText,
                  style: const TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 12.5,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      case ChatRole.assistant:
        if (message.kind == ChatMessageKind.chat) {
          return _buildChatBubble(message.text);
        }
        return _buildUiBubble(message, index);
      case ChatRole.error:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFCEEEE),
              border: Border.all(color: AppColors.statusError),
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
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.statusError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          fontFamily: AppFonts.uiFamily,
                          fontFamilyFallback: AppFonts.uiFallback,
                          fontSize: 11.5,
                          height: 1.5,
                          color: AppColors.statusError,
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
                            await ref
                                .read(workspaceProvider.notifier)
                                .retryLastPrompt();
                            ref
                                .read(historyProvider.notifier)
                                .persistCurrent();
                          },
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Coba lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusError,
                      side: const BorderSide(color: AppColors.statusError),
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
          ),
        );
    }
  }

  /// Bubble untuk jawaban percakapan biasa (mode chat).
  Widget _buildChatBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: AppRadius.md,
        ),
        child: MarkdownMessage(text: text),
      ),
    );
  }

  /// Bubble untuk hasil UI (menampilkan HTML yang bisa dibuka/tutup).
  Widget _buildUiBubble(CanvasMessage message, int index) {
    final expanded = _expandedAssistant.contains(index);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSunken,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: AppRadius.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.brush_outlined,
                    size: 13,
                    color: AppColors.accentPrimary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Generated UI',
                    style: TextStyle(
                      fontFamily: AppFonts.uiFamily,
                      fontFamilyFallback: AppFonts.uiFallback,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (!_expandedAssistant.add(index)) {
                        _expandedAssistant.remove(index);
                      }
                    }),
                    child: Text(
                      expanded ? 'Sembunyikan' : 'Lihat kode',
                      style: const TextStyle(
                        fontFamily: AppFonts.uiFamily,
                        fontFamilyFallback: AppFonts.uiFallback,
                        fontSize: 10,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (expanded)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF16181D),
                  borderRadius: AppRadius.sm,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontFamily: AppFonts.monoFamily,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 10,
                      height: 1.5,
                      color: Color(0xFFC7CBD3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
