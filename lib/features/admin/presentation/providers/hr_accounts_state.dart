import 'package:equatable/equatable.dart';

class HRAccountsState extends Equatable {
  final List<dynamic> hrAccounts;
  final List<dynamic> filteredAccounts;
  final List<dynamic> companies;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const HRAccountsState({
    this.hrAccounts = const [],
    this.filteredAccounts = const [],
    this.companies = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  HRAccountsState copyWith({
    List<dynamic>? hrAccounts,
    List<dynamic>? filteredAccounts,
    List<dynamic>? companies,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return HRAccountsState(
      hrAccounts: hrAccounts ?? this.hrAccounts,
      filteredAccounts: filteredAccounts ?? this.filteredAccounts,
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        hrAccounts,
        filteredAccounts,
        companies,
        isLoading,
        isSaving,
        error,
        successMessage,
      ];
}
