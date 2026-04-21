import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms_app/core/auth/secure_storage.dart';
import 'package:hrms_app/features/chat/data/models/chat_room_model.dart';
import 'package:hrms_app/features/chat/data/services/chat_service.dart';
import 'chat_state.dart';

typedef _GetTokenFn = Future<String?> Function();
typedef _GetChatRoomsFn = Future<ChatRoomsResponse> Function({
  required String token,
});
typedef _GetCompanyUsersFn = Future<ChatUsersResponse> Function({
  required String token,
});
typedef _GetUnreadCountFn = Future<UnreadCountResponse> Function({
  required String token,
});
typedef _GetRoomMessagesFn = Future<ChatMessagesResponse> Function({
  required String token,
  required String roomId,
  int? limit,
  String? before,
});
typedef _MarkRoomAsReadFn = Future<MarkReadResponse> Function({
  required String token,
  required String roomId,
});
typedef _GetOrCreatePersonalChatFn = Future<ChatPersonalRoomResponse> Function({
  required String token,
  required String userId,
});
typedef _SendRoomMessageFn = Future<SendMessageResponse> Function({
  required String token,
  required String roomId,
  required String content,
  String messageType,
  String? replyTo,
});
typedef _SendMediaMessageFn = Future<SendMessageResponse> Function({
  required String token,
  required String roomId,
  required File file,
  required String messageType,
  String content,
});
typedef _DeleteMessageFn = Future<Map<String, dynamic>> Function({
  required String token,
  required String messageId,
});
typedef _CreateGroupFn = Future<Map<String, dynamic>> Function({
  required String token,
  required String name,
  required List<String> memberIds,
  String? description,
});
typedef _AddGroupMemberFn = Future<Map<String, dynamic>> Function({
  required String token,
  required String groupId,
  required String userId,
});
typedef _LeaveGroupFn = Future<Map<String, dynamic>> Function({
  required String token,
  required String groupId,
});
typedef _DeleteGroupFn = Future<Map<String, dynamic>> Function({
  required String token,
  required String groupId,
});
typedef _SearchUsersFn = Future<ChatUsersResponse> Function({
  required String token,
  required String query,
});

class ChatNotifier extends ChangeNotifier {
  ChatState _state = const ChatState();

  ChatState get state => _state;

  final _GetTokenFn _getToken;
  final _GetChatRoomsFn _getChatRooms;
  final _GetCompanyUsersFn _getCompanyUsers;
  final _GetUnreadCountFn _getUnreadCount;
  final _GetRoomMessagesFn _getRoomMessages;
  final _MarkRoomAsReadFn _markRoomAsRead;
  final _GetOrCreatePersonalChatFn _getOrCreatePersonalChat;
  final _SendRoomMessageFn _sendRoomMessage;
  final _SendMediaMessageFn _sendMediaMessage;
  final _DeleteMessageFn _deleteMessage;
  final _CreateGroupFn _createGroup;
  final _AddGroupMemberFn _addGroupMember;
  final _LeaveGroupFn _leaveGroup;
  final _DeleteGroupFn _deleteGroup;
  final _SearchUsersFn _searchUsers;

