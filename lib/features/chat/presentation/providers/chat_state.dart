import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/chat/data/models/chat_room_model.dart';

class ChatState extends Equatable {
  static const Object _unset = Object();

  // ── Core Lists ───────────────────────────────────────────────────────────
  final List<ChatRoom> chatRooms;
  final List<ChatMessage> currentRoomMessages;
  final List<ChatUser> companyUsers;

  // ── Current Selection ────────────────────────────────────────────────────
  final ChatRoom? selectedChatRoom;
  final String? selectedRoomId;

  // ── Pagination ──────────────────────────────────────────────────────────
  final bool hasMoreMessages;
  final int messagesPageIndex;

  // ── Loading States ──────────────────────────────────────────────────────
  final bool isLoadingRooms;
  final bool isLoadingMessages;
  final bool isLoadingUsers;
  final bool isRefreshingRooms;
  final bool isRefreshingMessages;
  final bool isSendingMessage;
  final bool isUploadingMedia;

  // ── Real-time States ────────────────────────────────────────────────────
  final Map<String, bool> typingIndicators; // roomId -> isTyping
  final Map<String, String> userPresence; // userId -> 'online' | 'offline' | 'away'
  final Map<String, int> unreadCounts; // roomId -> unread message count
  final int totalUnreadMessages;

  // ── UI States ───────────────────────────────────────────────────────────
  final String? error;
  final String? successMessage;
  final String? searchQuery;
  final String? uploadingFileName;
  final double uploadProgress; // 0.0 to 1.0

  // ── File Management ────────────────────────────────────────────────────
  final List<ChatAttachment> selectedAttachments;

  // ── WebSocket Status ───────────────────────────────────────────────────
  final bool isConnected;
  final bool isReconnecting;

  const ChatState({
    this.chatRooms = const [],
    this.currentRoomMessages = const [],
    this.companyUsers = const [],
    this.selectedChatRoom,
    this.selectedRoomId,
    this.hasMoreMessages = true,
    this.messagesPageIndex = 0,
    this.isLoadingRooms = false,
    this.isLoadingMessages = false,
    this.isLoadingUsers = false,
    this.isRefreshingRooms = false,
    this.isRefreshingMessages = false,
    this.isSendingMessage = false,
    this.isUploadingMedia = false,
    this.typingIndicators = const {},
    this.userPresence = const {},
    this.unreadCounts = const {},
    this.totalUnreadMessages = 0,
    this.error,
    this.successMessage,
    this.searchQuery,
    this.uploadingFileName,
    this.uploadProgress = 0.0,
    this.selectedAttachments = const [],
    this.isConnected = false,
    this.isReconnecting = false,
  });

  // ── Computed Getters ──────────────────────────────────────────────────
  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasSuccess => successMessage != null && successMessage!.isNotEmpty;
  bool get isLoadingAny =>
      isLoadingRooms ||
      isLoadingMessages ||
      isLoadingUsers ||
      isRefreshingRooms ||
      isRefreshingMessages ||
      isSendingMessage ||
      isUploadingMedia;
  bool get isIdle =>
      !isLoadingAny &&
      !isConnected &&
      !isReconnecting &&
      selectedRoomId == null;

