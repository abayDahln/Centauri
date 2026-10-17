import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
import '../../../core/utils/app_constants.dart';
import '../data/catalog/provider_catalog.dart';
import '../data/catalog/provider_models.dart';
import '../data/datasources/ai_api_service.dart';
import '../data/oauth/oauth_provider_presets.dart';
import '../data/services/cursor_token_importer.dart';
import '../domain/catalog/catalog_selection.dart';
import '../domain/entities/api_provider.dart';
import '../domain/entities/oauth_config.dart';
import '../domain/entities/oauth_flow.dart';
import '../domain/entities/oauth_token_set.dart';
import '../domain/entities/provider_auth_type.dart';
import '../domain/oauth/oauth_provider_preset.dart';
import '../domain/services/oauth_service.dart';
import 'provider_navigation_args.dart';
import 'providers/provider_config_provider.dart';
import 'widgets/delete_provider_dialog.dart';
import 'widgets/device_connect_dialog.dart';
import 'widgets/model_card.dart';
import 'widgets/provider_catalog_panel.dart';

/// Layar detail provider: formulir tambah manual / edit lengkap dengan OAuth.
///
/// Menerima salah satu dari:
///  - [providerId] — provider tersimpan yang akan diedit (dari rute
///    `/providers/:id`);
///  - [args] — draft yang diteruskan lewat `extra` go_router.
class ProviderDetailPage extends ConsumerStatefulWidget {
  const ProviderDetailPage({super.key, this.providerId, this.args});

  final String? providerId;
  final ProviderDetailArgs? args;

  @override
  ConsumerState<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends ConsumerState<ProviderDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _newModelController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _authUrlController = TextEditingController();
  final _tokenUrlController = TextEditingController();

  String? _editingProviderId;

  /// Id preset OAuth yang saat ini memiliki sesi (token) tersimpan. Chip
  /// "Connected" hanya boleh tampil bila form memakai preset yang sama —
  /// berpindah preset berarti sesi milik preset lama tidak berlaku di sini.
  String? _oauthSessionPresetId;
  bool _isTesting = false;
  bool _isConnecting = false;

  /// Id katalog/preset provider yang sedang dipakai form. Dipakai untuk
  /// mencari daftar model hardcode ([ProviderModelCatalog]) dan menandai kartu
  /// provider yang aktif di panel. Null untuk provider custom/lokal.
  String? _catalogId;

  /// Id model kustom yang ditambahkan pengguna lewat tombol "Add Model".
  /// Boleh banyak; hanya satu yang dipakai — id terpilih disimpan di
  /// [_modelController].
  final List<String> _customModels = [];

  /// True saat field input model baru sedang ditampilkan.
  bool _addingModel = false;

