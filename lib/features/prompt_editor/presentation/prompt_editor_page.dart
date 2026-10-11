import 'package:flutter/material.dart';

import '../../../app/config/theme.dart';
import 'prompt_chat_panel.dart';

/// Screen standalone Prompt Editor — pada desktop/mobile chat terintegrasi
/// di canvas page; screen ini dipakai sebagai fallback route mandiri.
class PromptEditorPage extends StatelessWidget {
  const PromptEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(child: PromptChatPanel()),
    );
  }
}
