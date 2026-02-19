import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/services/profile_service.dart';
import 'package:hrms_app/utils/responsive_utils.dart';
// import 'employee_api_test_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileUser? user;
  final String? token;

  const ProfileScreen({super.key, this.user, this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Toggle State
  bool _isEditing = false;
  bool _isSaving = false;

  // -- Controllers --
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _dobController;

  // -- Data State --
  String _profileImage = ""; 
  String _initials = "RG";
  String _dob = "-";
  Map<String, String> _employmentData = {};
  ProfileUser? _currentUser;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _currentUser = user;
    _nameController = TextEditingController(text: user?.name ?? "Rahul Gupta");
    _emailController = TextEditingController(text: user?.email ?? "rahul.gupta@aseleanetwork.com");
    _phoneController = TextEditingController(text: user?.phone ?? "7014922901");
    _addressController = TextEditingController(text: user?.address ?? "8, Gyan Vihar, Model town, Jagatpura, Jaipur, 302017");
    _bioController = TextEditingController(text: "Passionate Flutter Developer building seamless cross-platform applications."); 
    _emergencyNameController = TextEditingController(text: "-");
    _emergencyPhoneController = TextEditingController(text: "-");
    _dobController = TextEditingController(text: _formatDate(user?.dateOfBirth) ?? "-");

    _profileImage = (user?.profilePhoto is String) ? (user?.profilePhoto as String) : "";
    _initials = _buildInitials(user?.name ?? "Rahul Gupta");
    _dob = _formatDate(user?.dateOfBirth) ?? "-";
    _employmentData = {
      "Employee ID": user?.employeeId ?? "RG-008",
      "Department": _titleCase(user?.department) ?? "Engineering",
      "Position": user?.position ?? "Flutter Intern",
      "Role": _titleCase(user?.role) ?? "Employee",
      "Status": _titleCase(user?.status) ?? "Active",
      "Join Date": _formatDate(user?.joinDate) ?? "February 3, 2026",
    
    };
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null || widget.token == null || widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to save profile right now."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Parse date of birth from controller
    DateTime? parsedDob;
    if (_dobController.text.isNotEmpty && _dobController.text != "-") {
      // Use the current user's dateOfBirth which gets updated in _selectDate
      parsedDob = _currentUser?.dateOfBirth;
    } else {
      parsedDob = _currentUser?.dateOfBirth;
    }

    final updatedUser = ProfileUser(
      id: _currentUser!.id,
      employeeId: _currentUser!.employeeId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: parsedDob ?? _currentUser!.dateOfBirth,
      address: _addressController.text.trim(),
      role: _currentUser!.role,
      department: _currentUser!.department,
      position: _currentUser!.position,
      joinDate: _currentUser!.joinDate,
      status: _currentUser!.status,
      profilePhoto: _currentUser!.profilePhoto,
      leaveBalance: _currentUser!.leaveBalance,
    );

    final result = await _profileService.updateProfile(
      token: widget.token!,
      userId: _currentUser!.id,
      payload: updatedUser.toJson(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      final saved = result['user'] as ProfileUser;
      setState(() {
        _currentUser = saved;
        _isEditing = false;
      });

      _nameController.text = saved.name;
      _emailController.text = saved.email;
      _phoneController.text = saved.phone;
      _addressController.text = saved.address;
      _dobController.text = _formatDate(saved.dateOfBirth) ?? "-";
      _profileImage = (saved.profilePhoto is String)
          ? (saved.profilePhoto as String)
          : "";
      _initials = _buildInitials(saved.name);
      _dob = _formatDate(saved.dateOfBirth) ?? "-";
      _employmentData = {
        "Employee ID": saved.employeeId,
        "Department": _titleCase(saved.department) ?? "Engineering",
        "Position": saved.position,
        "Role": _titleCase(saved.role) ?? "Employee",
        "Status": _titleCase(saved.status) ?? "Active",
        "Join Date": _formatDate(saved.joinDate) ?? "-",
      };

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
      final errorMessage = result['message'] ?? 'Profile update failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) {
      return "?";
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : "";
    final last = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : "";
    final initials = (first + last).toUpperCase();
    return initials.isEmpty ? "?" : initials;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }
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
    if (value == null || value.isEmpty) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r"[_-]+"), " ").trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned
        .split(RegExp(r"\s+"))
        .map((part) => part.isEmpty
            ? part
            : part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(" ");
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentUser?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
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
      setState(() {
        // Update the current user's date of birth
        if (_currentUser != null) {
          _currentUser = ProfileUser(
            id: _currentUser!.id,
            employeeId: _currentUser!.employeeId,
            name: _currentUser!.name,
            email: _currentUser!.email,
            phone: _currentUser!.phone,
            dateOfBirth: picked,
            address: _currentUser!.address,
            role: _currentUser!.role,
            department: _currentUser!.department,
            position: _currentUser!.position,
            joinDate: _currentUser!.joinDate,
            status: _currentUser!.status,
            profilePhoto: _currentUser!.profilePhoto,
            leaveBalance: _currentUser!.leaveBalance,
          );
        }
        _dobController.text = _formatDate(picked) ?? "-";
        _dob = _formatDate(picked) ?? "-";
      });
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

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
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
                  title: const Text("Take Photo", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null && mounted) {
                      await _uploadProfilePhoto(image.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null && mounted) {
                      await _uploadProfilePhoto(image.path);
                    }
                  },
                ),
                if (_profileImage.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text("Remove Photo", style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _profileImage = "";
                      });
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _profileService.uploadProfilePhoto(
      token: widget.token!,
      imagePath: imagePath,
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (result['success'] == true) {
      final updatedUser = result['user'] as ProfileUser?;
      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
          _profileImage = (updatedUser.profilePhoto is String) 
              ? (updatedUser.profilePhoto as String) 
              : imagePath;
        });
      } else {
        setState(() {
          _profileImage = imagePath;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profile photo updated successfully'),
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
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final responsive = ResponsiveUtils(context);
    
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
          icon: Icon(Icons.arrow_back_ios_new, size: responsive.smallIconSize, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // API Test Button
          // IconButton(
          //   icon: const Icon(Icons.api_outlined, color: Colors.pinkAccent),
          //   onPressed: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const EmployeeApiTestScreen()),
          //   ),
          //   tooltip: 'Employee API Tests',
          // ),
          // Edit/Save Button in AppBar for easier access
          Padding(
            padding: EdgeInsets.only(right: responsive.spacing),
            child: _isEditing
              ? TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? SizedBox(
                          height: responsive.smallIconSize,
                          width: responsive.smallIconSize,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Save",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.bodyFontSize,
                          ),
                        ),
                )
              : IconButton(
                  icon: Icon(Icons.edit_note, color: Colors.white, size: responsive.iconSize),
                  onPressed: _toggleEdit,
                  tooltip: "Edit Profile",
                ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isDesktopDevice ? 60 : responsive.horizontalPadding, 
          vertical: responsive.verticalPadding,
        ),
        child: responsive.isDesktopDevice 
            ? _buildDesktopLayout(primaryColor) 
            : _buildMobileLayout(primaryColor),
      ),
    );
  }

  // --- LAYOUTS ---

  Widget _buildMobileLayout(Color primaryColor) {
    return Column(
      children: [
        _buildProfileHeader(primaryColor),
        if (_isEditing || _bioController.text.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildBioCard(),
        ],
        const SizedBox(height: 30),
        _buildPersonalInfoSection(),
        const SizedBox(height: 20),
        _buildEmploymentSection(),
        const SizedBox(height: 20),
        _buildEmergencySection(),
      ],
    );
  }

  Widget _buildDesktopLayout(Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Sticky-like Header
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildProfileHeader(primaryColor),
              const SizedBox(height: 20),
               // Bio moved to left column on Desktop
              if (_isEditing || _bioController.text.isNotEmpty)
                _buildBioCard(),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Right Column: Details
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildPersonalInfoSection(),
              const SizedBox(height: 20),
              _buildEmploymentSection(),
              const SizedBox(height: 20),
              _buildEmergencySection(),
            ],
          ),
        ),
      ],
    );
  }

  // --- COMPONENT SECTIONS ---

  Widget _buildProfileHeader(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A1A1A), const Color(0xFF111111)],
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                  ]
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2A2A2A),
                  backgroundImage: _profileImage.isNotEmpty
                      ? (_profileImage.startsWith('http')
                          ? NetworkImage(_profileImage)
                          : FileImage(File(_profileImage)) as ImageProvider)
                      : null,
                  child: _profileImage.isEmpty 
                      ? Text(_initials, style: TextStyle(fontSize: 32, color: primaryColor, fontWeight: FontWeight.bold)) 
                      : null,
                ),
              ),
              if (_isEditing)
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
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 20),
          
          // Name (Non-editable)
          Text(
            _nameController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          
          const SizedBox(height: 6),
          Text(_employmentData["Position"] ?? "Employee", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          
          const SizedBox(height: 20),
          
          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildStatusChip(
                _employmentData["Status"] ?? "Active",
                Colors.greenAccent.withOpacity(0.1),
                Colors.greenAccent,
              ),
              _buildStatusChip(
                _employmentData["Department"] ?? "Engineering",
                Colors.blueAccent.withOpacity(0.1),
                Colors.blueAccent,
              ),
              _buildStatusChip("ID: ${_employmentData['Employee ID']}", Colors.white.withOpacity(0.05), Colors.grey),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildBioCard() {
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
          const Text("Bio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 4,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            decoration: InputDecoration(
              filled: _isEditing,
              fillColor: Colors.black,
              hintText: "Write something about yourself...",
              hintStyle: const TextStyle(color: Colors.grey),
              border: _isEditing ? OutlineInputBorder(borderRadius: BorderRadius.circular(8)) : InputBorder.none,
              contentPadding: _isEditing ? const EdgeInsets.all(12) : EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      title: "Personal Information",
      icon: Icons.person_outline_rounded,
      children: [
        _buildFieldRow("Full Name", _nameController, isEditable: false),
        _buildFieldRow("Email", _emailController, isEditable: false),
        _buildFieldRow("Phone", _phoneController, isEditable: true),
        _buildFieldRow("Address", _addressController, isEditable: true, maxLines: 2),
        _buildDateFieldRow("Date of Birth", _dobController),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return _buildSectionCard(
      title: "Employment Details",
      icon: Icons.badge_outlined,
      children: _employmentData.entries.map((e) => _buildStaticRow(e.key, e.value, null)).toList(),
    );
  }

  Widget _buildEmergencySection() {
    return _buildSectionCard(
      title: "Emergency Contact",
      icon: Icons.phone_callback_outlined,
      children: [
        _buildFieldRow("Contact Name", _emergencyNameController, isEditable: true),
        _buildFieldRow("Contact Number", _emergencyPhoneController, isEditable: true),
      ],
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
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
              Icon(icon, color: Theme.of(context).primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, TextEditingController controller, {bool isEditable = false, int maxLines = 1}) {
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
                    child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))
                  ),
                  Expanded(child: _buildInputOrText(controller, isEditable, maxLines)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  _buildInputOrText(controller, isEditable, maxLines),
                ],
              );
        }
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
                if (icon != null) ...[Icon(icon, size: 14, color: Colors.grey[600]), const SizedBox(width: 6)],
                Expanded(child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            )
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDateFieldRow(String label, TextEditingController controller) {
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
                        Icon(Icons.cake_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label, 
                            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)
                          )
                        ),
                      ],
                    )
                  ),
                  Expanded(child: _buildDateInput(controller)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cake_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        label, 
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildDateInput(controller),
                ],
              );
        }
      ),
    );
  }

  Widget _buildDateInput(TextEditingController controller) {
    if (_isEditing) {
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
                    fontSize: 14
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
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      );
    }
  }

  Widget _buildInputOrText(TextEditingController controller, bool isEditable, int maxLines) {
    if (_isEditing && isEditable) {
      return TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
      ),
    );
  }
}