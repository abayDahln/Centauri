import 'package:go_router/go_router.dart';

import '../../features/canvas_preview/presentation/canvas_preview_page.dart';
import '../../features/code_exporter/presentation/code_exporter_page.dart';
import '../../features/provider_config/presentation/provider_config_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String canvasPreview = '/';
  static const String providerConfig = '/provider-config';
  static const String codeExport = '/code-export';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.canvasPreview,
  routes: [
    GoRoute(
      path: AppRoutes.canvasPreview,
      builder: (_, _) => const CanvasPreviewPage(),
    ),
    GoRoute(
      path: AppRoutes.providerConfig,
      builder: (_, _) => const ProviderConfigPage(),
    ),
    GoRoute(
      path: AppRoutes.codeExport,
      builder: (_, _) => const CodeExporterPage(),
    ),
  ],
);