  ChatNotifier({
    _GetTokenFn? getToken,
    _GetChatRoomsFn? getChatRooms,
    _GetCompanyUsersFn? getCompanyUsers,
    _GetUnreadCountFn? getUnreadCount,
    _GetRoomMessagesFn? getRoomMessages,
    _MarkRoomAsReadFn? markRoomAsRead,
    _GetOrCreatePersonalChatFn? getOrCreatePersonalChat,
    _SendRoomMessageFn? sendRoomMessage,
    _SendMediaMessageFn? sendMediaMessage,
    _DeleteMessageFn? deleteMessage,
    _CreateGroupFn? createGroup,
    _AddGroupMemberFn? addGroupMember,
    _LeaveGroupFn? leaveGroup,
    _DeleteGroupFn? deleteGroup,
    _SearchUsersFn? searchUsers,
  })  : _getToken = getToken ?? SecureStorage().getToken,
        _getChatRooms = getChatRooms ?? ChatService.getChatRooms,
        _getCompanyUsers = getCompanyUsers ?? ChatService.getCompanyUsers,
        _getUnreadCount = getUnreadCount ?? ChatService.getUnreadCount,
        _getRoomMessages = getRoomMessages ?? ChatService.getRoomMessages,
        _markRoomAsRead = markRoomAsRead ?? ChatService.markRoomAsRead,
        _getOrCreatePersonalChat =
            getOrCreatePersonalChat ?? ChatService.getOrCreatePersonalChat,
        _sendRoomMessage = sendRoomMessage ?? ChatService.sendRoomMessage,
        _sendMediaMessage = sendMediaMessage ?? ChatService.sendMediaMessage,
        _deleteMessage = deleteMessage ?? ChatService.deleteMessage,
        _createGroup = createGroup ?? ChatService.createGroup,
        _addGroupMember = addGroupMember ?? ChatService.addGroupMember,
        _leaveGroup = leaveGroup ?? ChatService.leaveGroup,
        _deleteGroup = deleteGroup ?? ChatService.deleteGroup,
        _searchUsers = searchUsers ?? ChatService.searchUsers;

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialize chat: load rooms, users, and unread counts
  Future<void> initialize() async {
    try {
      _state = _state.copyWith(isLoadingRooms: true, error: null);
      notifyListeners();

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Rooms should load before unread counts are mapped by room ID.
      await Future.wait([
        loadChatRooms(token),
        loadCompanyUsers(token),
      ]);
      await _loadUnreadCounts(token);

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

      final response = await _getChatRooms(token: token);
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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _getChatRooms(token: token);
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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _loadRoomMessages(token, room.id, limit: 50);

      // Mark room as read
      await _markRoomAsRead(token: token, roomId: room.id);

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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _getOrCreatePersonalChat(
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

  /// Get or create a personal chat and return the room for navigation flows.
  Future<ChatRoom?> getOrCreatePersonalChatRoom(String userId) async {
    try {
      _state = _state.copyWith(error: null);
      notifyListeners();

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _getOrCreatePersonalChat(
        token: token,
        userId: userId,
      );
      final room = response.data;

      if (!_state.chatRooms.any((r) => r.id == room.id)) {
        _state = _state.copyWith(chatRooms: [room, ..._state.chatRooms]);
        notifyListeners();
      }

      return room;
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to open chat: ${e.toString()}',
      );
      notifyListeners();
      return null;
    }
  }

  /// Set the currently visible room messages from detail screen flows.
  void setDetailRoomMessages({
    required List<ChatMessage> messages,
    required bool hasMore,
  }) {
    _state = _state.copyWith(
      currentRoomMessages: messages,
      hasMoreMessages: hasMore,
      isRefreshingMessages: false,
    );
    notifyListeners();
  }

  /// Toggle older-messages loading state for detail pagination.
  void setLoadingOlderMessages(bool isLoading) {
    _state = _state.copyWith(isRefreshingMessages: isLoading);
    notifyListeners();
  }

  /// Append older messages at the end of the current room list.
  void appendOlderRoomMessages({
    required List<ChatMessage> olderMessages,
    required bool hasMore,
  }) {
    _state = _state.copyWith(
      currentRoomMessages: [..._state.currentRoomMessages, ...olderMessages],
      hasMoreMessages: hasMore,
      isRefreshingMessages: false,
    );
    notifyListeners();
  }

  /// Insert a message at the top (newest-first list), avoiding duplicates.
  void insertRoomMessage(ChatMessage message) {
    if (_state.currentRoomMessages.any((m) => m.id == message.id)) return;
    _state = _state.copyWith(
      currentRoomMessages: [message, ..._state.currentRoomMessages],
    );
    notifyListeners();
  }

  /// Replace an optimistic temp message with server-confirmed message.
  void replaceTempRoomMessage(String tempId, ChatMessage serverMessage) {
    final updatedMessages = _state.currentRoomMessages
        .map((m) => m.tempId == tempId ? serverMessage : m)
        .toList();
    _state = _state.copyWith(currentRoomMessages: updatedMessages);
    notifyListeners();
  }

  /// Remove an optimistic temp message when send fails.
  void removeTempRoomMessage(String tempId) {
    final updatedMessages = _state.currentRoomMessages
        .where((m) => m.tempId != tempId)
        .toList();
    _state = _state.copyWith(currentRoomMessages: updatedMessages);
    notifyListeners();
  }

  /// Mark outgoing messages as read after receiving read receipts.
  void markCurrentRoomMessagesRead(String? currentUserId) {
    if (currentUserId == null) return;

    final updatedMessages = _state.currentRoomMessages.map((m) {
      if ((m.sender?.id == currentUserId || m.sender == null) && !m.isRead) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    _state = _state.copyWith(currentRoomMessages: updatedMessages);
    notifyListeners();
  }

  /// Mark a message as deleted in local room list.
  void markRoomMessageDeleted(String messageId) {
    final updatedMessages = _state.currentRoomMessages
        .map((m) => m.id == messageId ? m.copyWith(isDeleted: true) : m)
        .toList();
    _state = _state.copyWith(currentRoomMessages: updatedMessages);
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MESSAGES
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetch room messages for screens that still manage local message state.
  Future<ChatMessagesResponse> fetchRoomMessages({
    required String token,
    required String roomId,
    int limit = 50,
    String? before,
  }) async {
    return _getRoomMessages(
      token: token,
      roomId: roomId,
      limit: limit,
      before: before,
    );
  }

  /// Send a room text message without mutating provider state.
  Future<SendMessageResponse> sendRoomMessageDirect({
    required String token,
    required String roomId,
    required String content,
    String? replyTo,
  }) async {
    return _sendRoomMessage(
      token: token,
      roomId: roomId,
      content: content,
      messageType: 'text',
      replyTo: replyTo,
    );
  }

  /// Send a room media message without mutating provider state.
  Future<SendMessageResponse> sendMediaMessageDirect({
    required String token,
    required String roomId,
    required File file,
    required String messageType,
    String content = '',
  }) async {
    return _sendMediaMessage(
      token: token,
      roomId: roomId,
      file: file,
      messageType: messageType,
      content: content,
    );
  }

  /// Load messages for the current room (internal helper)
  Future<void> _loadRoomMessages(
    String token,
    String roomId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await _getRoomMessages(
        token: token,
        roomId: roomId,
        limit: limit,
        before: before,
      );

      _state = _state.copyWith(
        currentRoomMessages: response.data,
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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      final roomId = _state.selectedRoomId;
      if (roomId == null) throw Exception('No room selected');

      // Get the timestamp of the oldest message
      final oldestMessage = _state.currentRoomMessages.isNotEmpty
          ? _state.currentRoomMessages.last
          : null;
      final beforeTimestamp =
          oldestMessage?.createdAt.toIso8601String();

      final response = await _getRoomMessages(
        token: token,
        roomId: roomId,
        limit: 50,
        before: beforeTimestamp,
      );

      final messagesList = response.data.cast<ChatMessage>();

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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _sendRoomMessage(
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
      } else {
        _state = _state.copyWith(isSendingMessage: false);
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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      // Simulate progress tracking (backend doesn't support real progress)
      _state = _state.copyWith(uploadProgress: 0.3);
      notifyListeners();

      final response = await _sendMediaMessage(
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
      } else {
        _state = _state.copyWith(
          isUploadingMedia: false,
          uploadingFileName: null,
          uploadProgress: 0.0,
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
      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _deleteMessage(token: token, messageId: messageId);

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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _createGroup(
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
      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _addGroupMember(
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
      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _leaveGroup(token: token, groupId: groupId);

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
      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _deleteGroup(token: token, groupId: groupId);

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

      final response = await _getCompanyUsers(token: token);
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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _searchUsers(
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

      final token = await _getToken();
      if (token == null) throw Exception('Token not found');

      await _markRoomAsRead(
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
      final response = await _getUnreadCount(token: token);

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
  // SOCKET EVENT HANDLERS (Real-time Messages)
  // ──────────────────────────────────────────────────────────────────────────

  /// Handle incoming message from socket
  /// Called when a new message arrives in real-time
  void receiveNewMessage(ChatMessage message) {
    try {
      // Only add if it's not a duplicate (check by ID) and for the current room
      if (_state.selectedRoomId == message.chatRoom &&
          !_state.currentRoomMessages.any((m) => m.id == message.id)) {
        _state = _state.copyWith(
          currentRoomMessages: [message, ..._state.currentRoomMessages],
        );
        notifyListeners();
      }

      // Update unread count for rooms other than current selection
      if (_state.selectedRoomId != message.chatRoom) {
        final unreadCounts = {..._state.unreadCounts};
        final current = unreadCounts[message.chatRoom] ?? 0;
        unreadCounts[message.chatRoom] = current + 1;

        _state = _state.copyWith(
          unreadCounts: unreadCounts,
          totalUnreadMessages: _state.totalUnreadMessages + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling received message: $e');
    }
  }

  /// Handle message-sent confirmation from socket
  /// Replaces temporary message with server-confirmed message
  void receiveMessageSent({
    required String tempId,
    required ChatMessage serverMessage,
  }) {
    try {
      // Replace temp message with real one
      final messages = _state.currentRoomMessages.where((m) => m.id != tempId).toList();
      if (!messages.any((m) => m.id == serverMessage.id)) {
        _state = _state.copyWith(
          currentRoomMessages: [serverMessage, ...messages],
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling message-sent: $e');
    }
  }

  /// Handle messages-read event from socket
  /// Updates unread count for a room when other users mark messages as read
  void receiveMessagesRead({
    required String roomId,
    required int count,
  }) {
    try {
      final unreadCounts = {..._state.unreadCounts};
      unreadCounts[roomId] = count;

      _state = _state.copyWith(unreadCounts: unreadCounts);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling messages-read: $e');
    }
  }

  /// Update list of online users
  /// Received once on connection and during status changes
  void updateOnlineUsers(List<String> userIds) {
    try {
      // Update user presence map to show they're online
      final presenceMap = {..._state.userPresence};
      for (final userId in userIds) {
        presenceMap[userId] = 'online';
      }

      _state = _state.copyWith(userPresence: presenceMap);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating online users: $e');
    }
  }

  /// Handle socket connection/disconnection status
  void setConnectionStatus({required bool isConnected, bool isReconnecting = false}) {
    try {
      _state = _state.copyWith(
        isConnected: isConnected,
        isReconnecting: isReconnecting,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating connection status: $e');
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
    _state = const ChatState();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
