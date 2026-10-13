import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../canvas_preview/presentation/widgets/skeleton.dart';
import '../../mcp/presentation/mcp_status_section.dart';
import '../data/datasources/ai_api_service.dart';
import '../domain/entities/api_provider.dart';
import 'providers/provider_config_provider.dart';

class ProviderConfigPage extends ConsumerStatefulWidget {
  const ProviderConfigPage({super.key});

  @override
  ConsumerState<ProviderConfigPage> createState() => _ProviderConfigPageState();
}

class _ProviderConfigPageState extends ConsumerState<ProviderConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  String? _editingProviderId;
  bool _isTesting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _editingProviderId = null;
      _nameController.clear();
      _baseUrlController.clear();
      _apiKeyController.clear();
      _modelController.clear();
    });
  }

  void _startEdit(ApiProvider provider) {
    setState(() {
      _editingProviderId = provider.id;
      _nameController.text = provider.name;
      _baseUrlController.text = provider.baseUrl;
      _apiKeyController.clear();
      _modelController.text = provider.model;
    });
  }

  ApiProvider _providerFromForm() {
    final apiKey = _apiKeyController.text.trim();
    return ApiProvider(
      id: _editingProviderId ?? 'pending',
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: apiKey.isEmpty ? null : apiKey,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = _providerFromForm();
    await ref
        .read(providerConfigProvider.notifier)
        .saveProvider(
          id: _editingProviderId,
          name: provider.name,
          baseUrl: provider.baseUrl,
          model: provider.model,
          apiKey: provider.apiKey,
        );

    if (!mounted) return;
    final result = ref.read(providerConfigProvider);
    if (result.hasError) {
      _showSnackBar('Gagal menyimpan: ${result.error}', isError: true);
      return;
    }

    _showSnackBar(
      _editingProviderId == null
          ? 'Provider berhasil ditambahkan.'
          : 'Provider berhasil diperbarui.',
      isError: false,
    );
    _resetForm();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);
    try {
      var provider = _providerFromForm();
      // Bug fix: saat mengedit provider tanpa mengisi ulang API Key, field
      // kosong (apiKey=null) membuat Test Connection selalu gagal. Pakai key
      // yang tersimpan di secure storage bila form tidak mengisi key baru.
      final editingId = _editingProviderId;
      if (provider.apiKey == null && editingId != null) {
        final existing = await ref
            .read(apiProviderRepositoryProvider)
            .getProviderById(editingId);
        if (existing?.apiKey != null) {
          provider = provider.copyWith(apiKey: existing!.apiKey);
        }
      }
      await ref
          .read(providerConfigProvider.notifier)
          .testConnection(provider);
      if (mounted) _showSnackBar('Koneksi berhasil.', isError: false);
    } on ApiConnectionException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _confirmDelete(ApiProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text(
          'Hapus Provider',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Hapus "${provider.name}" beserta API key tersimpan? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.statusError),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (_editingProviderId == provider.id) _resetForm();
    await ref.read(providerConfigProvider.notifier).deleteProvider(provider.id);
    if (mounted) _showSnackBar('Provider dihapus.', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 16,
                color: isError
                    ? AppColors.statusError
                    : AppColors.statusSuccess,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(providerConfigProvider);
    final providers = asyncState.value?.providers ?? const [];
    final activeProviderId = asyncState.value?.activeProvider?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Custom API Provider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
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
                  'Centauri tidak mengirim data Anda ke server mana pun. Semua kredensial API disimpan terenkripsi di perangkat Anda.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 32),
                _buildProviderList(providers, activeProviderId, asyncState),
                // MCP bridge agar agent eksternal bisa membaca/mengubah canvas.
                const SizedBox(height: 32),
                const McpStatusSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        borderRadius: AppRadius.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _editingProviderId == null
                      ? 'Tambah Provider Baru'
                      : 'Edit Provider',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_editingProviderId != null)
                  TextButton(
                    onPressed: _resetForm,
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Provider Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'My Groq'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama provider wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('Base URL'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _baseUrlController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'https://api.openai.com/v1',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Base URL wajib diisi.';
                final uri = Uri.tryParse(text);
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return 'Masukkan URL yang valid (contoh: https://...).';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            _buildResolvedEndpointPreview(),
            const SizedBox(height: 8),
            _buildPresetChips(),
            const SizedBox(height: 20),
            _buildLabel('API Key'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _apiKeyController,
              obscureText: true,
              style: const TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: _editingProviderId == null ? 'sk-...' : '••••••••',
                helperText: _editingProviderId == null
                    ? 'Kosongkan jika menggunakan endpoint lokal tanpa autentikasi.'
                    : 'Kosongkan untuk mempertahankan key yang tersimpan.',
                helperStyle: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Model Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _modelController,
              style: const TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 13,
              ),
              decoration: const InputDecoration(hintText: 'gpt-4o'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama model wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentPrimary,
                            ),
                          )
                        : const Text(
                            'Test Connection',
                            style: TextStyle(fontSize: 13),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(
                      _editingProviderId == null
                          ? 'Simpan Provider'
                          : 'Update Provider',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips() {
    final presets = AppConstants.knownProviderPresets.entries.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((entry) {
        return InkWell(
          onTap: () {
            setState(() {
              _baseUrlController.text = entry.value;
            });
          },
          borderRadius: AppRadius.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: AppRadius.sm,
            ),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Menampilkan URL endpoint final yang akan dipanggil. Membantu pengguna
  /// menyadari Base URL yang salah sebelum menekan Test/Save.
  Widget _buildResolvedEndpointPreview() {
    final base = _baseUrlController.text.trim();
    if (base.isEmpty) return const SizedBox.shrink();

    final endpoint = AiApiService.resolveEndpoint(
      base,
      AppConstants.chatCompletionsPath,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.arrow_forward, size: 12, color: AppColors.textDisabled),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            endpoint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 10,
              height: 1.4,
              color: AppColors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProviderList(
    List<ApiProvider> providers,
    String? activeProviderId,
    AsyncValue<ProviderConfigState> asyncState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Provider Tersimpan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (asyncState.isLoading && providers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                SkeletonListRow(),
                SkeletonListRow(),
              ],
            ),
          )
        else if (asyncState.hasError && providers.isEmpty)
          Container(
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
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.refresh(providerConfigProvider.future),
                  child: const Text(
                    'Coba lagi',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else if (providers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: AppRadius.md,
            ),
            child: const Column(
              children: [
                Text(
                  'Belum ada provider',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tambahkan provider di atas untuk mulai menggunakan Centauri.',
                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: providers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildProviderTile(providers[index], activeProviderId),
          ),
      ],
    );
  }

  Widget _buildProviderTile(ApiProvider provider, String? activeProviderId) {
    final isActive = provider.id == activeProviderId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(
          color: isActive ? AppColors.accentPrimary : AppColors.borderSubtle,
        ),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: AppRadius.sm,
                        ),
                        child: const Text(
                          'AKTIF',
                          style: TextStyle(
                            fontFamily: AppFonts.monoFamily,
                            fontFamilyFallback: AppFonts.monoFallback,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.baseUrl}  ·  ${provider.model}',
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
          ),
          if (!isActive)
            IconButton(
              tooltip: 'Jadikan aktif',
              icon: const Icon(Icons.check_circle_outline, size: 18),
              color: AppColors.textSecondary,
              splashRadius: 20,
              onPressed: () => ref
                  .read(providerConfigProvider.notifier)
                  .setActiveProvider(provider.id),
            ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textSecondary,
            splashRadius: 20,
            onPressed: () => _startEdit(provider),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.textSecondary,
            splashRadius: 20,
            onPressed: () => _confirmDelete(provider),
          ),
        ],
      ),
    );
  }
}
