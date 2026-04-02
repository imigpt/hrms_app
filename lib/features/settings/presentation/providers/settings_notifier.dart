import 'package:flutter/foundation.dart';
import 'package:hrms_app/shared/services/core/settings_service.dart';
import 'settings_state.dart';

class SettingsNotifier extends ChangeNotifier {
  SettingsState _state = const SettingsState();

  SettingsNotifier();

  SettingsState get state => _state;

  // ── Private Helper ──────────────────────────────────────────────────────

  void _setState(SettingsState newState) {
    _state = newState;
    notifyListeners();
  }

  // ── Load Data Methods ───────────────────────────────────────────────────

  /// Load company settings
  Future<void> loadCompanySettings(String token) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await SettingsService.getCompanySettings(token);

      if (response['success'] == true) {
        final data = response['data'] ?? response;

        _setState(_state.copyWith(
          companySettings: data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{},
          isLoading: false,
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'company': DateTime.now(),
          },
        ));
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to load company settings',
          isLoading: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  /// Load HRM settings
  Future<void> loadHRMSettings(String token) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await SettingsService.getHRMSettings(token);

      if (response['success'] == true) {
        final data = response['data'] ?? response;

        _setState(_state.copyWith(
          hrmSettings: data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{},
          isLoading: false,
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'hrm': DateTime.now(),
          },
        ));
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to load HRM settings',
          isLoading: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  /// Load payroll settings
  Future<void> loadPayrollSettings(String token) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await SettingsService.getPayrollSettings(token);

      if (response['success'] == true) {
        final data = response['data'] ?? response;

        _setState(_state.copyWith(
          payrollSettings: data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{},
          isLoading: false,
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'payroll': DateTime.now(),
          },
        ));
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to load payroll settings',
          isLoading: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  /// Load translation/localization settings
  Future<void> loadTranslationSettings(String token) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await SettingsService.getLocalizationSettings(token);

