import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/features/chat/data/models/chat_room_model.dart';
import 'package:hrms_app/features/chat/presentation/providers/chat_notifier.dart';

ChatRoom _room({
  required String id,
  String name = 'General',
  int unreadCount = 0,
  String type = 'group',
}) {
  final now = DateTime.utc(2026, 4, 1, 12, 0, 0);
  return ChatRoom(
    id: id,
    name: name,
    type: type,
    participants: const [],
    unreadCount: unreadCount,
    createdAt: now,
    updatedAt: now,
  );
}

ChatMessage _message({
  required String id,
  required String roomId,
  required String content,
  required DateTime createdAt,
}) {
  return ChatMessage(
    id: id,
    chatRoom: roomId,
    content: content,
    messageType: 'text',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

ChatUser _user({required String id, required String name}) {
  return ChatUser(
    id: id,
    name: name,
    email: '$id@example.com',
    role: 'employee',
  );
}

void main() {
  group('ChatNotifier', () {
    test('loadChatRooms fetches rooms and updates state', () async {
      final rooms = [_room(id: 'r1'), _room(id: 'r2', name: 'Product')];

      final notifier = ChatNotifier(
        getChatRooms: ({required token}) async {
          return ChatRoomsResponse(success: true, count: rooms.length, data: rooms);
        },
      );

      await notifier.loadChatRooms('token');

      expect(notifier.state.isLoadingRooms, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.chatRooms.length, 2);
      expect(notifier.state.chatRooms.first.id, 'r1');
    });

    test('selectChatRoom loads messages and marks room as read', () async {
      var markAsReadCalled = false;
      final room = _room(id: 'r100', unreadCount: 5);
      final message = _message(
        id: 'm1',
        roomId: room.id,
        content: 'hello',
        createdAt: DateTime.utc(2026, 4, 1, 10, 0, 0),
      );

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          return ChatMessagesResponse(
            success: true,
            count: 1,
            hasMore: false,
            data: [message],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          markAsReadCalled = true;
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
      );

      await notifier.selectChatRoom(room);

      expect(markAsReadCalled, true);
      expect(notifier.state.selectedRoomId, 'r100');
      expect(notifier.state.currentRoomMessages.length, 1);
      expect(notifier.state.currentRoomMessages.first.id, 'm1');
      expect(notifier.state.unreadCounts['r100'], 0);
      expect(notifier.state.isLoadingMessages, false);
    });

    test('deselectChatRoom clears selected room and messages', () async {
      final room = _room(id: 'r200');
      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          return ChatMessagesResponse(
            success: true,
            count: 1,
            hasMore: false,
            data: [
              _message(
                id: 'm2',
                roomId: room.id,
                content: 'test',
                createdAt: DateTime.utc(2026, 4, 1, 11, 0, 0),
              ),
            ],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
      );

      await notifier.selectChatRoom(room);
      notifier.deselectChatRoom();

      expect(notifier.state.selectedChatRoom, isNull);
      expect(notifier.state.selectedRoomId, isNull);
      expect(notifier.state.currentRoomMessages, isEmpty);
    });

    test('loadMoreMessages appends older messages and increments page', () async {
      final room = _room(id: 'r300');
      final newest = _message(
        id: 'm-new',
        roomId: room.id,
        content: 'newest',
        createdAt: DateTime.utc(2026, 4, 1, 12, 0, 0),
      );
      final older = _message(
        id: 'm-old',
        roomId: room.id,
        content: 'older',
        createdAt: DateTime.utc(2026, 3, 31, 12, 0, 0),
      );

      var calls = 0;
      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          calls += 1;
          if (calls == 1) {
            expect(before, isNull);
            return ChatMessagesResponse(
              success: true,
              count: 1,
              hasMore: true,
              data: [newest],
            );
          }

          expect(before, newest.createdAt.toIso8601String());
          return ChatMessagesResponse(
            success: true,
            count: 1,
            hasMore: false,
            data: [older],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
      );

      await notifier.selectChatRoom(room);
      await notifier.loadMoreMessages();

      expect(notifier.state.currentRoomMessages.map((m) => m.id), ['m-new', 'm-old']);
      expect(notifier.state.messagesPageIndex, 1);
      expect(notifier.state.hasMoreMessages, false);
    });

    test('sendMessage replaces temporary message with server message', () async {
      final room = _room(id: 'r400');
      final serverMessage = _message(
        id: 'm-real',
        roomId: room.id,
        content: 'hello world',
        createdAt: DateTime.utc(2026, 4, 1, 13, 0, 0),
      );

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          return ChatMessagesResponse(
            success: true,
            count: 0,
            hasMore: false,
            data: const [],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
        sendRoomMessage: ({
          required token,
          required roomId,
          required content,
          String messageType = 'text',
          String? replyTo,
        }) async {
          return SendMessageResponse(success: true, data: serverMessage);
        },
      );

      await notifier.selectChatRoom(room);
      await notifier.sendMessage('hello world');

      expect(notifier.state.isSendingMessage, false);
      expect(notifier.state.currentRoomMessages.first.id, 'm-real');
      expect(
        notifier.state.currentRoomMessages.where((m) => m.id.startsWith('temp_')),
        isEmpty,
      );
    });

    test('searchUsers stores query and filtered users', () async {
      final users = [_user(id: 'u1', name: 'Alice')];

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        searchUsers: ({required token, required query}) async {
          return ChatUsersResponse(success: true, count: users.length, data: users);
        },
      );

      await notifier.searchUsers('al');
      expect(notifier.state.searchQuery, 'al');
      expect(notifier.state.companyUsers.length, 1);
      expect(notifier.state.companyUsers.first.name, 'Alice');

      await notifier.searchUsers('');
      expect(notifier.state.searchQuery, isNull);
    });

    test('createGroup sets success message and refreshes rooms', () async {
      var createCalled = false;
      final rooms = [_room(id: 'r500', name: 'New Group')];

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        createGroup: ({
          required token,
          required name,
          required memberIds,
          String? description,
        }) async {
          createCalled = true;
          return {'success': true};
        },
        getChatRooms: ({required token}) async {
          return ChatRoomsResponse(success: true, count: rooms.length, data: rooms);
        },
      );

      await notifier.createGroup(name: 'New Group', memberIds: const ['u1', 'u2']);

      expect(createCalled, true);
      expect(notifier.state.successMessage, 'Group created successfully');
      expect(notifier.state.chatRooms.length, 1);
      expect(notifier.state.chatRooms.first.id, 'r500');
    });

    test('reset restores initial defaults', () async {
      final notifier = ChatNotifier();

      notifier.setTypingIndicator('u1', true);
      notifier.updateUserPresence('u1', 'online');
      notifier.reset();

      expect(notifier.state.chatRooms, isEmpty);
      expect(notifier.state.currentRoomMessages, isEmpty);
      expect(notifier.state.selectedRoomId, isNull);
      expect(notifier.state.typingIndicators, isEmpty);
      expect(notifier.state.userPresence, isEmpty);
      expect(notifier.state.error, isNull);
      expect(notifier.state.successMessage, isNull);
    });

    // ── Socket Event Handlers ──────────────────────────────────────────────

    test('receiveNewMessage adds message to current room', () async {
      final room = _room(id: 'r600');
      final incomingMsg = _message(
        id: 'm-new',
        roomId: room.id,
        content: 'incoming',
        createdAt: DateTime.utc(2026, 4, 1, 14, 0, 0),
      );

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          return ChatMessagesResponse(
            success: true,
            count: 0,
            hasMore: false,
            data: const [],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
      );

      await notifier.selectChatRoom(room);
      notifier.receiveNewMessage(incomingMsg);

      expect(notifier.state.currentRoomMessages.length, 1);
      expect(notifier.state.currentRoomMessages.first.id, 'm-new');
    });

    test('receiveNewMessage increments unread count for other rooms', () async {
      final room = _room(id: 'r700');
      final incomingMsg = _message(
        id: 'm-other',
        roomId: 'r-different',
        content: 'msg in another room',
        createdAt: DateTime.utc(2026, 4, 1, 14, 0, 0),
      );

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          return ChatMessagesResponse(
            success: true,
            count: 0,
            hasMore: false,
            data: const [],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
      );

      await notifier.selectChatRoom(room);
      expect(notifier.state.unreadCounts['r-different'] ?? 0, 0);

      notifier.receiveNewMessage(incomingMsg);

      expect(notifier.state.unreadCounts['r-different'], 1);
      expect(notifier.state.totalUnreadMessages, 1);
    });

    test('receiveMessageSent replaces temp message with server message', () async {
      final room = _room(id: 'r800');
      final tempMessage = ChatMessage(
        id: 'temp_12345',
        chatRoom: room.id,
        content: 'hello',
        messageType: 'text',
        createdAt: DateTime.utc(2026, 4, 1, 14, 0, 0),
        updatedAt: DateTime.utc(2026, 4, 1, 14, 0, 0),
      );
      final serverMessage = _message(
        id: 'm-confirmed',
        roomId: room.id,
        content: 'hello',
        createdAt: DateTime.utc(2026, 4, 1, 14, 0, 0),
      );

      final notifier = ChatNotifier(
        getToken: () async => 'token',
        getRoomMessages: ({
          required token,
          required roomId,
          int? limit,
          String? before,
        }) async {
          return ChatMessagesResponse(
            success: true,
            count: 1,
            hasMore: false,
            data: [tempMessage],
          );
        },
        markRoomAsRead: ({required token, required roomId}) async {
          return MarkReadResponse(success: true, modifiedCount: 1);
        },
      );

      await notifier.selectChatRoom(room);
      expect(notifier.state.currentRoomMessages.first.id, 'temp_12345');

      notifier.receiveMessageSent(tempId: 'temp_12345', serverMessage: serverMessage);

      expect(notifier.state.currentRoomMessages.first.id, 'm-confirmed');
      expect(
        notifier.state.currentRoomMessages.where((m) => m.id.startsWith('temp_')),
        isEmpty,
      );
    });

    test('receiveMessagesRead updates unread count', () async {
      final notifier = ChatNotifier();

      notifier.receiveMessagesRead(roomId: 'r900', count: 5);

      expect(notifier.state.unreadCounts['r900'], 5);

      notifier.receiveMessagesRead(roomId: 'r900', count: 0);

      expect(notifier.state.unreadCounts['r900'], 0);
    });

    test('updateOnlineUsers updates user presence', () async {
      final notifier = ChatNotifier();

      notifier.updateOnlineUsers(['u1', 'u2', 'u3']);

      expect(notifier.state.userPresence['u1'], 'online');
      expect(notifier.state.userPresence['u2'], 'online');
      expect(notifier.state.userPresence['u3'], 'online');
    });

    test('setConnectionStatus updates connection state', () async {
      final notifier = ChatNotifier();

      expect(notifier.state.isConnected, false);

      notifier.setConnectionStatus(isConnected: true);
      expect(notifier.state.isConnected, true);
      expect(notifier.state.isReconnecting, false);

      notifier.setConnectionStatus(isConnected: false, isReconnecting: true);
      expect(notifier.state.isConnected, false);
      expect(notifier.state.isReconnecting, true);
    });
  });
}
