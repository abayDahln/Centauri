import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/app_palette.dart';
import '../../../app/config/theme.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../app/widgets/stitch_widgets.dart';
import '../../canvas_preview/presentation/widgets/skeleton.dart';
import '../../mcp/presentation/mcp_status_section.dart';
import '../domain/entities/api_provider.dart';
import 'providers/provider_config_provider.dart';
import 'widgets/delete_provider_dialog.dart';

/// Layar daftar provider: satu panel daftar + aksi tambah/hapus.
///
/// Merupakan pintu masuk ke layar tambah provider dan detail/edit provider.
class ProviderListPage extends ConsumerWidget {
  const ProviderListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Layar sempit: rapatkan margin supaya isi tidak terhimpit.
    final compact = MediaQuery.sizeOf(context).width < 600;
    final asyncState = ref.watch(providerConfigProvider);
    final providers = asyncState.value?.providers ?? const <ApiProvider>[];
    final activeProviderId = asyncState.value?.activeProvider?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonProvider),
        // Tombol kembali eksplisit: halaman ini juga bisa menjadi halaman
        // pertama (mis. setelah simpan yang mengganti lokasi), dan pengguna
        // tidak boleh terjebak tanpa jalan keluar.
        leading: BackButton(onPressed: () => _leave(context)),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.providerNew),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.commonAdd),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 32,
          vertical: compact ? 20 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.providerListHeading,
                  style: TextStyle(
                    fontSize: compact ? 20 : 24,
                    height: 30 / 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(l10n.providerListSubtitle, style: context.text.uiSmall),
                const SizedBox(height: 28),
                _buildList(
                  context,
                  ref,
                  providers,
                  activeProviderId,
                  asyncState,
                ),
                // MCP bridge agar agent eksternal bisa membaca/mengubah canvas.
                // Mobile tidak mendukung MCP, jadi kartunya tidak ditampilkan.
                if (McpStatusSection.isSupported) ...[
                  const SizedBox(height: 32),
                  const McpStatusSection(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Keluar dari pengaturan provider: pop bila ditumpuk di atas layar lain,
  /// kalau tidak kembali ke canvas agar tidak ada jalan buntu.
  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.canvasPreview);
    }
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<ApiProvider> providers,
    String? activeProviderId,
    AsyncValue<ProviderConfigState> asyncState,
  ) {
    final l10n = context.l10n;

    if (asyncState.isLoading && providers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [SkeletonListRow(), SkeletonListRow(), SkeletonListRow()],
        ),
      );
    }

    if (asyncState.hasError && providers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.palette.statusError.withValues(alpha: 0.32),
          ),
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: context.palette.statusError,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.providerListLoadFailed,
                style: context.text.uiSmall,
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(providerConfigProvider.future),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (providers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: context.palette.borderSubtle),
          borderRadius: AppRadius.md,
          color: context.palette.bgSurface,
        ),
        child: Column(
          children: [
            Icon(
              Icons.key_outlined,
              size: 24,
              color: context.palette.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(l10n.providerListEmptyTitle, style: context.text.panelTitle),
            const SizedBox(height: 4),
            Text(
              l10n.providerListEmptyBody,
              style: context.text.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: AppRadius.panel,
        border: Border.all(color: context.palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < providers.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.palette.borderSubtle),
            _ProviderRow(
              provider: providers[i],
              isActive: providers[i].id == activeProviderId,
              onOpen: () =>
                  context.push(AppRoutes.providerDetail(providers[i].id)),
              onActivate: () => ref
                  .read(providerConfigProvider.notifier)
                  .setActiveProvider(providers[i].id),
              onDelete: () => _delete(context, ref, providers[i]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ApiProvider provider,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDeleteProviderDialog(context, provider.name);
    if (!confirmed) return;
    await ref.read(providerConfigProvider.notifier).deleteProvider(provider.id);
    if (!context.mounted) return;
    showAppToast(context, l10n.providerDeleted, kind: AppToastKind.success);
  }
}

/// Satu baris provider: identitas di kiri, status dan aksi di kanan.
class _ProviderRow extends StatefulWidget {
  const _ProviderRow({
    required this.provider,
    required this.isActive,
    required this.onOpen,
    required this.onActivate,
    required this.onDelete,
  });

  final ApiProvider provider;
  final bool isActive;
  final VoidCallback onOpen;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  State<_ProviderRow> createState() => _ProviderRowState();
}

class _ProviderRowState extends State<_ProviderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = widget.provider;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? context.palette.hoverBg : context.palette.bgSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.ui.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (provider.providerName.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              provider.providerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.monoSmall.copyWith(
                                color: context.palette.textDisabled,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (provider.baseUrl.trim().isNotEmpty ||
                        provider.model.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          provider.baseUrl.trim(),
                          provider.model.trim(),
                        ].where((v) => v.isNotEmpty).join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.monoSmall.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.isActive)
                StatusPill(label: l10n.commonActive)
              else
                TextButton(
                  onPressed: widget.onActivate,
                  child: Text(l10n.commonSetActive),
                ),
              const SizedBox(width: 4),
              SoftIconButton(
                icon: Icons.edit_outlined,
                tooltip: l10n.commonEdit,
                size: 32,
                iconSize: 16,
                onPressed: widget.onOpen,
              ),
              SoftIconButton(
                icon: Icons.delete_outline,
                tooltip: l10n.commonDelete,
                size: 32,
                iconSize: 16,
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
