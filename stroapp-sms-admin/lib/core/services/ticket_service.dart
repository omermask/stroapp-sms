import '../constants/api_constants.dart';
import '../models/support_ticket.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';

class TicketService {
  final _client = ApiClient();

  Future<List<SupportTicket>> listTickets({
    int limit = 50,
    int offset = 0,
    String status = '',
    String category = '',
  }) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (status.isNotEmpty) params['status'] = status;
    if (category.isNotEmpty) params['category'] = category;

    final response = await _client.getV4(
      ApiConstants.supportTickets,
      queryParameters: params,
    );
    final apiResp = ApiResponse.fromJson(response.data, null);

    if (apiResp.success && apiResp.data != null) {
      final list = (apiResp.data as List<dynamic>)
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw Exception(apiResp.error?.message ?? 'Failed to load tickets');
  }

  Future<SupportTicket> getTicketDetail(String id) async {
    final response = await _client.getV4(ApiConstants.ticketDetail(id));
    final apiResp = ApiResponse.fromJson(response.data, null);

    if (apiResp.success && apiResp.data != null) {
      return SupportTicket.fromJson(apiResp.data as Map<String, dynamic>);
    }
    throw Exception(apiResp.error?.message ?? 'Failed to load ticket');
  }

  Future<void> replyToTicket(String id, String message) async {
    final response =
        await _client.postV4(ApiConstants.ticketReply(id), data: {
      'message': message,
    });
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to reply');
    }
  }

  Future<void> closeTicket(String id) async {
    final response = await _client.postV4(ApiConstants.ticketClose(id), data: {});
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to close ticket');
    }
  }

  Future<void> assignTicket(String id, String adminId) async {
    final response =
        await _client.postV4(ApiConstants.ticketAssign(id), data: {
      'admin_id': adminId,
    });
    final apiResp = ApiResponse.fromJson(response.data, null);
    if (!apiResp.success) {
      throw Exception(apiResp.error?.message ?? 'Failed to assign ticket');
    }
  }
}
