import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';
import 'package:hrms_app/features/profile/presentation/providers/profile_notifier.dart';
import 'package:hrms_app/features/profile/presentation/providers/profile_state.dart';
import 'package:hrms_app/core/utils/responsive_utils.dart';
// import 'employee_api_test_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;
  final String role; // 'employee', 'hr', 'admin', 'client'

  const ProfileScreen({
    super.key,
    this.user,
    this.token,
    this.role = 'employee',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // -- Controllers (LOCAL STATE - NOT IN PROVIDER) --
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    
    // Debug: Log initial user data
    debugPrint('🔍 ProfileScreen InitState:');
    debugPrint('  Token: ${widget.token?.isNotEmpty == true ? "✓" : "✗"}');
    debugPrint('  User: ${user?.name ?? "NULL"}');
    debugPrint('  Role: ${widget.role}');
    
    // Create controllers once (kept as LOCAL state for form fields)
    _nameController = TextEditingController(text: user?.name ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
    _addressController = TextEditingController(text: user?.address ?? "");
    _bioController = TextEditingController(text: "");
    _emergencyNameController = TextEditingController(text: "");
    _emergencyPhoneController = TextEditingController(text: "");
    _dobController = TextEditingController(
      text: _formatDate(user?.dateOfBirth) ?? "",
    );
    
    debugPrint('  Initial Name: ${_nameController.text}');
    debugPrint('  Initial Phone: ${_phoneController.text}');
    debugPrint('  Initial Email: ${_emailController.text}');
    
    // Initialize Provider state & fetch fresh profile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileNotifier = context.read<ProfileNotifier>();
      
      // Initialize with passed user
      if (user != null) {
        profileNotifier.initializeProfile(user);
      }
      
      // Fetch fresh data from API
      if (widget.token != null && widget.token!.isNotEmpty) {
        await profileNotifier.fetchProfile(widget.token!, role: widget.role);
        
        // CRITICAL: Sync controllers with freshly fetched data
        if (mounted && profileNotifier.state.currentUser != null) {
          _applyUserToControllers(profileNotifier.state.currentUser!);
          debugPrint('✅ Controllers synced with fetched profile data');
        }
      }
    });
  }

  /// Apply notifier state to UI controllers
  void _applyUserToControllers(ProfileUser u) {
    debugPrint('🔄 ProfileScreen: Syncing user data to form controllers');
    _nameController.text = u.name;
    _emailController.text = u.email;
    _phoneController.text = u.phone;
    _addressController.text = u.address;
    _dobController.text = _formatDate(u.dateOfBirth) ?? "";
    
    debugPrint('  Updated Name: ${_nameController.text}');
    debugPrint('  Updated Email: ${_emailController.text}');
  }

  Future<void> _saveProfile(ProfileNotifier notifier) async {
    if (widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to save profile right now."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await notifier.saveProfile(
      token: widget.token!,
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      dateOfBirth: notifier.state.currentUser?.dateOfBirth,
    );

    if (!mounted) return;

    if (success) {
      // Sync notifier state back to controllers
      if (notifier.state.currentUser != null) {
        _applyUserToControllers(notifier.state.currentUser!);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Profile Updated Successfully!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notifier.state.errorMessage ?? 'Profile update failed',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Methods (LOCAL - Screen Utilities)
  // ─────────────────────────────────────────────────────────────────────────

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "?";
    final first = parts[0].isNotEmpty ? parts[0][0] : "";
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : "";
    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? "?" : initials;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
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
        .map((part) => part.isEmpty
            ? part
            : part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(" ");
  }

  Future<void> _selectDate() async {
    final profileNotifier = context.read<ProfileNotifier>();
    final currentUser = profileNotifier.state.currentUser;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentUser?.dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      // Update notifier state
      profileNotifier.updateDob(picked);
      // Update local controller
      _dobController.text = _formatDate(picked) ?? "-";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    if (widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Authentication required to upload photo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    "Take Photo",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null && mounted) {
                      await _uploadProfilePhoto(image.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    "Choose from Gallery",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null && mounted) {
                      await _uploadProfilePhoto(image.path);
                    }
                  },
                ),
                if (context.read<ProfileNotifier>().state.profileImage.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      "Remove Photo",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Note: Profile photo removal would require additional service method
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePhoto(String imagePath) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await context.read<ProfileNotifier>().uploadProfilePhoto(
      token: widget.token!,
      imagePath: imagePath,
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (result['success'] == true) {
      final updatedUser = result['user'] as ProfileUser?;
      if (updatedUser != null) {
        // Update controllers from cloud response
        _applyUserToControllers(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Profile photo updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to upload photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final responsive = ResponsiveUtils(context);

    return Consumer<ProfileNotifier>(
      builder: (context, profileNotifier, _) {
        final profileState = profileNotifier.state;
        
        return Scaffold(
          backgroundColor: const Color(0xFF050505), // Deep Black
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "My Profile",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: responsive.headingFontSize,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: responsive.smallIconSize,
                color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: responsive.spacing),
            child: profileState.isEditing
                ? Row(
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: profileState.isSaving
                            ? null
                            : () {
                                profileNotifier.cancelEditMode();
                                // Sync controllers back to current (original) profile data
                                if (profileNotifier.state.currentUser != null) {
                                  _applyUserToControllers(profileNotifier.state.currentUser!);
                                }
                              },
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.bodyFontSize,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Save button
                      TextButton(
                        onPressed: profileState.isSaving
                            ? null
                            : () => _saveProfile(profileNotifier),
                        child: profileState.isSaving
                            ? SizedBox(
                                height: responsive.smallIconSize,
                                width: responsive.smallIconSize,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Save",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: responsive.bodyFontSize,
                                ),
                              ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: Icon(
                      Icons.edit_note,
                      color: Colors.white,
                      size: responsive.iconSize,
                    ),
                    onPressed: () => profileNotifier.toggleEditMode(),
                    tooltip: "Edit Profile",
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isDesktopDevice ? 60 : responsive.horizontalPadding,
          vertical: responsive.verticalPadding,
        ),
        child: responsive.isDesktopDevice
            ? _buildDesktopLayout(primaryColor, profileState)
            : _buildMobileLayout(primaryColor, profileState),
      ),
    );
      },
    );
  }

  // --- LAYOUTS ---

  Widget _buildMobileLayout(Color primaryColor, ProfileState profileState) {
    return Column(
      children: [
        _buildProfileHeader(primaryColor, profileState),
        if (profileState.isEditing || _bioController.text.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildBioCard(profileState),
        ],
        const SizedBox(height: 30),
        _buildPersonalInfoSection(profileState),
        const SizedBox(height: 20),
        _buildEmploymentSection(profileState),
        const SizedBox(height: 20),
        _buildEmergencySection(profileState),
      ],
    );
  }

  Widget _buildDesktopLayout(Color primaryColor, ProfileState profileState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildProfileHeader(primaryColor, profileState),
              const SizedBox(height: 20),
              if (profileState.isEditing || _bioController.text.isNotEmpty)
                _buildBioCard(profileState),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildPersonalInfoSection(profileState),
              const SizedBox(height: 20),
              _buildEmploymentSection(profileState),
              const SizedBox(height: 20),
              _buildEmergencySection(profileState),
            ],
          ),
        ),
      ],
    );
  }

  // --- COMPONENT SECTIONS ---

  Widget _buildProfileHeader(Color primaryColor, ProfileState profileState) {
    final user = profileState.currentUser;
    if (user == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A1A1A), const Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2A2A2A),
                  backgroundImage: profileState.profileImage.isNotEmpty
                      ? (profileState.profileImage.startsWith('http')
                          ? NetworkImage(profileState.profileImage)
                          : FileImage(File(profileState.profileImage))
                              as ImageProvider)
                      : null,
                  child: profileState.profileImage.isEmpty
                      ? Text(
                          _buildInitials(user.name),
                          style: TextStyle(
                            fontSize: 32,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              if (profileState.isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profileState.employmentData["Position"] ?? "Employee",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildStatusChip(
                profileState.employmentData["Status"] ?? "Active",
                Colors.greenAccent.withOpacity(0.1),
                Colors.greenAccent,
              ),
              _buildStatusChip(
                profileState.employmentData["Department"] ?? "Engineering",
                Colors.blueAccent.withOpacity(0.1),
                Colors.blueAccent,
              ),
              _buildStatusChip(
                "ID: ${profileState.employmentData['Employee ID']}",
                Colors.white.withOpacity(0.05),
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(ProfileState profileState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bio",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            enabled: profileState.isEditing,
            maxLines: 4,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            decoration: InputDecoration(
              filled: profileState.isEditing,
              fillColor: Colors.black,
              hintText: "Write something about yourself...",
              hintStyle: const TextStyle(color: Colors.grey),
              border: profileState.isEditing
                  ? OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                  : InputBorder.none,
              contentPadding: profileState.isEditing
                  ? const EdgeInsets.all(12)
                  : EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(ProfileState profileState) {
    return _buildSectionCard(
      title: "Personal Information",
      icon: Icons.person_outline_rounded,
      children: [
        _buildFieldRow("Full Name", _nameController,
            isEditable: true, isEditing: profileState.isEditing),
        _buildFieldRow("Email", _emailController,
            isEditable: false, isEditing: profileState.isEditing),
        _buildFieldRow("Phone", _phoneController,
            isEditable: true, isEditing: profileState.isEditing),
        _buildFieldRow("Address", _addressController,
            isEditable: true, maxLines: 2, isEditing: profileState.isEditing),
        _buildDateFieldRow("Date of Birth", _dobController,
            isEditing: profileState.isEditing),
      ],
    );
  }

  Widget _buildEmploymentSection(ProfileState profileState) {
    return _buildSectionCard(
      title: "Employment Details",
      icon: Icons.badge_outlined,
      children: profileState.employmentData.entries
          .map((e) => _buildStaticRow(e.key, e.value, null))
          .toList(),
    );
  }

  Widget _buildEmergencySection(ProfileState profileState) {
    return _buildSectionCard(
      title: "Emergency Contact",
      icon: Icons.phone_callback_outlined,
      children: [
        _buildFieldRow("Contact Name", _emergencyNameController,
            isEditable: true, isEditing: profileState.isEditing),
        _buildFieldRow("Contact Number", _emergencyPhoneController,
            isEditable: true, isEditing: profileState.isEditing),
      ],
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: Theme.of(context).primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldRow(
    String label,
    TextEditingController controller, {
    bool isEditable = false,
    int maxLines = 1,
    required bool isEditing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 400;
          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildInputOrText(controller, isEditing && isEditable, maxLines),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputOrText(controller, isEditing && isEditable, maxLines),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildStaticRow(String label, String value, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFieldRow(
    String label,
    TextEditingController controller, {
    required bool isEditing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 400;
          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildDateInput(controller, isEditing)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildDateInput(controller, isEditing),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildDateInput(TextEditingController controller, bool isEditing) {
    if (isEditing) {
      return GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.text.isEmpty ? "Select Date" : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? Colors.grey : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      );
    } else {
      return Text(
        controller.text.isEmpty ? "-" : controller.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  Widget _buildInputOrText(
    TextEditingController controller,
    bool isEditable,
    int maxLines,
  ) {
    if (isEditable) {
      return TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      );
    } else {
      return Text(
        controller.text.isEmpty ? "-" : controller.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  Widget _buildStatusChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
