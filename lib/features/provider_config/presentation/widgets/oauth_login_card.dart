import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../domain/entities/oauth_session.dart';
import 'picker_field.dart';

/// Kartu masuk akun untuk provider yang memakai OAuth (Cline).
///
/// Teks judul/isi disediakan pemanggil karena tiap provider punya cara login
/// sendiri; sisanya (keadaan belum masuk, akun tersambung, saldo, tombol
/// Keluar) sama untuk semua provider akun.
class OAuthLoginCard extends StatefulWidget {
  const OAuthLoginCard({
    super.key,
    required this.title,
    required this.body,
    required this.session,
    required this.onConnect,
    required this.onDisconnect,
    required this.fallbackAccount,
    this.onCancel,
    this.loadBalance,
    this.busy = false,
  });

  final String title;
  final String body;

  /// Sesi aktif; null berarti belum masuk.
  final OAuthSession? session;

  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  /// Membatalkan proses hubungkan yang sedang berjalan.
  final VoidCallback? onCancel;

  /// Nama yang ditampilkan bila sesi tidak membawa nama/email.
  final String fallbackAccount;

  /// Pemuat saldo. Null untuk provider yang tidak menyediakan saldo.
  final Future<double> Function(OAuthSession session)? loadBalance;

  /// True selama proses hubungkan berjalan (tombol dinonaktifkan).
  final bool busy;

  @override
  State<OAuthLoginCard> createState() => _OAuthLoginCardState();
}

class _OAuthLoginCardState extends State<OAuthLoginCard> {
  double? _balance;
  bool _loadingBalance = false;

  @override
  void initState() {
    super.initState();
    // Flag diset langsung: initState berjalan di tengah build, jadi setState
    // di sini tidak perlu dan hanya menambah rebuild.
    _loadingBalance = _canLoadBalance;
    _loadBalance();
  }

  @override
  void didUpdateWidget(OAuthLoginCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sesi berganti (masuk ulang / keluar) → saldo harus dimuat ulang.
    if (oldWidget.session?.accessToken != widget.session?.accessToken) {
      _balance = null;
      _loadingBalance = _canLoadBalance;
      _loadBalance();
    }
  }

  bool get _canLoadBalance =>
      widget.loadBalance != null && widget.session != null;

  /// Saldo hanya informasi tambahan: gagal memuatnya tidak boleh menampilkan
  /// error di kartu, cukup disembunyikan.
  Future<void> _loadBalance() async {
    final load = widget.loadBalance;
    final session = widget.session;
    if (load == null || session == null) return;

    try {
      final balance = await load(session);
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _loadingBalance = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _balance = null;
        _loadingBalance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = widget.session;

    return Container(
      key: const ValueKey('oauth-login-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.bgSunken,
        border: Border.all(color: context.palette.borderSubtle),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session == null
                    ? Icons.person_outline
                    : Icons.verified_user_outlined,
                size: 16,
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (session == null)
            _buildSignedOut(l10n)
          else
            _buildSignedIn(context, l10n, session),
        ],
      ),
    );
  }

  Widget _buildSignedOut(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.body,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              key: const ValueKey('button-oauth-connect'),
              onPressed: widget.busy ? null : widget.onConnect,
              child: widget.busy
                  ? _busyLabel(l10n, context.palette.onPrimary)
                  : Text(l10n.oauthConnect),
            ),
            if (widget.busy && widget.onCancel != null) ...[
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('button-oauth-cancel-connect'),
                onPressed: widget.onCancel,
                child: Text(l10n.commonCancel),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSignedIn(
    BuildContext context,
    AppLocalizations l10n,
    OAuthSession session,
  ) {
    final name = session.displayName?.trim();
    final email = session.email?.trim();
    final account = name != null && name.isNotEmpty
        ? name
        : (email != null && email.isNotEmpty
              ? email.split('@').first
              : widget.fallbackAccount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.oauthConnectedAs(account),
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _maskEmail(email),
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (widget.loadBalance != null) ...[
          const SizedBox(height: 8),
          // Memuat saldo cukup ditandai spinner: tidak ada teks yang jujur
          // untuk keadaan sesingkat ini.
          if (_loadingBalance)
            SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.palette.textSecondary,
              ),
            )
          else if (_balance != null)
            Text(
              l10n.oauthBalance(_formatBalance(context, _balance!)),
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('button-oauth-disconnect'),
          onPressed: widget.busy ? null : widget.onDisconnect,
          child: Text(l10n.oauthDisconnect),
        ),
      ],
    );
  }

  Widget _busyLabel(AppLocalizations l10n, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: 8),
        Text(l10n.oauthConnecting),
      ],
    );
  }

  /// Email disamarkan: cukup awalannya untuk memastikan akun yang benar.
  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return email;
    return '${email.substring(0, 1)}***${email.substring(at)}';
  }

  /// Saldo mengikuti bahasa UI (pemisah desimal lokal), mata uang tetap USD.
  String _formatBalance(BuildContext context, double value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return NumberFormat.currency(
      locale: locale,
      symbol: r'$',
      decimalDigits: 2,
    ).format(value);
  }
}

/// Dialog tempel tautan login Cline.
///
/// Dipakai hanya saat browser tidak kembali ke aplikasi (Cline mengarahkan ke
/// `vscode://`). Mengembalikan tautan yang ditempel, atau null bila dibatalkan.
Future<String?> showClinePasteLinkDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ClinePasteLinkDialog(),
  );
}

class _ClinePasteLinkDialog extends StatefulWidget {
  const _ClinePasteLinkDialog();

  @override
  State<_ClinePasteLinkDialog> createState() => _ClinePasteLinkDialogState();
}

class _ClinePasteLinkDialogState extends State<_ClinePasteLinkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final link = _controller.text.trim();
    if (link.isEmpty) return;
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.clineLoginTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clinePasteBody,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(l10n.clineFieldLink),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('field-cline-link'),
              controller: _controller,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(hintText: l10n.clineFieldLinkHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('button-cline-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('button-cline-submit'),
          onPressed: _submit,
          child: Text(l10n.oauthConnect),
        ),
      ],
    );
  }
}
