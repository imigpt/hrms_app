import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:hrms_app/features/notifications/presentation/providers/notifications_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NotificationsNotifier uses fallback provider and sorts items', () async {
    SharedPreferences.setMockInitialValues({});

    Future<List<NotificationItem>> fallback(
      String token,
      String userId,
      String role,
    ) async {
      return [
        NotificationItem(
          id: 'old',
          userId: userId,
          title: 'Old',
          message: 'Older notification',
          type: 'general',
          isRead: false,
          createdAt: DateTime(2024, 1, 1),
        ),
        NotificationItem(
          id: 'new',
          userId: userId,
          title: 'New',
          message: 'Newer notification',
          type: 'general',
          isRead: true,
          createdAt: DateTime(2024, 1, 2),
        ),
      ];
    }

    final notifier = NotificationsNotifier(fallbackProvider: fallback);

    await notifier.loadNotifications(
      'token',
      userId: 'user-1',
      role: 'employee',
      preferFallback: true,
    );

    final state = notifier.state;
    expect(state.usingBackend, isFalse);
    expect(state.notifications.length, 2);
    expect(state.notifications.first.id, 'new');
    expect(state.unreadCount, 1);
  });
}
