import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';
import '../services/chat_socket_service.dart';
import '../services/token_storage_service.dart';
import '../services/notification_service.dart';
import '../services/chat_media_service.dart';
import 'chat_api_test_screen.dart';

// ─── Chat List Screen ─────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _socket = ChatSocketService();
  final List<StreamSubscription<dynamic>> _subs = [];

  List<ChatRoom> _allRooms = [];
  List<ChatRoom> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _initSocket();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    _token = await TokenStorageService().getToken();
    if (_token == null) return;
    _socket.connect(_token!);

    // Listen for any new incoming message across all rooms.
    _subs.add(
      _socket.onNewMessage.listen((msg) {
        if (!mounted) return;
        // Show local notification only when the user is NOT already viewing that room.
        if (ChatDetailScreen.visibleRoomId != msg.chatRoom) {
          final senderName = msg.sender?.name ?? 'New Message';
          final room = _allRooms.firstWhere(
            (r) => r.id == msg.chatRoom,
            orElse: () => ChatRoom(
              id: msg.chatRoom,
              name: 'Chat',
              type: 'personal',
              participants: const [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          NotificationService().showChatNotification(
            senderName: senderName,
            roomName: room.name,
            message: msg.messageType == 'text'
                ? msg.content
                : '[${msg.messageType}]',
            roomId: msg.chatRoom,
          );
        }
        // Silently refresh the room list so last-message preview and unread
        // badge update without the user needing to pull-to-refresh.
        _loadRooms();
      }),
    );
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = _token ?? await TokenStorageService().getToken();
      if (token == null) throw Exception('Not logged in. Please log in again.');

      final groupsResponse = await ChatService.getChatRooms(token: token);
      final combined = List<ChatRoom>.from(groupsResponse.data);

      if (mounted) {
        setState(() {
          _allRooms = combined;
          _filtered = _searchController.text.isEmpty
              ? List.from(_allRooms)
              : _allRooms
                    .where(
                      (r) => r.name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ),
                    )
                    .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_allRooms);
      } else {
        final searchTerm = query.toLowerCase();
        _filtered = _allRooms
            .where((room) {
              // Search by room name
              if (room.name.toLowerCase().contains(searchTerm)) return true;
              // Search by other user's name (for personal chats)
              if (room.otherUser?.name.toLowerCase().contains(searchTerm) ?? false) {
                return true;
              }
              // Search by last message content
              if (room.lastMessage?.content.toLowerCase().contains(searchTerm) ?? false) {
                return true;
              }
              return false;
            })
            .toList();
      }
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.api_outlined, color: AppTheme.primaryColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatApiTestScreen()),
            ),
            tooltip: 'Chat API Tests',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Conversation list ───────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),

      // ── FAB new message ────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatSheet,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[600], size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRooms,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _allRooms.isEmpty ? 'No conversations yet' : 'No conversations found',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      color: AppTheme.primaryColor,
      backgroundColor: const Color(0xFF1C1C1E),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) =>
            _buildConversationTile(_filtered[index]),
      ),
    );
  }

  Widget _buildConversationTile(ChatRoom room) {
    final lastMsg = room.lastMessage;
    final hasUnread = room.unreadCount > 0;
    // For personal rooms use the other user's name; group rooms use room.name
    final isPersonal = room.type == 'personal';
    final displayName = isPersonal
        ? (room.otherUser?.name ?? room.name)
        : room.name;
    final isVoice = lastMsg?.isVoice ?? false;
    final msgText = lastMsg?.content ?? '';
    final msgTime = lastMsg?.createdAt;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailScreen(room: room)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Avatar ─────────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _avatarColor(displayName),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials(displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (room.isGroup)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF050505),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.group,
                        size: 8,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                if (isPersonal)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF050505),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // ── Name + last message ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.isGroup)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Group',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isPersonal)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Personal',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (isVoice)
                        Icon(Icons.mic, size: 13, color: Colors.grey[500]),
                      if (isVoice) const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          msgText,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.white70
                                : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Time + badge ────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(msgTime),
                  style: TextStyle(
                    color: hasUnread ? AppTheme.primaryColor : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                if (hasUnread)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        room.unreadCount > 9 ? '9+' : '${room.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF8B2A3A),
      Color(0xFF9C1F4A),
      Color(0xFF7A1F5E),
      Color(0xFF6B2060),
      Color(0xFFAD2550),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  // ── Start New Chat sheet ───────────────────────────────────────────────
  void _showNewChatSheet() async {
    final token = _token ?? await TokenStorageService().getToken();
    if (token == null) return;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewChatSheet(
        token: token,
        onUserSelected: (room) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatDetailScreen(room: room)),
          ).then((_) => _loadRooms());
        },
      ),
    );
  }
}

