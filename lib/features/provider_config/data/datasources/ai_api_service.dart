import 'package:dio/dio.dart';

import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/api_provider.dart';

/// Exception koneksi API dengan pesan yang aman ditampilkan ke pengguna.
/// Tidak pernah memuat header/API key (NFR-01).
class ApiConnectionException implements Exception {
  ApiConnectionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// HTTP client dinamis berbasis Dio (TR-03). Dio dibuat per-request agar
/// Base URL, header, dan API Key selalu sesuai provider yang dipilih.
class AiApiService {
  const AiApiService();

  Dio _buildClient(ApiProvider provider) {
    final apiKey = provider.apiKey?.trim() ?? '';
    return Dio(BaseOptions(
      baseUrl: provider.normalizedBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      },
    ));
  }

  /// Memvalidasi endpoint & kredensial dengan GET {baseUrl}/models (FR-01).
  /// Melempar [ApiConnectionException] jika gagal.
  Future<void> testConnection(ApiProvider provider) async {
    try {
      final response = await _buildClient(provider).get(
        AppConstants.testConnectionPath,
      );
      if (response.statusCode == 200) return;
      throw ApiConnectionException(
        'Endpoint membalas dengan status ${response.statusCode}.',
      );
    } on DioException catch (e) {
      throw ApiConnectionException(_mapDioError(e));
    }
  }

  Future<String> generateUI({
    required ApiProvider provider,
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      final response = await _buildClient(provider).post(
        AppConstants.chatCompletionsPath,
        data: {
          'model': provider.model,
          'messages': messages,
          'temperature': 0.2,
        },
      );
      final content = response.data['choices'][0]['message']['content'];
      if (content is! String || content.trim().isEmpty) {
        throw ApiConnectionException('Respons AI tidak berisi konten.');
      }
      return content;
    } on DioException catch (e) {
      throw ApiConnectionException(_mapDioError(e));
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa Base URL atau jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke endpoint. Periksa Base URL.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          return 'API key tidak valid atau tidak memiliki akses (HTTP $status).';
        }
        if (status == 404) {
          return 'Endpoint tidak ditemukan (HTTP 404). Periksa Base URL.';
        }
        return 'Server menolak request (HTTP ${status ?? 'unknown'}).';
      case DioExceptionType.cancel:
        return 'Request dibatalkan.';
      default:
        return 'Terjadi kesalahan jaringan yang tidak terduga.';
    }
  }
}
