import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class CentauriApp extends StatelessWidget {
  const CentauriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Centauri - AI UI/UX Canvas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
