import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/policies/data/models/policy_model.dart';
import 'package:hrms_app/features/policies/data/services/policy_service.dart';
import 'package:hrms_app/features/policies/presentation/providers/policies_state.dart';

typedef _GetPoliciesFn = Future<PolicyListResponse> Function({
  required String token,
  String? search,
});
typedef _CreatePolicyFn = Future<void> Function({
  required String token,
  required String title,
  String description,
  String location,
  File? file,
  String? fileName,
});
typedef _DeletePolicyFn = Future<void> Function({
  required String token,
  required String id,
});

class PoliciesNotifier extends ChangeNotifier {
  PoliciesState _state = const PoliciesState();

  final _GetPoliciesFn _getPolicies;
  final _CreatePolicyFn _createPolicy;
  final _DeletePolicyFn _deletePolicy;

  PoliciesNotifier({
    _GetPoliciesFn? getPolicies,
    _CreatePolicyFn? createPolicy,
    _DeletePolicyFn? deletePolicy,
  })  : _getPolicies = getPolicies ?? PolicyService.getPolicies,
        _createPolicy = createPolicy ?? PolicyService.createPolicy,
        _deletePolicy = deletePolicy ?? PolicyService.deletePolicy;

  PoliciesState get state => _state;

  void _setState(PoliciesState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadPolicies({
    required String token,
    String? searchQuery,
  }) async {
    final query = searchQuery ?? _state.searchQuery;
    debugPrint('📄 PoliciesNotifier: Loading policies (search: $query)');

    _setState(
      _state.copyWith(
        isLoading: true,
        errorMessage: null,
        searchQuery: query,
      ),
    );

    try {
      final response = await _getPolicies(
        token: token,
        search: query.isEmpty ? null : query,
      );

      _setState(
        _state.copyWith(
          policies: response.data,
          totalCount: response.count,
          isLoading: false,
          lastUpdated: DateTime.now(),
        ),
      );
      debugPrint('✅ Policies loaded: ${response.data.length}');
    } catch (e) {
      debugPrint('❌ Error loading policies: $e');
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load policies: $e',
        ),
      );
    }
  }

  Future<void> refreshPolicies({required String token}) async {
    await loadPolicies(token: token, searchQuery: _state.searchQuery);
  }

  Future<void> searchPolicies({
    required String token,
    required String query,
  }) async {
    await loadPolicies(token: token, searchQuery: query);
  }

  Future<void> createPolicy({
    required String token,
    required String title,
    String description = '',
    String location = 'Head Office',
    File? file,
    String? fileName,
  }) async {
    debugPrint('📤 PoliciesNotifier: Creating policy');
    _setState(_state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      await _createPolicy(
        token: token,
        title: title,
        description: description,
        location: location,
        file: file,
        fileName: fileName,
      );

      await loadPolicies(token: token, searchQuery: _state.searchQuery);
      _setState(_state.copyWith(isSubmitting: false));
      debugPrint('✅ Policy created');
    } catch (e) {
      debugPrint('❌ Error creating policy: $e');
      _setState(
        _state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to create policy: $e',
        ),
      );
      rethrow;
    }
  }

  Future<void> deletePolicy({
    required String token,
    required String id,
  }) async {
    debugPrint('🗑️ PoliciesNotifier: Deleting policy $id');
    _setState(_state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      await _deletePolicy(token: token, id: id);

      final updated = _state.policies.where((p) => p.id != id).toList();
      _setState(
        _state.copyWith(
          policies: updated,
          totalCount: updated.length,
          isSubmitting: false,
          lastUpdated: DateTime.now(),
        ),
      );
      debugPrint('✅ Policy deleted');
    } catch (e) {
      debugPrint('❌ Error deleting policy: $e');
      _setState(
        _state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to delete policy: $e',
        ),
      );
      rethrow;
    }
  }

  void clearError() {
    _setState(_state.copyWith(errorMessage: null));
  }

  void reset() {
    _setState(const PoliciesState());
  }
}