  AuthType _authType = AuthType.apiKey;
  OAuthProviderPreset _preset = OAuthProviderPresets.googleGemini;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args?.draft != null) {
      final draft = args!.draft!;
      _fillForm(draft);
      // Draft belum tersimpan (id placeholder) → perlakukan sebagai provider
      // baru, bukan mode edit.
      if (draft.id.isEmpty || draft.id == 'pending') {
        _editingProviderId = null;
      }
    } else if (args?.selection != null) {
      _applySelection(args!.selection!);
    } else if (widget.providerId != null) {
      // Muat dari storage setelah frame pertama terbentuk agar aman dari
      // setState sebelum build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExisting(widget.providerId!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _newModelController.dispose();
    _clientIdController.dispose();
    _authUrlController.dispose();
    _tokenUrlController.dispose();
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

  /// Mengisi form dari [provider] tanpa memicu setState. Aman dipanggil dari
  /// [initState] maupun dibungkus [setState].
  void _fillForm(ApiProvider provider) {
    final config = provider.oauthConfig;
    _editingProviderId = provider.id;
    _nameController.text = provider.name;
    _baseUrlController.text = provider.baseUrl;
    _apiKeyController.clear();
    _modelController.text = provider.model;
    _authType = provider.authType;
    _preset = _presetFor(config);
    // Sesi token tersimpan berasal dari preset konfigurasi yang tersimpan.
    _oauthSessionPresetId = _preset.id;
    _catalogId = _resolveCatalogId(provider);
    _seedCustomModels(provider.model);
    _clientIdController.text = config?.clientId ?? '';
    _authUrlController.text = _preset.isCustom
        ? (config?.authorizationUrl ?? '')
        : '';
    _tokenUrlController.text = _preset.isCustom ? (config?.tokenUrl ?? '') : '';
  }

  /// Id katalog provider dari data tersimpan: preset OAuth → id preset;
  /// API key → entri katalog dengan Base URL yang cocok.
  String? _resolveCatalogId(ApiProvider provider) {
    if (provider.authType == AuthType.oauth) {
      return _preset.isCustom ? null : _preset.id;
    }
    final base = provider.normalizedBaseUrl;
    if (base.isEmpty) return null;
    for (final entry in ProviderCatalog.all) {
      if (entry.baseUrl.trim() == base) return entry.id;
    }
    return null;
  }

  /// Menyiapkan daftar model kustom dari model tersimpan: bila [model] tidak
  /// ada di daftar hardcode provider, tampilkan sebagai kartu kustom terpilih.
  void _seedCustomModels(String model) {
    _customModels.clear();
    final value = model.trim();
    if (value.isEmpty) return;
    final set = ProviderModelCatalog.forProvider(_catalogId);
    if (set != null && set.models.any((m) => m.id == value)) return;
    _customModels.add(value);
  }

  /// Menambahkan id model dari field "Add Model" ke daftar kustom, lalu
  /// memakainya sebagai model aktif. Id yang sudah ada di daftar hardcode
  /// provider cukup dipilih tanpa diduplikasi.
  void _addCustomModel() {
    final id = _newModelController.text.trim();
    if (id.isEmpty) return;
    setState(() {
      final set = ProviderModelCatalog.forProvider(_catalogId);
      final inCatalog = set != null && set.models.any((m) => m.id == id);
      if (!inCatalog && !_customModels.contains(id)) {
        _customModels.add(id);
      }
      _modelController.text = id;
      _newModelController.clear();
      _addingModel = false;
    });
  }

  /// Label tampilan untuk id model: `alias/id` bila provider punya alias
  /// katalog, selain itu id polos.
  String _modelLabel(String id) {
    final set = ProviderModelCatalog.forProvider(_catalogId);
    return set == null ? id : '${set.alias}/$id';
  }

  /// Model default saat memilih kartu provider: pakai [fallback] bila ada di
  /// daftar hardcode, jika tidak pakai model pertama daftar (agar tidak
  /// langsung jatuh ke mode custom).
  String _defaultModelFor(String? catalogId, String fallback) {
    final set = ProviderModelCatalog.forProvider(catalogId);
    if (set == null || set.models.isEmpty) return fallback;
    for (final model in set.models) {
      if (model.id == fallback) return model.id;
    }
    return set.models.first.id;
  }

  OAuthProviderPreset _presetFor(OAuthConfig? config) {
    if (config == null) return OAuthProviderPresets.googleGemini;
    for (final preset in OAuthProviderPresets.all) {
      if (preset.isCustom) continue;
      if (preset.flow != config.flow) continue;
      if (preset.authorizationUrl != config.authorizationUrl) continue;
      if (preset.tokenUrl != config.tokenUrl) continue;
      // Endpoint Google dipakai bersama (Gemini & Antigravity); bedakan
      // lewat clientId bila keduanya terisi.
      if (preset.clientId.isNotEmpty &&
          config.clientId.isNotEmpty &&
          preset.clientId != config.clientId) {
        continue;
      }
      return preset;
    }
    return OAuthProviderPresets.custom;
  }

  /// Preset yang mendukung dua metode auth sekaligus (OAuth + API Key).
  /// Saat ini hanya Zai GLM (OAuth + API Key). Qoder sengaja OAuth murni
  /// (tanpa PAT). Untuk preset ini form menampilkan field API Key di samping
  /// section OAuth tanpa tab bar.
  static const _dualAuthPresetIds = {'zai-glm'};

  /// True bila form menampilkan field API Key sekaligus section OAuth.
  bool get _supportsBothAuth =>
      _authType == AuthType.oauth && _dualAuthPresetIds.contains(_preset.id);

  /// True bila pengguna mengisi API Key pada provider dual-auth.
  /// Dipakai untuk menonaktifkan validasi token-only (chat via API key
  /// membutuhkan Base URL + model).
  bool get _usesApiKeyFallback =>
      _supportsBothAuth && _apiKeyController.text.trim().isNotEmpty;

  /// Preset yang API-nya bukan OpenAI-compatible sehingga chat tidak
  /// didukung (token saja, Base URL/model tidak relevan).
  bool get _isNonChatPreset =>
      _authType == AuthType.oauth && _preset.id == 'qoder';

  /// Preset hanya untuk memperoleh token (chat belum didukung) — Base URL &
  /// model tidak relevan. Untuk provider dual-auth yang dilengkapi API Key,
  /// chat via API key didukung sehingga validasi token-only dinonaktifkan.
  bool get _isTokenOnly =>
      _authType == AuthType.oauth &&
      _preset.isTokenOnly &&
      !_usesApiKeyFallback;

  /// Field Base URL hanya perlu untuk API Key (mis. OpenRouter, OpenCode),
  /// Custom OAuth, dan provider dual-auth Zai GLM (API key-nya memakai
  /// endpoint `api.z.ai`). Preset OAuth lain sudah membawa Base URL-nya
  /// sendiri, jadi tidak ditampilkan dan diambil otomatis dari preset.
  bool get _showBaseUrlField =>
      _authType == AuthType.apiKey ||
      _preset.isCustom ||
      (_supportsBothAuth && _preset.id == 'zai-glm');

  /// Base URL efektif yang akan disimpan: untuk OAuth non-custom selalu dari
  /// preset, kecuali provider dual-auth yang memakai input pengguna agar
  /// jalur API key bisa dipakai chat.
  String get _effectiveBaseUrl =>
      (_authType == AuthType.oauth &&
          !_preset.isCustom &&
          !_supportsBothAuth)
      ? _preset.baseUrl
      : _baseUrlController.text.trim();

  /// Base URL untuk validasi kredensial (Test Connection): endpoint khusus
  /// preset bila ada (mis. GitHub Copilot), selain itu Base URL chat efektif.
  ///
  /// `resolveEndpoint` memahami URL penuh (akhiran `/models` dipangkas dulu),
  /// sehingga `modelsUrl` boleh berupa endpoint penuh maupun root.
  String get _modelsBaseUrl {
    if (_authType == AuthType.oauth && _preset.modelsUrl.trim().isNotEmpty) {
      return _preset.modelsUrl.trim();
    }
    return _effectiveBaseUrl;
  }

  void _onPresetChangedInternal(OAuthProviderPreset preset) {
    _preset = preset;
    _catalogId = preset.isCustom ? null : preset.id;
    if (preset.id == 'zai-glm') {
      // Dual-auth: siapkan default endpoint API key Z.ai agar jalur API key
      // langsung bisa dipakai chat; pengguna tetap bisa mengubahnya.
      if (_baseUrlController.text.trim().isEmpty) {
        _baseUrlController.text = 'https://api.z.ai/api/paas/v4';
      }
      if (_modelController.text.trim().isEmpty) {
        _modelController.text = _defaultModelFor(preset.id, 'glm-4.6');
      }
    } else if (preset.isTokenOnly) {
      _baseUrlController.clear();
      _modelController.clear();
    } else {
      if (preset.baseUrl.isNotEmpty) _baseUrlController.text = preset.baseUrl;
      final defaultModel = preset.defaultModel;
      if (defaultModel != null && defaultModel.isNotEmpty) {
        _modelController.text = _defaultModelFor(preset.id, defaultModel);
      }
    }
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = preset.label;
    }
    if (preset.isCustom) {
      _authUrlController.clear();
      _tokenUrlController.clear();
      _clientIdController.clear();
    } else {
      _clientIdController.text = preset.clientId;
    }
    // Setel ulang daftar model kustom: model preset baru (bila di luar daftar
    // hardcode) tampil sebagai satu kartu kustom terpilih.
    _seedCustomModels(_modelController.text);
  }

  void _applySelection(CatalogSelection selection) {
    switch (selection) {
      case ApiKeySelection(:final entry):
        _authType = AuthType.apiKey;
        _catalogId = entry.id;
        _baseUrlController.text = entry.baseUrl;
        _modelController.text = _defaultModelFor(entry.id, entry.defaultModel);
        _seedCustomModels(_modelController.text);
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = entry.name;
        }
      case OAuthSelection(:final preset):
        _authType = AuthType.oauth;
        _onPresetChangedInternal(preset);
    }
  }

  OAuthConfig? _oauthConfigFromForm() {
    final authUrl = _preset.isCustom
        ? _authUrlController.text.trim()
        : _preset.authorizationUrl;
    final tokenUrl = _preset.isCustom
        ? _tokenUrlController.text.trim()
        : _preset.tokenUrl;
    final clientId = _clientIdController.text.trim();
    // Import lokal (mis. Cursor) tidak memakai endpoint OAuth.
    if (_preset.flow != OAuthFlow.importToken &&
        (authUrl.isEmpty || tokenUrl.isEmpty)) {
      return null;
    }
    // Client ID hanya wajib untuk Authorization Code; device/import flow tidak.
    if (_preset.flow == OAuthFlow.authorizationCode && clientId.isEmpty) {
      return null;
    }
    return _preset
        .toOAuthConfig(clientIdOverride: clientId)
        .copyWith(authorizationUrl: authUrl, tokenUrl: tokenUrl);
  }

  ApiProvider _providerFromForm() {
    final apiKey = _apiKeyController.text.trim();
    final isOAuth = _authType == AuthType.oauth;
    // Provider dual-auth (Qoder/Zai) menyimpan PAT/API Key sebagai fallback
    // bearer di samping oauthConfig, sehingga token tetap bisa dipakai
    // sebelum OAuth terhubung.
    final allowApiKey = !isOAuth || _supportsBothAuth;
    return ApiProvider(
      id: _editingProviderId ?? 'pending',
      name: _nameController.text.trim(),
      baseUrl: _effectiveBaseUrl,
      model: _modelController.text.trim(),
      apiKey: (allowApiKey && apiKey.isNotEmpty) ? apiKey : null,
      authType: _authType,
      oauthConfig: isOAuth ? _oauthConfigFromForm() : null,
    );
  }

  /// Provider dari form dengan kredensial tersimpan dilengkapi bila form tidak
  /// memuat ulang kredensial (API key / token OAuth). Dipakai untuk Test
  /// Connection dan pemilih model.
  Future<ApiProvider> _providerWithStoredCredentials() async {
    var provider = _providerFromForm();
    final editingId = _editingProviderId;
    if (editingId == null) return provider;

    final stored = await ref
        .read(apiProviderRepositoryProvider)
        .getProviderById(editingId);
    if (stored == null) return provider;

    if (provider.usesOAuth) {
      provider = provider.copyWith(oauthToken: stored.oauthToken);
      // Dual-auth: pertahankan PAT/API Key tersimpan bila field kosong.
      if (provider.apiKey == null && stored.apiKey != null) {
        provider = provider.copyWith(apiKey: stored.apiKey);
      }
    } else if (provider.apiKey == null && stored.apiKey != null) {
      provider = provider.copyWith(apiKey: stored.apiKey);
    }
    return provider;
  }

  /// Validasi tambahan di luar [Form] untuk mode OAuth.
  String? _validateOAuthFields() {
    if (_authType != AuthType.oauth) return null;
    // Device flow & impor token: endpoint & Client ID sudah terisi dari preset,
    // tidak ada field yang perlu divalidasi di sini.
    if (_preset.flow == OAuthFlow.deviceCode ||
        _preset.flow == OAuthFlow.importToken) {
      return null;
    }
    if (_clientIdController.text.trim().isEmpty) {
      return 'Client ID wajib diisi untuk OAuth.';
    }
    if (_preset.isCustom) {
      final authUrl = _authUrlController.text.trim();
      final tokenUrl = _tokenUrlController.text.trim();
      if (authUrl.isEmpty || tokenUrl.isEmpty) {
        return 'Authorization URL dan Token URL wajib diisi.';
      }
      if (Uri.tryParse(authUrl)?.hasScheme != true ||
          Uri.tryParse(tokenUrl)?.hasScheme != true) {
        return 'Authorization URL / Token URL tidak valid.';
      }
    }
    return null;
  }

  /// Validasi model terpilih. Section "Available Models" berada di luar [Form]
  /// (kolom kiri, di bawah form provider) dan pemilihan model dilakukan lewat
  /// kartu — bukan [TextFormField] — sehingga dicek manual di sini. Pengguna
  /// boleh menambah banyak model, tetapi satu harus dipakai.
  String? _validateModelField() {
    if (_isTokenOnly || _isNonChatPreset) return null;
    return _modelController.text.trim().isEmpty
        ? 'Pilih atau tambahkan satu model terlebih dahulu.'
        : null;
  }

  // ---------------------------------------------------------- navigasi ----

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.providers);
    }
  }

  // -------------------------------------------------------------- aksi ----

  /// Simpan provider dan kembalikan id-nya, atau null bila gagal.
  Future<String?> _persistProvider() async {
    final provider = _providerFromForm();
    final id = await ref
        .read(providerConfigProvider.notifier)
        .saveProvider(
          id: _editingProviderId,
          name: provider.name,
          baseUrl: provider.baseUrl,
          model: provider.model,
          apiKey: provider.apiKey,
          authType: provider.authType,
          oauthConfig: provider.oauthConfig,
        );

    if (!mounted) return null;
    final result = ref.read(providerConfigProvider);
    if (result.hasError) {
      _showSnackBar('Gagal menyimpan: ${result.error}', isError: true);
      return null;
    }
    return id;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = _validateOAuthFields() ?? _validateModelField();
    if (error != null) {
      _showSnackBar(error, isError: true);
      return;
    }

    final wasEditing = _editingProviderId != null;
    final id = await _persistProvider();
    if (id == null || !mounted) return;

    _showSnackBar(
      wasEditing
          ? 'Provider berhasil diperbarui.'
          : 'Provider berhasil ditambahkan.',
      isError: false,
    );

    if (!wasEditing) {
      // Beralih ke mode edit agar OAuth/Test Connection bisa langsung dipakai.
      context.replace(AppRoutes.providerDetail(id));
    }
  }

  Future<void> _connectOAuth() async {
    if (_isConnecting) return;
    if (!_formKey.currentState!.validate()) return;
    final error = _validateOAuthFields() ?? _validateModelField();
    if (error != null) {
      _showSnackBar(error, isError: true);
      return;
    }

    setState(() => _isConnecting = true);
    try {
      // Simpan isi form dulu (provider baru maupun yang diedit) agar alur
      // OAuth memakai konfigurasi yang benar-benar tampil: endpoint, Client
      // ID, dan preset yang sama. Juga memicu pembatalan token tersimpan
      // bila identitas OAuth berubah.
      final id = await _persistProvider();
      if (id == null) return;
      if (!mounted) return;
      if (id != _editingProviderId) {
        setState(() => _editingProviderId = id);
      }

      // Device flow: tampilkan dialog (login URL + kode + menunggu) alih-alih
      // alur PKCE loopback.
      final provider = _providerFromForm();
      final config = provider.oauthConfig;
      if (config?.flow == OAuthFlow.importToken) {
        final tokens = await _importLocalToken(config!);
        if (!mounted || tokens == null) return;
        await ref
            .read(providerConfigProvider.notifier)
            .saveOAuthTokens(id, tokens);
        if (!mounted) return;
        _markSessionConnected();
        _showSnackBar('Berhasil mengimpor token.', isError: false);
        return;
      }
      if (config?.flow == OAuthFlow.deviceCode) {
        final tokens = await showDeviceConnectDialog(
          context,
          provider: provider,
        );
        if (!mounted || tokens == null) return;
        await ref
            .read(providerConfigProvider.notifier)
            .saveOAuthTokens(id, tokens);
        if (!mounted) return;
        _markSessionConnected();
        _showSnackBar('Berhasil terhubung via OAuth.', isError: false);
        return;
      }

      await ref.read(providerConfigProvider.notifier).connectOAuth(id);
      if (!mounted) return;
      final result = ref.read(providerConfigProvider);
      if (result.hasError) {
        _showSnackBar('Gagal terhubung: ${result.error}', isError: true);
        return;
      }
      _markSessionConnected();
      _showSnackBar('Berhasil terhubung via OAuth.', isError: false);
    } on OAuthException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  /// Tegaskan bahwa sesi token yang baru tersimpan milik preset form saat
  /// ini — chip "Connected" berlaku untuk preset ini, bukan preset lain.
  void _markSessionConnected() {
    setState(() => _oauthSessionPresetId = _preset.id);
  }

  /// Impor token dari penyimpanan lokal aplikasi lain (mis. Cursor).
  Future<OAuthTokenSet?> _importLocalToken(OAuthConfig config) async {
    try {
      switch (config.importSource) {
        case ImportSource.cursor:
          return await const CursorTokenImporter().import();
        case null:
          throw const ImportTokenException('Sumber impor token tidak dikenal.');
      }
    } on ImportTokenException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
      return null;
    }
  }

  Future<void> _disconnectOAuth(String id) async {    await ref.read(providerConfigProvider.notifier).disconnectOAuth(id);
    if (mounted) _showSnackBar('Koneksi OAuth diputus.', isError: false);
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);
    try {
      var provider = await _providerWithStoredCredentials();
      // Uji lewat endpoint model bila preset punya endpoint khusus
      // (mis. token Copilot divalidasi via /v1/models).
      provider = provider.copyWith(baseUrl: _modelsBaseUrl);
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
    _cancel();
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
        title: Text(editing ? 'Edit Provider' : 'Tambah Provider'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Hapus provider',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Form + panel katalog provider berdampingan (mode tambah maupun edit).
  ///
  /// Kolom kiri berisi form provider dengan daftar "Available Models" tepat di
  /// bawahnya; kolom kanan berisi katalog provider. Mengetuk kartu katalog
  /// langsung mengisi form (tanpa halaman katalog terpisah), dan kartu provider
  /// yang sedang dipakai ditandai lewat [_catalogId]. Setelah disimpan, layar
  /// beralih ke mode edit dengan data yang sudah ditambahkan.
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              void onSelected(CatalogSelection s) =>
                  setState(() => _applySelection(s));
              final panel = ProviderCatalogPanel(
                onSelected: onSelected,
                selectedId: _catalogId,
              );
              // Kolom kiri: form provider + daftar model di bawahnya.
              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildAvailableModels(),
                ],
              );
              if (constraints.maxWidth < 900) {
                // Layar sempit: susun vertikal (form + model, lalu katalog).
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    const SizedBox(height: 24),
                    panel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 480, child: left),
                  const SizedBox(width: 24),
                  Expanded(child: panel),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    // Metode auth ditentukan otomatis dari pilihan kartu katalog
    // (ApiKeySelection vs OAuthSelection) atau dari provider tersimpan.
    // Khusus provider dual-auth (Zai GLM), field API Key ditampilkan
    // di samping section OAuth.
    final showApiKeyField =
        _authType == AuthType.apiKey || _supportsBothAuth;
    final showOAuthFields = _authType == AuthType.oauth;
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
            if (_showBaseUrlField) ...[
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
                  if (_isTokenOnly || _isNonChatPreset) return null;
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
              const SizedBox(height: 12),
            ],
            if (showApiKeyField) ...[
              _buildLabel('API Key'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiKeyController,
                onChanged: (_) => setState(() {}),
                obscureText: true,
                style: const TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: _editingProviderId == null ? 'sk-...' : '••••••••',
                  helperText: _supportsBothAuth
                      ? 'Opsional: dipakai bila OAuth belum terhubung.'
                      : (_editingProviderId == null
                            ? 'Kosongkan untuk layanan lokal tanpa autentikasi.'
                            : 'Kosongkan untuk mempertahankan key tersimpan.'),
                  helperStyle: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ),
              if (showOAuthFields) const SizedBox(height: 20),
            ],
            if (showOAuthFields) _buildOAuthFields(),
            const SizedBox(height: 24),
            _buildFormActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildOAuthFields() {
    final preset = _preset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset OAuth dipilih lewat kartu provider di panel sebelah kanan
        // (tidak ada dropdown terpisah agar tidak duplikat).
        Row(
          children: [
            _buildLabel('OAuth'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                preset.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (preset.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            preset.description,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
        if (preset.isExperimental || preset.isTokenOnly) ...[
          const SizedBox(height: 8),
          _buildWarning(_presetWarning(preset)),
        ],
        if (preset.isCustom) ...[
          const SizedBox(height: 16),
          _buildLabel('Authorization URL'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _authUrlController,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'https://provider.com/oauth/authorize',
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Token URL'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tokenUrlController,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'https://provider.com/oauth/token',
            ),
          ),
        ],
        if (!preset.isTokenOnly) ...[
          const SizedBox(height: 16),
          _buildLabel('Client ID'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _clientIdController,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'client-id.apps.googleusercontent.com',
              helperText:
                  'Client ID dari aplikasi OAuth tipe Desktop Anda.',
              helperStyle: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 11,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildOAuthStatusRow(),
      ],
    );
  }

  /// Pesan peringatan gabungan untuk preset eksperimental dan/atau token-only.
  String _presetWarning(OAuthProviderPreset preset) {
    final parts = <String>[];
    if (preset.isTokenOnly) {
      parts.add(
        'Preset ini hanya untuk login akun; chat belum didukung provider ini.',
      );
    }
    if (preset.isExperimental) {
      parts.add(
        'Koneksi tidak resmi dan bisa berhenti berfungsi sewaktu-waktu.',
      );
    }
    return parts.join(' ');
  }

  Widget _buildOAuthStatusRow() {
    final id = _editingProviderId;
    var status = id == null
        ? OAuthStatus.none
        : ref.watch(providerConfigProvider).value?.statusFor(id) ??
              OAuthStatus.none;
    // Sesi token tersimpan hanya sah pada preset asalnya. Saat form
    // berpindah ke preset katalog lain, kartu "Connected" milik sesi lama
    // ditandai stale — tidak boleh menempel pada provider lain.
    if (id != null &&
        (status == OAuthStatus.connected || status == OAuthStatus.expiring) &&
        _oauthSessionPresetId != _preset.id) {
      status = OAuthStatus.stale;
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isConnecting ? null : _connectOAuth,
            icon: _isConnecting
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentPrimary,
                    ),
                  )
                : const Icon(Icons.login, size: 16),
            label: Text(
              status == OAuthStatus.connected || status == OAuthStatus.expiring
                  ? 'Hubungkan Ulang'
                  : 'Hubungkan via OAuth',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        if (id != null &&
            (status == OAuthStatus.connected ||
                status == OAuthStatus.expiring)) ...[
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _disconnectOAuth(id),
            child: const Text('Putuskan', style: TextStyle(fontSize: 13)),
          ),
        ],
        const SizedBox(width: 12),
        _buildOAuthStatusChip(status),
      ],
    );
  }

  Widget _buildOAuthStatusChip(OAuthStatus status) {
    final color = switch (status) {
      OAuthStatus.connected => AppColors.statusSuccess,
      OAuthStatus.expiring => AppColors.statusWarning,
      OAuthStatus.disconnected => AppColors.statusError,
      OAuthStatus.stale => AppColors.textDisabled,
      OAuthStatus.none => AppColors.textDisabled,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        status.label,
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

  Widget _buildWarning(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.4),
        ),
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 16,
            color: AppColors.statusWarning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section "Available Models": kartu daftar model — model hardcode provider
  /// (ala 9router) bila ada, ditambah model kustom yang ditambahkan pengguna.
  ///
  /// Tombol "Add Model" selalu tersedia (boleh menambah banyak). Hanya satu
  /// model yang dipakai; kartu terpilih ditandai dan id polosnya disimpan ke
  /// [_modelController]. Label kartu memakai format `<alias>/<id>` bila provider
  /// punya alias, selain itu id polos.
  Widget _buildAvailableModels() {
    final set = ProviderModelCatalog.forProvider(_catalogId);
    final current = _modelController.text.trim();
    final hasCatalog = set != null && set.models.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLabel('Daftar Model'),
              if (set != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${set.alias}/…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.monoFamily,
                      fontFamilyFallback: AppFonts.monoFallback,
                      fontSize: 11,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasCatalog
                ? 'Model siap pakai dari provider ini. Klik untuk memilih.'
                : 'Belum ada model. Tambahkan model untuk mulai memakai '
                      'provider ini.',
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (set != null)
            for (final model in set.models) ...[
              ModelCard(
                label: set.label(model),
                name: model.name,
                selected: model.id == current,
                onTap: () => setState(() => _modelController.text = model.id),
              ),
              const SizedBox(height: 8),
            ],
          for (final id in _customModels) ...[
            ModelCard(
              label: _modelLabel(id),
              name: 'Custom model',
              selected: id == current,
              onTap: () => setState(() => _modelController.text = id),
            ),
            const SizedBox(height: 8),
          ],
          _buildAddModelCard(),
          if (_addingModel) ...[
            const SizedBox(height: 12),
            _buildNewModelField(),
          ],
        ],
      ),
    );
  }

  /// Kartu "Add Model": menampilkan field untuk mengetik id model baru.
  Widget _buildAddModelCard() {
    return InkWell(
      onTap: () => setState(() => _addingModel = true),
      borderRadius: AppRadius.lg,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, size: 18, color: AppColors.accentPrimary),
            SizedBox(width: 8),
            Text(
              'Tambah Model',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Field untuk mengetik id model baru (muncul dari tombol "Add Model").
  Widget _buildNewModelField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newModelController,
            autofocus: true,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'mis. gpt-4o',
              isDense: true,
            ),
            onSubmitted: (_) => _addCustomModel(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addCustomModel,
          child: const Text('Tambah', style: TextStyle(fontSize: 12.5)),
        ),
        IconButton(
          tooltip: 'Batal',
          icon: const Icon(Icons.close, size: 16),
          color: AppColors.textDisabled,
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() {
            _newModelController.clear();
            _addingModel = false;
          }),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
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
                    'Uji Koneksi',
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
                  : 'Perbarui Provider',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Menampilkan URL endpoint final yang akan dipanggil. Membantu pengguna
  /// menyadari Base URL yang salah sebelum menekan Test/Save.
  Widget _buildResolvedEndpointPreview() {
    final base = _effectiveBaseUrl;
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
}
