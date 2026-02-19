// lib/services/chat_socket_service.dart
// Real-time Socket.IO service for chat.
// Backend events documented in HRMS-Backend/socket/chatSocket.js
// ignore_for_file: use_null_aware_elements

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/chat_room_model.dart';

// ─── Event data classes ───────────────────────────────────────────────────────

class MessageSentEvent {
  final String tempId;
  final ChatMessage message;
  MessageSentEvent({required this.tempId, required this.message});
}

class TypingEvent {
  final String userId;
  final String userName;
  final String roomId;
  TypingEvent({
    required this.userId,
    required this.userName,
    required this.roomId,
  });
}

class UserStatusEvent {
  final String userId;
  final String userName;
  final bool isOnline;
  UserStatusEvent({
    required this.userId,
    required this.userName,
    required this.isOnline,
  });
}

class MessagesReadEvent {
  final String roomId;
  final String readBy;
  final String readByName;
  final int count;
  MessagesReadEvent({
    required this.roomId,
    required this.readBy,
    required this.readByName,
    required this.count,
  });
}

// ─── Service ─────────────────────────────────────────────────────────────────

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  static const String _socketUrl = 'https://hrms-backend-zzzc.onrender.com';

  io.Socket? _socket;

  // Stream controllers
  final _newMsgCtrl = StreamController<ChatMessage>.broadcast();
  final _msgSentCtrl = StreamController<MessageSentEvent>.broadcast();
  final _typingCtrl = StreamController<TypingEvent>.broadcast();
  final _stopTypingCtrl = StreamController<TypingEvent>.broadcast();
  final _userStatusCtrl = StreamController<UserStatusEvent>.broadcast();
  final _connectedCtrl = StreamController<bool>.broadcast();
  final _msgsReadCtrl = StreamController<MessagesReadEvent>.broadcast();

  /// Emitted once on connect: list of currently online userId strings
  final _onlineListCtrl = StreamController<List<String>>.broadcast();

  // Public streams
  Stream<ChatMessage> get onNewMessage => _newMsgCtrl.stream;
  Stream<MessageSentEvent> get onMessageSent => _msgSentCtrl.stream;
  Stream<TypingEvent> get onTyping => _typingCtrl.stream;
  Stream<TypingEvent> get onStopTyping => _stopTypingCtrl.stream;
  Stream<UserStatusEvent> get onUserStatus => _userStatusCtrl.stream;
  Stream<bool> get onConnectionChanged => _connectedCtrl.stream;
  Stream<MessagesReadEvent> get onMessagesRead => _msgsReadCtrl.stream;
  Stream<List<String>> get onOnlineUsersList => _onlineListCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Manually re-request the online-users list from the server.
  /// Call this every time a new chat room opens to get a fresh status snapshot.
  void requestOnlineUsers() {
    if (_socket?.connected == true) {
      _socket!.emit('get-online-users');
    }
  }

  /// Connect to Socket.IO server with JWT [token].
  /// Safe to call multiple times — emits get-online-users even if already connected.
  void connect(String token) {
    if (_socket != null) {
      if (_socket!.connected) {
        // Already connected — just refresh the online users list.
        _socket!.emit('get-online-users');
        return;
      }
      _socket!.dispose();
    }

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connectedCtrl.add(true);
      // Request initial list of online users
      _socket!.emit('get-online-users');
    });

    _socket!.onDisconnect((_) {
      _connectedCtrl.add(false);
    });

    _socket!.onConnectError((_) {
      _connectedCtrl.add(false);
    });

    // ── Incoming events ────────────────────────────────────────────────────

    _socket!.on('new-message', (data) {
      if (data is! Map) return;
      try {
        _newMsgCtrl.add(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
      } catch (_) {}
    });

    _socket!.on('message-sent', (data) {
      if (data is! Map) return;
      try {
        final map = Map<String, dynamic>.from(data);
        final msgRaw = map['message'];
        if (msgRaw is! Map) return;
        _msgSentCtrl.add(
          MessageSentEvent(
            tempId: map['tempId'] as String? ?? '',
            message: ChatMessage.fromJson(Map<String, dynamic>.from(msgRaw)),
          ),
        );
      } catch (_) {}
    });

    _socket!.on('user-typing', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _typingCtrl.add(
        TypingEvent(
          userId: m['userId'] as String? ?? '',
          userName: m['userName'] as String? ?? '',
          roomId: m['roomId'] as String? ?? '',
        ),
      );
    });

    _socket!.on('user-stopped-typing', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _stopTypingCtrl.add(
        TypingEvent(
          userId: m['userId'] as String? ?? '',
          userName: m['userName'] as String? ?? '',
          roomId: m['roomId'] as String? ?? '',
        ),
      );
    });

    _socket!.on('user-online', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _userStatusCtrl.add(
        UserStatusEvent(
          userId: m['userId'] as String? ?? '',
          userName: m['userName'] as String? ?? '',
          isOnline: true,
        ),
      );
    });

    _socket!.on('user-offline', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _userStatusCtrl.add(
        UserStatusEvent(
          userId: m['userId'] as String? ?? '',
          userName: m['userName'] as String? ?? '',
          isOnline: false,
        ),
      );
    });

    _socket!.on('messages-read', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _msgsReadCtrl.add(
        MessagesReadEvent(
          roomId: m['roomId'] as String? ?? '',
          readBy: m['readBy'] as String? ?? '',
          readByName: m['readByName'] as String? ?? '',
          count: (m['count'] as num?)?.toInt() ?? 0,
        ),
      );
    });

    _socket!.on('online-users', (data) {
      if (data is! List) return;
      final ids = data
          .whereType<Map>()
          .map((m) => m['userId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      _onlineListCtrl.add(ids);
    });

    _socket!.connect();
  }

  // ── Outgoing events ──────────────────────────────────────────────────────

  void joinRoom(String roomId) => _socket?.emit('join-room', roomId);

  void leaveRoom(String roomId) => _socket?.emit('leave-room', roomId);

  /// Send a text message via socket. Use [tempId] for optimistic UI.
  void sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    required String tempId,
    String? replyTo,
    Map<String, dynamic>? attachment,
  }) {
    _socket?.emit('send-message', {
      'roomId': roomId,
      'content': content,
      'messageType': messageType,
      'tempId': tempId,
      if (replyTo != null) 'replyTo': replyTo,
      if (attachment != null) 'attachment': attachment,
    });
  }

  void emitTyping(String roomId) => _socket?.emit('typing', {'roomId': roomId});

  void emitStopTyping(String roomId) =>
      _socket?.emit('stop-typing', {'roomId': roomId});

  void markRead(String roomId) =>
      _socket?.emit('mark-read', {'roomId': roomId});

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
