import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/routes.dart';
import '../../../app/config/app_palette.dart';
import '../../../app/config/theme.dart';
import '../../../app/l10n/error_messages.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/app_constants.dart';
import '../data/catalog/provider_catalog.dart';
import '../data/catalog/provider_models.dart';
import '../data/datasources/ai_api_service.dart';
import '../data/datasources/cline_oauth_loopback.dart';
import '../data/datasources/cline_oauth_service.dart';
import '../domain/catalog/provider_catalog_entry.dart';
import '../domain/entities/api_provider.dart';
import '../domain/entities/oauth_session.dart';
import 'providers/provider_config_provider.dart';
import 'widgets/oauth_login_card.dart';
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

  /// Sesi akun Cline untuk provider ini (null = belum masuk).
  OAuthSession? _oauthSession;

  /// True selama hubungkan/keluar akun Cline berjalan.
  bool _isConnecting = false;

  /// Server callback yang sedang menunggu browser, dan penanda batal.
  ClineLoopbackServer? _loopback;
  bool _cancelRequested = false;

  bool get _hasProvider => _catalogId != null;

  /// Provider yang masuk dengan akun, bukan API key.
  bool get _isCline => _catalogId == kClineOAuthCatalogId;

  /// Pengguna memilih "Custom API Key" → semua field bisa diisi sendiri.
  bool get _isCustom => _catalogId == kCustomCatalogId;

  /// Entri katalog untuk provider yang sedang dipilih; null saat belum
  /// dipilih atau saat memakai Custom (tidak punya situs bawaan).
  ProviderCatalogEntry? get _catalogEntry {
    final id = _catalogId;
    if (id == null || id == kCustomCatalogId) return null;
    return ProviderCatalog.byId(id);
  }

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
    _oauthSession = provider.oauthSession;
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
      authType: _isCline ? AuthType.oauth : AuthType.apiKey,
      oauthProvider: _isCline ? kClineOAuthCatalogId : null,
      oauthSession: _oauthSession,
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
    // Sesi akun terikat ke provider tempat ia dibuat: pindah provider berarti
    // kredensialnya berbeda juga, jadi sesi lama tidak boleh terbawa.
    _oauthSession = null;
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
    final l10n = context.l10n;
    if (!_hasProvider) {
      _showSnackBar(l10n.providerDetailPickProvider, isError: true);
      return false;
    }
    if (!_formKey.currentState!.validate()) return false;
    if (_model.trim().isEmpty) {
      _showSnackBar(l10n.providerDetailPickModel, isError: true);
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
          authType: provider.authType,
          oauthProvider: provider.oauthProvider,
          oauthSession: provider.oauthSession,
          customModels: _customModels,
          removedModels: _removedModels,
        );

    if (!mounted) return null;
    final result = ref.read(providerConfigProvider);
    if (result.hasError) {
      _showSnackBar(
        context.l10n.providerDetailSaveFailed(_errorText(result.error)),
        isError: true,
      );
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
          context.l10n.providerDetailClearKeyFailed(_errorText(cleared.error)),
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

    final l10n = context.l10n;
    _showSnackBar(
      wasEditing ? l10n.providerDetailUpdated : l10n.providerDetailAdded,
      isError: false,
    );

    // Kembali ke daftar provider; entri baru sudah langsung aktif. Memakai pop
    // agar tumpukan navigasi tetap utuh (tombol kembali di daftar tetap ada).
    _backToList();
  }

  Future<void> _testConnection() async {
    if (!_validateSelection()) return;
    if (_isCline) {
      await _testAccount();
      return;
    }

    setState(() => _isTesting = true);
    try {
      final provider = await _providerWithStoredCredentials();
      await ref.read(providerConfigProvider.notifier).testConnection(provider);
      if (mounted) {
        _showSnackBar(context.l10n.providerDetailTestOk, isError: false);
      }
    } on ApiConnectionException catch (e) {
      if (!mounted) return;
      _showSnackBar(localizedAppError(context.l10n, e), isError: true);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  /// Test untuk provider akun: `GET /users/me` lewat saldo akun, karena
  /// `/models` Cline publik dan tidak membuktikan sesinya berlaku.
  Future<void> _testAccount() async {
    final session = _oauthSession;
    if (session == null) {
      _showSnackBar(context.l10n.oauthLoginRequired, isError: true);
      return;
    }

    setState(() => _isTesting = true);
    try {
      await ref.read(clineOAuthServiceProvider).fetchBalance(session);
      if (mounted) {
        _showSnackBar(context.l10n.providerDetailTestOk, isError: false);
      }
    } on AppErrorDetails catch (e) {
      if (!mounted) return;
      _showSnackBar(localizedAppError(context.l10n, e), isError: true);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  /// Validasi sebelum masuk akun.
  ///
  /// Nama baru dipakai saat Simpan, jadi tidak diminta di sini; diisi nama
  /// provider supaya hasil connect langsung bisa disimpan.
  bool _prepareConnect() {
    if (_model.trim().isEmpty) {
      _showSnackBar(context.l10n.providerDetailPickModel, isError: true);
      return false;
    }
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = _providerLabel;
    }
    _cancelRequested = false;
    return true;
  }

  /// Masuk dengan akun Cline dalam satu klik.
  ///
  /// Browser dibuka langsung ke halaman login Cline dengan `callback_url`
  /// menunjuk server loopback sementara. Kalau Cline menghormati alamat itu,
  /// kode sesi diterima tanpa copy-paste. Bila browser tetap diarahkan ke
  /// `vscode://`, dialog tempel tautan muncul sebagai jalan lain.
  Future<void> _connectCline() async {
    if (!_prepareConnect()) return;
    setState(() => _isConnecting = true);

    final notifier = ref.read(providerConfigProvider.notifier);
    ClineLoopbackServer? server;
    try {
      server = await ref.read(clineLoopbackProvider)();
      if (!mounted) return;

      final String? link;
      if (server == null) {
        // Tanpa loopback (mis. di test): langsung tempel tautan.
        link = await showClinePasteLinkDialog(context);
      } else {
        _loopback = server;
        final opened = await _openClineLogin(server.callbackUrl);
        if (!mounted) return;

        final code = opened ? await server.waitForCode() : null;
        if (!mounted || _cancelRequested) return;
        link = code ?? await showClinePasteLinkDialog(context);
      }
      if (link == null || !mounted) return;

      await _finishConnect(
        () => notifier.connectCline(
          id: _editingProviderId,
          name: _nameController.text.trim(),
          providerName: _providerNameController.text.trim(),
          catalogId: _catalogId!,
          baseUrl: _baseUrlController.text.trim(),
          model: _model.trim(),
          link: link!,
          customModels: _customModels,
          removedModels: _removedModels,
        ),
      );
    } finally {
      _loopback = null;
      await server?.close();
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<bool> _openClineLogin(String callbackUrl) async {
    final uri = Uri.parse(
      ClineOAuthService.authorizeUrl(callbackUrl: callbackUrl),
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Browser tidak tersedia: pengguna masih bisa menempel tautan.
      return false;
    }
  }

  /// Hentikan penantian browser tanpa menutup kartu.
  void _cancelConnect() {
    _cancelRequested = true;
    _loopback?.close();
  }

  /// Tunggu [connect] selesai, lalu tampilkan akunnya di kartu.
  Future<void> _finishConnect(
    Future<({String id, OAuthSession session})> Function() connect,
  ) async {
    try {
      final connected = await connect();
      if (!mounted) return;

      final result = ref.read(providerConfigProvider);
      if (result.hasError) {
        _showSnackBar(
          context.l10n.providerDetailSaveFailed(_errorText(result.error)),
          isError: true,
        );
        return;
      }
      // Provider baru kini punya id: halaman beralih ke mode edit supaya
      // Keluar/Hapus bisa dipakai tanpa menyimpan ulang.
      setState(() {
        _editingProviderId = connected.id;
        _oauthSession = connected.session;
      });
    } on ApiConnectionException catch (e) {
      // Batal oleh pengguna bukan kegagalan yang perlu diberitahukan.
      if (!mounted || e.code == AppErrorCode.cancelled) return;
      // Tautan Cline kedaluwarsa dan tautan salah sama-sama berarti "salin
      // ulang"; provider lain memakai pesan umum.
      _showSnackBar(
        _isCline && e.code == AppErrorCode.apiUnauthorized
            ? context.l10n.clineLinkInvalid
            : localizedAppError(context.l10n, e),
        isError: true,
      );
    }
  }

  /// Keluar dari akun: sesi dihapus, provider tetap tersimpan.
  Future<void> _disconnectAccount() async {
    final id = _editingProviderId;
    if (id == null) return;

    setState(() => _isConnecting = true);
    try {
      await ref.read(providerConfigProvider.notifier).disconnectAccount(id);
      if (!mounted) return;

      final result = ref.read(providerConfigProvider);
      if (result.hasError) {
        _showSnackBar(
          context.l10n.providerDetailSaveFailed(_errorText(result.error)),
          isError: true,
        );
        return;
      }
      setState(() => _oauthSession = null);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
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
    _showSnackBar(context.l10n.providerDeleted, isError: false);
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

  /// Teks error dari state async: error berkode diterjemahkan, sisanya apa
  /// adanya (mis. pesan validasi formulir).
  String _errorText(Object? error) => error is AppErrorDetails
      ? localizedAppError(context.l10n, error)
      : '$error';

  void _showSnackBar(String message, {required bool isError}) {
    showAppToast(
      context,
      message,
      kind: isError ? AppToastKind.error : AppToastKind.success,
    );
  }

  // -------------------------------------------------------------- build ----

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = _editingProviderId != null;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? l10n.providerDetailTitleEdit : l10n.providerDetailTitleNew,
        ),
        actions: [
          if (editing)
            IconButton(
              tooltip: l10n.providerDetailDeleteTooltip,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: _confirmDelete,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 32,
          vertical: compact ? 20 : 32,
        ),
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
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border.all(color: context.palette.borderSubtle),
        borderRadius: AppRadius.panel,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(l10n.providerDetailFieldName),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('field-nama'),
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l10n.providerDetailNameHint,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.providerDetailNameRequired
                  : null,
            ),
            const SizedBox(height: 20),
            PickerField(
              key: const ValueKey('picker-provider'),
              label: l10n.commonProvider,
              value: _providerLabel,
              hint: l10n.providerDetailPickProviderLabel,
              onTap: _pickProvider,
            ),
            // Pintasan ke situs provider: halaman API key bila ada, kalau
            // tidak situs utamanya. Muncul begitu provider dipilih.
            if (_catalogEntry case final entry?) ...[
              const SizedBox(height: 8),
              _buildProviderSiteLink(entry),
            ],
            // Custom: pengguna mengetik nama providernya sendiri.
            if (_isCustom) ...[
              const SizedBox(height: 20),
              FieldLabel(l10n.providerDetailFieldProviderName),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('field-providerName'),
                controller: _providerNameController,
                decoration: InputDecoration(
                  hintText: l10n.providerDetailProviderNameHint,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.providerDetailProviderNameRequired
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            FieldLabel(
              l10n.commonBaseUrl,
              trailing: _baseUrlLocked ? _lockBadge() : null,
            ),
            const SizedBox(height: 8),
            _buildBaseUrlField(),
            const SizedBox(height: 20),
            // Provider akun tidak punya field API Key: kredensialnya sesi
            // login akun.
            if (_isCline)
              OAuthLoginCard(
                title: l10n.clineLoginTitle,
                body: l10n.clineLoginBody,
                session: _oauthSession,
                busy: _isConnecting,
                fallbackAccount: _providerLabel,
                onConnect: _connectCline,
                onCancel: _cancelConnect,
                onDisconnect: _disconnectAccount,
                loadBalance: ref.read(clineOAuthServiceProvider).fetchBalance,
              )
            else ...[
              FieldLabel(l10n.commonApiKey),
              const SizedBox(height: 8),
              _buildApiKeyField(),
            ],
            const SizedBox(height: 20),
            PickerField(
              key: const ValueKey('picker-model'),
              label: l10n.commonModel,
              value: _model,
              hint: _hasProvider
                  ? l10n.providerDetailPickModelLabel
                  : l10n.providerDetailPickProviderFirst,
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
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.palette.primary,
                        ),
                      )
                    : Text(
                        _isCline
                            ? l10n.providerDetailTestAccount
                            : l10n.providerDetailTestAction,
                      ),
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
          // Latar field tidak dibedakan saat nonaktif; hanya warna teksnya.
          style: TextStyle(
            fontFamily: AppFonts.monoFamily,
            fontFamilyFallback: AppFonts.monoFallback,
            fontSize: 13,
            color: _isCustom
                ? context.palette.textPrimary
                : context.palette.textDisabled,
          ),
          decoration: const InputDecoration(
            hintText: 'https://api.openai.com/v1',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return context.l10n.providerDetailBaseUrlRequired;
            final uri = Uri.tryParse(text);
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return context.l10n.providerDetailBaseUrlInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: 6),
        _buildResolvedEndpointPreview(),
      ],
    );
  }

  /// Tautan ke situs provider supaya API key bisa dibuat tanpa mencari
  /// halaman key sendiri. Halaman API key diutamakan; provider tanpa halaman
  /// key (mis. Ollama, Cline) memakai situs utamanya.
  Widget _buildProviderSiteLink(ProviderCatalogEntry entry) {
    final raw = entry.apiKeyUrl ?? entry.website;
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return const SizedBox.shrink();

    // Tanpa skema: domain + path sudah cukup jelas dan jauh lebih ringkas.
    final label = uri.path.isEmpty || uri.path == '/'
        ? uri.host
        : '${uri.host}${uri.path}';
    final palette = context.palette;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: () => _openExternal(uri),
        borderRadius: AppRadius.sm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry.apiKeyUrl == null ? Icons.public : Icons.key_outlined,
                size: 13,
                color: palette.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.uiFamily,
                    fontFamilyFallback: AppFonts.uiFallback,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 11, color: palette.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Buka tautan di browser luar. Gagal membuka dilaporkan sebagai toast
  /// singkat, bukan dibiarkan diam.
  Future<void> _openExternal(Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _showSnackBar(context.l10n.commonGenericError, isError: true);
    }
  }

  Widget _lockBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 12, color: context.palette.textDisabled),
        const SizedBox(width: 4),
        Text(
          context.l10n.providerDetailApiKeyFromProvider,
          style: TextStyle(color: context.palette.textDisabled, fontSize: 11),
        ),
      ],
    );
  }

  /// Keterangan di bawah field API Key, mengikuti keadaan field.
  String get _apiKeyHelper {
    final l10n = context.l10n;
    if (_apiKeyLocked) return l10n.providerDetailApiKeyStored;
    if (_apiKeyCleared && _apiKeyController.text.trim().isEmpty) {
      return l10n.providerDetailApiKeyCleared;
    }
    return l10n.providerDetailApiKeyOptional;
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
                  // Latar field tetap sama saat terkunci; hanya teksnya redup.
                  style: TextStyle(
                    fontFamily: AppFonts.monoFamily,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: 13,
                    color: _apiKeyLocked
                        ? context.palette.textDisabled
                        : context.palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: _apiKeyLocked ? '••••••••' : 'sk-...',
                  ),
                ),
              ),
              if (_canResetApiKey) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const ValueKey('button-reset-apiKey'),
                  onPressed: _resetApiKey,
                  child: Text(context.l10n.providerDetailReset),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _apiKeyHelper,
          style: TextStyle(color: context.palette.textDisabled, fontSize: 11),
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
          child: Text(context.l10n.commonCancel),
        ),
        const SizedBox(width: 12),
        FilledButton(
          key: const ValueKey('button-save'),
          onPressed: _save,
          child: Text(context.l10n.commonSave),
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
        Icon(
          Icons.arrow_forward,
          size: 12,
          color: context.palette.textDisabled,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            endpoint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 10,
              height: 1.4,
              color: context.palette.textDisabled,
            ),
          ),
        ),
      ],
    );
  }
}
