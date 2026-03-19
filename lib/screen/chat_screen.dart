import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/chat/data/models/chat_room_model.dart';
import 'package:hrms_app/features/chat/data/services/chat_service.dart';
import 'package:hrms_app/shared/services/communication/chat_socket_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/services/chat_media_service.dart';
// import 'chat_api_test_screen.dart';

// ─── Chat List Screen ─────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String? recipientId;

  const ChatScreen({super.key, this.recipientId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _socket = ChatSocketService();
  final List<StreamSubscription<dynamic>> _subs = [];
  final _storage = TokenStorageService();

  List<ChatRoom> _allRooms = [];
  List<ChatRoom> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String? _token;
  String? _userRole; // 'employee', 'admin', or 'hr'

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadRooms();
    _initSocket();
  }

  Future<void> _loadUserRole() async {
    _userRole = await _storage.getUserRole();
    if (mounted) setState(() {});
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
        _filtered = _allRooms.where((room) {
          // Search by room name
          if (room.name.toLowerCase().contains(searchTerm)) return true;
          // Search by other user's name (for personal chats)
          if (room.otherUser?.name.toLowerCase().contains(searchTerm) ??
              false) {
            return true;
          }
          // Search by last message content
          if (room.lastMessage?.content.toLowerCase().contains(searchTerm) ??
              false) {
            return true;
          }
          return false;
        }).toList();
      }
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt.toLocal());
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Get display ID for a user (Employee ID, HR ID, Admin ID, or fallback)
  String _getDisplayUserId(ChatParticipant? user) {
    if (user == null) return 'Unknown';
    return user.getDisplayId();
  }

  /// Get ID prefix label (EMP, HR, ADM, etc.)
  String _getIdPrefix(ChatParticipant? user) {
    if (user == null) return 'USR';
    return user.getIdPrefix();
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
          if (_userRole == 'admin' || _userRole == 'hr')
            IconButton(
              icon: const Icon(Icons.group_add, color: Colors.white, size: 22),
              onPressed: _showCreateGroupDialog,
              tooltip: 'Create Group',
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
    // For personal rooms display user ID; group rooms use room.name
    final isPersonal = room.type == 'personal';
    final displayName = isPersonal
        ? (_getDisplayUserId(room.otherUser) +
              ' (${_getIdPrefix(room.otherUser)})')
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

  void _showCreateGroupDialog() async {
    final token = _token ?? await TokenStorageService().getToken();
    if (token == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => _CreateGroupDialog(
        token: token,
        onGroupCreated: () {
          Navigator.pop(context);
          _loadRooms();
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
  String? _userRole; // 'employee', 'admin', or 'hr'

  // Online status: userId -> isOnline
  final Map<String, bool> _onlineUsers = {};

  // Reply / forward state
  ChatMessage? _replyTo;

  // Typing indicator
  bool _someoneTyping = false;
  String _typingUserName = '';
  String _typingUserId = '';
  String _typingUserIdPrefix = '';
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
    ChatDetailScreen.visibleRoomId = widget.room.id;
    NotificationService.activeChatRoomId = widget.room.id; // suppress FCM while open
    _init();
  }

  @override
  void dispose() {
    if (ChatDetailScreen.visibleRoomId == widget.room.id) {
      ChatDetailScreen.visibleRoomId = null;
      NotificationService.activeChatRoomId = null;
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
    _userRole = await _storage.getUserRole();
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
        // FIX: API ke data ko reverse karna zaroori hai taki newest message index 0 par aaye
        _messages = res.data.reversed.toList();
        _hasMore = res.hasMore;
      });
      
      // DEBUG: Log loaded messages
      if (initial) {
        print('═══════════════════════════════════════════════════════════');
        print('📥 INITIAL MESSAGES LOADED: ${_messages.length} messages');
        if (_messages.isNotEmpty) {
          for (int i = 0; i < (_messages.length > 5 ? 5 : _messages.length); i++) {
            final m = _messages[i];
            final preview = m.content.length > 40 ? m.content.substring(0, 40) : m.content;
            print('   [$i] ID: ${m.id} | ${m.sender?.name ?? "Unknown"}: $preview...');
          }
          if (_messages.length > 5) print('   ... and ${_messages.length - 5} more');
        }
        print('═══════════════════════════════════════════════════════════');
      }
      
      _scrollToBottom(jump: true);
      _socket.markRead(widget.room.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (!_hasMore || _isLoadingOlder || _messages.isEmpty) return;
    setState(() => _isLoadingOlder = true);
    try {
      // Kyunki list reversed hai, oldest message ab list ke last mein hoga
      final oldest = _messages.last.createdAt.toUtc().toIso8601String();
      final res = await ChatService.getRoomMessages(
        token: _token!,
        roomId: widget.room.id,
        limit: 30,
        before: oldest,
      );
      if (!mounted) return;

      // FIX: Purane messages ko bhi reverse karein aur list ke end me (addAll) jod dein
      final olderReversed = res.data.reversed.toList();
      final prevHeight = _scrollController.position.extentTotal;
      setState(() {
        _messages.addAll(olderReversed);
        _hasMore = res.hasMore;
        _isLoadingOlder = false;
      });
      // Scroll position ko maintain rakhne ke liye
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
        if (msg.chatRoom != widget.room.id) return;
        if (msg.sender?.id == _currentUserId) return;
        
        // DEDUPLICATION: Check by message ID
        final isDuplicate = _messages.any((m) => m.id == msg.id);
        if (isDuplicate) {
          print('⚠️ DUPLICATE CHAT MESSAGE BLOCKED - ID: ${msg.id}');
          print('   Message: ${msg.content}');
          print('   Sender: ${msg.sender?.name}');
          return;
        }

        // FIX: Naye message ko list ke top (index 0) par daalein taki bottom me dikhe
        print('✅ NEW SOCKET MESSAGE ADDED - ID: ${msg.id}');
        print('   Message: ${msg.content}');
        print('   Total messages: ${_messages.length + 1}');
        setState(() => _messages.insert(0, msg));
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
        // Try to get user info from room participants
        final participant = widget.room.participants.firstWhere(
          (p) => p.id == evt.userId,
          orElse: () =>
              ChatParticipant(id: evt.userId, name: evt.userName, email: ''),
        );
        setState(() {
          _someoneTyping = true;
          _typingUserName = evt.userName;
          _typingUserId = participant.getDisplayId();
          _typingUserIdPrefix = participant.getIdPrefix();
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
    // Jab optimistic banate hain (baaki upar ka same rakhein)
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
    // FIX: Naye bhejey gaye message ko zero index par insert karein
    setState(() => _messages.insert(0, optimistic));
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
    // Jab media optimistic banate hain (baaki upar ka same rakhein)
    final optimistic = ChatMessage(
      id: tempId,
      chatRoom: widget.room.id,
      content: '[$messageType]',
      messageType: messageType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tempId: tempId,
    );
    // FIX: insert use karein
    setState(() => _messages.insert(0, optimistic));
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
                  PlatformFile? picked;
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      picked = result.files.single;
                    }
                  } catch (e) {
                    if (mounted) _showSnack('Could not open file picker');
                    return;
                  }
                  if (picked == null) return;

                  File? fileToSend;
                  if (picked.path != null) {
                    fileToSend = File(picked.path!);
                  } else if (picked.bytes != null) {
                    // Cloud-based file (Google Drive, iCloud, etc.) has no
                    // local path — write bytes to a temp file before sending.
                    try {
                      final tmpDir = await getTemporaryDirectory();
                      final safeName = picked.name
                          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
                      final tmp = File('${tmpDir.path}/$safeName');
                      await tmp.writeAsBytes(picked.bytes!);
                      fileToSend = tmp;
                    } catch (e) {
                      if (mounted) {
                        _showSnack(
                          'Could not read file. Please pick a local file.',
                        );
                      }
                      return;
                    }
                  } else {
                    if (mounted) {
                      _showSnack(
                        'Could not access the selected file. Please pick a local file.',
                      );
                    }
                    return;
                  }

                  if (mounted) {
                    await _sendMedia(fileToSend, 'document');
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

  Future<void> _showAddMemberDialog() async {
    final groupId = widget.room.id;
    List<ChatUser> allUsers = [];
    List<ChatUser> filtered = [];
    final searchCtrl = TextEditingController();

    try {
      final res = await ChatService.getCompanyUsers(token: _token!);
      allUsers = res.data;
      filtered = res.data;
    } catch (e) {
      _showSnack(
        'Failed to load users: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF3C3C3E), height: 1),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (q) {
                    final query = q.toLowerCase();
                    setState(() {
                      filtered = query.isEmpty
                          ? allUsers
                          : allUsers
                                .where(
                                  (u) =>
                                      u.name.toLowerCase().contains(query) ||
                                      u.email.toLowerCase().contains(query),
                                )
                                .toList();
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // User list
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final user = filtered[i];
                    return ListTile(
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        user.position ?? user.role,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addGroupMember(groupId, user.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addGroupMember(String groupId, String userId) async {
    try {
      await ChatService.addGroupMember(
        token: _token!,
        groupId: groupId,
        userId: userId,
      );
      if (!mounted) return;
      _showSnack('Member added successfully');
    } catch (e) {
      _showSnack(
        'Failed to add member: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  Future<void> _showDeleteGroupConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Delete Group',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.room.name}"? This action cannot be undone.',
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
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _deleteGroup();
  }

  Future<void> _deleteGroup() async {
    try {
      await ChatService.deleteGroup(token: _token!, groupId: widget.room.id);
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Group deleted successfully');
    } catch (e) {
      _showSnack(
        'Failed to delete group: ${e.toString().replaceFirst('Exception: ', '')}',
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
                                      m.getDisplayId() +
                                          ' (${m.getIdPrefix()})',
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

  /// Get display ID for a sender (Employee ID, HR ID, Admin ID, or fallback)
  String _getSenderDisplayId(ChatMessageSender? sender) {
    if (sender == null) return 'Unknown';
    return sender.getDisplayId();
  }

  /// Get ID prefix label (EMP, HR, ADM, etc.)
  String _getSenderIdPrefix(ChatMessageSender? sender) {
    if (sender == null) return 'USR';
    return sender.getIdPrefix();
  }

  /// Get display ID for a user (Employee ID, HR ID, Admin ID, or fallback)
  String _getDisplayUserId(ChatParticipant? user) {
    if (user == null) return 'Unknown';
    return user.getDisplayId();
  }

  /// Get ID prefix label (EMP, HR, ADM, etc.)
  String _getIdPrefix(ChatParticipant? user) {
    if (user == null) return 'USR';
    return user.getIdPrefix();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final displayName = widget.room.type == 'personal'
        ? (_getDisplayUserId(widget.room.otherUser) +
              ' (${_getIdPrefix(widget.room.otherUser)})')
        : widget.room.name;
    final otherUserId = widget.room.otherUser?.id;
    final isPersonal = widget.room.type == 'personal';
    final isOtherOnline =
        isPersonal &&
        otherUserId != null &&
        (_onlineUsers[otherUserId] ?? false);

    // Use role-aware subtitle
    final subTitle = _getSubtitleByRole();
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
                  // Display name with role badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role badge
                      if (_userRole != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _userRole == 'admin'
                                ? Colors.red.withOpacity(0.3)
                                : _userRole == 'employee'
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _userRole == 'admin'
                                  ? Colors.red.withOpacity(0.6)
                                  : _userRole == 'employee'
                                  ? Colors.blue.withOpacity(0.6)
                                  : Colors.orange.withOpacity(0.6),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _userRole?.toUpperCase() ?? '',
                            style: TextStyle(
                              color: _userRole == 'admin'
                                  ? Colors.red
                                  : _userRole == 'employee'
                                  ? Colors.blue
                                  : Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_someoneTyping)
                    Text(
                      '$_typingUserId ($_typingUserIdPrefix) is typing...',
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
                if (val == 'add_member') _showAddMemberDialog();
                if (val == 'delete') _showDeleteGroupConfirm();
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
                if (_userRole == 'admin') ...[
                  PopupMenuItem(
                    value: 'add_member',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_add_rounded,
                          color: Colors.lightBlueAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Add Member',
                          style: TextStyle(color: Colors.lightBlueAccent),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Delete Group',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
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

  // ── Role-based subtitle ────────────────────────────────────────────────────
  /// Returns the subtitle text based on user role and online status
  String _getSubtitleByRole() {
    if (widget.room.type == 'personal') {
      final otherUserId = widget.room.otherUser?.id;
      final isOtherOnline =
          otherUserId != null && (_onlineUsers[otherUserId] ?? false);

      String baseStatus = isOtherOnline ? 'Online' : 'Offline';

      // Add role info to subtitle for admins
      if (_userRole == 'admin') {
        return '$baseStatus • Admin Chat';
      } else if (_userRole == 'employee') {
        return '$baseStatus • Employee Chat';
      } else if (_userRole == 'hr') {
        return '$baseStatus • HR Chat';
      }

      return baseStatus;
    } else {
      String groupInfo = '${widget.room.participants.length} members';

      if (_userRole == 'admin') {
        return '$groupInfo • Admin Group';
      } else if (_userRole == 'employee') {
        return '$groupInfo • Employee Group';
      }

      return groupInfo;
    }
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
      reverse: true, // 👈 Bottom-to-top messaging
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length + (_someoneTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // FIX 1: Typing indicator hamesha sabse niche (index 0) hona chahiye
        if (_someoneTyping && index == 0) {
          return _TypingBubble(name: '$_typingUserId ($_typingUserIdPrefix)');
        }

        // FIX 2: Agar koi type kar raha hai, toh message ka index 1 se start hoga
        final msgIndex = _someoneTyping ? index - 1 : index;
        final msg = _messages[msgIndex];

        // FIX 3: Date separator ab list reverse hone ke karan theek se show hoga
        final showDate =
            msgIndex == _messages.length - 1 ||
            !_isSameDay(_messages[msgIndex + 1].createdAt, msg.createdAt);

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
    final senderDisplayId = msg.sender != null
        ? (_getSenderDisplayId(msg.sender) +
              ' (${_getSenderIdPrefix(msg.sender)})')
        : (widget.room.type == 'personal'
              ? (_getDisplayUserId(widget.room.otherUser) +
                    ' (${_getIdPrefix(widget.room.otherUser)})')
              : widget.room.name);
    final senderName = msg.sender?.name ?? widget.room.name;

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
                        senderDisplayId,
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
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(color: Colors.white70),
        ),
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
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
              widget.reply.getDisplayId() + ' (${widget.reply.getIdPrefix()})',
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
  String? _localPath; // Cached local file path for auth-required images

  final _media = ChatMediaService();

  @override
  void initState() {
    super.initState();
    // If Image.network might fail (non-CDN URL), pre-download with auth
    _tryAuthDownload();
  }

  /// For URLs that may need authentication, download to local cache first.
  Future<void> _tryAuthDownload() async {
    // First check if url is a CDN url (public) — Image.network will work fine
    if (_media.isCdnUrl(widget.url)) return;

    // Non-CDN url: download with auth to local cache
    try {
      await _media.init();
      final path = await _media.downloadMedia(widget.url, 'images');
      if (mounted && path.isNotEmpty) {
        setState(() {
          _localPath = path;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Image auth download failed: $e');
      // Let Image.network try as fallback
    }
  }

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

    // If we have a locally-cached version, use Image.file instead
    Widget imageWidget;
    if (_localPath != null) {
      imageWidget = Image.file(
        File(_localPath!),
        width: _fullScreen ? fullW : thumbW,
        height: _fullScreen ? null : thumbH,
        fit: _fullScreen ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (ctx, err, st) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hasError = true);
          });
          return SizedBox(width: thumbW, height: thumbH);
        },
      );
    } else {
      imageWidget = Image.network(
        widget.url,
        width: _fullScreen ? fullW : thumbW,
        height: _fullScreen ? null : thumbH,
        fit: _fullScreen ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (ctx, err, st) {
          debugPrint('Image.network error for: ${widget.url} — $err');
          // On error, try authenticated download as fallback
          if (_localPath == null && !_hasError) {
            _tryAuthDownload().then((_) {
              if (_localPath == null && mounted) {
                setState(() => _hasError = true);
              }
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _localPath == null) {
              setState(() => _hasError = true);
            }
          });
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
      );
    }

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
                  imageWidget,
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
  bool _isOpening = false;
  double _downloadProgress = 0.0;

  final _media = ChatMediaService();

  Future<void> _downloadAndOpen() async {
    if (_isDownloading) return;
    var url = widget.attachment.url;
    if (url.isEmpty) {
      if (mounted) {
        // Show helpful error dialog with debugging info
        final hasPublicId = widget.attachment.publicId != null &&
                            widget.attachment.publicId!.isNotEmpty;
        final fileName = widget.attachment.name ?? 'Document';

        debugPrint('❌ [CHAT] PDF Download Attempted - URL Empty');
        debugPrint('   File: $fileName');
        debugPrint('   Size: ${widget.attachment.size} bytes');
        debugPrint('   MIME: ${widget.attachment.mimeType}');
        debugPrint('   Public ID: ${widget.attachment.publicId ?? "MISSING"}');

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ File Not Ready'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The file URL is missing from the server response.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This could mean:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildErrorPoint('Backend Cloudinary upload might have failed'),
                  _buildErrorPoint('Environment variables not configured (CLOUDINARY_*)'),
                  _buildErrorPoint('Network interruption during upload'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'File Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('Name', fileName),
                        if (hasPublicId)
                          _buildDetailRow('Public ID', widget.attachment.publicId!),
                        _buildDetailRow('Size', _formatBytes(widget.attachment.size ?? 0)),
                        _buildDetailRow('Type', widget.attachment.mimeType ?? 'Unknown'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _downloadAndOpen(); // Retry
                },
                child: const Text('Try Again'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        );
      }
      return;
    }
    // Fix common Cloudinary URL typos (e.g. /iimage/ → /image/)
    if (url.contains('cloudinary.com')) {
      url = url
          .replaceAll('/iimage/', '/image/')
          .replaceAll('/image/uploadd/', '/image/upload/')
          .replaceAll('/video/uploadd/', '/video/upload/')
          .replaceAll('/raw/uploadd/', '/raw/upload/')
          .replaceAll('/auto/uploadd/', '/auto/upload/');
    }
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    final attachmentName = widget.attachment.name;
    try {
      // Ensure media service is ready
      await _media.init();
      // Use cache if available, otherwise download
      String? cachedPath = _media.getCachedPath(url, 'documents', fileName: attachmentName);
      if (cachedPath == null || !File(cachedPath).existsSync()) {
        cachedPath = await _media.downloadMedia(
          url,
          'documents',
          fileName: attachmentName,
          onProgress: (p) {
            if (mounted) {
              setState(() => _downloadProgress = p.clamp(0.0, 1.0));
            }
          },
        );
      }
      if (cachedPath.isEmpty) {
        throw Exception('Download returned empty path');
      }
      // Small delay so the user can see download completion
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) setState(() {_isDownloading = false; _isOpening = true;});

      // Check if file is PDF
      final fileName = widget.attachment.name ?? 'Document';
      final isPdf = fileName.toLowerCase().endsWith('.pdf') ||
                    widget.attachment.mimeType?.contains('pdf') == true;

      if (isPdf && mounted) {
        // For PDFs: Open in browser (safest, no GPU issues)
        // This avoids Syncfusion viewer which has GPU compatibility problems
        debugPrint('📄 [PDF] Opening in browser to avoid GPU issues');
        debugPrint('   File: $fileName');
        debugPrint('   URL: $url');

        if (url.isNotEmpty) {
          // Open in browser (best compatibility)
          _media.openUrlInBrowser(url);
        } else {
          // No URL available, try to open downloaded file
          await _media.openFile(
            cachedPath,
            mimeTypeOverride: 'application/pdf',
          );
        }
      } else {
        // For non-PDF files, try opening with external app
        await _media.openFile(
          cachedPath,
          fallbackUrl: url,
          mimeTypeOverride: widget.attachment.mimeType,
        );
      }
      if (mounted) setState(() => _isOpening = false);
    } catch (e) {
      debugPrint('Document open error: $e');
      if (mounted) {
        setState(() { _isDownloading = false; _isOpening = false; });
        _showDownloadFailedSheet(url, e.toString(), fileName: attachmentName);
      }
    }
  }

  void _showDownloadFailedSheet(String url, String error, {String? fileName}) {
    // Determine the specific error type
    final isBrowserError = error.contains('Browser') || error.contains('browser');
    final isNoAppError = error.contains('No app found') || error.contains('no app');
    
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
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
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
                isNoAppError 
                  ? 'No PDF reader app installed. Try opening in browser.'
                  : isBrowserError
                  ? 'Browser launch failed. Try downloading directly.'
                  : 'Download or open failed. Try again or use browser.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Error: ${error.length > 80 ? error.substring(0, 80) + "..." : error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              // Option 1: Open in Browser
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final browserUrl = ChatMediaService.buildBrowserViewUrl(
                      url,
                      fileName: fileName,
                      mimeType: widget.attachment.mimeType,
                    );
                    debugPrint('🌐 Opening browser: $browserUrl');
                    _media.openUrlInBrowser(browserUrl);
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
              // Option 2: Retry Download
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _downloadAndOpen(); // retry
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Option 3: Copy URL (advanced option)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy URL'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
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
                  child: (_isDownloading || _isOpening)
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: _isDownloading && _downloadProgress > 0
                                ? _downloadProgress
                                : null,
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
                      if (widget.attachment.mimeType != null && !_isOpening)
                        Text(
                          widget.attachment.mimeType!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      if (_isOpening)
                        Text(
                          'Opening…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
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

  /// Build a single error point bullet
  Widget _buildErrorPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  /// Build a detail row for file info
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Format bytes to human readable size
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = (bytes.toString().length / 3).ceil();
    if (i == 0) i = 1;
    double size = bytes / (1024 * (i - 1).toDouble());
    return '${size.toStringAsFixed(2)} ${suffixes[i - 1]}';
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
              style: TextStyle(
                color: widget.color ?? Colors.white,
                fontSize: 14,
              ),
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
                                      u.getDisplayId() +
                                          ' (${u.getIdPrefix()})',
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

// ─── Create Group Dialog ──────────────────────────────────────────────────────

class _CreateGroupDialog extends StatefulWidget {
  final String token;
  final VoidCallback onGroupCreated;

  const _CreateGroupDialog({required this.token, required this.onGroupCreated});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<ChatUser> _allUsers = [];
  List<ChatUser> _filtered = [];
  Set<String> _selectedMemberIds = {};
  bool _loadingUsers = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _error = null;
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
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingUsers = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allUsers
          : _allUsers
                .where(
                  (u) =>
                      u.name.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q) ||
                      (u.position ?? '').toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await ChatService.createGroup(
        token: widget.token,
        name: name,
        description: _descriptionCtrl.text.trim(),
        memberIds: _selectedMemberIds.toList(),
      );
      if (!mounted) return;
      widget.onGroupCreated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error ?? 'Failed to create group')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1C1C1E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Group name input
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Group description input (optional)
                TextField(
                  controller: _descriptionCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey[700] ?? const Color(0xFF3C3C3E),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF3C3C3E), height: 1),

          // ── Search and member selection ────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Expanded(
                  child: _loadingUsers
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final user = _filtered[i];
                            final isSelected = _selectedMemberIds.contains(
                              user.id,
                            );
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedMemberIds.remove(user.id);
                                  } else {
                                    _selectedMemberIds.add(user.id);
                                  }
                                });
                              },
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                user.position ?? user.role,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: AppTheme.primaryColor,
                              tileColor: const Color(0xFF2C2C2E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              dense: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
