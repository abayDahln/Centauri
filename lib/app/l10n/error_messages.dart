import 'package:flutter/widgets.dart';

import '../../core/errors/app_error.dart';
import '../../l10n/generated/app_localizations.dart';

/// Terjemahan [AppErrorDetails] untuk ditampilkan ke pengguna.
///
/// Dipakai di widget (`localizedAppError(context.l10n, e)`) maupun di lapisan
/// state (`localizedAppError(l10nOf(ref), e)`), sehingga pesan error dari data
/// layer selalu mengikuti bahasa UI yang aktif.
String localizedAppError(AppLocalizations l10n, AppErrorDetails error) {
  final detail = error.detail?.trim();
  final name = error.name?.trim();
  final version = error.version?.trim();
  final formats = error.formats?.trim();

  return switch (error.code) {
    AppErrorCode.cancelled => l10n.errorCancelled,

    AppErrorCode.apiTimeout => l10n.errorApiTimeout,
    AppErrorCode.apiUnreachable => l10n.errorApiUnreachable,
    AppErrorCode.apiUnauthorized => l10n.errorApiUnauthorized,
    AppErrorCode.apiInsufficientCredits => l10n.errorApiInsufficientCredits,
    AppErrorCode.apiRateLimited => l10n.errorApiRateLimited,
    AppErrorCode.apiNotFound => l10n.errorApiNotFound,
    AppErrorCode.apiRejected => l10n.errorApiRejected,
    AppErrorCode.apiCertificate => l10n.errorApiCertificate,
    AppErrorCode.apiSendFailed => l10n.errorApiSendFailed,
    AppErrorCode.apiBadResponse => l10n.errorApiBadResponse,
    AppErrorCode.apiNoChatEndpoint => l10n.errorApiNoChatEndpoint,
    AppErrorCode.apiModelUnavailable => l10n.errorApiModelUnavailable,
    AppErrorCode.apiConnectionBroken => l10n.errorApiConnectionBroken,
    AppErrorCode.apiProviderReported =>
      detail == null || detail.isEmpty
          ? l10n.commonGenericError
          : l10n.errorApiProviderReported(detail),

    AppErrorCode.generationTimeout => l10n.errorGenerationTimeout,

    AppErrorCode.exportNotReady => l10n.errorExportNotReady,
    AppErrorCode.exportTimeout => l10n.errorExportTimeout,
    AppErrorCode.exportNoElements => l10n.errorExportNoElements,
    AppErrorCode.exportEmptyResult => l10n.errorExportEmptyResult,
    AppErrorCode.exportWriteFailed => l10n.errorExportWriteFailed,
    AppErrorCode.exportFailed => l10n.exportFailed,

    AppErrorCode.importInvalidFile => l10n.errorImportInvalidFile,
    AppErrorCode.importNotProject => l10n.errorImportNotProject,
    AppErrorCode.importNewerVersion => l10n.errorImportNewerVersion(
      version == null || version.isEmpty ? '?' : version,
    ),
    AppErrorCode.importEmpty =>
      name == null || name.isEmpty
          ? l10n.errorImportEmpty
          : l10n.errorImportEmptyFile(name),
    AppErrorCode.importUnusable =>
      name == null || name.isEmpty
          ? l10n.errorImportUnusable
          : l10n.errorImportUnusableFile(name),

    AppErrorCode.attachmentEmpty =>
      name == null || name.isEmpty
          ? l10n.errorAttachmentEmpty
          : l10n.errorAttachmentEmptyFile(name),
    AppErrorCode.attachmentTooLarge => l10n.errorAttachmentTooLarge(
      error.maxMb ?? 0,
    ),
    AppErrorCode.attachmentUnsupported => l10n.errorAttachmentUnsupported(
      formats == null || formats.isEmpty ? '?' : formats,
    ),

    AppErrorCode.storageFailed => l10n.errorStorageFailed,

    AppErrorCode.transformNoCode => l10n.errorTransformNoCode,
    AppErrorCode.transformFailed => l10n.codeExportTransformErrorFallback(
      formats == null || formats.isEmpty ? '?' : formats,
    ),

    AppErrorCode.unknown => l10n.commonGenericError,
  };
}

/// `BuildContext` versi pendek, dipakai widget.
extension AppErrorContextX on BuildContext {
  String appError(AppErrorDetails error) =>
      localizedAppError(AppLocalizations.of(this), error);
}

/// Versi untuk tempat yang sudah memegang `AppLocalizations` (mis. `snack`).
extension AppErrorWordsX on AppLocalizations {
  String appError(AppErrorDetails error) => localizedAppError(this, error);
}
