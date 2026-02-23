import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/policy_model.dart';
import '../services/policy_service.dart';
import '../services/token_storage_service.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
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
    final token = await TokenStorageService().getToken();
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
              onSubmitted: _onSearch,
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

            // Download button
            if (hasFile)
              IconButton(
                onPressed: () => _downloadPolicy(policy),
                icon: Icon(Icons.download_rounded, color: Theme.of(context).primaryColor, size: 22),
                tooltip: 'Download',
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadPolicy(policy);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Download ${policy.file!.displayName}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
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