      if (response['success'] == true) {
        final data = response['data'] ?? response;

        _setState(_state.copyWith(
          translationSettings: data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{},
          isLoading: false,
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'translation': DateTime.now(),
          },
        ));
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to load translation settings',
          isLoading: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  /// Refresh all settings
  Future<void> refreshAllSettings(String token) async {
    try {
      _setState(_state.copyWith(isRefreshing: true, error: null));

      await Future.wait([
        loadCompanySettings(token),
        loadHRMSettings(token),
        loadPayrollSettings(token),
        loadTranslationSettings(token),
      ]);

      _setState(_state.copyWith(isRefreshing: false));
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isRefreshing: false,
      ));
    }
  }

  // ── Update Methods ──────────────────────────────────────────────────────

  /// Update company settings
  Future<void> updateCompanySettings(
    String token,
    Map<String, dynamic> updates,
  ) async {
    try {
      _setState(_state.copyWith(isSaving: true, error: null));

      final response = await SettingsService.updateCompanySettings(
        token,
        updates,
      );

      if (response['success'] == true) {
        final updatedSettings = {
          ..._state.companySettings,
          ...updates,
        };

        _setState(_state.copyWith(
          companySettings: updatedSettings,
          isSaving: false,
          successMessage: 'Company settings updated successfully',
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'company': DateTime.now(),
          },
        ));

        // Clear unsaved flag
        _clearUnsavedSection('company');
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to update company settings',
          isSaving: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isSaving: false,
      ));
      rethrow;
    }
  }

  /// Update HRM settings
  Future<void> updateHRMSettings(
    String token,
    Map<String, dynamic> updates,
  ) async {
    try {
      _setState(_state.copyWith(isSaving: true, error: null));

      final response = await SettingsService.updateHRMSettings(
        token,
        updates,
      );

      if (response['success'] == true) {
        final updatedSettings = {
          ..._state.hrmSettings,
          ...updates,
        };

        _setState(_state.copyWith(
          hrmSettings: updatedSettings,
          isSaving: false,
          successMessage: 'HRM settings updated successfully',
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'hrm': DateTime.now(),
          },
        ));

        _clearUnsavedSection('hrm');
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to update HRM settings',
          isSaving: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isSaving: false,
      ));
      rethrow;
    }
  }

  /// Update payroll settings
  Future<void> updatePayrollSettings(
    String token,
    Map<String, dynamic> updates,
  ) async {
    try {
      _setState(_state.copyWith(isSaving: true, error: null));

      final response = await SettingsService.updatePayrollSettings(
        token,
        updates,
      );

      if (response['success'] == true) {
        final updatedSettings = {
          ..._state.payrollSettings,
          ...updates,
        };

        _setState(_state.copyWith(
          payrollSettings: updatedSettings,
          isSaving: false,
          successMessage: 'Payroll settings updated successfully',
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'payroll': DateTime.now(),
          },
        ));

        _clearUnsavedSection('payroll');
      } else {
        _setState(_state.copyWith(
          error: response['message'] ?? 'Failed to update payroll settings',
          isSaving: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isSaving: false,
      ));
      rethrow;
    }
  }

  /// Update translation settings
  Future<void> updateTranslationSettings(
    String token,
    Map<String, dynamic> updates,
  ) async {
    try {
      _setState(_state.copyWith(isSaving: true, error: null));

      final response = await SettingsService.updateLocalizationSettings(
        token,
        updates,
      );

      if (response['success'] == true) {
        final updatedSettings = {
          ..._state.translationSettings,
          ...updates,
        };

        _setState(_state.copyWith(
          translationSettings: updatedSettings,
          isSaving: false,
          successMessage: 'Translation settings updated successfully',
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'translation': DateTime.now(),
          },
        ));

        _clearUnsavedSection('translation');
      } else {
        _setState(_state.copyWith(
          error: response['message'] ??
              'Failed to update translation settings',
          isSaving: false,
        ));
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isSaving: false,
      ));
      rethrow;
    }
  }

  // ── Section Navigation ──────────────────────────────────────────────────

  /// Switch to a different settings section
  void switchSection(String section) {
    _setState(_state.copyWith(
      currentSettingsSection: section,
      successMessage: null,
    ));
  }

  // ── Change Tracking ────────────────────────────────────────────────────

  /// Mark a section as having unsaved changes
  void markSectionUnsaved(String section) {
    final unsaved = Set<String>.from(_state.unsavedSections);
    unsaved.add(section);
    _setState(_state.copyWith(unsavedSections: unsaved));
  }

  /// Clear unsaved flag for a section
  void _clearUnsavedSection(String section) {
    final unsaved = Set<String>.from(_state.unsavedSections);
    unsaved.remove(section);
    _setState(_state.copyWith(unsavedSections: unsaved));
  }

  /// Clear all unsaved changes
  void clearAllUnsavedChanges() {
    _setState(_state.copyWith(unsavedSections: const {}));
  }

  // ── UI State Methods ────────────────────────────────────────────────────

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(error: null));
  }

  /// Clear success message
  void clearSuccessMessage() {
    _setState(_state.copyWith(successMessage: null));
  }

  // ── Reset & Cleanup ────────────────────────────────────────────────────

  /// Reset all settings state
  void reset() {
    _setState(const SettingsState());
  }

  /// Discard unsaved changes for a section and reload it
  Future<void> discardChanges(String token, String section) async {
    _clearUnsavedSection(section);

    try {
      switch (section) {
        case 'company':
          await loadCompanySettings(token);
          break;
        case 'hrm':
          await loadHRMSettings(token);
          break;
        case 'payroll':
          await loadPayrollSettings(token);
          break;
        case 'translation':
          await loadTranslationSettings(token);
          break;
      }
    } catch (e) {
      _setState(_state.copyWith(
        error: 'Failed to reload settings: ${e.toString()}',
      ));
    }
  }
}
