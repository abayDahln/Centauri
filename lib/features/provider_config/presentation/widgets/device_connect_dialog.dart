import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/theme.dart';
import '../../data/services/browser_launcher.dart';
import '../../domain/entities/api_provider.dart';
import '../../domain/entities/device_authorization.dart';
import '../../domain/entities/oauth_token_set.dart';
import '../../domain/services/oauth_service.dart';
import '../providers/provider_config_provider.dart';

/// Menampilkan dialog koneksi device flow (login URL + kode + menunggu
/// otorisasi).
///
/// Mengembalikan token set bila berhasil, atau `null` bila dibatalkan/gagal.
Future<OAuthTokenSet?> showDeviceConnectDialog(
  BuildContext context, {
  required ApiProvider provider,
  BrowserLauncher launcher = const BrowserLauncher(),
}) {
  return showDialog<OAuthTokenSet>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _DeviceConnectDialog(provider: provider, launcher: launcher),
  );
}

class _DeviceConnectDialog extends ConsumerStatefulWidget {
  const _DeviceConnectDialog({required this.provider, required this.launcher});

  final ApiProvider provider;
  final BrowserLauncher launcher;

  @override
  ConsumerState<_DeviceConnectDialog> createState() =>
      _DeviceConnectDialogState();
}

class _DeviceConnectDialogState extends ConsumerState<_DeviceConnectDialog> {
  final Completer<void> _cancel = Completer<void>();
  DeviceAuthorization? _auth;
  String? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    if (!_cancel.isCompleted) _cancel.complete();
    super.dispose();
  }

  Future<void> _begin() async {
    final service = ref.read(oauthServiceProvider);
    try {
      final auth = await service.startDeviceFlow(widget.provider);
      if (!mounted) return;
      setState(() => _auth = auth);
      await _openInBrowser();
      final tokens = await service.pollDeviceFlow(
        widget.provider,
        auth,
        cancel: _cancel.future,
      );
      if (!mounted) return;
      Navigator.of(context).pop(tokens);
    } on OAuthException catch (e) {
      if (!mounted || _cancel.isCompleted) return; // dibatalkan: tanpa error.
      setState(() => _error = e.message);
    }
  }

  Future<void> _openInBrowser() async {
    final auth = _auth;
    if (auth == null || _opening) return;
    setState(() => _opening = true);
    await widget.launcher.open(auth.openUri);
    if (mounted) setState(() => _opening = false);
  }

  void _close() {
    if (!_cancel.isCompleted) _cancel.complete();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    return Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect ${widget.provider.name}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Buka URL login di bawah, lalu setujui akses di browser.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              if (widget.provider.oauthConfig?.isExperimental ?? false) ...[
                const SizedBox(height: 12),
                _buildWarning(
                  'Flow ini memakai endpoint tidak resmi (reverse-engineered) '
                  'dan bisa berhenti berfungsi sewaktu-waktu.',
                ),
              ],
              const SizedBox(height: 16),
              ..._buildBody(auth),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _close,
                  child: Text(
                    _error != null ? 'Tutup' : 'Batal',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(DeviceAuthorization? auth) {
    if (_error != null) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusError.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.statusError.withValues(alpha: 0.4),
            ),
            borderRadius: AppRadius.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.statusError,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (auth == null) {
      return [_waitingRow('Menyiapkan device flow…')];
    }

    return [
      _ValueBox(
        label: 'Login URL',
        value: auth.verificationUri.toString(),
        onOpen: _opening ? null : _openInBrowser,
      ),
      // Sebagian provider tidak menampilkan kode (mis. CodeBuddy, Zai GLM).
      if (auth.userCode.isNotEmpty) ...[
        const SizedBox(height: 12),
        _ValueBox(label: 'Your Code', value: auth.userCode, emphasize: true),
      ],
      const SizedBox(height: 16),
      _waitingRow('Waiting for authorization…'),
    ];
  }

  Widget _waitingRow(String text) {
    return Row(
      children: [
        const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: AppText.uiSmall),
      ],
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
}

/// Kotak nilai monospace dengan tombol Salin (dan opsional Buka).
class _ValueBox extends StatelessWidget {
  const _ValueBox({
    required this.label,
    required this.value,
    this.onOpen,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final VoidCallback? onOpen;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSunken,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  maxLines: emphasize ? 1 : 3,
                  style: TextStyle(
                    fontFamily: AppFonts.monoFamily,
                    fontFamilyFallback: AppFonts.monoFallback,
                    fontSize: emphasize ? 18 : 12,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: emphasize ? 2 : 0,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 16),
                tooltip: 'Salin',
                onPressed: () => _copy(context),
              ),
              if (onOpen != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  tooltip: 'Buka di browser',
                  onPressed: onOpen,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Disalin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
