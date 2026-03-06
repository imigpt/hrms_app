// lib/services/chat_service.dart
// Covers all user-accessible chat endpoints at /api/chat/*

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_room_model.dart';

class ChatService {
  static const String _baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> _getHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  // ── Error helper ──────────────────────────────────────────────────────────
  static String _msg(String body, String fallback) {
    try {
      final m = (jsonDecode(body) as Map<String, dynamic>)['message'];
      return (m as String?) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // =========================================================================
  // CHAT ROOMS
  // =========================================================================

  /// GET /api/chat/rooms — all rooms (personal + groups) for the current user
  static Future<ChatRoomsResponse> getChatRooms({required String token}) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/chat/rooms'), headers: _getHeaders(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChatRoomsResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to load chat rooms'));
  }

  /// POST /api/chat/rooms/personal — get or create a personal (1-1) room
  /// [userId] is the ID of the other participant.
  static Future<ChatPersonalRoomResponse> getOrCreatePersonalChat({
    required String token,
    required String userId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/rooms/personal'),
          headers: _headers(token),
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChatPersonalRoomResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to get/create personal chat'));
  }

  /// GET /api/chat/rooms/:roomId/messages — paginated messages for a room
  /// [limit] defaults to 50 on the server; [before] is an ISO-8601 timestamp
  /// for cursor-based pagination (load older messages).
  static Future<ChatMessagesResponse> getRoomMessages({
    required String token,
    required String roomId,
    int? limit,
    String? before,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (before != null) params['before'] = before;
    final uri = Uri.parse(
      '$_baseUrl/chat/rooms/$roomId/messages',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await http
        .get(uri, headers: _getHeaders(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChatMessagesResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to fetch messages'));
  }

  /// POST /api/chat/rooms/:roomId/messages — send a text message to a room
  /// [messageType] defaults to 'text'; can be 'text' | 'image' | 'voice' | 'document'
  static Future<SendMessageResponse> sendRoomMessage({
    required String token,
    required String roomId,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'messageType': messageType,
    };
    if (replyTo != null) body['replyTo'] = replyTo;

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/rooms/$roomId/messages'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SendMessageResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to send message'));
  }

  /// PUT /api/chat/rooms/:roomId/read — mark all unread messages in a room as read
  static Future<MarkReadResponse> markRoomAsRead({
    required String token,
    required String roomId,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/chat/rooms/$roomId/read'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return MarkReadResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to mark room as read'));
  }

  // =========================================================================
  // GROUPS
  // =========================================================================

  /// GET /api/chat/groups/:groupId — full group details (participants, admins)
  static Future<ChatPersonalRoomResponse> getGroupDetails({
    required String token,
    required String groupId,
  }) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/chat/groups/$groupId'),
          headers: _getHeaders(token),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChatPersonalRoomResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to fetch group details'));
  }

  /// POST /api/chat/groups — create a new group chat
  /// [name] is the group name; [memberIds] are user IDs to add to the group
  static Future<Map<String, dynamic>> createGroup({
    required String token,
    required String name,
    required List<String> memberIds,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/groups'),
          headers: _headers(token),
          body: jsonEncode({'name': name, 'memberIds': memberIds}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201)
      return decoded;
    throw Exception(_msg(response.body, 'Failed to create group'));
  }

  /// POST /api/chat/groups/:groupId/members — add a member to a group
  /// [userId] is the user ID to add to the group
  static Future<Map<String, dynamic>> addGroupMember({
    required String token,
    required String groupId,
    required String userId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/groups/$groupId/members'),
          headers: _headers(token),
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201)
      return decoded;
    throw Exception(_msg(response.body, 'Failed to add member to group'));
  }

  /// DELETE /api/chat/groups/:groupId — delete a group chat
  static Future<Map<String, dynamic>> deleteGroup({
    required String token,
    required String groupId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/chat/groups/$groupId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return decoded;
    throw Exception(_msg(response.body, 'Failed to delete group'));
  }

  /// POST /api/chat/groups/:groupId/leave — leave a group chat
  static Future<Map<String, dynamic>> leaveGroup({
    required String token,
    required String groupId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/groups/$groupId/leave'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return decoded;
    throw Exception(_msg(response.body, 'Failed to leave group'));
  }

  // =========================================================================
  // USERS
  // =========================================================================

  /// GET /api/chat/users — all company users available for starting a chat
  static Future<ChatUsersResponse> getCompanyUsers({
    required String token,
  }) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/chat/users'), headers: _getHeaders(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChatUsersResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to fetch users'));
  }

  /// GET /api/chat/users/search?q= — search company users by name / email / employeeId
  /// [query] must be at least 2 characters.
  static Future<ChatUsersResponse> searchUsers({
    required String token,
    required String query,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/chat/users/search',
    ).replace(queryParameters: {'q': query});

    final response = await http
        .get(uri, headers: _getHeaders(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return ChatUsersResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to search users'));
  }

  // =========================================================================
  // MESSAGES
  // =========================================================================

  /// DELETE /api/chat/messages/:messageId — soft-delete your own message
  static Future<Map<String, dynamic>> deleteMessage({
    required String token,
    required String messageId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/chat/messages/$messageId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return decoded;
    throw Exception(_msg(response.body, 'Failed to delete message'));
  }

  // =========================================================================
  // UNREAD
  // =========================================================================

  /// GET /api/chat/unread — total unread message count across all rooms
  static Future<UnreadCountResponse> getUnreadCount({
    required String token,
  }) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/chat/unread'), headers: _getHeaders(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return UnreadCountResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(response.body, 'Failed to fetch unread count'));
  }

  // =========================================================================
  // MEDIA UPLOAD
  // =========================================================================

  /// POST /api/chat/rooms/:roomId/messages — multipart upload for image/document.
  /// [messageType]: 'image' | 'document' | 'voice'
  static Future<SendMessageResponse> sendMediaMessage({
    required String token,
    required String roomId,
    required File file,
    required String messageType,
    String content = '',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/chat/rooms/$roomId/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['messageType'] = messageType;
    if (content.isNotEmpty) request.fields['content'] = content;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return SendMessageResponse.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
    }
    throw Exception(_msg(body, 'Failed to send media'));
  }
}
