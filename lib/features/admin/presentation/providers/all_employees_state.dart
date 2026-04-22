import 'package:equatable/equatable.dart';

class AllEmployeesState extends Equatable {
  final List<dynamic> allEmployees;
  final List<dynamic> filteredEmployees;
  final List<Map<String, dynamic>> companies;
  final List<String> departments;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const AllEmployeesState({
    this.allEmployees = const [],
    this.filteredEmployees = const [],
    this.companies = const [],
    this.departments = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  AllEmployeesState copyWith({
    List<dynamic>? allEmployees,
    List<dynamic>? filteredEmployees,
    List<Map<String, dynamic>>? companies,
    List<String>? departments,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return AllEmployeesState(
      allEmployees: allEmployees ?? this.allEmployees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      companies: companies ?? this.companies,
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        allEmployees,
        filteredEmployees,
        companies,
        departments,
        isLoading,
        isSaving,
        error,
        successMessage,
      ];
}