// ─── Chat Detail Screen ───────────────────────────────────────────────────────

/// Full-featured WhatsApp-style chat screen.
/// • Real-time via Socket.IO (new-message / message-sent / typing)
/// • Pagination: scroll to top loads older messages
/// • Optimistic UI: temp bubble appears instantly, replaced on server confirm
/// • Swipe-to-reply & long-press forward
/// • Media: camera / gallery / file picker with multipart upload
/// • Typing indicators
class ChatDetailScreen extends StatefulWidget {
  final ChatRoom room;

  /// The room ID the user is currently viewing. Used by the chat-list screen
  /// to suppress notifications for the active conversation.
  static String? visibleRoomId;

  const ChatDetailScreen({super.key, required this.room});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  // ── Controllers & services ─────────────────────────────────────────────
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _storage = TokenStorageService();
  final _socket = ChatSocketService();
  final _imagePicker = ImagePicker();

  // ── State ──────────────────────────────────────────────────────────────
  List<ChatMessage> _messages = [];
  // bool _isLoading = true;
  bool _isSendingText = false;
  bool _isLoadingOlder = false;
  bool _hasMore = true;
  String? _error;
  String? _currentUserId;
  String? _token;

  // Online status: userId -> isOnline
  final Map<String, bool> _onlineUsers = {};

  // Reply / forward state
  ChatMessage? _replyTo;

  // Typing indicator
  bool _someoneTyping = false;
  String _typingUserName = '';
  Timer? _typingDebounce;
  Timer? _typingHideTimer;

