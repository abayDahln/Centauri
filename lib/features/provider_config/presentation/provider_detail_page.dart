import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
import '../../../core/utils/app_constants.dart';
import '../data/catalog/provider_catalog.dart';
import '../data/catalog/provider_models.dart';
import '../data/datasources/ai_api_service.dart';
import '../domain/catalog/provider_catalog_entry.dart';
import '../domain/entities/api_provider.dart';
import 'providers/provider_config_provider.dart';
import 'widgets/delete_provider_dialog.dart';
import 'widgets/model_picker_dialog.dart';
import 'widgets/picker_field.dart';
import 'widgets/provider_picker_dialog.dart';

/// Layar tambah/edit provider berbentuk satu kartu setelan.
///
/// Alur: isi **Nama**, pilih **Provider** lewat dialog (Custom API Key atau
/// template katalog), lalu lengkapi Base URL, API Key, dan Model. Memilih
/// template mengunci Nama Provider & Base URL; memilih Custom membebaskan
/// keduanya. Setelah disimpan, layar kembali ke daftar provider dan entri baru
/// langsung aktif.
class ProviderDetailPage extends ConsumerStatefulWidget {
  const ProviderDetailPage({super.key, this.providerId});

  /// Provider tersimpan yang akan diedit; null berarti tambah baru.
  final String? providerId;

  @override
  ConsumerState<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends ConsumerState<ProviderDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  String? _editingProviderId;
  bool _isTesting = false;

  /// Id entri katalog provider yang dipilih. Null = belum dipilih.
  String? _catalogId;

  /// Id model polos yang dipakai.
  String _model = '';

  /// Model di luar saran provider yang ditambahkan pengguna.
  final List<String> _customModels = [];

  /// Model template yang dihapus untuk provider ini saja; template aslinya
  /// tetap utuh sehingga provider baru masih menampilkan semua model bawaan.
  final List<String> _removedModels = [];

  /// True bila provider yang sedang diedit punya API Key di secure storage.
  bool _hasStoredApiKey = false;

  /// Pengguna menekan Reset: key tersimpan akan dihapus saat Simpan. Selama
  /// belum disimpan key lama tetap utuh, sehingga Batal tidak menghapus apa pun.
  bool _apiKeyCleared = false;

  bool get _hasProvider => _catalogId != null;

  /// Pengguna memilih "Custom API Key" → semua field bisa diisi sendiri.
  bool get _isCustom => _catalogId == kCustomCatalogId;

  /// Base URL terkunci saat memakai template katalog.
  bool get _baseUrlLocked => _hasProvider && !_isCustom;

  /// Field API Key terkunci selama masih ada key tersimpan yang belum di-reset,
  /// supaya key lama tidak tertimpa tanpa sepengetahuan pengguna.
  bool get _apiKeyLocked => _hasStoredApiKey && !_apiKeyCleared;

  /// Tombol Reset hanya relevan saat masih ada key tersimpan.
  bool get _canResetApiKey => _hasStoredApiKey && !_apiKeyCleared;

