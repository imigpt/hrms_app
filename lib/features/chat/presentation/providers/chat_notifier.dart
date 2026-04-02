import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms_app/core/auth/secure_storage.dart';
import 'package:hrms_app/features/chat/data/models/chat_room_model.dart';
import 'package:hrms_app/features/chat/data/services/chat_service.dart';
import 'chat_state.dart';

class ChatNotifier extends ChangeNotifier {
  ChatState _state = ChatState();

  ChatState get state => _state;

  final ChatService _chatService = ChatService();
  final SecureStorage _secureStorage = SecureStorage();

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialize chat: load rooms, users, and unread counts
  Future<void> initialize() async {
    try {
      _state = _state.copyWith(isLoadingRooms: true, error: null);
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Load rooms and users in parallel
      await Future.wait([
        loadChatRooms(token),
        loadCompanyUsers(token),
        _loadUnreadCounts(token),
      ]);

      _state = _state.copyWith(
        isLoadingRooms: false,
        isConnected: true,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingRooms: false,
        error: 'Failed to initialize chat: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHAT ROOMS
  // ──────────────────────────────────────────────────────────────────────────

  /// Load all chat rooms for the current user
  Future<void> loadChatRooms(String token) async {
    try {
      _state = _state.copyWith(isLoadingRooms: true, error: null);
      notifyListeners();

      final response = await ChatService.getChatRooms(token: token);
      _state = _state.copyWith(
        chatRooms: response.data,
        isLoadingRooms: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingRooms: false,
        error: 'Failed to load chat rooms: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Refresh chat rooms
  Future<void> refreshChatRooms() async {
    try {
      _state = _state.copyWith(isRefreshingRooms: true);
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await ChatService.getChatRooms(token: token);
      _state = _state.copyWith(
        chatRooms: response.data,
        isRefreshingRooms: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isRefreshingRooms: false,
        error: 'Failed to refresh rooms: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Select a chat room and load its messages
  Future<void> selectChatRoom(ChatRoom room) async {
    try {
      _state = _state.copyWith(
        selectedChatRoom: room,
        selectedRoomId: room.id,
        isLoadingMessages: true,
        messagesPageIndex: 0,
        hasMoreMessages: true,
        error: null,
      );
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      await _loadRoomMessages(token, room.id, limit: 50);

      // Mark room as read
      await ChatService.markRoomAsRead(token: token, roomId: room.id);

      _state = _state.copyWith(
        isLoadingMessages: false,
        unreadCounts: {
          ..._state.unreadCounts,
          room.id: 0,
        },
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to load room: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Deselect current chat room
  void deselectChatRoom() {
    _state = _state.copyWith(
      selectedChatRoom: null,
      selectedRoomId: null,
      currentRoomMessages: [],
    );
    notifyListeners();
  }

  /// Get or create a personal (1-1) chat with a user
  Future<void> openOrCreatePersonalChat(String userId) async {
    try {
      _state = _state.copyWith(isLoadingMessages: true, error: null);
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await ChatService.getOrCreatePersonalChat(
        token: token,
        userId: userId,
      );

      final room = response.data;
      _state = _state.copyWith(
        selectedChatRoom: room,
        selectedRoomId: room.id,
        isLoadingMessages: true,
      );
      notifyListeners();

      // Load messages for the room
      await _loadRoomMessages(token, room.id, limit: 50);

      _state = _state.copyWith(isLoadingMessages: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to open chat: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MESSAGES
  // ──────────────────────────────────────────────────────────────────────────

  /// Load messages for the current room (internal helper)
  Future<void> _loadRoomMessages(
    String token,
    String roomId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await ChatService.getRoomMessages(
        token: token,
        roomId: roomId,
        limit: limit,
        before: before,
      );

      _state = _state.copyWith(
        currentRoomMessages: response.data ?? const [],
        hasMoreMessages: response.hasMore,
      );
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  /// Load more messages in the current room (pagination)
  Future<void> loadMoreMessages() async {
    try {
      if (!_state.canLoadMoreMessagesInCurrentRoom) return;

      _state = _state.copyWith(isLoadingMessages: true);
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final roomId = _state.selectedRoomId;
      if (roomId == null) throw Exception('No room selected');

      // Get the timestamp of the oldest message
      final oldestMessage = _state.currentRoomMessages.isNotEmpty
          ? _state.currentRoomMessages.last
          : null;
      final beforeTimestamp =
          oldestMessage?.createdAt.toIso8601String();

      final response = await ChatService.getRoomMessages(
        token: token,
        roomId: roomId,
        limit: 50,
        before: beforeTimestamp,
      );

      final messagesList = (response.data ?? const [])
          .cast<ChatMessage>();

      final updatedMessages = [
        ..._state.currentRoomMessages,
        ...messagesList,
      ];

      _state = _state.copyWith(
        currentRoomMessages: updatedMessages,
        hasMoreMessages: response.hasMore,
        messagesPageIndex: _state.messagesPageIndex + 1,
        isLoadingMessages: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to load more messages: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Send a text message to the current room
  Future<void> sendMessage(String content) async {
    try {
      if (content.isEmpty || _state.selectedRoomId == null) return;

      // Optimistic UI update
      final tempMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatRoom: _state.selectedRoomId!,
        content: content,
        messageType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _state = _state.copyWith(
        currentRoomMessages: [tempMessage, ..._state.currentRoomMessages],
        isSendingMessage: true,
        error: null,
      );
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await ChatService.sendRoomMessage(
        token: token,
        roomId: _state.selectedRoomId!,
        content: content,
        messageType: 'text',
      );

      if (response.data != null) {
        // Replace temp message with real one
        final messages = _state.currentRoomMessages.where((m) => m.id != tempMessage.id).toList();
        _state = _state.copyWith(
          currentRoomMessages: [response.data!, ...messages],
          isSendingMessage: false,
        );
      }

      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isSendingMessage: false,
        error: 'Failed to send message: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Send a media message (image, document, voice)
  Future<void> sendMediaMessage(
    File file,
    String messageType, {
    String caption = '',
  }) async {
    try {
      if (_state.selectedRoomId == null) {
        throw Exception('No room selected');
      }

      final fileName = file.path.split('/').last;
      _state = _state.copyWith(
        isUploadingMedia: true,
        uploadingFileName: fileName,
        uploadProgress: 0.0,
        error: null,
      );
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      // Simulate progress tracking (backend doesn't support real progress)
      _state = _state.copyWith(uploadProgress: 0.3);
      notifyListeners();

      final response = await ChatService.sendMediaMessage(
        token: token,
        roomId: _state.selectedRoomId!,
        file: file,
        messageType: messageType,
        content: caption,
      );

      _state = _state.copyWith(uploadProgress: 1.0);
      notifyListeners();

      if (response.data != null) {
        _state = _state.copyWith(
          currentRoomMessages: [response.data!, ..._state.currentRoomMessages],
          isUploadingMedia: false,
          uploadingFileName: null,
          uploadProgress: 0.0,
          successMessage: 'Media sent successfully',
        );
      }

      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isUploadingMedia: false,
        uploadingFileName: null,
        uploadProgress: 0.0,
        error: 'Failed to send media: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      await ChatService.deleteMessage(token: token, messageId: messageId);

      // Update local message state
      final updatedMessages = _state.currentRoomMessages
          .map((m) => m.id == messageId ? m.copyWith(isDeleted: true) : m)
          .toList();

      _state = _state.copyWith(currentRoomMessages: updatedMessages);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to delete message: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GROUPS
  // ──────────────────────────────────────────────────────────────────────────

  /// Create a new group chat
  Future<void> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
  }) async {
    try {
      _state = _state.copyWith(error: null);
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final result = await ChatService.createGroup(
        token: token,
        name: name,
        memberIds: memberIds,
        description: description,
      );

      _state = _state.copyWith(
        successMessage: 'Group created successfully',
      );
      notifyListeners();

      // Reload rooms
      await loadChatRooms(token);
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to create group: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Add a member to a group
  Future<void> addGroupMember(String groupId, String userId) async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      await ChatService.addGroupMember(
        token: token,
        groupId: groupId,
        userId: userId,
      );

      _state = _state.copyWith(
        successMessage: 'Member added to group',
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to add member: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      await ChatService.leaveGroup(token: token, groupId: groupId);

      // Remove from local list
      final updatedRooms =
          _state.chatRooms.where((r) => r.id != groupId).toList();
      _state = _state.copyWith(
        chatRooms: updatedRooms,
        selectedChatRoom: _state.selectedRoomId == groupId ? null : _state.selectedChatRoom,
        selectedRoomId: _state.selectedRoomId == groupId ? null : _state.selectedRoomId,
        successMessage: 'Left the group',
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to leave group: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Delete a group (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      await ChatService.deleteGroup(token: token, groupId: groupId);

      // Remove from local list
      final updatedRooms =
          _state.chatRooms.where((r) => r.id != groupId).toList();
      _state = _state.copyWith(
        chatRooms: updatedRooms,
        selectedChatRoom: _state.selectedRoomId == groupId ? null : _state.selectedChatRoom,
        selectedRoomId: _state.selectedRoomId == groupId ? null : _state.selectedRoomId,
        successMessage: 'Group deleted successfully',
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to delete group: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // USERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Load all company users
  Future<void> loadCompanyUsers(String token) async {
    try {
      _state = _state.copyWith(isLoadingUsers: true, error: null);
      notifyListeners();

      final response = await ChatService.getCompanyUsers(token: token);
      _state = _state.copyWith(
        companyUsers: response.data,
        isLoadingUsers: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingUsers: false,
        error: 'Failed to load users: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Search company users
  Future<void> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        _state = _state.copyWith(searchQuery: null);
        notifyListeners();
        return;
      }

      if (query.length < 2) return;

      _state = _state.copyWith(isLoadingUsers: true, error: null);
      notifyListeners();

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await ChatService.searchUsers(
        token: token,
        query: query,
      );

      _state = _state.copyWith(
        companyUsers: response.data,
        searchQuery: query,
        isLoadingUsers: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoadingUsers: false,
        error: 'Failed to search users: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REAL-TIME STATES
  // ──────────────────────────────────────────────────────────────────────────

  /// Set typing indicator for a user in current room
  void setTypingIndicator(String userId, bool isTyping) {
    final updated = {..._state.typingIndicators, userId: isTyping};
    _state = _state.copyWith(typingIndicators: updated);
    notifyListeners();
  }

  /// Update user presence
  void updateUserPresence(String userId, String status) {
    final updated = {..._state.userPresence, userId: status};
    _state = _state.copyWith(userPresence: updated);
    notifyListeners();
  }

  /// Mark messages as read in current room
  Future<void> markRoomAsRead() async {
    try {
      if (_state.selectedRoomId == null) return;

      final token = await _secureStorage.getToken();
      if (token == null) throw Exception('Token not found');

      await ChatService.markRoomAsRead(
        token: token,
        roomId: _state.selectedRoomId!,
      );

      // Update local state
      final unreadCounts = {..._state.unreadCounts};
      unreadCounts[_state.selectedRoomId!] = 0;

      _state = _state.copyWith(unreadCounts: unreadCounts);
      notifyListeners();
    } catch (e) {
      // Silent fail for read operations
    }
  }

  /// Load unread counts for all rooms
  Future<void> _loadUnreadCounts(String token) async {
    try {
      final response = await ChatService.getUnreadCount(token: token);

      final countMap = <String, int>{};
      for (final room in _state.chatRooms) {
        countMap[room.id] = room.unreadCount;
      }

      _state = _state.copyWith(
        unreadCounts: countMap,
        totalUnreadMessages: response.count,
      );
      notifyListeners();
    } catch (e) {
      // Silent fail for unread loads
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ERROR & UI MANAGEMENT
  // ──────────────────────────────────────────────────────────────────────────

  /// Clear error message
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  /// Clear success message
  void clearSuccessMessage() {
    _state = _state.copyWith(successMessage: null);
    notifyListeners();
  }

  /// Clear all UI messages
  void clearAllMessages() {
    _state = _state.copyWith(error: null, successMessage: null);
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _state = ChatState();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