  /// Filtered chat rooms based on search query
  List<ChatRoom> get filteredChatRooms {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return chatRooms;
    }
    final query = searchQuery!.toLowerCase();
    return chatRooms.where((room) {
      return room.name.toLowerCase().contains(query) ||
          room.description.toLowerCase().contains(query);
    }).toList();
  }

  /// Rooms sorted by last message date (newest first)
  List<ChatRoom> get sortedChatRooms {
    final rooms = List<ChatRoom>.from(filteredChatRooms);
    rooms.sort((a, b) => (b.lastMessage?.createdAt ?? b.updatedAt)
        .compareTo(a.lastMessage?.createdAt ?? a.updatedAt));
    return rooms;
  }

  /// Rooms with unread messages
  List<ChatRoom> get roomsWithUnread {
    return filteredChatRooms
        .where((room) => (unreadCounts[room.id] ?? 0) > 0)
        .toList();
  }

  /// Count of rooms with unread messages
  int get unreadRoomsCount => roomsWithUnread.length;

  /// Count of group chats
  int get groupChatCount =>
      chatRooms.where((room) => room.isGroup).length;

  /// Count of direct chats
  int get directChatCount =>
      chatRooms.where((room) => !room.isGroup).length;

  /// All users who are currently typing in the current room
  List<String> get typingUsersInCurrentRoom {
    if (typingIndicators.isEmpty) return [];
    return typingIndicators.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Count of users typing in current room
  int get typingCountInCurrentRoom => typingUsersInCurrentRoom.length;

  /// Total unread message count across all rooms
  int get totalUnread {
    return unreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Is any room currently selected
  bool get hasSelectedRoom => selectedRoomId != null && selectedChatRoom != null;

  /// Is current selection a group chat
  bool get isCurrentRoomGroup => selectedChatRoom?.isGroup ?? false;

  /// Current room message count
  int get currentRoomMessageCount => currentRoomMessages.length;

  /// Does current room have more messages to load
  bool get canLoadMoreMessagesInCurrentRoom =>
      hasMoreMessages && !isLoadingMessages && hasSelectedRoom;

  /// Last message in current room
  ChatMessage? get lastMessageInCurrentRoom {
    if (currentRoomMessages.isEmpty) return null;
    return currentRoomMessages.first; // First item typically is newest
  }

  /// First unread message index in current room
  int? get firstUnreadMessageIndex {
    try {
      return currentRoomMessages
          .indexWhere((msg) => !msg.isRead && msg.sender?.id != '');
    } catch (_) {
      return null;
    }
  }

  /// All online users from company users list
  List<ChatUser> get onlineUsers {
    return companyUsers
        .where((user) => userPresence[user.id] == 'online')
        .toList();
  }

  /// Online users count
  int get onlineUsersCount => onlineUsers.length;

  /// All users available for starting a new chat
  List<ChatUser> get availableUsersForChat {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return companyUsers;
    }
    final query = searchQuery!.toLowerCase();
    return companyUsers.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.employeeId?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Is media currently uploading
  bool get isMediaUploading => isUploadingMedia && uploadingFileName != null;

  /// Media upload percentage (0-100)
  int get uploadPercentage => (uploadProgress * 100).toInt();

  /// Should show loading indicator instead of content
  bool get shouldShowLoadingPlaceholder => isLoadingRooms && chatRooms.isEmpty;

  /// Should show empty state
  bool get shouldShowEmptyState =>
      !isLoadingRooms && chatRooms.isEmpty && !hasError;

  /// ConnectionState for UI display
  String get connectionStatus {
    if (!isConnected && isReconnecting) return 'Reconnecting...';
    if (!isConnected) return 'Disconnected';
    return 'Connected';
  }

  @override
  List<Object?> get props => [
    chatRooms,
    currentRoomMessages,
    companyUsers,
    selectedChatRoom,
    selectedRoomId,
    hasMoreMessages,
    messagesPageIndex,
    isLoadingRooms,
    isLoadingMessages,
    isLoadingUsers,
    isRefreshingRooms,
    isRefreshingMessages,
    isSendingMessage,
    isUploadingMedia,
    typingIndicators,
    userPresence,
    unreadCounts,
    totalUnreadMessages,
    error,
    successMessage,
    searchQuery,
    uploadingFileName,
    uploadProgress,
    selectedAttachments,
    isConnected,
    isReconnecting,
  ];

  ChatState copyWith({
    List<ChatRoom>? chatRooms,
    List<ChatMessage>? currentRoomMessages,
    List<ChatUser>? companyUsers,
    Object? selectedChatRoom = _unset,
    Object? selectedRoomId = _unset,
    bool? hasMoreMessages,
    int? messagesPageIndex,
    bool? isLoadingRooms,
    bool? isLoadingMessages,
    bool? isLoadingUsers,
    bool? isRefreshingRooms,
    bool? isRefreshingMessages,
    bool? isSendingMessage,
    bool? isUploadingMedia,
    Map<String, bool>? typingIndicators,
    Map<String, String>? userPresence,
    Map<String, int>? unreadCounts,
    int? totalUnreadMessages,
    Object? error = _unset,
    Object? successMessage = _unset,
    Object? searchQuery = _unset,
    Object? uploadingFileName = _unset,
    double? uploadProgress,
    List<ChatAttachment>? selectedAttachments,
    bool? isConnected,
    bool? isReconnecting,
  }) {
    return ChatState(
      chatRooms: chatRooms ?? this.chatRooms,
      currentRoomMessages: currentRoomMessages ?? this.currentRoomMessages,
      companyUsers: companyUsers ?? this.companyUsers,
      selectedChatRoom: identical(selectedChatRoom, _unset)
          ? this.selectedChatRoom
          : selectedChatRoom as ChatRoom?,
      selectedRoomId: identical(selectedRoomId, _unset)
          ? this.selectedRoomId
          : selectedRoomId as String?,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      messagesPageIndex: messagesPageIndex ?? this.messagesPageIndex,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isRefreshingRooms: isRefreshingRooms ?? this.isRefreshingRooms,
      isRefreshingMessages: isRefreshingMessages ?? this.isRefreshingMessages,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isUploadingMedia: isUploadingMedia ?? this.isUploadingMedia,
      typingIndicators: typingIndicators ?? this.typingIndicators,
      userPresence: userPresence ?? this.userPresence,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      totalUnreadMessages: totalUnreadMessages ?? this.totalUnreadMessages,
      error: identical(error, _unset) ? this.error : error as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
      searchQuery: identical(searchQuery, _unset)
          ? this.searchQuery
          : searchQuery as String?,
      uploadingFileName: identical(uploadingFileName, _unset)
          ? this.uploadingFileName
          : uploadingFileName as String?,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      selectedAttachments: selectedAttachments ?? this.selectedAttachments,
      isConnected: isConnected ?? this.isConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
    );
  }
}
