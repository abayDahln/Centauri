import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'locale_provider.dart';

export '../../l10n/generated/app_localizations.dart';

/// Pintasan `AppLocalizations.of(context)`, supaya pemanggilan di widget tetap
/// pendek: `context.l10n.commonSave`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Terjemahan untuk lapisan yang tidak punya `BuildContext` — provider/state,
/// tempat pesan status atau judul bawaan dibuat sebelum sampai ke widget.
///
/// Memakai bahasa UI yang sedang aktif (preferensi aplikasi), bukan locale dari
/// context, sehingga nilai yang dihasilkan tetap konsisten dengan tampilan.
AppLocalizations l10nOf(Ref ref) =>
    lookupAppLocalizations(ref.read(appLanguageProvider).locale);
