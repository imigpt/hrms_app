import 'package:provider/provider.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:hrms_app/features/notifications/presentation/providers/notifications_notifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Service Instance
// ═══════════════════════════════════════════════════════════════════════════

final notificationService = ApiNotificationService();

// ═══════════════════════════════════════════════════════════════════════════
// Notifications State Provider
// ═══════════════════════════════════════════════════════════════════════════

final notificationsNotifierProvider = ChangeNotifierProvider<NotificationsNotifier>(
  create: (context) => NotificationsNotifier(notificationService),
);