  // Socket subscriptions
  final List<StreamSubscription<dynamic>> _subs = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _msgController.addListener(_onTextChanged);
    ChatDetailScreen.visibleRoomId =
        widget.room.id; // suppress notifications while open
    _init();
  }

  @override
  void dispose() {
    if (ChatDetailScreen.visibleRoomId == widget.room.id) {
      ChatDetailScreen.visibleRoomId = null;
    }
    _typingDebounce?.cancel();
    _typingHideTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _socket.leaveRoom(widget.room.id);
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _currentUserId = await _storage.getUserId();
    _token = await _storage.getToken();
    if (_token == null) {
      setState(() {
        _error = 'Not logged in';
        // _isLoading = false;
      });
      return;
    }
    await _loadMessages(initial: true);
    _connectSocket();
  }

  // ── Pagination ─────────────────────────────────────────────────────────
  void _onScroll() {
    // With reverse: true, newest messages are at the top (offset ~0)
    // and oldest messages are at the bottom (offset ~maxScrollExtent).
    // So load older messages when user scrolls DOWN near the bottom.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 60) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadMessages({bool initial = false}) async {
    if (initial) {
      setState(() {
        // _isLoading = true;
        _error = null;
      });
    }
    try {
      final res = await ChatService.getRoomMessages(
        token: _token!,
        roomId: widget.room.id,
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _messages = res.data.reversed.toList(); // oldest → top, newest → bottom
        _hasMore = res.hasMore;
        // _isLoading = false;
      });
      _scrollToBottom(jump: true);
      _socket.markRead(widget.room.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        // _isLoading = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (!_hasMore || _isLoadingOlder || _messages.isEmpty) return;
    setState(() => _isLoadingOlder = true);
    try {
      final oldest = _messages.first.createdAt.toUtc().toIso8601String();
      final res = await ChatService.getRoomMessages(
        token: _token!,
        roomId: widget.room.id,
        limit: 30,
        before: oldest,
      );
      if (!mounted) return;
      final older = res.data.reversed.toList();
      final prevHeight = _scrollController.position.extentTotal;
      setState(() {
        _messages = [...older, ..._messages];
        _hasMore = res.hasMore;
        _isLoadingOlder = false;
      });
      // Keep scroll position stable after prepending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newHeight = _scrollController.position.extentTotal;
          _scrollController.jumpTo(
            _scrollController.offset + (newHeight - prevHeight),
          );
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOlder = false);
    }
  }

  // ── Socket ─────────────────────────────────────────────────────────────
  void _connectSocket() {
    // Clear stale status so the AppBar doesn't show a ghost green dot from
    // a previous room/session.
    _onlineUsers.clear();

    // Register ALL stream listeners BEFORE connect() so we never miss events
    // that arrive synchronously or very shortly after connection.

    // Real-time read receipts
    _subs.add(
      _socket.onMessagesRead.listen((evt) {
        if (!mounted) return;
        if (evt.roomId != widget.room.id) return;
        if (evt.readBy == _currentUserId) return;
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            final m = _messages[i];
            if ((m.sender?.id == _currentUserId || m.sender == null) &&
                !m.isRead) {
              _messages[i] = m.copyWith(isRead: true);
            }
          }
        });
      }),
    );

    // Track online/offline status
    _subs.add(
      _socket.onUserStatus.listen((evt) {
        if (!mounted) return;
        setState(() => _onlineUsers[evt.userId] = evt.isOnline);
      }),
    );

    // Initial online snapshot from server
    _subs.add(
      _socket.onOnlineUsersList.listen((ids) {
        if (!mounted) return;
        setState(() {
          for (final id in ids) {
            _onlineUsers[id] = true;
          }
        });
      }),
    );

    // Now initiate / reuse the connection.
    // connect() will emit 'get-online-users' immediately if already connected,
    // or via onConnect callback after a fresh handshake.
    _socket.connect(_token!);
    _socket.joinRoom(widget.room.id);

    _subs.add(
      _socket.onNewMessage.listen((msg) {
        if (!mounted) return;
        // Only handle messages belonging to this room
        if (msg.chatRoom != widget.room.id) return;
        // Skip our own messages — handled via onMessageSent (socket) or REST response
        if (msg.sender?.id == _currentUserId) return;
        // Deduplicate by id
        if (_messages.any((m) => m.id == msg.id)) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
        _socket.markRead(widget.room.id);
      }),
    );

    _subs.add(
      _socket.onMessageSent.listen((evt) {
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m.tempId == evt.tempId);
          if (idx != -1) {
            _messages[idx] = evt.message;
          }
        });
      }),
    );

    _subs.add(
      _socket.onTyping.listen((evt) {
        if (!mounted) return;
        if (evt.roomId != widget.room.id) return;
        if (evt.userId == _currentUserId) return;
        _typingHideTimer?.cancel();
        setState(() {
          _someoneTyping = true;
          _typingUserName = evt.userName;
        });
        _typingHideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _someoneTyping = false);
        });
      }),
    );

    _subs.add(
      _socket.onStopTyping.listen((evt) {
        if (!mounted) return;
        if (evt.roomId != widget.room.id) return;
        setState(() => _someoneTyping = false);
      }),
    );

    // Belt-and-suspenders: if connect() already returned early (socket was
    // connected) and the get-online-users response arrived before our
    // onOnlineUsersList subscription above was registered, ask again now.
    // This is safe to call multiple times — the server just replies again.
    _socket.requestOnlineUsers();

    // Reconnect recovery: if the socket drops and reconnects, we must
    // re-join the room so the server starts forwarding messages again.
    _subs.add(
      _socket.onConnectionChanged.listen((connected) {
        if (!mounted) return;
        if (connected) {
          // Re-join current room and refresh online users after reconnect
          _socket.joinRoom(widget.room.id);
          _socket.requestOnlineUsers();
          // Reload messages to fill any gap while disconnected
          _loadMessages();
        }
      }),
    );
  }

  // ── Text field listener for typing indicator ────────────────────────────
  void _onTextChanged() {
    _typingDebounce?.cancel();
    if (_msgController.text.isNotEmpty) {
      _socket.emitTyping(widget.room.id);
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        _socket.emitStopTyping(widget.room.id);
      });
    } else {
      _socket.emitStopTyping(widget.room.id);
    }
  }

  // ── Send text ───────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSendingText) return;
    final replyRef = _replyTo;
    _msgController.clear();
    setState(() {
      _replyTo = null;
      _isSendingText = true;
    });
    _socket.emitStopTyping(widget.room.id);

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic bubble
    final optimistic = ChatMessage(
      id: tempId,
      chatRoom: widget.room.id,
      content: text,
      messageType: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tempId: tempId,
      replyTo: replyRef != null
          ? ChatReplyMessage(
              id: replyRef.id,
              content: replyRef.content,
              senderName: replyRef.sender?.name,
            )
          : null,
    );
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    if (_socket.isConnected) {
      // Fast path: socket — server saves once, broadcasts only to OTHERS,
      // and sends 'message-sent' back to us for confirmation.
      _socket.sendMessage(
        roomId: widget.room.id,
        content: text,
        tempId: tempId,
        replyTo: replyRef?.id,
      );
      if (mounted) setState(() => _isSendingText = false);
    } else {
      // Offline fallback: REST — used only when socket is not connected.
      // The server will emit new-message to others; we update our own bubble
      // from the REST response.
      try {
        final res = await ChatService.sendRoomMessage(
          token: _token!,
          roomId: widget.room.id,
          content: text,
          replyTo: replyRef?.id,
        );
        if (!mounted) return;
        if (res.success && res.data != null) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.tempId == tempId);
            if (idx != -1) _messages[idx] = res.data!;
          });
        }
      } catch (e) {
        if (mounted) {
          _showSnack(
            'Failed to send: ${e.toString().replaceFirst('Exception: ', '')}',
          );
          setState(() => _messages.removeWhere((m) => m.tempId == tempId));
        }
      } finally {
        if (mounted) setState(() => _isSendingText = false);
      }
    }
  }

  // ── Send media ──────────────────────────────────────────────────────────
  Future<void> _sendMedia(File file, String messageType) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final ext = file.path.split('.').last.toLowerCase();
    final optimistic = ChatMessage(
      id: tempId,
      chatRoom: widget.room.id,
      content: '[$messageType]',
      messageType: messageType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tempId: tempId,
    );
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final res = await ChatService.sendMediaMessage(
        token: _token!,
        roomId: widget.room.id,
        file: file,
        messageType: messageType,
        content: '[$ext file]',
      );
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.tempId == tempId);
          if (idx != -1) _messages[idx] = res.data!;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.tempId == tempId));
      _showSnack(
        'Failed to send: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  // ── Media picker ────────────────────────────────────────────────────────
  void _showMediaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MediaOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: Colors.blueAccent,
                onTap: () async {
                  Navigator.pop(context);
                  final xf = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (xf != null) await _sendMedia(File(xf.path), 'image');
                },
              ),
              _MediaOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: Colors.greenAccent,
                onTap: () async {
                  Navigator.pop(context);
                  final xf = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (xf != null) await _sendMedia(File(xf.path), 'image');
                },
              ),
              _MediaOption(
                icon: Icons.videocam_rounded,
                label: 'Video',
                color: Colors.orangeAccent,
                onTap: () async {
                  Navigator.pop(context);
                  final xf = await _imagePicker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (xf != null) await _sendMedia(File(xf.path), 'video');
                },
              ),
              _MediaOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'Document',
                color: AppTheme.primaryColor,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    await _sendMedia(
                      File(result.files.single.path!),
                      'document',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Group actions ─────────────────────────────────────────────────
  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Leave Group', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to leave "${widget.room.name}"?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ChatService.leaveGroup(token: _token!, groupId: widget.room.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnack(
        'Could not leave group: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _showGroupInfo() async {
    // Use participants already in the room model; optionally refresh from API
    final members = widget.room.participants;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, sc) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Text(
                widget.room.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                '${members.length} member${members.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
            const Divider(color: Color(0xFF1C1C1E), height: 1),
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: members.length,
                      itemBuilder: (_, i) {
                        final m = members[i];
                        final name = m.name;
                        final initials = () {
                          final p = name.trim().split(' ');
                          if (p.length >= 2) {
                            return '${p[0][0]}${p[1][0]}'.toUpperCase();
                          }
                          return name.isNotEmpty ? name[0].toUpperCase() : '?';
                        }();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: _avatarColor(name),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (m.position != null)
                                      Text(
                                        m.position!,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (m.id == _currentUserId)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'You',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  void _scrollToBottom({bool jump = false}) {
    // With reverse: true, the newest messages are at offset 0 (top of viewport)
    // and oldest messages are at maxScrollExtent (bottom of viewport).
    // So to auto-scroll when new messages arrive, we need to scroll to offset 0.
    const Duration delay = Duration(milliseconds: 50);
    // Use a short Timer so we run after ALL pending frames + layout are done.
    // A single post-frame can fire before ListView measures its content height;
    // 50 ms is imperceptible to the user but gives the layout pipeline time to
    // finish, making this reliable on both first-load and new-message arrivals.
    Timer(delay, () {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (!pos.hasContentDimensions) return;
      if (jump) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF1C1C1E)),
    );
  }

  Color _avatarColor(String name) {
    if (name.isEmpty) return const Color(0xFF8B2A3A);
    const c = [
      Color(0xFF8B2A3A),
      Color(0xFF9C1F4A),
      Color(0xFF7A1F5E),
      Color(0xFF6B2060),
      Color(0xFFAD2550),
    ];
    return c[name.codeUnitAt(0) % c.length];
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final displayName = widget.room.type == 'personal'
        ? (widget.room.otherUser?.name ?? widget.room.name)
        : widget.room.name;
    final otherUserId = widget.room.otherUser?.id;
    final isPersonal = widget.room.type == 'personal';
    final isOtherOnline =
        isPersonal &&
        otherUserId != null &&
        (_onlineUsers[otherUserId] ?? false);
    final subTitle = isPersonal
        ? (isOtherOnline ? 'Online' : 'Offline')
        : '${widget.room.participants.length} members';
    final subColor = isPersonal
        ? (isOtherOnline ? Colors.greenAccent : Colors.grey[500])
        : Colors.grey[500];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                _RoomAvatar(
                  name: displayName,
                  isGroup: widget.room.isGroup,
                  isPersonal: isPersonal,
                  size: 36,
                ),
                if (isPersonal)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: isOtherOnline
                            ? Colors.greenAccent
                            : Colors.grey[600],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F0F0F),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_someoneTyping)
                    Text(
                      '$_typingUserName is typing...',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      subTitle,
                      style: TextStyle(color: subColor, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.room.isGroup)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
              color: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                if (val == 'info') _showGroupInfo();
                if (val == 'leave') _leaveGroup();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Group Info',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.exit_to_app_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Leave Group',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Older-messages loader
          if (_isLoadingOlder)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF0F0F0F),
              color: AppTheme.primaryColor,
            ),

          // Messages
          Expanded(child: _buildMessages()),

          // Reply preview
          if (_replyTo != null) _buildReplyBar(),

          // Input
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Message area ─────────────────────────────────────────────────────────
  Widget _buildMessages() {
    // if (_isLoading) {
    //   return const Center(
    //     child: CircularProgressIndicator(color: AppTheme.primaryColor),
    //   );
    // }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[600], size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadMessages(initial: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello! 👋',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      reverse: true, // 👈 Bottom-to-top messaging: newest at top, oldest at bottom
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length + (_someoneTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing bubble at the very end
        if (_someoneTyping && index == _messages.length) {
          return _TypingBubble(name: _typingUserName);
        }
        final msg = _messages[index];
        // Show date separator
        final showDate =
            index == 0 ||
            !_isSameDay(_messages[index - 1].createdAt, msg.createdAt);
        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.createdAt),
            _buildSwipeable(msg),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Swipe-to-reply wrapper (smooth drag, not snap)
  Widget _buildSwipeable(ChatMessage msg) {
    return _SwipeToReplyWrapper(
      onReply: () => setState(() => _replyTo = msg),
      child: _buildBubble(msg),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMine =
        msg.sender?.id == _currentUserId || (msg.isTemp && msg.sender == null);
    final timeStr = DateFormat('hh:mm a').format(msg.createdAt.toLocal());
    final senderName =
        msg.sender?.name ??
        (widget.room.type == 'personal'
            ? (widget.room.otherUser?.name ?? widget.room.name)
            : widget.room.name);

    return GestureDetector(
      onLongPress: () => _showBubbleMenu(msg),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 4,
          left: isMine ? 60 : 0,
          right: isMine ? 0 : 60,
        ),
        child: Row(
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              _RoomAvatar(name: senderName, size: 26),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMine && widget.room.isGroup)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Bubble
                  Container(
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppTheme.primaryColor
                          : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply quote
                        if (msg.replyTo != null)
                          _ReplyQuote(reply: msg.replyTo!, isMine: isMine),

                        // Content
                        if (msg.isDeleted)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Text(
                              'This message was deleted',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else if (msg.messageType == 'image' &&
                            msg.attachment?.url != null)
                          _ImageBubble(url: msg.attachment!.url)
                        else if (msg.messageType == 'document' &&
                            msg.attachment != null)
                          _DocumentBubble(
                            attachment: msg.attachment!,
                            isMine: isMine,
                          )
                        else if (msg.messageType == 'video' &&
                            msg.attachment?.url != null)
                          _VideoBubble(url: msg.attachment!.url, isMine: isMine)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Text(
                              msg.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.grey[700], fontSize: 10),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isTemp
                              ? Icons.access_time
                              : (msg.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded),
                          size: 12,
                          color: msg.isRead
                              ? Colors.blueAccent
                              : Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBubbleMenu(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (!msg.isDeleted) ...[
              _MenuTile(
                icon: Icons.reply_rounded,
                label: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyTo = msg);
                },
              ),
              _MenuTile(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: msg.content));
                  _showSnack('Copied to clipboard');
                },
              ),
              if (msg.sender?.id == _currentUserId)
                _MenuTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(msg);
                  },
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Delete message ────────────────────────────────────────────────────────
  void _confirmDeleteMessage(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this message?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(msg);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    try {
      await ChatService.deleteMessage(token: _token!, messageId: msg.id);
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(isDeleted: true);
          }
        });
        _showSnack('Message deleted');
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to delete message');
    }
  }

  // ── Reply bar ─────────────────────────────────────────────────────────────
  Widget _buildReplyBar() {
    return Container(
      color: const Color(0xFF0F0F0F),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyTo!.sender?.name ?? 'You',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _replyTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[500], size: 18),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF0F0F0F),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              Icons.attach_file_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
            onPressed: _showMediaSheet,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isSendingText
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