  @override
  void initState() {
    super.initState();
    final id = widget.providerId;
    if (id != null) {
      // Muat setelah frame pertama agar aman dari setState sebelum build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting(id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerNameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting(String id) async {
    final provider = await ref
        .read(apiProviderRepositoryProvider)
        .getProviderById(id);
    if (provider == null || !mounted) return;
    setState(() => _fillForm(provider));
  }

  // ------------------------------------------------------------- form ----

  /// Mengisi kartu setelan dari [provider]. Aman dipanggil dari [initState]
  /// maupun dibungkus [setState].
  void _fillForm(ApiProvider provider) {
    _editingProviderId = provider.id;
    _nameController.text = provider.name;
    _providerNameController.text = provider.providerName;
    _baseUrlController.text = provider.baseUrl;
    _apiKeyController.clear();
    _hasStoredApiKey = (provider.apiKey ?? '').trim().isNotEmpty;
    _apiKeyCleared = false;
    _catalogId = provider.catalogId ?? kCustomCatalogId;
    _model = provider.model;
    _customModels
      ..clear()
      ..addAll(provider.customModels);
    _removedModels
      ..clear()
      ..addAll(provider.removedModels);
    _seedCustomModel(_model);
  }

  /// Bila [model] tidak ada di saran provider, tampilkan sebagai model kustom
  /// agar tetap terpilih di dialog.
  void _seedCustomModel(String model) {
    final value = model.trim();
    if (value.isEmpty) return;
    final set = ProviderModelCatalog.forProvider(_catalogId);
    if (set != null && set.models.any((m) => m.id == value)) return;
    if (!_customModels.contains(value)) _customModels.add(value);
  }

  /// Model default saat memilih template: pakai default katalog bila ada di
  /// daftar, jika tidak model pertama.
  String _defaultModelFor(String? catalogId, String fallback) {
    final set = ProviderModelCatalog.forProvider(catalogId);
    if (set == null || set.models.isEmpty) return fallback;
    for (final model in set.models) {
      if (model.id == fallback) return model.id;
    }
    return set.models.first.id;
  }

  String get _providerLabel {
    final id = _catalogId;
    if (id == null) return '';
    return ProviderCatalog.byId(id)?.name ?? id;
  }

  ApiProvider _providerFromForm() {
    final apiKey = _apiKeyController.text.trim();
    return ApiProvider(
      id: _editingProviderId ?? 'pending',
      name: _nameController.text.trim(),
      providerName: _providerNameController.text.trim(),
      catalogId: _catalogId,
      baseUrl: _baseUrlController.text.trim(),
      model: _model.trim(),
      apiKey: apiKey.isNotEmpty ? apiKey : null,
    );
  }

  /// Provider dari form, dilengkapi API Key tersimpan bila field dikosongkan
  /// saat mengedit. Dipakai untuk Test.
  Future<ApiProvider> _providerWithStoredCredentials() async {
    var provider = _providerFromForm();
    final editingId = _editingProviderId;
    if (editingId == null) return provider;

    final stored = await ref
        .read(apiProviderRepositoryProvider)
        .getProviderById(editingId);
    if (stored == null) return provider;

    // Setelah Reset, key lama sengaja tidak dipakai: Test harus mencerminkan
    // keadaan yang akan disimpan.
    if (provider.apiKey == null && !_apiKeyCleared && stored.apiKey != null) {
      provider = provider.copyWith(apiKey: stored.apiKey);
    }
    return provider;
  }

  // ----------------------------------------------------------- pemilih ----

  Future<void> _pickProvider() async {
    final entry = await showProviderPickerDialog(
      context,
      selectedId: _catalogId,
    );
    if (entry == null || !mounted) return;
    // Mengetuk provider yang sama tidak mengubah apa pun.
    if (entry.id == _catalogId) return;
    setState(() => _applyCatalogEntry(entry));
  }

  /// Menerapkan pilihan provider. Template mengisi Nama Provider & Base URL
  /// (terkunci); Custom membiarkan pengguna mengisi keduanya sendiri.
  void _applyCatalogEntry(ProviderCatalogEntry entry) {
    _catalogId = entry.id;
    _customModels.clear();
    // Provider baru memakai template apa adanya: penghapusan model di provider
    // lain tidak boleh ikut terbawa.
    _removedModels.clear();

    if (entry.id == kCustomCatalogId) {
      _providerNameController.text = '';
      _baseUrlController.text = '';
      _model = '';
      return;
    }

    _providerNameController.text = entry.name;
    _baseUrlController.text = entry.baseUrl;
    _model = _defaultModelFor(entry.id, entry.defaultModel);
    _seedCustomModel(_model);
  }

  Future<void> _pickModel() async {
    if (!_hasProvider) return;
    final result = await showModelPickerDialog(
      context,
      catalogId: _catalogId,
      selectedModel: _model,
      customModels: _customModels,
      removedModels: _removedModels,
    );
    if (result == null || !mounted) return;
    setState(() {
      _model = result.modelId;
      _customModels
        ..clear()
        ..addAll(result.customModels);
      _removedModels
        ..clear()
        ..addAll(result.removedModels);
    });
  }

  // -------------------------------------------------------------- aksi ----

  /// Validasi yang tidak tercakup [Form]: provider & model wajib dipilih.
  bool _validateSelection() {
    if (!_hasProvider) {
      _showSnackBar('Pilih provider dulu.', isError: true);
      return false;
    }
    if (!_formKey.currentState!.validate()) return false;
    if (_model.trim().isEmpty) {
      _showSnackBar('Pilih model dulu.', isError: true);
      return false;
    }
    return true;
  }

  /// Simpan provider dan kembalikan id-nya, atau null bila gagal.
  Future<String?> _persistProvider() async {
    final provider = _providerFromForm();
    final id = await ref
        .read(providerConfigProvider.notifier)
        .saveProvider(
          id: _editingProviderId,
          name: provider.name,
          providerName: provider.providerName,
          catalogId: _catalogId!,
          baseUrl: provider.baseUrl,
          model: provider.model,
          apiKey: provider.apiKey,
          customModels: _customModels,
          removedModels: _removedModels,
        );

    if (!mounted) return null;
    final result = ref.read(providerConfigProvider);
    if (result.hasError) {
      _showSnackBar('Gagal menyimpan: ${result.error}', isError: true);
      return null;
    }

    // Reset baru menghapus key setelah Simpan, bukan saat tombolnya ditekan,
    // supaya Batal membatalkan Reset juga.
    if (_apiKeyCleared && provider.apiKey == null) {
      await ref.read(providerConfigProvider.notifier).clearApiKey(id);
      if (!mounted) return null;
      final cleared = ref.read(providerConfigProvider);
      if (cleared.hasError) {
        _showSnackBar(
          'Gagal menghapus API Key: ${cleared.error}',
          isError: true,
        );
        return null;
      }
    }

    return id;
  }

  Future<void> _save() async {
    if (!_validateSelection()) return;

    final wasEditing = _editingProviderId != null;
    final id = await _persistProvider();
    if (id == null || !mounted) return;

    _showSnackBar(
      wasEditing ? 'Provider diperbarui.' : 'Provider ditambahkan.',
      isError: false,
    );

    // Kembali ke daftar provider; entri baru sudah langsung aktif. Memakai pop
    // agar tumpukan navigasi tetap utuh (tombol kembali di daftar tetap ada).
    _backToList();
  }

  Future<void> _testConnection() async {
    if (!_validateSelection()) return;

    setState(() => _isTesting = true);
    try {
      final provider = await _providerWithStoredCredentials();
      await ref.read(providerConfigProvider.notifier).testConnection(provider);
      if (mounted) _showSnackBar('Koneksi berhasil.', isError: false);
    } on ApiConnectionException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  /// Menandai API Key tersimpan untuk dihapus, lalu membuka isian agar bisa
  /// diisi key baru. Penghapusan sebenarnya terjadi saat Simpan; selama belum
  /// disimpan key lama tetap utuh, jadi Batal membatalkan Reset juga.
  void _resetApiKey() {
    setState(() {
      _apiKeyCleared = true;
      _apiKeyController.clear();
    });
  }

  Future<void> _confirmDelete() async {
    final id = _editingProviderId;
    if (id == null) return;

    final confirmed = await showDeleteProviderDialog(
      context,
      _nameController.text,
    );
    if (!confirmed || !mounted) return;

    await ref.read(providerConfigProvider.notifier).deleteProvider(id);
    if (!mounted) return;
    _showSnackBar('Provider dihapus.', isError: false);
    _backToList();
  }

  /// Kembali ke daftar provider. Memakai pop bila halaman ini ditumpuk di atas
  /// daftar; kalau tidak (dibuka langsung lewat tautan), ganti lokasi ke daftar.
  void _backToList() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.providers);
    }
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

