import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';

/// Merender teks markdown dari AI (bold, heading, list, code, dsb) dengan
/// gaya yang sesuai tema terang Centauri.
///
/// Dipakai untuk bubble chat. User bisa menyeleksi teks.
class MarkdownMessage extends StatelessWidget {
  const MarkdownMessage({super.key, required this.text, this.baseColor});

  final String text;

  /// Warna dasar teks; `null` = warna teks utama palet aktif.
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    final base = baseColor ?? context.palette.textPrimary;
    final style = MarkdownStyleSheet(
      p: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 14,
        height: 1.55,
        color: base,
      ),
      strong: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      em: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontStyle: FontStyle.italic,
        color: base,
      ),
      h1: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: base,
      ),
      h2: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: base,
      ),
      h3: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: base,
      ),
      listBullet: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 14,
        height: 1.55,
        color: base,
      ),
      code: TextStyle(
        fontFamily: AppFonts.monoFamily,
        fontFamilyFallback: AppFonts.monoFallback,
        fontSize: 12.5,
        color: context.palette.textPrimary,
        backgroundColor: context.palette.hoverBg,
      ),
      codeblockDecoration: const BoxDecoration(
        color: Color(0xFF16181D),
        borderRadius: AppRadius.sm,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: context.palette.bgSunken,
        border: Border(
          left: BorderSide(color: context.palette.primary, width: 3),
        ),
        borderRadius: AppRadius.sm,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      a: TextStyle(
        fontFamily: AppFonts.uiFamily,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: 14,
        color: context.palette.link,
        decoration: TextDecoration.underline,
        decorationColor: context.palette.link,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.borderStrong)),
      ),
      pPadding: const EdgeInsets.only(bottom: 6),
      h1Padding: const EdgeInsets.only(top: 4, bottom: 6),
      h2Padding: const EdgeInsets.only(top: 4, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 4),
      listIndent: 20,
      blockSpacing: 8,
    );

    return MarkdownBody(
      data: text.isEmpty ? context.l10n.markdownEmpty : text,
      styleSheet: style,
      // Render tiap blok sebagai teks biasa; seleksi lintas-blok ditangani
      // oleh SelectionArea di pemanggil (mis. daftar pesan).
      selectable: false,
      shrinkWrap: true,
    );
  }
}
