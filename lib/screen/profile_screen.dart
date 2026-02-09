import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Toggle State
  bool _isEditing = false;

  // -- Controllers --
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  // -- Data State --
  String _profileImage = ""; 
  final String _initials = "RG";
  final String _dob = "December 28, 2001";
  
  final Map<String, String> _employmentData = {
    "Employee ID": "RG-008",
    "Department": "Engineering",
    "Position": "Flutter Intern",
    "Reporting To": "Senior Dev",
    "Join Date": "February 3, 2026",
    "Years of Service": "0 years",
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Rahul Gupta");
    _emailController = TextEditingController(text: "rahul.gupta@aseleanetwork.com");
    _phoneController = TextEditingController(text: "7014922901");
    _addressController = TextEditingController(text: "8, Gyan Vihar, Model town, Jagatpura, Jaipur, 302017");
    _bioController = TextEditingController(text: "Passionate Flutter Developer building seamless cross-platform applications."); 
    _emergencyNameController = TextEditingController(text: "Rajesh Gupta");
    _emergencyPhoneController = TextEditingController(text: "9876543210");
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
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _pickProfileImage() async {
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
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null && mounted) {
                      setState(() {
                        _profileImage = image.path;
                      });
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null && mounted) {
                      setState(() {
                        _profileImage = image.path;
                      });
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                if (_profileImage.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text("Remove Photo", style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      setState(() {
                        _profileImage = "";
                      });
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveProfile() {
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Profile Updated Successfully!", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Deep Black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Edit/Save Button in AppBar for easier access
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isEditing
              ? TextButton(
                  onPressed: _saveProfile,
                  child: Text("Save", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                )
              : IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.white),
                  onPressed: _toggleEdit,
                  tooltip: "Edit Profile",
                ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // --- RESPONSIVE LOGIC ---
          bool isDesktop = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 60 : 20, 
              vertical: 20
            ),
            child: isDesktop 
                ? _buildDesktopLayout(primaryColor) 
                : _buildMobileLayout(primaryColor),
          );
        },
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
          
          // Name
          _isEditing 
            ? SizedBox(
                width: 200,
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter Name",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Text(
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
              _buildStatusChip("Active", Colors.greenAccent.withOpacity(0.1), Colors.greenAccent),
              _buildStatusChip("Engineering", Colors.blueAccent.withOpacity(0.1), Colors.blueAccent),
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
        _buildFieldRow("Full Name", _nameController, isEditable: true),
        _buildFieldRow("Email", _emailController, isEditable: true),
        _buildFieldRow("Phone", _phoneController, isEditable: true),
        _buildFieldRow("Address", _addressController, isEditable: true, maxLines: 2),
        _buildStaticRow("Date of Birth", _dob, Icons.cake_outlined),
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