// lib/models/chat_room_model.dart

class ChatParticipant {
  final String id;
  final String name;
  final String email;
  final String? profilePhoto;
  final String? position;
  final String status;
  final String? employeeId; // for employees
  final String? hrId; // for HR
  final String? adminId; // for admins
  final String? userRole; // 'employee' | 'hr' | 'admin'

  ChatParticipant({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.position,
    this.status = 'active',
    this.employeeId,
    this.hrId,
    this.adminId,
    this.userRole,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    // profilePhoto can be null, a String URL, or an object {url, publicId}
    String? photo;
    final raw = json['profilePhoto'];
    if (raw is String) {
      photo = raw;
    } else if (raw is Map<String, dynamic>) {
      photo = raw['url'] as String?;
    }

    return ChatParticipant(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePhoto: photo,
      position: json['position'] as String?,
      status: json['status'] as String? ?? 'active',
      employeeId: json['employeeId'] as String?,
      hrId: json['hrId'] as String?,
      adminId: json['adminId'] as String?,
      userRole: json['userRole'] as String?,
    );
  }

  /// Returns the appropriate ID for display (Employee ID, HR ID, Admin ID, or User ID)
  String getDisplayId() {
    if (adminId != null && adminId!.isNotEmpty) return adminId!;
    if (hrId != null && hrId!.isNotEmpty) return hrId!;
    if (employeeId != null && employeeId!.isNotEmpty) return employeeId!;
    return id.substring(0, 8); // fallback: first 8 chars of MongoDB ID
  }

  /// Returns a label for the display ID (e.g., "EMP-", "HR-", "ADM-")
  String getIdPrefix() {
    if (adminId != null && adminId!.isNotEmpty) return 'ADM';
    if (hrId != null && hrId!.isNotEmpty) return 'HR';
    if (employeeId != null && employeeId!.isNotEmpty) return 'EMP';
    return 'USR';
  }
}

class ChatLastMessage {
  final String content;
  final String senderName;
  final String senderId;
  final String messageType;
  final DateTime createdAt;

  ChatLastMessage({
    required this.content,
    required this.senderName,
    required this.senderId,
    required this.messageType,
    required this.createdAt,
  });

