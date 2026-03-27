import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/admin/data/models/company_model.dart';

class CompanyState extends Equatable {
  final List<Company> companies;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const CompanyState({
    this.companies = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  CompanyState copyWith({
    List<Company>? companies,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return CompanyState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }

  // Stats getters
  int get totalCompanies => companies.length;
  int get activeCompanies => companies.where((c) => c.status == 'active').length;
  int get pendingCompanies => companies.where((c) => c.status == 'pending').length;
  int get totalEmployees => companies.fold<int>(0, (sum, c) => sum + (c.employeeCount ?? 0));
  int get totalHR => companies.fold<int>(0, (sum, c) => sum + (c.hrCount ?? 0));

  @override
  List<Object?> get props => [
    companies,
    isLoading,
    isSaving,
    error,
    successMessage,
  ];
}
