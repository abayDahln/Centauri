import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/theme.dart';
import '../domain/prompt_templates.dart';
import '../../canvas_preview/presentation/provider/canvas_provider.dart';

/// Panel chat/iterasi AI (FR-04) + pemilih design token (FR-02).
/// Dipakai di right-pane desktop dan bottom-sheet mobile.
class PromptChatPanel extends ConsumerStatefulWidget {
  const PromptChatPanel({super.key});

  @override
  ConsumerState<PromptChatPanel> createState() => _PromptChatPanelState();
}

class _PromptChatPanelState extends ConsumerState<PromptChatPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  DesignTokenPreset? _selectedToken;
  bool _expandedAssistant = false;

  @override
  void dispose() {
    _inputController.dispose();
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

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await ref.read(canvasProvider.notifier).submitPrompt(
          text,
          designToken: _selectedToken,
        );
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    if (canvasState.messages.isNotEmpty) _scrollToBottom();

    return Column(
      children: [
        _buildHeader(canvasState),
        Expanded(
          child: canvasState.messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(canvasState),
        ),
        _buildInputArea(canvasState),
      ],
    );
  }

  Widget _buildHeader(CanvasState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          const Text(
            'Prompt & Iterasi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (state.messages.isNotEmpty)
            TextButton(
              onPressed: state.isGenerating
                  ? null
                  : () => ref.read(canvasProvider.notifier).clearCanvas(),
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
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
            Icon(Icons.auto_awesome_outlined,
                size: 32, color: AppColors.textDisabled),
            SizedBox(height: 12),
            Text(
              'Deskripsikan UI yang ingin dibuat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Contoh: "Buat landing page SaaS dengan hero, pricing 3 tier, dan footer gelap."',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _buildMessageList(CanvasState state) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildMessageBubble(state.messages[index]),
    );
  }

  Widget _buildMessageBubble(CanvasMessage message) {
    switch (message.role) {
      case ChatRole.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        );
      case ChatRole.assistant:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 13, color: AppColors.statusSuccess),
                      const SizedBox(width: 6),
                      const Text(
                        'UI di-generate ke canvas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(
                            () => _expandedAssistant = !_expandedAssistant),
                        child: Text(
                          _expandedAssistant ? 'Tutup' : 'Lihat kode',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_expandedAssistant)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bgBase,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        message.text,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      case ChatRole.error:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.statusError),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: AppColors.statusError),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildInputArea(CanvasState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: designTokenPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final preset = designTokenPresets[index];
                final selected = _selectedToken?.id == preset.id;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedToken = selected ? null : preset;
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.accentPrimary
                            : AppColors.borderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      preset.label,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgBase,
                    border: Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _inputController,
                    enabled: !state.isGenerating,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Deskripsikan UI atau revisi...',
                      hintStyle: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: AppColors.textDisabled,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  onPressed: state.isGenerating ? null : _send,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: state.isGenerating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
