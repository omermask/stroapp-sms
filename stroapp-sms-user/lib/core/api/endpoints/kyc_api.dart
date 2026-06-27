import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class KycApi {
  final Dio _dio;

  KycApi(this._dio);

  Future<Map<String, dynamic>> getKycProfile() async {
    final response = await _dio.get('/kyc/profile');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createKycProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/kyc/profile', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateKycProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/kyc/profile', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadDocument(
    String documentType,
    String filePath,
    String fileHash,
  ) async {
    final response = await _dio.post(
      '/kyc/documents/upload',
      data: {
        'document_type': documentType,
        'file_path': filePath,
        'file_hash': fileHash,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getDocuments() async {
    final response = await _dio.get('/kyc/documents');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getKycStatus() async {
    final response = await _dio.get('/kyc/status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getKycLimits() async {
    final response = await _dio.get('/kyc/limits');
    return response.data as Map<String, dynamic>;
  }
}

final kycApiProvider = Provider<KycApi>((ref) {
  final dio = ref.read(dioProvider);
  return KycApi(dio);
});
