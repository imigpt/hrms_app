import 'package:hrms_app/features/settings/presentation/providers/settings_notifier.dart';
import 'package:provider/provider.dart';

final settingsNotifierProvider = ChangeNotifierProvider<SettingsNotifier>(
  create: (context) => SettingsNotifier(),
);
