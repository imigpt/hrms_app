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
  String? deletingCompanyId;
  String? viewingCompanyId;
  Map<String, dynamic>? companyStats;
  bool isLoadingStats = false;

  // Form controllers
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController websiteCtrl;
  late TextEditingController industryCtrl;
  late TextEditingController sizeCtrl;
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
    sizeCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    companySizeCtrl = TextEditingController();
    rejectionReasonCtrl = TextEditingController();
  }

  Future<void> _loadCompanies() async {
    try {
      print('[API DEBUG] _loadCompanies: Starting to load companies...');
      setState(() => isLoading = true);
      final result = await _service.getCompanies();
      print('[API DEBUG] _loadCompanies: Success! Loaded ${result.length} companies');
      print('[API DEBUG] _loadCompanies: Companies data: ${result.map((c) => c.name).toList()}');
      setState(() {
        companies = result;
        isLoading = false;
      });
    } catch (e) {
      print('[API ERROR] _loadCompanies: Error occurred: $e');
      print('[API ERROR] _loadCompanies: Error type: ${e.runtimeType}');
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
      print('[API DEBUG] _createCompany: Starting to create company...');
      print('[API DEBUG] _createCompany: Company data - Name: ${nameCtrl.text}, Email: ${emailCtrl.text}');
      setState(() => isSaving = true);
      await _service.createCompany(
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        address: addressCtrl.text,
        website: websiteCtrl.text,
        industry: industryCtrl.text,
        size: sizeCtrl.text,
        companySize: int.tryParse(companySizeCtrl.text),
      );

      print('[API DEBUG] _createCompany: Company created successfully!');
      _showSnackBar('Company created successfully');
      _clearForm();
      Navigator.pop(context);
      _loadCompanies();
    } catch (e) {
      print('[API ERROR] _createCompany: Error occurred: $e');
      print('[API ERROR] _createCompany: Error type: ${e.runtimeType}');
      _showSnackBar('Error creating company', isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateCompany() async {
    if (!_validateForm() || editingCompany == null) return;

    try {
      print('[API DEBUG] _updateCompany: Starting to update company...');
      print('[API DEBUG] _updateCompany: Company ID: ${editingCompany!.id}, Name: ${nameCtrl.text}');
      setState(() => isSaving = true);
      await _service.updateCompany(
        id: editingCompany!.id!,
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        address: addressCtrl.text,
        website: websiteCtrl.text,
        industry: industryCtrl.text,
        size: sizeCtrl.text,
        companySize: int.tryParse(companySizeCtrl.text),
        status: selectedStatus,
      );

      print('[API DEBUG] _updateCompany: Company updated successfully!');
      _showSnackBar('Company updated successfully');
      _clearForm();
      Navigator.pop(context);
      _loadCompanies();
    } catch (e) {
      print('[API ERROR] _updateCompany: Error occurred: $e');
      print('[API ERROR] _updateCompany: Error type: ${e.runtimeType}');
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
      print('[API DEBUG] _deleteCompany: Starting to delete company...');
      print('[API DEBUG] _deleteCompany: Company ID: $id');
      setState(() => deletingCompanyId = id);
      await _service.deleteCompany(id);
      print('[API DEBUG] _deleteCompany: Company deleted successfully!');
      _showSnackBar('Company deleted successfully');
      _loadCompanies();
    } catch (e) {
      print('[API ERROR] _deleteCompany: Error occurred: $e');
      print('[API ERROR] _deleteCompany: Error type: ${e.runtimeType}');
      _showSnackBar('Error deleting company', isError: true);
    } finally {
      setState(() => deletingCompanyId = null);
    }
  }

  Future<void> _updateCompanyStatus(Company company, String newStatus) async {
    try {
      print('[API DEBUG] _updateCompanyStatus: Starting to update status...');
      print('[API DEBUG] _updateCompanyStatus: Company ID: ${company.id}, Name: ${company.name}, Status: $newStatus');
      setState(() => approvingId = company.id);
      await _service.updateCompanyStatus(company.id!, newStatus);
      print('[API DEBUG] _updateCompanyStatus: Company status updated successfully!');
      _showSnackBar('${company.name} status updated to $newStatus');
      _loadCompanies();
    } catch (e) {
      print('[API ERROR] _updateCompanyStatus: Error occurred: $e');
      print('[API ERROR] _updateCompanyStatus: Error type: ${e.runtimeType}');
      _showSnackBar('Error updating company status: ${e.toString()}', isError: true);
    } finally {
      setState(() => approvingId = null);
    }
  }

  Future<void> _showCompanyOverview(Company company) async {
    try {
      print('[API DEBUG] _showCompanyOverview: Fetching stats for company ${company.id}');
      setState(() {
        viewingCompanyId = company.id;
        isLoadingStats = true;
        companyStats = null;
      });

      final stats = await _service.getCompanyStats(company.id!);
      print('[API DEBUG] _showCompanyOverview: Stats fetched successfully');

      final employeeData = stats['employees'] ?? {};
      final employeeList = (employeeData['byDepartment'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      final statusList = (employeeData['byStatus'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

      setState(() => companyStats = stats);

      if (!mounted) return;

      final isMobile = MediaQuery.of(context).size.width < 600;
      final dialogWidth = isMobile 
          ? MediaQuery.of(context).size.width * 0.95 
          : MediaQuery.of(context).size.width * 0.75;
      final maxHeight = MediaQuery.of(context).size.height * 0.9;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: maxHeight,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Company Overview',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.onSurface),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppTheme.surfaceVariant, height: 1),

                  // Dialog Content
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Details Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Company Information', 
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Company ID
                              _buildInfoRow('Company ID', company.id ?? 'N/A', isMobile),
                              const SizedBox(height: 12),
                              
                              // Email and Phone in row
                              if (isMobile)
                                Column(
                                  children: [
                                    _buildInfoRow('Email', company.email ?? 'N/A', isMobile),
                                    const SizedBox(height: 12),
                                    _buildInfoRow('Phone', company.phone ?? 'N/A', isMobile),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(child: _buildInfoRow('Email', company.email ?? 'N/A', isMobile)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildInfoRow('Phone', company.phone ?? 'N/A', isMobile)),
                                  ],
                                ),
                              
                              if (company.address != null && company.address!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow('Address', company.address!, isMobile),
                              ],
                              
                              if (company.industry != null && company.industry!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                if (isMobile)
                                  _buildInfoRow('Industry', company.industry!, isMobile)
                                else
                                  Row(
                                    children: [
                                      Expanded(child: _buildInfoRow('Industry', company.industry!, isMobile)),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildInfoRow('Size', company.size ?? 'N/A', isMobile)),
                                    ],
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Employee Statistics Section
                        Text('Employee Statistics',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid
                        isMobile
                            ? Column(
                                children: [
                                  _buildStatBox('Total Employees', (stats['employees']?['total'] ?? 0).toString(), color: Colors.blue),
                                  const SizedBox(height: 12),
                                  _buildStatBox('HR Users', (stats['hrCount'] ?? 0).toString(), color: Colors.purple),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildStatBox('Total Employees', (stats['employees']?['total'] ?? 0).toString(), color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatBox('HR Users', (stats['hrCount'] ?? 0).toString(), color: Colors.purple),
                                  ),
                                ],
                              ),

                        // Department Breakdown
                        if (employeeList.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Employees by Department',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...employeeList.map((dept) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dept['_id'] ?? 'Unknown',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${dept['count'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],

                        // Status Breakdown
                        if (statusList.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Employees by Status',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...statusList.map((status) {
                                  final statusStr = status['_id'] ?? 'Unknown';
                                  final color = statusStr.toLowerCase() == 'active' 
                                      ? Colors.green 
                                      : statusStr.toLowerCase() == 'inactive' 
                                      ? Colors.orange 
                                      : Colors.red;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          statusStr,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${status['count'] ?? 0}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Dialog Footer
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('[API ERROR] _showCompanyOverview: Error occurred: $e');
      _showSnackBar('Error loading company overview: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        viewingCompanyId = null;
        isLoadingStats = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.outline, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
      ],
    );
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
    sizeCtrl.text = company.size ?? '';
    companySizeCtrl.text = company.companySize?.toString() ?? '';
    selectedStatus = company.status ?? 'active';

    showDialog(
      context: context,
      builder: (context) => _buildFormDialog('Edit Company', isCreate: false),
    );
  }

  void _showRejectDialog(Company company) {
    selectedCompanyForReject = company;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Company'),
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspend: ${company.name}', style: const TextStyle(color: AppTheme.onSurface)),
            const SizedBox(height: 16),
            const Text('Are you sure you want to suspend this company? It will no longer be able to access the system.', 
              style: TextStyle(color: AppTheme.outline)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              _updateCompanyStatus(selectedCompanyForReject!, 'suspended');
            },
            child: const Text('Suspend', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormDialog(String title, {required bool isCreate}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final dialogWidth = isMobile 
            ? constraints.maxWidth * 0.9 
            : constraints.maxWidth * 0.6;

        return Dialog(
          backgroundColor: AppTheme.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCreate
                        ? 'Create company and admin login. Company ID is generated automatically.'
                        : 'Update company details and settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Company Name (Full Width)
                  _buildFormField(
                    label: 'Company Name',
                    controller: nameCtrl,
                    hintText: 'Enter company name',
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Email + Password (Responsive Grid)
                  _buildResponsiveRow(
                    isMobile,
                    [
                      _buildFormField(
                        label: 'Email',
                        controller: emailCtrl,
                        hintText: 'company@example.com',
                        keyboardType: TextInputType.emailAddress,
                        isMobile: isMobile,
                      ),
                      _buildFormField(
                        label: 'Temporary Admin Password (optional)',
                        controller: passwordCtrl,
                        hintText: 'Auto-generated if left empty',
                        obscureText: true,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Phone + Website (Responsive Grid)
                  _buildResponsiveRow(
                    isMobile,
                    [
                      _buildFormField(
                        label: 'Phone',
                        controller: phoneCtrl,
                        hintText: '+1 (555) 123-4567',
                        keyboardType: TextInputType.phone,
                        isMobile: isMobile,
                      ),
                      _buildFormField(
                        label: 'Website',
                        controller: websiteCtrl,
                        hintText: 'https://example.com',
                        keyboardType: TextInputType.url,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Industry + Size Label (Responsive Grid)
                  _buildResponsiveRow(
                    isMobile,
                    [
                      _buildFormField(
                        label: 'Industry',
                        controller: industryCtrl,
                        hintText: 'Technology',
                        isMobile: isMobile,
                      ),
                      _buildFormField(
                        label: 'Company Size Label',
                        controller: sizeCtrl,
                        hintText: '11-50',
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // User Limit (Full Width)
                  _buildFormField(
                    label: 'User Limit (Company Size)',
                    controller: companySizeCtrl,
                    hintText: '50',
                    keyboardType: TextInputType.number,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Address (Full Width - Multi-line)
                  _buildFormField(
                    label: 'Address',
                    controller: addressCtrl,
                    hintText: 'Enter company address',
                    maxLines: 3,
                    minLines: 3,
                    isMobile: isMobile,
                  ),

                  if (!isCreate) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    // Status (only for edit)
                    _buildStatusDropdown(isMobile),
                  ],

                  SizedBox(height: isMobile ? 20 : 24),

                  // Buttons
                  _buildDialogButtons(isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: children
            .expand((child) => [child, SizedBox(height: isMobile ? 12 : 16)])
            .toList()
          ..removeLast(),
      );
    }
    return Row(
      children: [
        Expanded(child: children[0]),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    int minLines = 1,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: _inputDecoration(hintText),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: _labelStyle()),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedStatus,
          items: ['active', 'inactive', 'suspended', 'pending']
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedStatus = v ?? 'active'),
          decoration: _inputDecoration('Select status'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildDialogButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isMobile) ...[
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.outline,
              ),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isSaving ? null : (editingCompany == null ? _createCompany : _updateCompany),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
              ),
              child: isSaving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    )
                  : Text(
                      editingCompany == null ? 'Create' : 'Update',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.outline,
            ),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isSaving ? null : (editingCompany == null ? _createCompany : _updateCompany),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    editingCompany == null ? 'Create' : 'Update',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
          ),
        ],
      ],
    );
  }

  TextStyle _labelStyle() {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        ) ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.outline.withOpacity(0.6),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
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
    sizeCtrl.clear();
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
    sizeCtrl.dispose();
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ID: ${company.id ?? "N/A"}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                    'View',
                    Icons.visibility,
                    colors: AppTheme.primaryColor,
                    onPressed: viewingCompanyId == company.id && isLoadingStats
                        ? null
                        : () => _showCompanyOverview(company),
                  ),
                  const SizedBox(width: 8),
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
                    onPressed: deletingCompanyId == company.id
                        ? null
                        : () => _deleteCompany(company.id ?? ''),
                  ),
                  const SizedBox(width: 8),
                  if (company.status != 'active')
                    _buildActionButton(
                      approvingId == company.id ? 'Activating...' : 'Activate',
                      Icons.check_circle,
                      colors: Colors.green,
                      onPressed: approvingId == company.id
                          ? null
                          : () => _updateCompanyStatus(company, 'active'),
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
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
            ? colors.withOpacity(0.1)
            : colors.withOpacity(0.2),
        foregroundColor: isDisabled
            ? colors.withOpacity(0.5)
            : colors,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {Color? bgColor, Color? textColor, Color? color}) {
    // If color is provided (positional), use the colored version
    if (color != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.outline, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
    }
    
    // Default version with bgColor and textColor
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor ?? AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.outline)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? AppTheme.onSurface)),
        ],
      ),
    );
  }
}
