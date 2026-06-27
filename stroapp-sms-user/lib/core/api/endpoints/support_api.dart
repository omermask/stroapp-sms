import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class SupportApi {
  final Dio _dio;

  SupportApi(this._dio);

  Future<Map<String, dynamic>> createTicket(
    String subject,
    String message,
    String category,
    String priority,
  ) async {
    final response = await _dio.post(
      '/user/support/tickets',
      data: {
        'subject': subject,
        'message': message,
        'category': category,
        'priority': priority,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTickets() async {
    final response = await _dio.get('/user/support/tickets');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTicketDetail(String ticketId) async {
    final response = await _dio.get('/user/support/tickets/$ticketId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> replyToTicket(
    String ticketId,
    String message,
  ) async {
    final response = await _dio.post(
      '/user/support/tickets/$ticketId/reply',
      data: {'message': message},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> closeTicket(String ticketId) async {
    final response = await _dio.post('/user/support/tickets/$ticketId/close');
    return response.data as Map<String, dynamic>;
  }
}

final supportApiProvider = Provider<SupportApi>((ref) {
  final dio = ref.read(dioProvider);
  return SupportApi(dio);
});
