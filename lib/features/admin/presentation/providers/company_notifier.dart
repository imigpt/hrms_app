import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/admin/data/services/company_service.dart';
import 'package:hrms_app/features/admin/presentation/providers/company_state.dart';

class CompanyNotifier extends ChangeNotifier {
  CompanyState _state = const CompanyState();
  late CompanyService _service;

  CompanyState get state => _state;

  CompanyNotifier({CompanyService? service}) {
    _service = service ?? CompanyService();
  }

  void _setState(CompanyState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Fetch all companies
  Future<void> fetchCompanies() async {
    _setState(_state.copyWith(isLoading: true, error: null));
    try {
      final result = await _service.getCompanies();
      _setState(_state.copyWith(companies: result, isLoading: false));
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  /// Create a new company
  Future<bool> createCompany({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? website,
    String? industry,
    String size = 'medium',
    int? companySize,
    String? password,
  }) async {
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      await _service.createCompany(
        name: name,
        email: email,
        phone: phone,
        address: address,
        website: website,
        industry: industry,
        size: size,
        companySize: companySize,
      );
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Company created successfully',
      ));
      await fetchCompanies();
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString(),
        isSaving: false,
      ));
      return false;
    }
  }

  /// Update a company
  Future<bool> updateCompany({
    required String id,
    required String name,
    required String email,
    required String phone,
    String? address,
    String? website,
    String? industry,
    String? size,
    int? companySize,
    String? status,
  }) async {
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      await _service.updateCompany(
        id: id,
        name: name,
        email: email,
        phone: phone,
        address: address,
        website: website,
        industry: industry,
        size: size,
        companySize: companySize,
        status: status,
      );
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Company updated successfully',
      ));
      await fetchCompanies();
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString(),
        isSaving: false,
      ));
      return false;
    }
  }

  /// Delete a company
  Future<bool> deleteCompany(String id) async {
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      await _service.deleteCompany(id);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Company deleted successfully',
      ));
      await fetchCompanies();
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString(),
        isSaving: false,
      ));
      return false;
    }
  }

  /// Approve a pending company
  Future<bool> approveCompany(String id) async {
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      await _service.approveCompany(id);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Company approved successfully',
      ));
      await fetchCompanies();
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString(),
        isSaving: false,
      ));
      return false;
    }
  }

  /// Reject a company
  Future<bool> rejectCompany(String id, String reason) async {
    _setState(_state.copyWith(isSaving: true, error: null));
    try {
      await _service.rejectCompany(id, reason);
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Company rejected successfully',
      ));
      await fetchCompanies();
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString(),
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
  void clearSuccess() {
    _setState(_state.copyWith(successMessage: null));
  }
}
