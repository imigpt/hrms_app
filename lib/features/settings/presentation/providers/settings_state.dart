import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
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
  final Set<String> unsavedSections;
  final Map<String, DateTime> lastUpdatedTimes;

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
    this.unsavedSections = const {},
    this.lastUpdatedTimes = const {},
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
  List<String> get sectionsWithChanges =>
      unsavedSections.toList();

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

  /// Get last update time for a section
  DateTime? getLastUpdatedTime(String section) =>
      lastUpdatedTimes[section];

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
    unsavedSections,
    lastUpdatedTimes,
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
    String? error,
    String? successMessage,
    String? currentSettingsSection,
    Set<String>? unsavedSections,
    Map<String, DateTime>? lastUpdatedTimes,
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
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      currentSettingsSection:
          currentSettingsSection ?? this.currentSettingsSection,
      unsavedSections: unsavedSections ?? this.unsavedSections,
      lastUpdatedTimes: lastUpdatedTimes ?? this.lastUpdatedTimes,
    );
  }
}
