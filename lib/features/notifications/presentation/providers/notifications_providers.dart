import 'package:provider/provider.dart';
import 'package:hrms_app/features/notifications/presentation/providers/notifications_notifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Notifications State Provider
// ═══════════════════════════════════════════════════════════════════════════

final notificationsNotifierProvider = ChangeNotifierProvider<NotificationsNotifier>(
  create: (context) => NotificationsNotifier(),
);
