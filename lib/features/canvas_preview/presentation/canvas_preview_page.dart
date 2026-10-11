import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/theme.dart';

class CanvasPreviewPage extends StatelessWidget {
  const CanvasPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Centauri Canvas',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/provider-config'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.web_asset_outlined, size: 48, color: AppColors.textDisabled),
              SizedBox(height: 16),
              Text(
                'Live Canvas Preview',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Hasil generate AI akan dirender di sini (WebView)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      // Floating Prompt Input (Mobile Style)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Buka Bottom Sheet Prompt Editor
        },
        backgroundColor: AppColors.accentPrimary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Generate UI', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}