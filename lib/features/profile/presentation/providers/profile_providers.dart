import 'package:provider/provider.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';
import 'package:hrms_app/features/profile/presentation/providers/profile_notifier.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Service Instances
// ═══════════════════════════════════════════════════════════════════════════

final profileService = ProfileService();

// ═══════════════════════════════════════════════════════════════════════════
// Profile State Provider
// ═══════════════════════════════════════════════════════════════════════════

final profileNotifierProvider = ChangeNotifierProvider<ProfileNotifier>(
  create: (context) => ProfileNotifier(profileService),
);
