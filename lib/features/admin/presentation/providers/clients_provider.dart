import 'package:provider/provider.dart';
import 'clients_notifier.dart';

final clientsNotifierProvider = ChangeNotifierProvider<ClientsNotifier>(
  create: (_) => ClientsNotifier(),
);