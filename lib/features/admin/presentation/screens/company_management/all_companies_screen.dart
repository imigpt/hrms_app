import 'package:flutter/material.dart';
import 'package:hrms_app/features/admin/data/models/company_model.dart';
import 'package:hrms_app/features/admin/data/services/company_service.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

class AllCompaniesScreen extends StatefulWidget {
  final String? token;

  const AllCompaniesScreen({super.key, this.token});

  @override
  State<AllCompaniesScreen> createState() => _AllCompaniesScreenState();
}

class _AllCompaniesScreenState extends State<AllCompaniesScreen> {
  late CompanyService _service;
  List<Company> companies = [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? approvingId;
  String? rejectingId;

  // Form controllers
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController websiteCtrl;
  late TextEditingController industryCtrl;
  late TextEditingController passwordCtrl;
  late TextEditingController companySizeCtrl;
  late TextEditingController rejectionReasonCtrl;

  String selectedSize = 'medium';
  String selectedStatus = 'active';
  Company? editingCompany;
  Company? selectedCompanyForReject;

  @override
  void initState() {
    super.initState();
    _service = CompanyService(token: widget.token);
    _initControllers();
    _loadCompanies();
  }

  void _initControllers() {
    nameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    addressCtrl = TextEditingController();
    websiteCtrl = TextEditingController();
    industryCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    companySizeCtrl = TextEditingController();
    rejectionReasonCtrl = TextEditingController();
  }

  Future<void> _loadCompanies() async {
    try {
      setState(() => isLoading = true);
      final result = await _service.getCompanies();
      setState(() {
        companies = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      _showSnackBar('Error loading companies', isError: true);
    }
  }

  Future<void> _createCompany() async {
    if (!_validateForm()) return;

    try {
      setState(() => isSaving = true);
      await _service.createCompany(
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        address: addressCtrl.text,
        website: websiteCtrl.text,
        industry: industryCtrl.text,
        size: selectedSize,
        companySize: int.tryParse(companySizeCtrl.text),
      );

      _showSnackBar('Company created successfully');
      _clearForm();
      Navigator.pop(context);
      _loadCompanies();
    } catch (e) {
      _showSnackBar('Error creating company', isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateCompany() async {
    if (!_validateForm() || editingCompany == null) return;

    try {
      setState(() => isSaving = true);
      await _service.updateCompany(
        id: editingCompany!.id!,
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        address: addressCtrl.text,
        website: websiteCtrl.text,
        industry: industryCtrl.text,
        size: selectedSize,
        companySize: int.tryParse(companySizeCtrl.text),
        status: selectedStatus,
      );

      _showSnackBar('Company updated successfully');
      _clearForm();
      Navigator.pop(context);
      _loadCompanies();
    } catch (e) {
      _showSnackBar('Error updating company', isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _deleteCompany(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: const Text('Are you sure you want to delete this company?'),
        backgroundColor: AppTheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteCompany(id);
      _showSnackBar('Company deleted successfully');
      _loadCompanies();
    } catch (e) {
      _showSnackBar('Error deleting company', isError: true);
    }
  }

  void _showCreateDialog() {
    _clearForm();
    editingCompany = null;
    showDialog(
      context: context,
      builder: (context) => _buildFormDialog('Create Company', isCreate: true),
    );
  }

  void _showEditDialog(Company company) {
    editingCompany = company;
    nameCtrl.text = company.name;
    emailCtrl.text = company.email ?? '';
    phoneCtrl.text = company.phone ?? '';
    addressCtrl.text = company.address ?? '';
    websiteCtrl.text = company.website ?? '';
    industryCtrl.text = company.industry ?? '';
    selectedSize = company.size ?? 'medium';
    companySizeCtrl.text = company.companySize?.toString() ?? '';
    selectedStatus = company.status ?? 'active';

    showDialog(
      context: context,
      builder: (context) => _buildFormDialog('Edit Company', isCreate: false),
    );
  }

  void _showRejectDialog(Company company) {
    selectedCompanyForReject = company;
    rejectionReasonCtrl.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Company'),
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting: ${company.name}', style: const TextStyle(color: AppTheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: rejectionReasonCtrl,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
              ),
              maxLines: 3,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: rejectionReasonCtrl.text.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((value) {
      if (value == true && selectedCompanyForReject != null) {
        // Handle rejection
      }
    });
  }

  Widget _buildFormDialog(String title, {required bool isCreate}) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 24),
            // Company Name
            TextField(
              controller: nameCtrl,
              decoration: _inputDecoration('Company Name'),
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Email
            TextField(
              controller: emailCtrl,
              decoration: _inputDecoration('Email'),
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Phone
            TextField(
              controller: phoneCtrl,
              decoration: _inputDecoration('Phone'),
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Address
            TextField(
              controller: addressCtrl,
              decoration: _inputDecoration('Address'),
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Website
            TextField(
              controller: websiteCtrl,
              decoration: _inputDecoration('Website'),
              keyboardType: TextInputType.url,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Industry
            TextField(
              controller: industryCtrl,
              decoration: _inputDecoration('Industry'),
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Size Dropdown
            DropdownButtonFormField<String>(
              value: selectedSize,
              items: ['small', 'medium', 'large', 'enterprise']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => selectedSize = v ?? 'medium'),
              decoration: _inputDecoration('Company Size Category'),
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Employee Limit
            TextField(
              controller: companySizeCtrl,
              decoration: _inputDecoration('Max Employee Limit'),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            if (!isCreate) ...[
              const SizedBox(height: 16),
              // Status (only for edit)
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['active', 'inactive', 'suspended', 'pending']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedStatus = v ?? 'active'),
                decoration: _inputDecoration('Status'),
                style: const TextStyle(color: AppTheme.onSurface),
              ),
            ],
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isSaving ? null : (isCreate ? _createCompany : _updateCompany),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
    );
  }

  bool _validateForm() {
    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
      _showSnackBar('Please fill all required fields', isError: true);
      return false;
    }
    return true;
  }

  void _clearForm() {
    nameCtrl.clear();
    emailCtrl.clear();
    phoneCtrl.clear();
    addressCtrl.clear();
    websiteCtrl.clear();
    industryCtrl.clear();
    passwordCtrl.clear();
    companySizeCtrl.clear();
    selectedSize = 'medium';
    selectedStatus = 'active';
    editingCompany = null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    websiteCtrl.dispose();
    industryCtrl.dispose();
    passwordCtrl.dispose();
    companySizeCtrl.dispose();
    rejectionReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.background,
        title: const Text('Companies'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Company'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorMessage', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCompanies,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards
                      _buildStatsSection(isMobile),
                      const SizedBox(height: 24),
                      // Companies List
                      const Text(
                        'All Companies',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      companies.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('No companies found'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: companies.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _buildCompanyCard(companies[index], isMobile),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    final total = companies.length;
    final active = companies.where((c) => c.status == 'active').length;
    final pending = companies.where((c) => c.status == 'pending').length;
    final totalEmployees = companies.fold<int>(0, (sum, c) => sum + (c.employeeCount ?? 0));
    final totalHR = companies.fold<int>(0, (sum, c) => sum + (c.hrCount ?? 0));

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.2 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard('Total Companies', total.toString(), Colors.blue, Icons.apartment),
        _buildStatCard('Active', active.toString(), Colors.green, Icons.check_circle),
        _buildStatCard('Pending', pending.toString(), Colors.orange, Icons.schedule),
        _buildStatCard('Total Employees', totalEmployees.toString(), Colors.purple, Icons.people),
        _buildStatCard('Total HR', totalHR.toString(), Colors.cyan, Icons.admin_panel_settings),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Company company, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.email ?? 'No email',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(company.status ?? 'active'),
                  ],
                ),
                const SizedBox(height: 12),
                // Company Details Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: [
                    _buildDetailItem('Industry', company.industry ?? 'N/A'),
                    _buildDetailItem('Size', company.size ?? 'N/A'),
                    _buildDetailItem('Employees', company.employeeCount?.toString() ?? '0'),
                    _buildDetailItem('HR Users', company.hrCount?.toString() ?? '0'),
                  ],
                ),
              ],
            ),
          ),
            Divider(color: AppTheme.surfaceVariant, height: 1),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    'Edit',
                    Icons.edit,
                    onPressed: () => _showEditDialog(company),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Delete',
                    Icons.delete,
                    colors: Colors.red,
                    onPressed: () => _deleteCompany(company.id ?? ''),
                  ),
                  const SizedBox(width: 8),
                  if (company.status == 'pending')
                    _buildActionButton(
                      'Approve',
                      Icons.check_circle,
                      colors: Colors.green,
                      onPressed: () {
                        // Handle approve
                      },
                    ),
                  if (company.status == 'pending') const SizedBox(width: 8),
                  if (company.status == 'pending')
                    _buildActionButton(
                      'Reject',
                      Icons.close,
                      colors: Colors.red,
                      onPressed: () => _showRejectDialog(company),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        break;
      case 'rejected':
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    Color colors = AppTheme.primaryColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.withOpacity(0.2),
        foregroundColor: colors,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