  bool get isVoice => messageType == 'voice';

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    return ChatLastMessage(
      content: json['content'] as String? ?? '',
      senderName: sender['name'] as String? ?? '',
      senderId: sender['_id'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'text',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String type; // 'group' | 'direct'
  final List<ChatParticipant> participants;
  final String description;
  final bool isActive;
  final bool onlyAdminsCanMessage;
  final ChatLastMessage? lastMessage;
  final int unreadCount;
  final ChatParticipant? otherUser; // for direct chats
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.description = '',
    this.isActive = true,
    this.onlyAdminsCanMessage = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.otherUser,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isGroup => type == 'group';

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    final participantsList = (json['participants'] as List<dynamic>? ?? [])
        .map((p) => ChatParticipant.fromJson(p as Map<String, dynamic>))
        .toList();

    return ChatRoom(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'group',
      participants: participantsList,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      onlyAdminsCanMessage: settings['onlyAdminsCanMessage'] as bool? ?? false,
      lastMessage: json['lastMessage'] != null
          ? ChatLastMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      otherUser: json['otherUser'] != null
          ? ChatParticipant.fromJson(json['otherUser'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatRoomsResponse {
  final bool success;
  final int count;
  final List<ChatRoom> data;

  ChatRoomsResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory ChatRoomsResponse.fromJson(Map<String, dynamic> json) {
    return ChatRoomsResponse(
      success: json['success'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((r) => ChatRoom.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatPersonalRoomResponse {
  final bool success;
  final ChatRoom data;

  ChatPersonalRoomResponse({required this.success, required this.data});

  factory ChatPersonalRoomResponse.fromJson(Map<String, dynamic> json) {
    return ChatPersonalRoomResponse(
      success: json['success'] as bool? ?? false,
      data: ChatRoom.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Message  — shape returned by GET /rooms/:id/messages, POST /messages
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessageSender {
  final String id;
  final String name;
  final String? profilePhoto;
  final String? position;
  final String? employeeId;
  final String? hrId;
  final String? adminId;
  final String? userRole;

  ChatMessageSender({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.position,
    this.employeeId,
    this.hrId,
    this.adminId,
    this.userRole,
  });

  factory ChatMessageSender.fromJson(Map<String, dynamic> json) {
    String? photo;
    final raw = json['profilePhoto'];
    if (raw is String) photo = raw;
    if (raw is Map<String, dynamic>) photo = raw['url'] as String?;
    return ChatMessageSender(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profilePhoto: photo,
      position: json['position'] as String?,
      employeeId: json['employeeId'] as String?,
      hrId: json['hrId'] as String?,
      adminId: json['adminId'] as String?,
      userRole: json['userRole'] as String?,
    );
  }

  /// Returns the appropriate ID for display
  String getDisplayId() {
    if (adminId != null && adminId!.isNotEmpty) return adminId!;
    if (hrId != null && hrId!.isNotEmpty) return hrId!;
    if (employeeId != null && employeeId!.isNotEmpty) return employeeId!;
    return id.substring(0, 8);
  }

  /// Returns label prefix
  String getIdPrefix() {
    if (adminId != null && adminId!.isNotEmpty) return 'ADM';
    if (hrId != null && hrId!.isNotEmpty) return 'HR';
    if (employeeId != null && employeeId!.isNotEmpty) return 'EMP';
    return 'USR';
  }
}

class ChatAttachment {
  final String url;
  final String? publicId;
  final String? name;
  final int? size;
  final String? mimeType;

  ChatAttachment({
    required this.url,
    this.publicId,
    this.name,
    this.size,
    this.mimeType,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    var url = json['url'] as String? ?? '';
    final publicId = json['publicId'] as String?;

    // If URL is empty but publicId exists, try to reconstruct it
    if (url.isEmpty && publicId != null && publicId.isNotEmpty) {
      // Try to extract cloud name from any URLs that might be in the message
      // For now, log the missing URL so it can be debugged
      print('⚠️ [CHAT ATTACHMENT] URL is empty but publicId found: $publicId');
      print('   Backend should return secure_url from Cloudinary');
      print('   Attempting fallback URL construction...');

      // Construct standard Cloudinary URL with public ID
      // Note: This assumes 'res' is the standard Cloudinary subdomain
      url = 'https://res.cloudinary.com/hrms-network/raw/upload/$publicId';
    }

    return ChatAttachment(
      url: url,
      publicId: publicId,
      name: json['name'] as String?,
      size: json['size'] as int?,
      mimeType: json['mimeType'] as String?,
    );
  }
}

/// Lightweight quoted message shown inside a bubble when this is a reply
class ChatReplyMessage {
  final String id;
  final String content;
  final String? senderName;
  final String? senderId;
  final String? senderEmployeeId;
  final String? senderHrId;
  final String? senderAdminId;

  ChatReplyMessage({
    required this.id,
    required this.content,
    this.senderName,
    this.senderId,
    this.senderEmployeeId,
    this.senderHrId,
    this.senderAdminId,
  });

  factory ChatReplyMessage.fromJson(Map<String, dynamic> json) {
    String? senderName;
    String? senderId;
    String? senderEmployeeId;
    String? senderHrId;
    String? senderAdminId;
    final s = json['sender'];
    if (s is Map<String, dynamic>) {
      senderName = s['name'] as String?;
      senderId = s['_id'] as String?;
      senderEmployeeId = s['employeeId'] as String?;
      senderHrId = s['hrId'] as String?;
      senderAdminId = s['adminId'] as String?;
    }
    return ChatReplyMessage(
      id: json['_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      senderName: senderName,
      senderId: senderId,
      senderEmployeeId: senderEmployeeId,
      senderHrId: senderHrId,
      senderAdminId: senderAdminId,
    );
  }

  /// Returns the appropriate ID for display
  String getDisplayId() {
    if (senderAdminId != null && senderAdminId!.isNotEmpty)
      return senderAdminId!;
    if (senderHrId != null && senderHrId!.isNotEmpty) return senderHrId!;
    if (senderEmployeeId != null && senderEmployeeId!.isNotEmpty)
      return senderEmployeeId!;
    return senderId?.substring(0, 8) ?? 'Unknown';
  }

  /// Returns label prefix
  String getIdPrefix() {
    if (senderAdminId != null && senderAdminId!.isNotEmpty) return 'ADM';
    if (senderHrId != null && senderHrId!.isNotEmpty) return 'HR';
    if (senderEmployeeId != null && senderEmployeeId!.isNotEmpty) return 'EMP';
    return 'USR';
  }
}

class ChatMessage {
  final String id;
  final String chatRoom;
  final ChatMessageSender? sender;
  final String content;
  final String messageType; // text | image | voice | document
  final bool isRead;
  final bool isDeleted;
  final bool isGroupMessage;
  final ChatAttachment? attachment;
  final ChatReplyMessage? replyTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// For optimistic UI — a locally-generated temp id before server confirms.
  final String? tempId;

  ChatMessage({
    required this.id,
    required this.chatRoom,
    this.sender,
    required this.content,
    required this.messageType,
    this.isRead = false,
    this.isDeleted = false,
    this.isGroupMessage = false,
    this.attachment,
    this.replyTo,
    required this.createdAt,
    required this.updatedAt,
    this.tempId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['_id'] as String? ?? '',
    chatRoom:
        (json['chatRoom'] is String
            ? json['chatRoom'] as String?
            : (json['chatRoom'] as Map<String, dynamic>?)?['_id'] as String?) ??
        '',
    sender: json['sender'] != null
        ? ChatMessageSender.fromJson(json['sender'] as Map<String, dynamic>)
        : null,
    content: json['content'] as String? ?? '',
    messageType: json['messageType'] as String? ?? 'text',
    isRead: json['isRead'] as bool? ?? false,
    isDeleted: json['isDeleted'] as bool? ?? false,
    isGroupMessage: json['isGroupMessage'] as bool? ?? false,
    attachment: json['attachment'] != null
        ? ChatAttachment.fromJson(json['attachment'] as Map<String, dynamic>)
        : null,
    replyTo: json['replyTo'] is Map<String, dynamic>
        ? ChatReplyMessage.fromJson(json['replyTo'] as Map<String, dynamic>)
        : null,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  bool get isMedia => messageType != 'text';
  bool get isTemp => id.isEmpty || id.startsWith('temp_');

  ChatMessage copyWith({bool? isRead, bool? isDeleted}) {
    return ChatMessage(
      id: id,
      chatRoom: chatRoom,
      sender: sender,
      content: content,
      messageType: messageType,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      isGroupMessage: isGroupMessage,
      attachment: attachment,
      replyTo: replyTo,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tempId: tempId,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Response wrappers
// ─────────────────────────────────────────────────────────────────────────────

/// GET /api/chat/rooms/:roomId/messages
class ChatMessagesResponse {
  final bool success;
  final int count;
  final bool hasMore;
  final List<ChatMessage> data;

  ChatMessagesResponse({
    required this.success,
    required this.count,
    required this.hasMore,
    required this.data,
  });

  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) =>
      ChatMessagesResponse(
        success: json['success'] as bool? ?? false,
        count: json['count'] as int? ?? 0,
        hasMore: json['hasMore'] as bool? ?? false,
        data: (json['data'] as List<dynamic>? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

/// POST /api/chat/rooms/:roomId/messages
class SendMessageResponse {
  final bool success;
  final ChatMessage? data;

  SendMessageResponse({required this.success, this.data});

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      SendMessageResponse(
        success: json['success'] as bool? ?? false,
        data: json['data'] != null
            ? ChatMessage.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

/// PUT /api/chat/rooms/:roomId/read
class MarkReadResponse {
  final bool success;
  final int modifiedCount;

  MarkReadResponse({required this.success, required this.modifiedCount});

  factory MarkReadResponse.fromJson(Map<String, dynamic> json) =>
      MarkReadResponse(
        success: json['success'] as bool? ?? false,
        modifiedCount: json['modifiedCount'] as int? ?? 0,
      );
}

/// GET /api/chat/unread
class UnreadCountResponse {
  final bool success;
  final int count;

  UnreadCountResponse({required this.success, required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      UnreadCountResponse(
        success: json['success'] as bool? ?? false,
        count: json['count'] as int? ?? 0,
      );
}

/// User shape returned by GET /api/chat/users and GET /api/chat/users/search
class ChatUser {
  final String id;
  final String name;
  final String email;
  final String? employeeId;
  final String? hrId;
  final String? adminId;
  final String? profilePhoto;
  final String? position;
  final String? department;
  final String role;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId,
    this.hrId,
    this.adminId,
    this.profilePhoto,
    this.position,
    this.department,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    String? photo;
    final raw = json['profilePhoto'];
    if (raw is String) photo = raw;
    if (raw is Map<String, dynamic>) photo = raw['url'] as String?;
    return ChatUser(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      hrId: json['hrId'] as String?,
      adminId: json['adminId'] as String?,
      profilePhoto: photo,
      position: json['position'] as String?,
      department: json['department'] as String?,
      role: json['role'] as String? ?? 'employee',
    );
  }

  /// Returns the appropriate ID for display
  String getDisplayId() {
    if (adminId != null && adminId!.isNotEmpty) return adminId!;
    if (hrId != null && hrId!.isNotEmpty) return hrId!;
    if (employeeId != null && employeeId!.isNotEmpty) return employeeId!;
    return id.substring(0, 8);
  }

  /// Returns label prefix
  String getIdPrefix() {
    if (adminId != null && adminId!.isNotEmpty) return 'ADM';
    if (hrId != null && hrId!.isNotEmpty) return 'HR';
    if (employeeId != null && employeeId!.isNotEmpty) return 'EMP';
    return 'USR';
  }
}

/// GET /api/chat/users  and  GET /api/chat/users/search
class ChatUsersResponse {
  final bool success;
  final int count;
  final List<ChatUser> data;

  ChatUsersResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory ChatUsersResponse.fromJson(Map<String, dynamic> json) =>
      ChatUsersResponse(
        success: json['success'] as bool? ?? false,
        count: json['count'] as int? ?? 0,
        data: (json['data'] as List<dynamic>? ?? [])
            .map((u) => ChatUser.fromJson(u as Map<String, dynamic>))
            .toList(),
      );
}
