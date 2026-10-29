import 'package:go_router/go_router.dart';

import '../../features/canvas_preview/presentation/canvas_preview_page.dart';
import '../../features/code_exporter/presentation/code_exporter_page.dart';
import '../../features/mcp/presentation/mcp_guide_page.dart';
import '../../features/provider_config/presentation/provider_detail_page.dart';
import '../../features/provider_config/presentation/provider_list_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String canvasPreview = '/';
  static const String codeExport = '/code-export';

  /// Daftar provider tersimpan (pintu masuk konfigurasi).
  static const String providers = '/providers';

  /// Formulir tambah provider baru (API Key).
  static const String providerNew = '/providers/new';

  /// Detail/edit provider tersimpan.
  static String providerDetail(String id) => '/providers/$id';

  /// Panduan koneksi MCP server.
  static const String mcpGuide = '/mcp-guide';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.canvasPreview,
  routes: [
    GoRoute(
      path: AppRoutes.canvasPreview,
      builder: (_, _) => const CanvasPreviewPage(),
    ),
    GoRoute(
      path: AppRoutes.providers,
      builder: (_, _) => const ProviderListPage(),
      routes: [
        // Segmen statis didahulukan agar tidak tertangkap oleh `:id`.
        GoRoute(path: 'new', builder: (_, _) => const ProviderDetailPage()),
        GoRoute(
          path: ':id',
          builder: (_, state) =>
              ProviderDetailPage(providerId: state.pathParameters['id']),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.codeExport,
      builder: (_, _) => const CodeExporterPage(),
    ),
    GoRoute(
      path: AppRoutes.mcpGuide,
      builder: (_, _) => const McpGuidePage(),
    ),
  ],
);
