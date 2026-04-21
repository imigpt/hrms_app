import 'package:provider/provider.dart';
import 'package:hrms_app/features/profile/presentation/providers/profile_notifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Profile State Provider
// ═══════════════════════════════════════════════════════════════════════════

final profileNotifierProvider = ChangeNotifierProvider<ProfileNotifier>(
  create: (context) => ProfileNotifier(),
);
