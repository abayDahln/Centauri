import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import 'code_export_view.dart';

/// Launcher adaptif: dialog di desktop (>=960px), bottom sheet di mobile.
void showCodeExportSheet(BuildContext context, String htmlSource) {
  final isWide = MediaQuery.sizeOf(context).width >= 960;

  if (isWide) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.bgSurface,
        insetPadding: const EdgeInsets.all(48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.xl,
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        child: SizedBox(
          width: 760,
          height: 560,
          child: CodeExportView(htmlSource: htmlSource),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      side: BorderSide(color: AppColors.borderSubtle),
    ),
    builder: (_) =>
        SizedBox(height: 640, child: CodeExportView(htmlSource: htmlSource)),
  );
}
