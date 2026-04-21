import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';

class ProfileState extends Equatable {
  static const Object _unset = Object();

  final ProfileUser? currentUser;
  final bool isLoading;
  final bool isSaving;
  final bool isEditing;
  final String? errorMessage;
  final bool isInitialized;
  final Map<String, String> employmentData;
  final String profileImage;
  final String dob;

  const ProfileState({
    this.currentUser,
    this.isLoading = false,
    this.isSaving = false,
    this.isEditing = false,
    this.errorMessage,
    this.isInitialized = false,
    this.employmentData = const {},
    this.profileImage = '',
    this.dob = '-',
  });

  ProfileState copyWith({
    Object? currentUser = _unset,
    bool? isLoading,
    bool? isSaving,
    bool? isEditing,
    Object? errorMessage = _unset,
    bool? isInitialized,
    Map<String, String>? employmentData,
    String? profileImage,
    String? dob,
  }) {
    return ProfileState(
      currentUser: identical(currentUser, _unset)
          ? this.currentUser
          : currentUser as ProfileUser?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isInitialized: isInitialized ?? this.isInitialized,
      employmentData: employmentData ?? this.employmentData,
      profileImage: profileImage ?? this.profileImage,
      dob: dob ?? this.dob,
    );
  }

  @override
  List<Object?> get props => [
    currentUser,
    isLoading,
    isSaving,
    isEditing,
    errorMessage,
    isInitialized,
    employmentData,
    profileImage,
    dob,
  ];
}
