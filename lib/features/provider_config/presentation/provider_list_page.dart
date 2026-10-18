import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
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
    final asyncState = ref.watch(providerConfigProvider);
    final providers = asyncState.value?.providers ?? const <ApiProvider>[];
    final activeProviderId = asyncState.value?.activeProvider?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider'),
        // Tombol kembali eksplisit: halaman ini juga bisa menjadi halaman
        // pertama (mis. setelah simpan yang mengganti lokasi), dan pengguna
        // tidak boleh terjebak tanpa jalan keluar.
        leading: BackButton(onPressed: () => _leave(context)),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.providerNew),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bring Your Own Key (BYOK)',
                  style: TextStyle(
                    fontSize: 24,
                    height: 30 / 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Semua data tersimpan dan terenkripsi di perangkat Anda.',
                  style: AppText.uiSmall,
                ),
                const SizedBox(height: 28),
                _buildList(
                  context,
                  ref,
                  providers,
                  activeProviderId,
                  asyncState,
                ),
                const SizedBox(height: 32),
                // MCP bridge agar agent eksternal bisa membaca/mengubah canvas.
                const McpStatusSection(),
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
            color: AppColors.statusError.withValues(alpha: 0.32),
          ),
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 16,
              color: AppColors.statusError,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Gagal memuat daftar provider.',
                style: AppText.uiSmall,
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(providerConfigProvider.future),
              child: const Text('Coba lagi'),
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
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: AppRadius.md,
          color: AppColors.bgSurface,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.key_outlined,
              size: 24,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text('Belum ada provider', style: AppText.panelTitle),
            const SizedBox(height: 4),
            const Text(
              'Tambahkan provider untuk mulai menggunakan Centauri.',
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.providerNew),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah provider'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < providers.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderSubtle),
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
    final confirmed = await showDeleteProviderDialog(context, provider.name);
    if (!confirmed) return;
    await ref.read(providerConfigProvider.notifier).deleteProvider(provider.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Provider dihapus.')));
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
    final provider = widget.provider;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? AppColors.hoverBg : AppColors.bgSurface,
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
                            style: AppText.ui.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (provider.providerName.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            provider.providerName,
                            style: AppText.monoSmall.copyWith(
                              color: AppColors.textDisabled,
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
                        style: AppText.monoSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.isActive)
                const StatusPill(label: 'Aktif')
              else
                TextButton(
                  onPressed: widget.onActivate,
                  child: const Text('Jadikan aktif'),
                ),
              const SizedBox(width: 4),
              SoftIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Ubah',
                size: 32,
                iconSize: 16,
                onPressed: widget.onOpen,
              ),
              SoftIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Hapus',
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