/// Smooth swipe-to-reply: drag right slowly, icon fades in, snaps back.
class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  const _SwipeToReplyWrapper({required this.child, required this.onReply});

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _triggered = false;
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  static const double _triggerAt = 72.0;
  static const double _maxDrag = 88.0;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_snapCtrl.isAnimating) return;
    setState(() {
      _dragOffset = (_dragOffset + d.delta.dx).clamp(0.0, _maxDrag);
    });
    if (!_triggered && _dragOffset >= _triggerAt) {
      _triggered = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _triggered = false;
    _snapAnim = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
    )..addListener(() => setState(() => _dragOffset = _snapAnim.value));
    _snapCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / _triggerAt).clamp(0.0, 1.0);
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Reply icon fades/scales in as drag progresses
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * progress,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Message bubble slides slowly
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _RoomAvatar extends StatefulWidget {
  final String name;
  final bool isGroup;
  final bool isPersonal;
  final double size;

  const _RoomAvatar({
    required this.name,
    this.isGroup = false,
    this.isPersonal = false,
    this.size = 40,
  });

  @override
  State<_RoomAvatar> createState() => _RoomAvatarState();
}

class _RoomAvatarState extends State<_RoomAvatar> {
  bool _pressed = false;

  String _initials(String n) {
    final p = n.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  Color _avatarColor(String n) {
    if (n.isEmpty) return const Color(0xFF8B2A3A);
    const c = [
      Color(0xFF8B2A3A),
      Color(0xFF9C1F4A),
      Color(0xFF7A1F5E),
      Color(0xFF6B2060),
      Color(0xFFAD2550),
    ];
    return c[n.codeUnitAt(0) % c.length];
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = widget.size * 0.38;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _avatarColor(widget.name),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(widget.name),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.size * 0.35,
                  ),
                ),
              ),
            ),
            if (widget.isGroup)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F0F0F),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.group,
                    size: badgeSize * 0.6,
                    color: Colors.white70,
                  ),
                ),
              ),
            if (widget.isPersonal)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F0F0F),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: badgeSize * 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatefulWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  State<_DateDivider> createState() => _DateDividerState();
}

