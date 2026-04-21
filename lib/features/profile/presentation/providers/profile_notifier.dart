import 'package:flutter/foundation.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';
import 'profile_state.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Profile Notifier (ChangeNotifier for state management)
// ═══════════════════════════════════════════════════════════════════════════

class ProfileNotifier extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileState _state = const ProfileState();

  ProfileNotifier({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  ProfileState get state => _state;

  void _setState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialize profile from passed user (on screen creation)
  void initializeProfile(ProfileUser? user) {
    if (user == null) return;

    debugPrint('🔍 ProfileNotifier: Initializing with user: ${user.name}');

    _setState(_state.copyWith(
      currentUser: user,
      isInitialized: true,
      profileImage: user.profilePhotoUrl,
      dob: _formatDate(user.dateOfBirth) ?? "-",
      employmentData: _buildEmploymentData(user),
    ));
  }

  /// Fetch fresh profile from API
  Future<void> fetchProfile(String token, {String role = 'employee'}) async {
    if (_state.isLoading) return;

    _setState(_state.copyWith(
      isLoading: true,
      errorMessage: null,
    ));

    try {
      debugPrint('📡 ProfileNotifier: Fetching profile from API...');

      final freshUser = await _profileService.fetchProfile(
        token,
        role: role,
      );

      if (freshUser != null) {
        debugPrint('✅ ProfileNotifier: Profile loaded successfully');
        _setState(_state.copyWith(
          currentUser: freshUser,
          isLoading: false,
          profileImage: freshUser.profilePhotoUrl,
          dob: _formatDate(freshUser.dateOfBirth) ?? "-",
          employmentData: _buildEmploymentData(freshUser),
        ));
      } else {
        debugPrint('⚠️ ProfileNotifier: API returned null user');
        _setState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load profile',
        ));
      }
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Error fetching profile: $e');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile: $e',
      ));
    }
  }

  /// Save profile changes
  Future<bool> saveProfile({
    required String token,
    required String name,
    required String phone,
    required String address,
    required DateTime? dateOfBirth,
  }) async {
    if (_state.currentUser == null || _state.isSaving) return false;

    _setState(_state.copyWith(
      isSaving: true,
      errorMessage: null,
    ));

    try {
      debugPrint('💾 ProfileNotifier: Saving profile...');

      // Build payload with only provided values
      final Map<String, dynamic> payload = {};
      if (name.trim().isNotEmpty) payload['name'] = name.trim();
      if (phone.trim().isNotEmpty) payload['phone'] = phone.trim();
      if (address.trim().isNotEmpty) payload['address'] = address.trim();
      if (dateOfBirth != null) {
        payload['dateOfBirth'] = dateOfBirth.toIso8601String();
      }

      if (payload.isEmpty) {
        debugPrint('⚠️ ProfileNotifier: No changes to save');
        _setState(_state.copyWith(
          isSaving: false,
          errorMessage: 'No changes to save',
        ));
        return false;
      }

      final result = await _profileService.updateProfile(
        token: token,
        userId: _state.currentUser!.id,
        payload: payload,
      );

      if (result['success'] == true) {
        final saved = result['user'] as ProfileUser;
        debugPrint('✅ ProfileNotifier: Profile saved successfully');

        _setState(_state.copyWith(
          currentUser: saved,
          isSaving: false,
          isEditing: false,
          profileImage: saved.profilePhotoUrl,
          dob: _formatDate(saved.dateOfBirth) ?? "-",
          employmentData: _buildEmploymentData(saved),
        ));
        return true;
      } else {
        final errorMessage = result['message'] ?? 'Profile update failed';
        debugPrint('❌ ProfileNotifier: Save failed - $errorMessage');

        _setState(_state.copyWith(
          isSaving: false,
          errorMessage: errorMessage,
        ));
        return false;
      }
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Error saving profile: $e');
      _setState(_state.copyWith(
        isSaving: false,
        errorMessage: 'Error saving profile: $e',
      ));
      return false;
    }
  }

  /// Upload profile photo and refresh local profile state.
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String imagePath,
  }) async {
    _setState(_state.copyWith(
      isSaving: true,
      errorMessage: null,
    ));

    try {
      final result = await _profileService.uploadProfilePhoto(
        token: token,
        imagePath: imagePath,
      );

      if (result['success'] == true) {
        final updatedUser = result['user'] as ProfileUser?;
        if (updatedUser != null) {
          _setState(_state.copyWith(
            currentUser: updatedUser,
            isSaving: false,
            profileImage: updatedUser.profilePhotoUrl,
            dob: _formatDate(updatedUser.dateOfBirth) ?? '-',
            employmentData: _buildEmploymentData(updatedUser),
          ));
        } else {
          _setState(_state.copyWith(isSaving: false));
        }
      } else {
        _setState(_state.copyWith(
          isSaving: false,
          errorMessage: (result['message'] ?? 'Failed to upload photo').toString(),
        ));
      }

      return result;
    } catch (e) {
      final message = 'Error uploading photo: $e';
      _setState(_state.copyWith(
        isSaving: false,
        errorMessage: message,
      ));
      return {
        'success': false,
        'message': message,
      };
    }
  }

  /// Toggle edit mode
  void toggleEditMode() {
    _setState(_state.copyWith(isEditing: !_state.isEditing));
    debugPrint('🔄 ProfileNotifier: Edit mode = ${_state.isEditing}');
  }

  /// Cancel edit mode and discard changes (revert to last saved state)
  void cancelEditMode() {
    if (_state.currentUser == null) return;
    
    debugPrint('🔙 ProfileNotifier: Cancelling edit mode, reverting changes');
    _setState(_state.copyWith(
      isEditing: false,
      dob: _formatDate(_state.currentUser!.dateOfBirth) ?? "-",
      errorMessage: null,
    ));
  }

  /// Clear error message
  void clearError() {
    _setState(_state.copyWith(errorMessage: null));
  }

  /// Update DOB when selected
  void updateDob(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return;
    
    final user = _state.currentUser;
    if (user == null) return;

    final updatedUser = ProfileUser(
      id: user.id,
      employeeId: user.employeeId,
      name: user.name,
      email: user.email,
      phone: user.phone,
      dateOfBirth: dateOfBirth,
      address: user.address,
      role: user.role,
      department: user.department,
      position: user.position,
      joinDate: user.joinDate,
      status: user.status,
      profilePhoto: user.profilePhoto,
      leaveBalance: user.leaveBalance,
    );

    _setState(_state.copyWith(
      currentUser: updatedUser,
      dob: _formatDate(dateOfBirth) ?? "-",
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String? _formatDate(DateTime? date) {
    if (date == null) return null;

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    final month = months[date.month - 1];
    return "$month ${date.day}, ${date.year}";
  }

  String? _titleCase(String? value) {
    if (value == null || value.isEmpty) return null;

    final cleaned = value.replaceAll(RegExp(r"[_-]+"), " ").trim();
    if (cleaned.isEmpty) return null;

    return cleaned
        .split(RegExp(r"\s+"))
        .map(
          (part) => part.isEmpty
              ? part
              : part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(" ");
  }

  Map<String, String> _buildEmploymentData(ProfileUser user) {
    return {
      "Employee ID": user.employeeId,
      "Department": _titleCase(user.department) ?? "",
      "Position": user.position,
      "Role": _titleCase(user.role) ?? "",
      "Status": _titleCase(user.status) ?? "",
      "Join Date": _formatDate(user.joinDate) ?? "",
    };
  }
}
