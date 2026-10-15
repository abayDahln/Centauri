import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/api_provider.dart';
import 'provider_config_provider.dart';

/// Kunci cache daftar model.
///
/// [ApiProvider] tidak punya `==`, jadi query ini dibuat equatable agar
/// `FutureProvider.family` bisa meng-cache per baseUrl + kredensial.
class ModelListQuery {
  const ModelListQuery({required this.baseUrl, this.bearerToken});

  final String baseUrl;
  final String? bearerToken;

  @override
  bool operator ==(Object other) =>
      other is ModelListQuery &&
      other.baseUrl == baseUrl &&
      other.bearerToken == bearerToken;

  @override
  int get hashCode => Object.hash(baseUrl, bearerToken);
}

/// Mengambil daftar model dari `GET {baseUrl}/models`.
///
/// Provider draft dibangun ulang dari query; `bearerToken` dipetakan ke
/// `apiKey` sehingga `_buildClient` memasang header `Authorization: Bearer`.
final modelListProvider =
    FutureProvider.autoDispose.family<List<String>, ModelListQuery>((
      ref,
      query,
    ) async {
      final draft = ApiProvider(
        id: 'draft',
        name: '',
        baseUrl: query.baseUrl,
        model: '',
        apiKey: query.bearerToken,
      );
      return ref.read(aiApiServiceProvider).listModels(draft);
    });
