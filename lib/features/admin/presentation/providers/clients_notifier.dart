import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/admin/data/services/admin_clients_service.dart';
import 'package:hrms_app/features/admin/presentation/providers/clients_state.dart';

class ClientsNotifier extends ChangeNotifier {
  ClientsState _state = const ClientsState();

  ClientsState get state => _state;

  void _setState(ClientsState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Load all clients with optional status filter
  Future<void> loadClients(String token, {String? status}) async {
    print('[CLIENTS NOTIFIER] loadClients: Starting - Status filter: $status');
    _setState(_state.copyWith(isLoading: true, error: null));

    try {
      final result = await AdminClientsService.getAllClients(token, status: status);

      List<dynamic> data = [];

      // Handle different response formats from backend
      if (result['success'] == true && result['data'] is List) {
        data = result['data'] as List<dynamic>;
      } else if (result['data'] is List) {
        data = result['data'] as List<dynamic>;
      } else if (result['clients'] is List) {
        data = result['clients'] as List<dynamic>;
      } else if (result.isNotEmpty &&
          result.values.isNotEmpty &&
          result.values.first is List) {
        data = result.values.first as List<dynamic>;
      }

      print('[CLIENTS NOTIFIER] ✅ loadClients: Success - ${data.length} clients loaded');
      _setState(_state.copyWith(clients: data, isLoading: false));
    } catch (e) {
      print('[CLIENTS NOTIFIER] ❌ loadClients: Exception - $e');
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  /// Add a new client
  Future<bool> addClient({
    required String token,
    required String name,
    required String email,
    String? phone,
    String? companyName,
    String? password,
    String? assignedCompanyId,
    String? clientNotes,
  }) async {
    print('[CLIENTS NOTIFIER] addClient: Starting - $name ($email)');
    _setState(_state.copyWith(isSaving: true, error: null));

    try {
      final result = await AdminClientsService.addClient(
        token: token,
        name: name,
        email: email,
        phone: phone,
        companyName: companyName,
        password: password,
        assignedCompanyId: assignedCompanyId,
        clientNotes: clientNotes,
      );

      if (result['success'] != false) {
        print('[CLIENTS NOTIFIER] ✅ addClient: Success - ClientId: ${result['data']?['_id'] ?? result['data']?['id']}');
        _setState(_state.copyWith(
          successMessage: 'Client added successfully',
          isSaving: false,
        ));
        return true;
      } else {
        print('[CLIENTS NOTIFIER] ❌ addClient: Failed - ${result['message']}');
        _setState(_state.copyWith(
          error: result['message'] ?? 'Failed to add client',
          isSaving: false,
        ));
        return false;
      }
    } catch (e) {
      print('[CLIENTS NOTIFIER] ❌ addClient: Exception - $e');
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
      ));
      return false;
    }
  }

  /// Update an existing client
  Future<bool> updateClient({
    required String token,
    required String clientId,
    String? name,
    String? email,
    String? phone,
    String? companyName,
    String? password,
    String? assignedCompanyId,
    String? clientNotes,
  }) async {
    print('[CLIENTS NOTIFIER] updateClient: Starting - ClientId: $clientId');
    _setState(_state.copyWith(isSaving: true, error: null));

    try {
      final result = await AdminClientsService.updateClient(
        token: token,
        clientId: clientId,
        name: name,
        email: email,
        phone: phone,
        companyName: companyName,
        password: password,
        assignedCompanyId: assignedCompanyId,
        clientNotes: clientNotes,
      );

      if (result['success'] != false) {
        print('[CLIENTS NOTIFIER] ✅ updateClient: Success');
        _setState(_state.copyWith(
          successMessage: 'Client updated successfully',
          isSaving: false,
        ));
        return true;
      } else {
        print('[CLIENTS NOTIFIER] ❌ updateClient: Failed - ${result['message']}');
        _setState(_state.copyWith(
          error: result['message'] ?? 'Failed to update client',
          isSaving: false,
        ));
        return false;
      }
    } catch (e) {
      print('[CLIENTS NOTIFIER] ❌ updateClient: Exception - $e');
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
      ));
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(error: null));
  }

  /// Clear success message
  void clearSuccessMessage() {
    _setState(_state.copyWith(successMessage: null));
  }

  /// Set search query for filtering
  void setSearchQuery(String query) {
    _setState(_state.copyWith(searchQuery: query));
  }

  /// Set status filter
  void setStatusFilter(String status) {
    _setState(_state.copyWith(statusFilter: status));
  }

  /// Get filtered clients based on search and status
  List<dynamic> get filteredClients {
    final clients = _state.clients;
    final query = _state.searchQuery.toLowerCase();
    final statusFilter = _state.statusFilter;

    return clients.where((client) {
      // Status filter
      if (statusFilter.isNotEmpty) {
        if ((client['status']?.toString() ?? '') != statusFilter) return false;
      }

      // Search filter
      if (query.isNotEmpty) {
        final name = (client['name'] ?? '').toString().toLowerCase();
        final email = (client['email'] ?? '').toString().toLowerCase();
        final company = (client['company'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !email.contains(query) && !company.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Get client statistics
  int get totalCount => _state.clients.length;
  int get activeCount => _state.clients.where((c) => c['status'] == 'active').length;
  int get inactiveCount => _state.clients.where((c) => c['status'] == 'inactive').length;
}