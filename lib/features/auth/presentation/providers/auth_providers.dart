import 'package:provider/provider.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Service Instances
// ═══════════════════════════════════════════════════════════════════════════

final authService = AuthService();
final tokenStorageService = TokenStorageService();

// ═══════════════════════════════════════════════════════════════════════════
// Main Auth State Provider
// ═══════════════════════════════════════════════════════════════════════════

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>(
  (ref) => AuthNotifier(authService, tokenStorageService),
);
