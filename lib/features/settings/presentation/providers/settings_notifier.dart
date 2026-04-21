import 'package:flutter/foundation.dart';
import 'package:hrms_app/shared/services/core/settings_service.dart';
import 'package:hrms_app/shared/services/device/location_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsNotifier extends ChangeNotifier {
  static const String _kSearchQuery = 'settings.search_query';
  static const String _kCurrentSection = 'settings.current_section';
  static const String _kNotificationsEnabled =
      'settings.notifications_enabled';
  static const String _kBiometricEnabled = 'settings.biometric_enabled';
  static const String _kLocationTrackingEnabled =
      'settings.location_tracking_enabled';

  final LocationUpdateService _locationService;
  final Future<SharedPreferences> Function() _prefsFactory;

  SettingsState _state = const SettingsState();

  SettingsNotifier({
    LocationUpdateService? locationService,
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _locationService = locationService ?? LocationUpdateService(),
       _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  SettingsState get state => _state;

  // ── Private Helper ──────────────────────────────────────────────────────

  void _setState(SettingsState newState) {
    _state = newState;
    notifyListeners();
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return response;
  }

  Future<void> _persistString(String key, String value) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('SettingsNotifier: Failed to persist string "$key": $e');
    }
  }

  Future<void> _persistBool(String key, bool value) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('SettingsNotifier: Failed to persist bool "$key": $e');
    }
  }

  // ── Initialization & Local Preferences ──────────────────────────────────

  Future<void> initialize() async {
    if (_state.preferencesLoaded) return;

    try {
      final prefs = await _prefsFactory();

      _setState(_state.copyWith(
        searchQuery: prefs.getString(_kSearchQuery) ?? '',
        currentSettingsSection:
            prefs.getString(_kCurrentSection) ?? _state.currentSettingsSection,
        notificationsEnabled: prefs.getBool(_kNotificationsEnabled) ?? true,
        biometricEnabled: prefs.getBool(_kBiometricEnabled) ?? false,
        locationTrackingEnabled:
            prefs.getBool(_kLocationTrackingEnabled) ?? true,
        preferencesLoaded: true,
      ));
    } catch (e) {
      _setState(_state.copyWith(
        error: 'Failed to load local settings preferences',
      ));
    }
  }

  Future<void> setSearchQuery(String query) async {
    final normalized = query.trim();
    _setState(_state.copyWith(searchQuery: normalized));
    await _persistString(_kSearchQuery, normalized);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _setState(_state.copyWith(notificationsEnabled: value));
    await _persistBool(_kNotificationsEnabled, value);
  }

  Future<void> setBiometricEnabled(bool value) async {
    _setState(_state.copyWith(biometricEnabled: value));
    await _persistBool(_kBiometricEnabled, value);
  }

  Future<void> setLocationTrackingEnabled(bool value) async {
    _setState(_state.copyWith(locationTrackingEnabled: value));
    await _persistBool(_kLocationTrackingEnabled, value);
  }

  Future<bool> updateCurrentLocation() async {
    if (_state.isUpdatingLocation) return false;

    if (!_state.locationTrackingEnabled) {
      _setState(_state.copyWith(
        error: 'Location tracking is disabled in settings',
      ));
      return false;
    }

    _setState(_state.copyWith(
      isUpdatingLocation: true,
      error: null,
      successMessage: null,
    ));

    try {
      final result = await _locationService.updateCurrentLocation();

      if (result != null && result.success) {
        _setState(_state.copyWith(
          isUpdatingLocation: false,
          lastLocationUpdate: result,
          successMessage: 'Location updated successfully',
          lastUpdatedTimes: {
            ..._state.lastUpdatedTimes,
            'location': DateTime.now(),
          },
        ));
        return true;
      }

      _setState(_state.copyWith(
        isUpdatingLocation: false,
        error: 'Failed to update location',
      ));
      return false;
    } catch (e) {
      _setState(_state.copyWith(
        isUpdatingLocation: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  // ── Load Data Methods ───────────────────────────────────────────────────

  /// Load company settings
  Future<void> loadCompanySettings(String token) async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      final response = await SettingsService.getCompanySettings(token);

      if (response['success'] == true) {
        final data = _extractData(response);

        _setState(_state.copyWith(
          companySettings: data,
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
        final data = _extractData(response);

        _setState(_state.copyWith(
          hrmSettings: data,
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
        final data = _extractData(response);

        _setState(_state.copyWith(
          payrollSettings: data,
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
        final data = _extractData(response);

        _setState(_state.copyWith(
          translationSettings: data,
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
  Future<void> switchSection(String section) async {
    _setState(_state.copyWith(
      currentSettingsSection: section,
      successMessage: null,
    ));

    await _persistString(_kCurrentSection, section);
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
