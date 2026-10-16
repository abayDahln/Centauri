import '../../domain/oauth/oauth_provider_preset.dart';
import 'provider_catalog_entry.dart';

/// Hasil pemilihan dari katalog provider.
///
/// Menyatukan dua model yang berbeda (preset API-key vs preset OAuth) hanya di
/// lapisan UI, tanpa mencampur entity-nya.
sealed class CatalogSelection {
  const CatalogSelection();
}

class ApiKeySelection extends CatalogSelection {
  const ApiKeySelection(this.entry);
  final ProviderCatalogEntry entry;
}

class OAuthSelection extends CatalogSelection {
  const OAuthSelection(this.preset);
  final OAuthProviderPreset preset;
}
