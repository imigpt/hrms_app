import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/policies/data/models/policy_model.dart';

class PoliciesState extends Equatable {
  static const Object _unset = Object();

  final List<CompanyPolicy> policies;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String searchQuery;
  final DateTime? lastUpdated;
  final int totalCount;

  const PoliciesState({
    this.policies = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdated,
    this.totalCount = 0,
  });

  PoliciesState copyWith({
    List<CompanyPolicy>? policies,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _unset,
    String? searchQuery,
    DateTime? lastUpdated,
    int? totalCount,
  }) {
    return PoliciesState(
      policies: policies ?? this.policies,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [
        policies,
        isLoading,
        isSubmitting,
        errorMessage,
        searchQuery,
        lastUpdated,
        totalCount,
      ];
}
