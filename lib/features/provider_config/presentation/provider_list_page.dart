import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
import '../../canvas_preview/presentation/widgets/skeleton.dart';
import '../../mcp/presentation/mcp_status_section.dart';
import '../domain/entities/api_provider.dart';
import 'providers/provider_config_provider.dart';
import 'widgets/delete_provider_dialog.dart';

/// Layar daftar provider: list kartu provider tersimpan + aksi tambah/hapus.
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
      appBar: AppBar(title: const Text('Provider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bring Your Own Key (BYOK)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Centauri tidak mengirim data Anda ke server mana pun. Semua '
                  'kredensial API disimpan terenkripsi di perangkat Anda.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildActions(context),
                const SizedBox(height: 20),
                _buildList(context, ref, providers, activeProviderId, asyncState),
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

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.providerNew),
          icon: const Icon(Icons.add, size: 16),
          label: const Text(
            'Tambah Provider',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
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
          border: Border.all(color: AppColors.statusError),
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
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(providerConfigProvider.future),
              child: const Text('Coba lagi', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (providers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: AppRadius.md,
        ),
        child: const Column(
          children: [
            Text(
              'Belum ada provider',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Tambahkan provider untuk mulai menggunakan Centauri.',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final oauthStatus =
        asyncState.value?.oauthStatus ?? const <String, OAuthStatus>{};

    // List kartu vertikal (bukan tabel) agar teks panjang seperti Base URL
    // dan nama model tampil penuh tanpa terpotong.
    return Column(
      children: [
        for (var i = 0; i < providers.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _providerCard(
            context,
            ref,
            providers[i],
            providers[i].id == activeProviderId,
            oauthStatus[providers[i].id] ?? OAuthStatus.none,
          ),
        ],
      ],
    );
  }

  Widget _providerCard(
    BuildContext context,
    WidgetRef ref,
    ApiProvider provider,
    bool isActive,
    OAuthStatus status,
  ) {
    return InkWell(
      onTap: () => context.push(AppRoutes.providerDetail(provider.id)),
      borderRadius: AppRadius.md,
      hoverColor: AppColors.hoverBg,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(
            color: isActive ? AppColors.accentPrimary : AppColors.borderSubtle,
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: AppRadius.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (provider.baseUrl.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          provider.baseUrl,
                          style: const TextStyle(
                            fontFamily: AppFonts.monoFamily,
                            fontFamilyFallback: AppFonts.monoFallback,
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _actionsCell(context, ref, provider, isActive),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _authCell(provider, status),
                if (provider.model.trim().isNotEmpty)
                  _chip(provider.model, AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _authCell(ApiProvider provider, OAuthStatus status) {
    if (!provider.usesOAuth) {
      return _chip('API Key', AppColors.textSecondary);
    }
    final (label, color) = switch (status) {
      OAuthStatus.connected => ('OAuth · Connected', AppColors.statusSuccess),
      OAuthStatus.expiring => ('OAuth · Expiring', AppColors.statusWarning),
      OAuthStatus.disconnected => (
        'OAuth · Disconnected',
        AppColors.statusError,
      ),
      OAuthStatus.none => ('OAuth', AppColors.textDisabled),
    };
    return _chip(label, color);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.monoFamily,
          fontFamilyFallback: AppFonts.monoFallback,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionsCell(
    BuildContext context,
    WidgetRef ref,
    ApiProvider provider,
    bool isActive,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isActive)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'AKTIF',
              style: TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.accentPrimary,
              ),
            ),
          )
        else
          IconButton(
            tooltip: 'Jadikan aktif',
            icon: const Icon(Icons.check_circle_outline, size: 18),
            color: AppColors.textSecondary,
            splashRadius: 18,
            onPressed: () => ref
                .read(providerConfigProvider.notifier)
                .setActiveProvider(provider.id),
          ),
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.textSecondary,
          splashRadius: 18,
          onPressed: () =>
              context.push(AppRoutes.providerDetail(provider.id)),
        ),
        IconButton(
          tooltip: 'Hapus',
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.textSecondary,
          splashRadius: 18,
          onPressed: () => _delete(context, ref, provider),
        ),
      ],
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
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Provider dihapus.',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
