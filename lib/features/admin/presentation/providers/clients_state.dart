import 'package:equatable/equatable.dart';

class ClientsState extends Equatable {
  final List<dynamic> clients;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final String searchQuery;
  final String statusFilter;

  const ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.searchQuery = '',
    this.statusFilter = '',
  });

  ClientsState copyWith({
    List<dynamic>? clients,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    String? searchQuery,
    String? statusFilter,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [
    clients,
    isLoading,
    isSaving,
    error,
    successMessage,
    searchQuery,
    statusFilter,
  ];
}