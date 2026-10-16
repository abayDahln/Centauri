import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/theme.dart';
import '../../../core/utils/app_constants.dart';
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
  final _clientIdController = TextEditingController();
  final _authUrlController = TextEditingController();
  final _tokenUrlController = TextEditingController();

  String? _editingProviderId;
  bool _isTesting = false;
  bool _isConnecting = false;

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
    _clientIdController.text = config?.clientId ?? '';
    _authUrlController.text = _preset.isCustom
        ? (config?.authorizationUrl ?? '')
        : '';
    _tokenUrlController.text = _preset.isCustom ? (config?.tokenUrl ?? '') : '';
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

  /// Preset yang mendukung dua metode auth sekaligus (OAuth + API Key/PAT).
  /// Dipakai untuk provider yang menyediakan keduanya, mis. Qoder (OAuth +
  /// PAT) dan Zai GLM (OAuth + API Key). Untuk preset ini form menampilkan
  /// field API Key di samping section OAuth tanpa tab bar.
  static const _dualAuthPresetIds = {'qoder', 'zai-glm'};

  /// True bila form menampilkan field API Key sekaligus section OAuth.
  bool get _supportsBothAuth =>
      _authType == AuthType.oauth && _dualAuthPresetIds.contains(_preset.id);

  /// True bila pengguna mengisi API Key/PAT pada provider dual-auth.
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

  void _onPresetChangedInternal(OAuthProviderPreset preset) {
    _preset = preset;
    if (preset.id == 'zai-glm') {
      // Dual-auth: siapkan default endpoint API key Z.ai agar jalur API key
      // langsung bisa dipakai chat; pengguna tetap bisa mengubahnya.
      if (_baseUrlController.text.trim().isEmpty) {
        _baseUrlController.text = 'https://api.z.ai/api/paas/v4';
      }
      if (_modelController.text.trim().isEmpty) {
        _modelController.text = 'glm-4.6';
      }
    } else if (preset.isTokenOnly) {
      _baseUrlController.clear();
      _modelController.clear();
    } else {
      if (preset.baseUrl.isNotEmpty) _baseUrlController.text = preset.baseUrl;
      final defaultModel = preset.defaultModel;
      if (defaultModel != null && defaultModel.isNotEmpty) {
        _modelController.text = defaultModel;
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
  }

  void _onPresetChanged(OAuthProviderPreset? preset) {
    if (preset == null) return;
    setState(() => _onPresetChangedInternal(preset));
  }

  void _applySelection(CatalogSelection selection) {
    switch (selection) {
      case ApiKeySelection(:final entry):
        _authType = AuthType.apiKey;
        _baseUrlController.text = entry.baseUrl;
        _modelController.text = entry.defaultModel;
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

  // ---------------------------------------------------------- navigasi ----

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.providers);
    }
  }

  /// Buka layar pemilih model; hasilnya mengisi field Model Name.
  Future<void> _openModelPicker() async {
    if (_effectiveBaseUrl.isEmpty) {
      _showSnackBar('Isi Base URL terlebih dahulu.', isError: true);
      return;
    }
    final provider = await _providerWithStoredCredentials();
    if (!mounted) return;

    final model = await context.push<String>(
      AppRoutes.providersModels,
      extra: ModelPickerArgs(provider: provider),
    );
    if (model == null || !mounted) return;
    setState(() => _modelController.text = model);
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
    final oauthError = _validateOAuthFields();
    if (oauthError != null) {
      _showSnackBar(oauthError, isError: true);
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
    final oauthError = _validateOAuthFields();
    if (oauthError != null) {
      _showSnackBar(oauthError, isError: true);
      return;
    }

    setState(() => _isConnecting = true);
    try {
      var id = _editingProviderId;
      if (id == null) {
        id = await _persistProvider();
        if (id == null) return;
        if (!mounted) return;
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
      _showSnackBar('Berhasil terhubung via OAuth.', isError: false);
    } on OAuthException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
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
      final provider = await _providerWithStoredCredentials();
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
      body: editing ? _buildDetailBody() : _buildAddBody(),
    );
  }

  /// Mode tambah: form manual + panel katalog inline berdampingan.
  ///
  /// Mengetuk kartu katalog langsung mengisi form (tanpa halaman katalog
  /// terpisah). Setelah disimpan, layar beralih ke mode detail/edit dengan
  /// data yang sudah ditambahkan.
  Widget _buildAddBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              void onSelected(CatalogSelection s) =>
                  setState(() => _applySelection(s));
              if (constraints.maxWidth < 900) {
                // Layar sempit: susun vertikal (form lalu katalog).
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildForm(),
                    const SizedBox(height: 24),
                    ProviderCatalogPanel(onSelected: onSelected),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 480, child: _buildForm()),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ProviderCatalogPanel(onSelected: onSelected),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Mode detail/edit: form terisi data tersimpan, tanpa panel katalog.
  Widget _buildDetailBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    // Metode auth ditentukan otomatis dari pilihan kartu katalog
    // (ApiKeySelection vs OAuthSelection) atau dari provider tersimpan.
    // Khusus provider dual-auth (Qoder, Zai GLM), field API Key/PAT
    // ditampilkan di samping section OAuth.
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
              _buildLabel(
                _supportsBothAuth ? 'API Key / PAT' : 'API Key',
              ),
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
                      ? 'Opsional: PAT/API Key sebagai fallback bila OAuth belum terhubung.'
                      : (_editingProviderId == null
                            ? 'Kosongkan jika menggunakan endpoint lokal tanpa autentikasi.'
                            : 'Kosongkan untuk mempertahankan key yang tersimpan.'),
                  helperStyle: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ),
              if (showOAuthFields) const SizedBox(height: 20),
            ],
            if (showOAuthFields) _buildOAuthFields(),
            const SizedBox(height: 20),
            _buildModelField(),
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
        _buildLabel('OAuth Provider'),
        const SizedBox(height: 8),
        DropdownButtonFormField<OAuthProviderPreset>(
          // FormField tidak menyinkronkan initialValue saat berubah, jadi beri
          // key agar dropdown dibangun ulang ketika preset di-set programatik
          // (mis. saat mengedit provider OAuth yang tersimpan).
          key: ValueKey('oauth-preset-${preset.id}'),
          initialValue: preset,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: OAuthProviderPresets.all
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.isExperimental ? '${p.label} (eksperimental)' : p.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: _onPresetChanged,
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
                  'Client ID dari aplikasi OAuth Anda (tipe Desktop/native). '
                  'Client ID bersifat publik dan aman disimpan lokal.',
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
        'Preset ini hanya untuk menghubungkan akun (menyimpan token); chat '
        'belum didukung untuk provider ini.',
      );
    }
    if (preset.isExperimental) {
      parts.add(
        'Memakai endpoint tidak resmi (reverse-engineered) yang bisa berhenti '
        'berfungsi sewaktu-waktu. Pastikan Anda mematuhi ketentuan layanan '
        'provider.',
      );
    }
    return parts.join(' ');
  }

  Widget _buildOAuthStatusRow() {
    final id = _editingProviderId;
    final status = id == null
        ? OAuthStatus.none
        : ref.watch(providerConfigProvider).value?.statusFor(id) ??
              OAuthStatus.none;

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
                  : 'Connect with OAuth',
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
            child: const Text('Disconnect', style: TextStyle(fontSize: 13)),
          ),
        ],
        const SizedBox(width: 12),
        _buildOAuthStatusChip(status),
      ],
    );
  }

  Widget _buildOAuthStatusChip(OAuthStatus status) {
    final (label, color) = switch (status) {
      OAuthStatus.connected => ('Connected', AppColors.statusSuccess),
      OAuthStatus.expiring => ('Expiring soon', AppColors.statusWarning),
      OAuthStatus.disconnected => ('Disconnected', AppColors.statusError),
      OAuthStatus.none => ('Belum tersimpan', AppColors.textDisabled),
    };
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

  /// Field Model Name + tombol pembuka layar pemilih model.
  Widget _buildModelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('Model Name'),
            const Spacer(),
            TextButton.icon(
              onPressed: _openModelPicker,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text(
                'Pilih dari Daftar',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _modelController,
          style: const TextStyle(
            fontFamily: AppFonts.monoFamily,
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: 13,
          ),
          decoration: const InputDecoration(hintText: 'gpt-4o'),
          validator: (value) {
            if (_isTokenOnly || _isNonChatPreset) return null;
            return (value == null || value.trim().isEmpty)
                ? 'Nama model wajib diisi.'
                : null;
          },
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