  // -------------------------------------------------------------- build ----

  @override
  Widget build(BuildContext context) {
    final editing = _editingProviderId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Ubah provider' : 'Tambah provider'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Hapus provider',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: _confirmDelete,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: AppRadius.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('Nama'),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('field-nama'),
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. "OpenAI Pro"'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 20),
            PickerField(
              key: const ValueKey('picker-provider'),
              label: 'Provider',
              value: _providerLabel,
              hint: 'Pilih provider',
              onTap: _pickProvider,
            ),
            // Custom: pengguna mengetik nama providernya sendiri.
            if (_isCustom) ...[
              const SizedBox(height: 20),
              const FieldLabel('Nama Provider'),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('field-providerName'),
                controller: _providerNameController,
                decoration: const InputDecoration(hintText: 'e.g. "OpenAI"'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Nama provider wajib diisi.'
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            FieldLabel(
              'Base URL',
              trailing: _baseUrlLocked ? _lockBadge() : null,
            ),
            const SizedBox(height: 8),
            _buildBaseUrlField(),
            const SizedBox(height: 20),
            const FieldLabel('API Key'),
            const SizedBox(height: 8),
            _buildApiKeyField(),
            const SizedBox(height: 20),
            PickerField(
              key: const ValueKey('picker-model'),
              label: 'Model',
              value: _model,
              hint: _hasProvider ? 'Pilih model' : 'Pilih provider dulu',
              enabled: _hasProvider,
              onTap: _pickModel,
              valueStyle: const TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 13,
              ),
              // Uji koneksi duduk di samping field model karena validasi selalu
              // memakai pasangan Base URL + model yang sedang dipilih.
              trailing: OutlinedButton(
                key: const ValueKey('button-test'),
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
                    : const Text('Test'),
              ),
            ),
            const SizedBox(height: 24),
            _buildFormActions(),
          ],
        ),
      ),
    );
  }

  /// Base URL hanya bisa diisi untuk provider custom; template terkunci.
  Widget _buildBaseUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('field-baseUrl'),
          controller: _baseUrlController,
          enabled: _isCustom,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: AppFonts.monoFamily,
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'https://api.openai.com/v1',
            // Nonaktif = tenggelam, sama seperti field pilihan yang terkunci.
            fillColor: _isCustom ? AppColors.inputBg : AppColors.bgSunken,
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
      ],
    );
  }

  Widget _lockBadge() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 12, color: AppColors.textDisabled),
        SizedBox(width: 4),
        Text(
          'Dari provider',
          style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
        ),
      ],
    );
  }

  /// Keterangan di bawah field API Key, mengikuti keadaan field.
  String get _apiKeyHelper {
    if (_apiKeyLocked) return 'API Key tersimpan. Reset untuk mengganti.';
    if (_apiKeyCleared && _apiKeyController.text.trim().isEmpty) {
      return 'API Key dihapus saat disimpan.';
    }
    return 'Kosongkan untuk layanan lokal tanpa autentikasi.';
  }

  /// Field API Key: terkunci bila provider sudah punya key tersimpan. Tombol
  /// Reset membuka isian dan menandai key lama untuk dihapus saat Simpan.
  Widget _buildApiKeyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('field-apiKey'),
                  controller: _apiKeyController,
                  enabled: !_apiKeyLocked,
                  obscureText: true,
                  // Helper di bawah field ikut berubah saat key baru diketik.
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: AppFonts.monoFamily,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: _apiKeyLocked ? '••••••••' : 'sk-...',
                    // Terkunci = tenggelam, sejalan dengan field nonaktif lain.
                    fillColor: _apiKeyLocked
                        ? AppColors.bgSunken
                        : AppColors.inputBg,
                  ),
                ),
              ),
              if (_canResetApiKey) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const ValueKey('button-reset-apiKey'),
                  onPressed: _resetApiKey,
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _apiKeyHelper,
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
        ),
      ],
    );
  }

  /// Aksi kartu: Batal dan Simpan berukuran isi, rata kanan — pola yang sama
  /// dengan dialog aplikasi. Tombol mewarisi gaya dari tema (13 px, w600), jadi
  /// tidak ada teks yang ditimpa per tombol.
  Widget _buildFormActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          key: const ValueKey('button-cancel'),
          onPressed: _backToList,
          child: const Text('Batal'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          key: const ValueKey('button-save'),
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  /// Menampilkan URL endpoint final yang akan dipanggil. Membantu pengguna
  /// menyadari Base URL yang salah sebelum menekan Test/Simpan.
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
        const Icon(
          Icons.arrow_forward,
          size: 12,
          color: AppColors.textDisabled,
        ),
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
}
