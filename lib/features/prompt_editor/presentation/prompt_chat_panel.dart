import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_palette.dart';
import '../../../app/config/theme.dart';
import '../../../app/l10n/l10n.dart';
import '../../canvas_preview/presentation/provider/workspace_provider.dart';
import '../../canvas_preview/presentation/widgets/attachment_preview_dialog.dart';
import '../../canvas_preview/presentation/widgets/chat_error_card.dart';
import '../../canvas_preview/presentation/widgets/generation_step_card.dart';
import '../../canvas_preview/presentation/widgets/markdown_message.dart';

/// Panel riwayat percakapan (read-only). Hanya menampilkan pesan user dan AI.
/// Input prompt ada di PromptBar (bawah tengah board).
class PromptChatPanel extends ConsumerStatefulWidget {
  const PromptChatPanel({super.key, this.contentMaxWidth});

  /// Batas lebar kolom percakapan, mis. di mode fokus chat.
  ///
  /// Bila diisi, daftar pesan tetap selebar panel (scrollbar di tepi kanan)
  /// sementara isinya dipusatkan ke tengah dengan lebar maksimum ini.
  final double? contentMaxWidth;

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

  /// Saat AI sedang memproses dan belum ada pesan: tampilkan kartu langkah
  /// agar jelas ada aktivitas dan tahapnya, bukan layar kosong.
  Widget _buildThinkingState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: GenerationStepCard(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 28,
              color: context.palette.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.chatNoMessagesTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.chatNoMessagesBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.uiFamily,
                fontFamilyFallback: AppFonts.uiFallback,
                fontSize: 11,
                height: 1.6,
                color: context.palette.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(WorkspaceState state) {
    final extra = state.isGenerating ? 1 : 0;
    final hasUserMessage = state.messages.any((m) => m.role == ChatRole.user);
    // Saat lebar kolom dibatasi, padding pindah ke dalam tiap item agar daftar
    // tetap selebar panel — scrollbar ada di tepi kanan, bukan di tengah.
    final limited = widget.contentMaxWidth != null;
    return SelectionArea(
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          limited ? 0 : 16,
          16,
          limited ? 0 : 16,
          24,
        ),
        itemCount: state.messages.length + extra,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.messages.length) {
            return _centered(
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: GenerationStepCard(),
              ),
            );
          }
          return _centered(
            _buildMessageBubble(
              state.messages[index],
              index,
              busy: state.isGenerating,
              canRetry: hasUserMessage,
            ),
          );
        },
      ),
    );
  }

  /// Pusatkan item ke lebar kolom bila [PromptChatPanel.contentMaxWidth] diisi.
  Widget _centered(Widget child) {
    final maxWidth = widget.contentMaxWidth;
    if (maxWidth == null) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
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
        return LayoutBuilder(
          builder: (context, constraints) {
            // Lebar bubble mengikuti isi teks, maksimal 3/4 kolom percakapan.
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.palette.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(2),
                  ),
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
                                          color: context.palette.onPrimary
                                              .withValues(alpha: 0.18),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.description_outlined,
                                            size: 20,
                                            color: context.palette.onPrimary,
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
                                            color: context.palette.onPrimary
                                                .withValues(alpha: 0.18),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 20,
                                              color: context.palette.onPrimary,
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
                      style: TextStyle(
                        fontFamily: AppFonts.uiFamily,
                        fontFamilyFallback: AppFonts.uiFallback,
                        fontSize: 13.5,
                        height: 1.5,
                        color: context.palette.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case ChatRole.assistant:
        if (message.kind == ChatMessageKind.chat) {
          return _buildChatBubble(message.text);
        }
        return _buildUiBubble(message, index);
      case ChatRole.error:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: ChatErrorCard(
            text: message.text,
            canRetry: canRetry,
            busy: busy,
          ),
        );
    }
  }

  /// Jawaban percakapan biasa (mode chat): teks langsung, tanpa bubble.
  Widget _buildChatBubble(String text) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alpha',
              style: context.text.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            MarkdownMessage(text: text),
          ],
        ),
      ),
    );
  }

  /// Bubble untuk hasil UI (menampilkan HTML yang bisa dibuka/tutup).
  Widget _buildUiBubble(CanvasMessage message, int index) {
    final expanded = _expandedAssistant.contains(index);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderSubtle),
          borderRadius: AppRadius.md,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.brush_outlined,
                    size: 13,
                    color: context.palette.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'UI siap',
                    style: TextStyle(
                      fontFamily: AppFonts.uiFamily,
                      fontFamilyFallback: AppFonts.uiFallback,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
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
                      expanded
                          ? context.l10n.chatHideCode
                          : context.l10n.chatViewCode,
                      style: TextStyle(
                        fontFamily: AppFonts.uiFamily,
                        fontFamilyFallback: AppFonts.uiFallback,
                        fontSize: 10,
                        color: context.palette.primary,
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
