import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/admin/data/services/admin_employees_service.dart';
import 'package:hrms_app/features/admin/presentation/providers/all_employees_state.dart';

class AllEmployeesNotifier extends ChangeNotifier {
  AllEmployeesState _state = const AllEmployeesState();

  AllEmployeesState get state => _state;

  void _setState(AllEmployeesState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadEmployees(String token, {String role = 'admin'}) async {
    _setState(_state.copyWith(isLoading: true));
    try {
      final result = await AdminEmployeesService.getAllEmployees(token, role: role);
      if (result['success'] == true) {
        final data = (result['data'] as List<dynamic>?) ?? [];
        final seenCompanies = <String>{};
        final companiesList = <Map<String, dynamic>>[];
        final deptSet = <String>{};

        for (final emp in data) {
          final compObj = emp['company'];
          if (compObj is Map) {
            final id = compObj['_id']?.toString() ?? '';
            final name = compObj['name']?.toString() ?? '';
            if (id.isNotEmpty && !seenCompanies.contains(id)) {
              seenCompanies.add(id);
              companiesList.add({'_id': id, 'name': name});
            }
          }
          final dept = emp['department']?.toString() ?? '';
          if (dept.isNotEmpty) deptSet.add(dept);
        }

        final sortedDepts = deptSet.toList()..sort();

        _setState(_state.copyWith(
          allEmployees: data,
          filteredEmployees: data,
          companies: companiesList,
          departments: sortedDepts,
          isLoading: false,
        ));
      } else {
        _setState(_state.copyWith(
          error: result['message'] ?? 'Failed to load employees',
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

  void applyFilters({
    required String query,
    required String selectedCompanyId,
    required String selectedDepartment,
    required String selectedStatus,
  }) {
    final q = query.toLowerCase();
    final filtered = _state.allEmployees.where((emp) {
      if (selectedCompanyId.isNotEmpty) {
        final compId = (emp['company'] is Map)
            ? (emp['company']['_id']?.toString() ?? '')
            : '';
        if (compId != selectedCompanyId) return false;
      }
      if (selectedDepartment.isNotEmpty) {
        if ((emp['department']?.toString() ?? '') != selectedDepartment) {
          return false;
        }
      }
      if (selectedStatus.isNotEmpty) {
        if ((emp['status']?.toString() ?? '') != selectedStatus) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final name = (emp['name'] ?? '').toString().toLowerCase();
        final email = (emp['email'] ?? '').toString().toLowerCase();
        final empId = (emp['employeeId'] ?? '').toString().toLowerCase();
        final phone = (emp['phone'] ?? '').toString().toLowerCase();
        final dept = (emp['department'] ?? '').toString().toLowerCase();
        final pos = (emp['position'] ?? '').toString().toLowerCase();
        if (!name.contains(q) &&
            !email.contains(q) &&
            !empId.contains(q) &&
            !phone.contains(q) &&
            !dept.contains(q) &&
            !pos.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    _setState(_state.copyWith(
      filteredEmployees: filtered,
    ));
  }

  Future<bool> addEmployee(String token, Map<String, dynamic> data, File? profilePhoto, {String role = 'admin'}) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      await AdminEmployeesService.addEmployee(
        token: token,
        name: data['name'] ?? '',
        employeeId: data['employeeId'] ?? '',
        password: data['password'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'],
        dateOfBirth: data['dateOfBirth'],
        address: data['address'],
        department: data['department'],
        position: data['position'],
        joinDate: data['joinDate'],
        salary: data['salary']?.toString(),
        salaryType: data['salaryType'],
        status: data['status'],
        company: data['company'],
        role: role,
        profilePhoto: profilePhoto,
      );
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Employee added successfully',
      ));
      await loadEmployees(token, role: role);
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
      ));
      return false;
    }
  }

  Future<bool> updateEmployee(String token, String employeeId, Map<String, dynamic> data, File? profilePhoto, {String role = 'admin'}) async {
    _setState(_state.copyWith(isSaving: true));
    try {
      await AdminEmployeesService.updateEmployee(
        token: token,
        employeeId: employeeId,
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        dateOfBirth: data['dateOfBirth'],
        address: data['address'],
        department: data['department'],
        position: data['position'],
        joinDate: data['joinDate'],
        status: data['status'],
        company: data['company'],
        role: role,
        profilePhoto: profilePhoto,
      );
      _setState(_state.copyWith(
        isSaving: false,
        successMessage: 'Employee updated successfully',
      ));
      await loadEmployees(token, role: role);
      return true;
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isSaving: false,
      ));
      return false;
    }
  }

  void clearMessages() {
    if (_state.error != null || _state.successMessage != null) {
      _setState(_state.copyWith());
    }
  }
}
