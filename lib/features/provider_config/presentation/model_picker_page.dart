import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../canvas_preview/presentation/widgets/skeleton.dart';
import '../data/datasources/ai_api_service.dart';
import '../domain/entities/api_provider.dart';
import 'provider_navigation_args.dart';
import 'providers/model_list_provider.dart';

/// Layar pemilih model: mengambil daftar model live dari `GET /models`
/// milik provider tersebut (valid langsung dari provider) dan menyediakannya
/// sebagai list 1 kolom penuh yang bisa dicari. Bila pengambilan gagal atau
/// model tidak ada di daftar, pengguna tetap bisa mengetik manual.
///
/// Menutup layar sambil mengembalikan id model terpilih lewat [context.pop].
class ModelPickerPage extends ConsumerStatefulWidget {
  const ModelPickerPage({super.key, required this.args});

  /// Argumen dari `extra` go_router; null bila layar dibuka tanpa konteks
  /// provider (mis. deep link).
  final ModelPickerArgs? args;

  @override
  ConsumerState<ModelPickerPage> createState() => _ModelPickerPageState();
}

class _ModelPickerPageState extends ConsumerState<ModelPickerPage> {
  final _searchController = TextEditingController();
  final _manualController = TextEditingController();

  String _query = '';
  String? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  List<String> _filter(List<String> models) {
    if (_query.isEmpty) return models;
    final q = _query.toLowerCase();
    return models.where((m) => m.toLowerCase().contains(q)).toList();
  }

  void _use(String model) {
    final trimmed = model.trim();
    if (trimmed.isEmpty) return;
    context.pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) return _buildMissingArgs();

    final provider = args.provider;
    final query = ModelListQuery(
      baseUrl: provider.normalizedBaseUrl,
      bearerToken: provider.bearerToken,
    );
    final asyncModels = ref.watch(modelListProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Model'),
        actions: [
          if (asyncModels.hasValue && !asyncModels.isLoading)
            IconButton(
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => ref.invalidate(modelListProvider(query)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProviderHeader(provider),
                const SizedBox(height: 16),
                asyncModels.when(
                  loading: _buildLoading,
                  error: (error, _) => _buildError(error, query),
                  data: _buildModelTable,
                ),
                const SizedBox(height: 24),
                _buildManualFallback(),
                const SizedBox(height: 16),
                _buildSelectionBar(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingArgs() {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Model')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.link_off,
              size: 28,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            const Text(
              'Konteks provider tidak tersedia.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.providers),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderHeader(ApiProvider provider) {
    final name = provider.name.trim().isEmpty
        ? 'Provider'
        : provider.name.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AiApiService.resolveEndpoint(
              provider.normalizedBaseUrl,
              AppConstants.testConnectionPath,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonListRow(),
          SkeletonListRow(),
          SkeletonListRow(),
        ],
      ),
    );
  }

  Widget _buildError(Object error, ModelListQuery query) {
    final message = error is ApiConnectionException
        ? error.message
        : error.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.statusError),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.statusError,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gagal memuat daftar model.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(modelListProvider(query)),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba lagi', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Atau ketik nama model secara manual di bawah.',
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelTable(List<String> models) {
    final filtered = _filter(models);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            hintText: 'Cari model... (${models.length} tersedia)',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _query.isEmpty
              ? '${models.length} model dari provider ini.'
              : 'Menampilkan ${filtered.length} dari ${models.length} model.',
          style: const TextStyle(
            color: AppColors.textDisabled,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Tidak ada model yang cocok dengan pencarian.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          // List 1 kolom penuh (bukan tabel) agar id model yang panjang
          // tampil penuh tanpa terpotong — beberapa provider punya
          // ratusan model.
          for (var i = 0; i < filtered.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildModelRow(filtered[i], filtered[i] == _selected),
          ],
      ],
    );
  }

  Widget _buildModelRow(String model, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selected = model),
      borderRadius: AppRadius.sm,
      hoverColor: AppColors.hoverBg,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.08)
              : AppColors.bgSurface,
          border: Border.all(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.borderSubtle,
          ),
          borderRadius: AppRadius.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                model,
                style: const TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _use(model),
              child: const Text('Pakai', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  /// Jalur cadangan: mengetik id model secara manual.
  Widget _buildManualFallback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input manual',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan bila model tidak muncul di daftar.',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  onSubmitted: _use,
                  style: const TextStyle(
                    fontFamily: AppFonts.monoFamily,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(hintText: 'mis. gpt-4o-mini'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _use(_manualController.text),
                child: const Text('Pakai', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _selected == null ? 'Belum ada model dipilih.' : 'Dipilih: $_selected',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 12,
              color: _selected == null
                  ? AppColors.textDisabled
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _selected == null ? null : () => _use(_selected!),
          child: const Text(
            'Gunakan Model',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
