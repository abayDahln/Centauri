import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../app/config/theme.dart';

/// Merender teks markdown dari AI (bold, heading, list, code, dsb) dengan
/// gaya yang sesuai tema terang Centauri.
///
/// Dipakai untuk bubble chat. User bisa menyeleksi teks.
class MarkdownMessage extends StatelessWidget {
  const MarkdownMessage({
    super.key,
    required this.text,
    this.baseColor = AppColors.textPrimary,
  });

  final String text;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final style = MarkdownStyleSheet(
      p: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 13.5,
        height: 1.6,
        color: baseColor,
      ),
      strong: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      em: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontStyle: FontStyle.italic,
        color: baseColor,
      ),
      h1: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: baseColor,
      ),
      h2: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: baseColor,
      ),
      h3: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: baseColor,
      ),
      listBullet: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 13.5,
        height: 1.6,
        color: baseColor,
      ),
      code: TextStyle(
        fontFamily: AppFonts.monoFamily,
        fontFamilyFallback: AppFonts.monoFallback,
        fontSize: 12.5,
        color: AppColors.textPrimary,
        backgroundColor: AppColors.hoverBg,
      ),
      codeblockDecoration: const BoxDecoration(
        color: Color(0xFF16181D),
        borderRadius: AppRadius.sm,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.bgSunken,
        border: const Border(
          left: BorderSide(color: AppColors.accentPrimary, width: 3),
        ),
        borderRadius: AppRadius.sm,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      a: const TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 13.5,
        color: AppColors.link,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.link,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderStrong)),
      ),
      pPadding: const EdgeInsets.only(bottom: 6),
      h1Padding: const EdgeInsets.only(top: 4, bottom: 6),
      h2Padding: const EdgeInsets.only(top: 4, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 4),
      listIndent: 20,
      blockSpacing: 8,
    );

    return MarkdownBody(
      data: text.isEmpty ? '(kosong)' : text,
      styleSheet: style,
      selectable: true,
      shrinkWrap: true,
    );
  }
}
