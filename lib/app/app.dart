import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'widgets/app_title_bar.dart';

class CentauriApp extends StatelessWidget {
  const CentauriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Centauri - AI UI/UX Canvas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!AppTitleBar.isSupported || child == null) return child ?? const SizedBox.shrink();
        return Scaffold(
          backgroundColor: AppColors.chromeBg,
          body: Column(
            children: [
              const AppTitleBar(),
              const Divider(height: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
