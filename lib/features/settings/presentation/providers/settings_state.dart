import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/attendance/data/models/update_location_model.dart';

class SettingsState extends Equatable {
  static const Object _sentinel = Object();

  final Map<String, dynamic> allSettings;
  final Map<String, dynamic> companySettings;
  final Map<String, dynamic> translationSettings;
  final Map<String, dynamic> hrmSettings;
  final Map<String, dynamic> payrollSettings;
  final Map<String, dynamic> roleSettings;
  final Map<String, dynamic> workStatusSettings;
  final Map<String, dynamic> currencySettings;
  final Map<String, dynamic> locationSettings;
  final Map<String, dynamic> pdfFontSettings;
  final Map<String, dynamic> emailSettings;
  final Map<String, dynamic> customFieldSettings;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final String currentSettingsSection;
  final String searchQuery;
  final Set<String> unsavedSections;
  final Map<String, DateTime> lastUpdatedTimes;
  final bool preferencesLoaded;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final bool locationTrackingEnabled;
  final bool isUpdatingLocation;
  final UpdateLocation? lastLocationUpdate;

  const SettingsState({
    this.allSettings = const {},
    this.companySettings = const {},
    this.translationSettings = const {},
    this.hrmSettings = const {},
    this.payrollSettings = const {},
    this.roleSettings = const {},
    this.workStatusSettings = const {},
    this.currencySettings = const {},
    this.locationSettings = const {},
    this.pdfFontSettings = const {},
    this.emailSettings = const {},
    this.customFieldSettings = const {},
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.currentSettingsSection = 'company',
    this.searchQuery = '',
    this.unsavedSections = const {},
    this.lastUpdatedTimes = const {},
    this.preferencesLoaded = false,
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.locationTrackingEnabled = true,
    this.isUpdatingLocation = false,
    this.lastLocationUpdate,
  });

  // ── Computed Getters ─────────────────────────────────────────────────────

  /// Check if settings have unsaved changes
  bool get hasUnsavedChanges => unsavedSections.isNotEmpty;

  /// Get current section's settings
  Map<String, dynamic> get currentSectionSettings {
    switch (currentSettingsSection) {
      case 'company':
        return companySettings;
      case 'translation':
        return translationSettings;
      case 'hrm':
        return hrmSettings;
      case 'payroll':
        return payrollSettings;
      case 'role':
        return roleSettings;
      case 'work_status':
        return workStatusSettings;
      case 'currency':
        return currencySettings;
      case 'location':
        return locationSettings;
      case 'pdf_font':
        return pdfFontSettings;
      case 'email':
        return emailSettings;
      case 'custom_field':
        return customFieldSettings;
      default:
        return {};
    }
  }

  /// Check if current section is loading
  bool get isCurrentSectionLoading =>
      isLoading && currentSettingsSection.isNotEmpty;

  /// Check if current section has unsaved changes
  bool get currentSectionHasChanges =>
      unsavedSections.contains(currentSettingsSection);

  /// Get list of all sections with unsaved changes
  List<String> get sectionsWithChanges => unsavedSections.toList();

  /// Get company name if available
  String get companyName =>
      companySettings['name'] ?? companySettings['companyName'] ?? 'Unknown';

  /// Get company timezone if available
  String get companyTimezone =>
      companySettings['timezone'] ?? companySettings['defaultTimezone'] ?? 'UTC';

  /// Get default language/locale
  String get defaultLanguage =>
      translationSettings['defaultLanguage'] ??
      translationSettings['language'] ??
      'en';

  /// Check if any settings are being saved
  bool get isSavingAny => isSaving;

    /// Check if local preferences have been loaded from persistent storage
    bool get isReady => preferencesLoaded;

    /// Whether location can be refreshed right now
    bool get canUpdateLocation =>
      locationTrackingEnabled && !isUpdatingLocation;

  /// Get last update time for a section
    DateTime? getLastUpdatedTime(String section) => lastUpdatedTimes[section];

  @override
  List<Object?> get props => [
    allSettings,
    companySettings,
    translationSettings,
    hrmSettings,
    payrollSettings,
    roleSettings,
    workStatusSettings,
    currencySettings,
    locationSettings,
    pdfFontSettings,
    emailSettings,
    customFieldSettings,
    isLoading,
    isRefreshing,
    isSaving,
    error,
    successMessage,
    currentSettingsSection,
    searchQuery,
    unsavedSections,
    lastUpdatedTimes,
    preferencesLoaded,
    notificationsEnabled,
    biometricEnabled,
    locationTrackingEnabled,
    isUpdatingLocation,
    lastLocationUpdate,
  ];

  SettingsState copyWith({
    Map<String, dynamic>? allSettings,
    Map<String, dynamic>? companySettings,
    Map<String, dynamic>? translationSettings,
    Map<String, dynamic>? hrmSettings,
    Map<String, dynamic>? payrollSettings,
    Map<String, dynamic>? roleSettings,
    Map<String, dynamic>? workStatusSettings,
    Map<String, dynamic>? currencySettings,
    Map<String, dynamic>? locationSettings,
    Map<String, dynamic>? pdfFontSettings,
    Map<String, dynamic>? emailSettings,
    Map<String, dynamic>? customFieldSettings,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSaving,
    Object? error = _sentinel,
    Object? successMessage = _sentinel,
    String? currentSettingsSection,
    String? searchQuery,
    Set<String>? unsavedSections,
    Map<String, DateTime>? lastUpdatedTimes,
    bool? preferencesLoaded,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? locationTrackingEnabled,
    bool? isUpdatingLocation,
    Object? lastLocationUpdate = _sentinel,
  }) {
    return SettingsState(
      allSettings: allSettings ?? this.allSettings,
      companySettings: companySettings ?? this.companySettings,
      translationSettings: translationSettings ?? this.translationSettings,
      hrmSettings: hrmSettings ?? this.hrmSettings,
      payrollSettings: payrollSettings ?? this.payrollSettings,
      roleSettings: roleSettings ?? this.roleSettings,
      workStatusSettings: workStatusSettings ?? this.workStatusSettings,
      currencySettings: currencySettings ?? this.currencySettings,
      locationSettings: locationSettings ?? this.locationSettings,
      pdfFontSettings: pdfFontSettings ?? this.pdfFontSettings,
      emailSettings: emailSettings ?? this.emailSettings,
      customFieldSettings: customFieldSettings ?? this.customFieldSettings,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
        error: identical(error, _sentinel) ? this.error : error as String?,
        successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
      currentSettingsSection:
          currentSettingsSection ?? this.currentSettingsSection,
        searchQuery: searchQuery ?? this.searchQuery,
      unsavedSections: unsavedSections ?? this.unsavedSections,
      lastUpdatedTimes: lastUpdatedTimes ?? this.lastUpdatedTimes,
        preferencesLoaded: preferencesLoaded ?? this.preferencesLoaded,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
        isUpdatingLocation: isUpdatingLocation ?? this.isUpdatingLocation,
        lastLocationUpdate: identical(lastLocationUpdate, _sentinel)
          ? this.lastLocationUpdate
          : lastLocationUpdate as UpdateLocation?,
    );
  }
}