class _DateDividerState extends State<_DateDivider> {
  String _label() {
    final now = DateTime.now();
    final d = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(widget.date);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[800], thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            _label(),
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[800], thickness: 0.5)),
      ],
    ),
  );
}

class _TypingBubble extends StatefulWidget {
  final String name;
  const _TypingBubble({required this.name});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
    child: Row(
      children: [
        const SizedBox(width: 32),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [_Dot(delay: 0), _Dot(delay: 200), _Dot(delay: 400)],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Colors.grey[500],
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class _ReplyQuote extends StatefulWidget {
  final ChatReplyMessage reply;
  final bool isMine;
  const _ReplyQuote({required this.reply, required this.isMine});

  @override
  State<_ReplyQuote> createState() => _ReplyQuoteState();
}

class _ReplyQuoteState extends State<_ReplyQuote> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _expanded = !_expanded),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppTheme.primaryColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.reply.senderName != null)
            Text(
              widget.reply.senderName!,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            widget.reply.content,
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ImageBubble extends StatefulWidget {
  final String url;
  const _ImageBubble({required this.url});

  @override
  State<_ImageBubble> createState() => _ImageBubbleState();
}

class _ImageBubbleState extends State<_ImageBubble> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _fullScreen = false;
  bool _isSaving = false;

  final _media = ChatMediaService();

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _media.downloadMedia(widget.url, 'images');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbW = 200.0;
    final thumbH = 200.0;
    final fullW = screenWidth * 0.85;

    return GestureDetector(
      onTap: () => setState(() => _fullScreen = !_fullScreen),
      onLongPress: _saveToGallery,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _hasError
            ? Container(
                width: thumbW,
                height: thumbH,
                color: const Color(0xFF2C2C2E),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 36,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Failed to load',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    widget.url,
                    width: _fullScreen ? fullW : thumbW,
                    height: _fullScreen ? null : thumbH,
                    fit: _fullScreen ? BoxFit.contain : BoxFit.cover,
                    errorBuilder: (ctx, err, st) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (ts) {
                          if (mounted) setState(() => _hasError = true);
                        },
                      );
                      return SizedBox(width: thumbW, height: thumbH);
                    },
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) {
                        if (_isLoading) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _isLoading = false);
                          });
                        }
                        return child;
                      }
                      return child;
                    },
                  ),
                  if (_isLoading)
                    Container(
                      width: thumbW,
                      height: thumbH,
                      color: const Color(0xFF2C2C2E),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  // Saving overlay
                  if (_isSaving)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Download/save button (shown after image loads)
                  if (!_isLoading && !_hasError && !_isSaving)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: _saveToGallery,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _DocumentBubble extends StatefulWidget {
  final ChatAttachment attachment;
  final bool isMine;
  const _DocumentBubble({required this.attachment, required this.isMine});

  @override
  State<_DocumentBubble> createState() => _DocumentBubbleState();
}

class _DocumentBubbleState extends State<_DocumentBubble> {
  bool _pressed = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  final _media = ChatMediaService();

  Future<void> _downloadAndOpen() async {
    if (_isDownloading) return;
    final url = widget.attachment.url;
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document URL is not available')),
        );
      }
      return;
    }
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    try {
      // Ensure media service is ready
      await _media.init();

      // Use cache if available, otherwise download
      String? cachedPath = _media.getCachedPath(url, 'documents');
      if (cachedPath == null) {
        cachedPath = await _media.downloadMedia(
          url,
          'documents',
          onProgress: (p) {
            if (mounted) setState(() => _downloadProgress = p);
          },
        );
      }
      if (cachedPath.isEmpty) {
        throw Exception('Download returned empty path');
      }
      await _media.openFile(cachedPath);
    } catch (e) {
      debugPrint('Document open error: $e');
      if (mounted) {
        _showDownloadFailedSheet(url, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showDownloadFailedSheet(String url, String error) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Could not open document',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Download failed. You can open it in your browser instead.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _media.openUrlInBrowser(url);
                  },
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Open in Browser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadAndOpen(); // retry
                  },
                  child: Text(
                    'Retry Download',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _downloadAndOpen,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isDownloading
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            strokeWidth: 2.5,
                            color: widget.isMine
                                ? Colors.white70
                                : AppTheme.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.insert_drive_file_rounded,
                          key: ValueKey(_pressed),
                          color: widget.isMine
                              ? (_pressed ? Colors.white : Colors.white70)
                              : (_pressed ? Colors.white70 : Colors.grey[400]),
                          size: 28,
                        ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.attachment.name ?? 'Document',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.attachment.mimeType != null)
                        Text(
                          widget.attachment.mimeType!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isDownloading && _downloadProgress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoBubble extends StatefulWidget {
  final String url;
  final bool isMine;
  const _VideoBubble({required this.url, required this.isMine});

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  bool _pressed = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  final _media = ChatMediaService();

  Future<void> _downloadAndPlay() async {
    if (_isDownloading) return;
    final url = widget.url;
    if (url.isEmpty) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    try {
      await _media.init();

      // Use cache if available, otherwise download
      String? cachedPath = _media.getCachedPath(url, 'videos');
      if (cachedPath == null) {
        cachedPath = await _media.downloadMedia(
          url,
          'videos',
          onProgress: (p) {
            if (mounted) setState(() => _downloadProgress = p);
          },
        );
      }
      await _media.openFile(cachedPath);
    } catch (e) {
      debugPrint('Video play error: $e');
      if (mounted) {
        // Offer to open in browser as fallback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to play video. Opening in browser…'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => _media.openUrlInBrowser(url),
            ),
          ),
        );
        _media.openUrlInBrowser(url);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _downloadAndPlay,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 200,
        height: 130,
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFF3A3A3C) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _pressed ? 0.88 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Icon(
                    _isDownloading
                        ? Icons.hourglass_top_rounded
                        : Icons.play_circle_fill_rounded,
                    color: _isDownloading
                        ? Colors.white38
                        : AppTheme.primaryColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isDownloading ? 'Downloading...' : 'Video',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            // Progress ring overlay while downloading
            if (_isDownloading)
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  strokeWidth: 3,
                  backgroundColor: Colors.white12,
                  color: AppTheme.primaryColor,
                ),
              ),
            // Progress bar at bottom
            if (_isDownloading && _downloadProgress > 0)
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MediaOption> createState() => _MediaOptionState();
}

