import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/policy_model.dart';
import '../services/policy_service.dart';
import '../services/token_storage_service.dart';

class PoliciesScreen extends StatefulWidget {
  final String? role;
  final String? token;
  const PoliciesScreen({super.key, this.role, this.token});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  bool get _isAdmin => widget.role?.toLowerCase() == 'admin' || widget.role?.toLowerCase() == 'hr';

  String? _token;
  List<CompanyPolicy> _policies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicies() async {
    final token = widget.token ?? await TokenStorageService().getToken();
    if (token == null || !mounted) return;
    setState(() { _token = token; _isLoading = true; });

    try {
      final res = await PolicyService.getPolicies(
        token: token,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) setState(() { _policies = res.data; _isLoading = false; });
    } catch (e) {
      print('Policies fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadPolicies();
  }

  Future<void> _downloadPolicy(CompanyPolicy policy) async {
    if (!policy.hasFile || _token == null) return;

    // Open the download URL in a browser — backend handles streaming
    final url = PolicyService.getDownloadUrl(policy.id);
    try {
      // For direct files we can also use the file URL from CloudinaryÃ
      final fileUrl = policy.file!.url!;
      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to API download endpoint
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreatePolicyDialog,
              backgroundColor: const Color(0xFFFF8FA3),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('Add Policy', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Company Policies', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search policies...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF111111),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _policies.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPolicies,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _policies.length,
                          itemBuilder: (_, i) => _buildPolicyCard(_policies[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Create Policy Dialog ───────────────────────────────────────────────
  Future<void> _showCreatePolicyDialog() async {
    const kCard = Color(0xFF141414);
    const kInput = Color(0xFF1F1F1F);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Head Office');
    File? pickedFile;
    String? pickedFileName;
    bool submitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(builder: (_, ss) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.policy_outlined, color: Color(0xFFFF8FA3), size: 22),
                  const SizedBox(width: 10),
                  const Text('Add Policy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20)),
                ]),
                const SizedBox(height: 20),
                // Title
                const Text('Title *', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Policy title',
                    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                    filled: true, fillColor: kInput,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                const Text('Description', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Brief description (optional)',
                    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                    filled: true, fillColor: kInput,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Location
                const Text('Location', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Head Office',
                    hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                    filled: true, fillColor: kInput,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                // File picker
                const Text('Attachment', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'xls', 'ppt', 'pptx'],
                    );
                    if (result != null && result.files.single.path != null) {
                      ss(() {
                        pickedFile = File(result.files.single.path!);
                        pickedFileName = result.files.single.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pickedFile != null
                            ? const Color(0xFF00C853).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        pickedFile != null ? Icons.attach_file_rounded : Icons.upload_file_outlined,
                        color: pickedFile != null ? const Color(0xFF00C853) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pickedFileName ?? 'Tap to attach a file (PDF, DOCX, XLSX...)',
                          style: TextStyle(
                            color: pickedFile != null ? Colors.white : Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pickedFile != null)
                        GestureDetector(
                          onTap: () => ss(() { pickedFile = null; pickedFileName = null; }),
                          child: const Icon(Icons.close, color: Colors.white38, size: 16),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8FA3),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: submitting ? null : () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red));
                        return;
                      }
                      final token = widget.token ?? _token ?? await TokenStorageService().getToken();
                      if (token == null) return;
                      ss(() => submitting = true);
                      try {
                        await PolicyService.createPolicy(
                          token: token,
                          title: title,
                          description: descCtrl.text.trim(),
                          location: locationCtrl.text.trim().isEmpty ? 'Head Office' : locationCtrl.text.trim(),
                          file: pickedFile,
                          fileName: pickedFileName,
                        );
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx, true);
                      } catch (e) {
                        if (sheetCtx.mounted) ss(() => submitting = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.red));
                      }
                    },
                    icon: submitting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(submitting ? 'Saving...' : 'Save Policy',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      }),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Policy created!'),
        backgroundColor: Color(0xFF00C853),
      ));
      _loadPolicies();
    }
  }

  Future<void> _confirmDeletePolicy(CompanyPolicy policy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "\${policy.title}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = widget.token ?? _token ?? await TokenStorageService().getToken();
    if (token == null) return;

    try {
      await PolicyService.deletePolicy(token: token, id: policy.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Policy deleted'),
          backgroundColor: Colors.redAccent,
        ));
        _loadPolicies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _buildPolicyCard(CompanyPolicy policy) {
    final hasFile = policy.hasFile;
    final fileExtension = hasFile ? policy.file!.fileExtension : null;

    return GestureDetector(
      onTap: () => _showPolicyDetail(policy),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _fileColor(fileExtension).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: hasFile
                    ? Text(fileExtension ?? 'FILE',
                        style: TextStyle(
                          color: _fileColor(fileExtension),
                          fontWeight: FontWeight.bold,
                          fontSize: fileExtension != null && fileExtension.length > 3 ? 9 : 11,
                        ))
                    : Icon(Icons.description_outlined, color: Colors.grey[600], size: 22),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(policy.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Text(policy.location,
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      if (policy.createdAt != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey[600]),
                        const SizedBox(width: 3),
                        Text(DateFormat('dd MMM yyyy').format(policy.createdAt!),
                            style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Download + Delete buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasFile)
                  IconButton(
                    onPressed: () => _downloadPolicy(policy),
                    icon: Icon(Icons.download_rounded, color: Theme.of(context).primaryColor, size: 22),
                    tooltip: 'Download',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (_isAdmin) ...[  
                  if (hasFile) const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _confirmDeletePolicy(policy),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicyDetail(CompanyPolicy policy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(policy.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(policy.location, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
            if (policy.createdBy != null && policy.createdBy!.name != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('By ${policy.createdBy!.name}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ],
            if (policy.createdAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd MMM yyyy').format(policy.createdAt!),
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ],
            if (policy.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(policy.description, style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5)),
            ],
            if (policy.hasFile) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadPolicy(policy);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Download \${policy.file!.displayName}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (_isAdmin) ...[              
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeletePolicy(policy);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  label: const Text('Delete Policy', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.policy_outlined, size: 48, color: Colors.grey[700]),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty ? 'No policies match your search' : 'No company policies found',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );

  Color _fileColor(String? ext) {
    switch (ext) {
      case 'PDF':
        return Colors.redAccent;
      case 'DOCX':
      case 'DOC':
        return Colors.blueAccent;
      case 'XLSX':
      case 'XLS':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }
}
