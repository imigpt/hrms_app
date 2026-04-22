import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/admin/data/services/hr_accounts_service.dart';
import 'package:hrms_app/features/admin/presentation/providers/hr_accounts_state.dart';

class HRAccountsNotifier extends ChangeNotifier {
  HRAccountsState _state = const HRAccountsState();

  HRAccountsState get state => _state;

  void _setState(HRAccountsState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> fetchHRAccounts(String token) async {
    _setState(_state.copyWith(isLoading: true));
    try {
      final result = await HRAccountsService.getHRAccounts(token);
      if (result['success'] == true) {
        final accounts = result['data'] ?? [];
        _setState(_state.copyWith(
          hrAccounts: accounts,
          filteredAccounts: accounts,
          isLoading: false,
        ));
      } else {
        _setState(_state.copyWith(
          error: result['message'] ?? 'Failed to load HR accounts',
          isLoading: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  Future<void> fetchCompanies(String token) async {
    try {
      final list = await HRAccountsService.getCompanies(token);
      _setState(_state.copyWith(
        companies: list,
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        isLoading: _state.isLoading,
        isSaving: _state.isSaving,
        error: _state.error,
        successMessage: _state.successMessage,
      ));
    } catch (_) {}
  }

  void searchHRAccounts(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = _state.hrAccounts.where((account) {
      final name = (account['name'] ?? '').toString().toLowerCase();
      final email = (account['email'] ?? '').toString().toLowerCase();
      final employeeId = (account['employeeId'] ?? '').toString().toLowerCase();
      final companyName = (account['company']?['name'] ?? '').toString().toLowerCase();

      return name.contains(lowerQuery) ||
          email.contains(lowerQuery) ||
          employeeId.contains(lowerQuery) ||
          companyName.contains(lowerQuery);
    }).toList();

    _setState(_state.copyWith(
      filteredAccounts: filtered,
      hrAccounts: _state.hrAccounts,
      companies: _state.companies,
      isLoading: _state.isLoading,
      isSaving: _state.isSaving,
    ));
  }

  Future<bool> updateHRStatus(String token, String hrId, String newStatus) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      await HRAccountsService.updateHRStatus(token, hrId, newStatus);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Status updated to $newStatus',
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      await fetchHRAccounts(token);
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      return false;
    }
  }

  Future<bool> resetHRPassword(String token, String hrId) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      await HRAccountsService.resetHRPassword(token, hrId);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Password reset sent',
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      return false;
    }
  }

  Future<bool> createHRAccount(String token, Map<String, dynamic> data, File? photo) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      final result = await HRAccountsService.createHRAccountWithPhoto(token, data, photo);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'HR Manager created successfully',
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      await fetchHRAccounts(token);
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      return false;
    }
  }

  Future<bool> updateHRAccount(String token, String hrId, Map<String, dynamic> data, File? photo) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      await HRAccountsService.updateHRAccountWithPhoto(token, hrId, data, photo);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Manager updated successfully',
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      await fetchHRAccounts(token);
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      return false;
    }
  }

  Future<bool> deleteHRAccount(String token, String managerId) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      await HRAccountsService.deleteHRAccount(token, managerId);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Manager deleted successfully',
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      await fetchHRAccounts(token);
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
      ));
      return false;
    }
  }

  void clearMessages() {
    if (_state.error != null || _state.successMessage != null) {
      _setState(_state.copyWith(
        hrAccounts: _state.hrAccounts,
        filteredAccounts: _state.filteredAccounts,
        companies: _state.companies,
        isLoading: _state.isLoading,
        isSaving: _state.isSaving,
      ));
    }
  }
}