class _MediaOptionState extends State<_MediaOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _pressed
                    ? widget.color.withValues(alpha: 0.30)
                    : widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.color ?? Colors.white70, size: 22),
            const SizedBox(width: 16),
            Text(
              widget.label,
              style: TextStyle(color: widget.color ?? Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
// ─── New Chat Sheet with live search ────────────────────────────────────────

class _NewChatSheet extends StatefulWidget {
  final String token;
  final void Function(ChatRoom room) onUserSelected;

  const _NewChatSheet({required this.token, required this.onUserSelected});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<ChatUser> _allUsers = []; // full list
  List<ChatUser> _filtered = []; // shown list
  bool _loadingUsers = true; // initial fetch
  bool _searching = false; // debounced server search
  String? _loadError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _loadError = null;
    });
    try {
      final res = await ChatService.getCompanyUsers(token: widget.token);
      if (!mounted) return;
      setState(() {
        _allUsers = res.data;
        _filtered = res.data;
        _loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loadingUsers = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    // Instant client-side filter
    setState(() {
      _filtered = q.isEmpty
          ? _allUsers
          : _allUsers
                .where(
                  (u) =>
                      u.name.toLowerCase().contains(q.toLowerCase()) ||
                      (u.position ?? '').toLowerCase().contains(
                        q.toLowerCase(),
                      ) ||
                      u.email.toLowerCase().contains(q.toLowerCase()),
                )
                .toList();
    });
    // Server-side search for more complete results (debounced 400ms)
    if (q.length >= 2) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        setState(() => _searching = true);
        try {
          final res = await ChatService.searchUsers(
            token: widget.token,
            query: q,
          );
          if (!mounted) return;
          setState(() => _filtered = res.data);
        } catch (_) {
          // Keep client-side filter result on error
        } finally {
          if (mounted) setState(() => _searching = false);
        }
      });
    }
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    if (name.isEmpty) return const Color(0xFF8B2A3A);
    const c = [
      Color(0xFF8B2A3A),
      Color(0xFF9C1F4A),
      Color(0xFF7A1F5E),
      Color(0xFF6B2060),
      Color(0xFFAD2550),
    ];
    return c[name.codeUnitAt(0) % c.length];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, sc) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Header ────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Start New Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // ── Search bar (hidden while loading) ─────────────────────────
          if (!_loadingUsers)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or position...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : (_searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[600],
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _filtered = _allUsers);
                                  },
                                )
                              : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          // ── Result count ──────────────────────────────────────────────
          if (!_loadingUsers && _loadError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                _searchCtrl.text.isEmpty
                    ? '${_filtered.length} colleagues'
                    : '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: _loadingUsers
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadUsers,
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search,
                          color: Colors.grey[700],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchCtrl.text.isEmpty
                              ? 'No colleagues found'
                              : 'No results for "${_searchCtrl.text}"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            final roomRes =
                                await ChatService.getOrCreatePersonalChat(
                                  token: widget.token,
                                  userId: u.id,
                                );
                            widget.onUserSelected(roomRes.data);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not open chat: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: _avatarColor(u.name),
                                child: Text(
                                  _initials(u.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (u.position != null) ...[
                                          Text(
                                            u.position!,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            ' · ',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                        Flexible(
                                          child: Text(
                                            u.department ?? u.role,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
