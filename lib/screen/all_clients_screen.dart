import 'package:flutter/material.dart';
import '../services/admin_clients_service.dart';
import '../utils/responsive_utils.dart';

class AllClientsScreen extends StatefulWidget {
  final String? token;

  const AllClientsScreen({super.key, this.token});

  @override
  State<AllClientsScreen> createState() => _AllClientsScreenState();
}

class _AllClientsScreenState extends State<AllClientsScreen> {
  // Theme
  static const Color _bg = Color(0xFF050505);
  static const Color _card = Color(0xFF141414);
  static const Color _input = Color(0xFF1C1C1C);
  static const Color _border = Color(0xFF2A2A2A);
  static const Color _pink = Color(0xFFFF8FA3);
  static const Color _green = Color(0xFF00C853);
  static const Color _red = Color(0xFFEF5350);
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = Color(0xFFE0E0E0);
  static const Color _tableHeader = Color(0xFF1A1A1A);

  // State
  bool _isLoading = true;
  String? _error;
  List<dynamic> _allClients = [];
  List<dynamic> _filtered = [];

  String _searchQuery = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  // Data loading
  Future<void> _loadClients() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _error = 'No authentication token provided';
        _isLoading = false;
      });
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await AdminClientsService.getAllClients(widget.token!);
      if (!mounted) return;

      List<dynamic> data = [];
      
      // Handle different response formats from backend
      // Check for success flag and data key
      if (result['success'] == true && result['data'] is List) {
        data = result['data'] as List<dynamic>;
      } else if (result['data'] is List) {
        data = result['data'] as List<dynamic>;
      } else if (result['clients'] is List) {
        // Alternative structure
        data = result['clients'] as List<dynamic>;
      } else if (result.isNotEmpty && result.values.isNotEmpty && result.values.first is List) {
        // Fallback: if first value in map is a list
        data = result.values.first as List<dynamic>;
      }

      setState(() {
        _allClients = data;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _filtered = _allClients.where((client) {
        if (_selectedStatus.isNotEmpty) {
          if ((client['status']?.toString() ?? '') != _selectedStatus) return false;
        }
        if (q.isNotEmpty) {
          final name = (client['name'] ?? '').toString().toLowerCase();
          final email = (client['email'] ?? '').toString().toLowerCase();
          final company = (client['company'] ?? '').toString().toLowerCase();
          if (!name.contains(q) &&
              !email.contains(q) &&
              !company.contains(q)) return false;
        }
        return true;
      }).toList();
    });
  }

  // Stats
  int get _totalCount => _allClients.length;
  int get _activeCount =>
      _allClients.where((c) => c['status'] == 'active').length;
  int get _inactiveCount =>
      _allClients.where((c) => c['status'] == 'inactive').length;

  // Helpers
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFFAF52DE),
      Color(0xFF007AFF),
      Color(0xFF34C759),
      Color(0xFFFF9500),
      Color(0xFFFF3B30),
      Color(0xFF5AC8FA),
      Color(0xFFFF2D55),
      Color(0xFF4CD964),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        bg = _green.withOpacity(0.15);
        fg = _green;
        label = 'Active';
        break;
      case 'inactive':
        bg = _red.withOpacity(0.15);
        fg = _red;
        label = 'Inactive';
        break;
      default:
        bg = _textGrey.withOpacity(0.15);
        fg = _textGrey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(isMobile),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : _error != null
                ? _buildError()
                : _buildBody(isMobile, responsive),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Clients',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _addClientBtn(compact: true),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _addClientBtn(compact: false),
          ),
      ],
    );
  }

  Widget _buildBody(bool isMobile, ResponsiveUtils responsive) {
    return RefreshIndicator(
      color: _pink,
      backgroundColor: _card,
      onRefresh: _loadClients,
      child: CustomScrollView(
        slivers: [
          // Desktop subtitle
          if (!isMobile)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Text(
                  'Manage client accounts & access',
                  style: TextStyle(color: _textGrey, fontSize: 13),
                ),
              ),
            ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 16),
              child: _buildStatsRow(isMobile),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 4),
              child: Text(
                'Showing ${_filtered.length} of $_totalCount clients',
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // List / Table
          if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else if (isMobile)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildMobileCard(_filtered[i]),
                  childCount: _filtered.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _buildTable()),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // Add Client button
  Widget _addClientBtn({required bool compact}) {
    return ElevatedButton.icon(
      onPressed: () => _showAddClientDialog(context),
      icon: Icon(Icons.add, size: compact ? 16 : 18, color: Colors.black),
      label: Text(
        compact ? 'Add' : 'Add Client',
        style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 13 : 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 18, vertical: compact ? 8 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  // Stats row
  Widget _buildStatsRow(bool isMobile) {
    final stats = [
      {
        'label': 'Total Clients',
        'value': _totalCount,
        'icon': Icons.people_rounded,
        'iconColor': _pink,
        'iconBg': _pink.withOpacity(0.15),
      },
      {
        'label': 'Active',
        'value': _activeCount,
        'icon': Icons.check_circle_rounded,
        'iconColor': _green,
        'iconBg': _green.withOpacity(0.15),
      },
      {
        'label': 'Inactive',
        'value': _inactiveCount,
        'icon': Icons.cancel_rounded,
        'iconColor': _red,
        'iconBg': _red.withOpacity(0.15),
      },
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => _statsCard(stats[i]),
      );
    }

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding:
                i < stats.length - 1 ? const EdgeInsets.only(right: 14) : EdgeInsets.zero,
            child: _statsCard(s),
          ),
        );
      }).toList(),
    );
  }

  Widget _statsCard(Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat['iconBg'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'] as IconData,
                color: stat['iconColor'] as Color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${stat['value']}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'] as String,
                  style: const TextStyle(color: _textGrey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile filters
  Widget _buildMobileFilters() {
    return Column(
      children: [
        _searchField(),
        const SizedBox(height: 10),
        _statusDropdown(),
      ],
    );
  }

  // Desktop filters
  Widget _buildDesktopFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _searchField()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _statusDropdown()),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) {
          _searchQuery = v;
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(color: _textGrey.withOpacity(0.6), fontSize: 14),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: _textGrey, size: 18),
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus.isEmpty ? '' : _selectedStatus,
          onChanged: (v) {
            setState(() => _selectedStatus = v ?? '');
            _applyFilters();
          },
          items: const [
            DropdownMenuItem(
              value: '',
              child: Text('All Status'),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Text('Active'),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Text('Inactive'),
            ),
          ]
              .map((item) {
                final isSelected = item.value == _selectedStatus;
                return DropdownMenuItem<String>(
                  value: item.value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (item.child as Text).data ?? '',
                      style: const TextStyle(
                        color: _textLight,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                );
              })
              .toList(),
          dropdownColor: const Color(0xFF1E1E1E),
          iconEnabledColor: _textGrey,
          style: const TextStyle(color: _textLight, fontSize: 13),
          isExpanded: true,
        ),
      ),
    );
  }

  // Desktop table
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(color: _border, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(color: _border, height: 1),
            itemBuilder: (_, i) => _buildTableRow(_filtered[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
        color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5);
    return Container(
      color: _tableHeader,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('CLIENT', style: style)),
          Expanded(flex: 3, child: Text('CONTACT', style: style)),
          Expanded(flex: 3, child: Text('COMPANY', style: style)),
          Expanded(flex: 2, child: Text('ID', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          SizedBox(width: 80, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  } 

  Widget _buildTableRow(Map<String, dynamic> client) {
    final name = client['name']?.toString() ?? 'Unknown';
    final email = client['email']?.toString() ?? '-';
    final phone = client['phone']?.toString() ?? '-';
    final companyName = client['companyName']?.toString() ?? '-';
    final clientId = client['id']?.toString() ?? client['_id']?.toString() ?? '-';
    final status = client['status']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Client name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _avatar(name, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Contact
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.email_outlined, color: _textGrey, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(email,
                          style: const TextStyle(color: _textLight, fontSize: 11),
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.phone_outlined, color: _textGrey, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(phone,
                          style: const TextStyle(color: _textLight, fontSize: 11),
                          overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ),
          ),
          // Company
          Expanded(
            flex: 3,
            child: Text(companyName,
                style: const TextStyle(color: _textLight, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          // ID
          Expanded(
            flex: 2,
            child: Text(clientId,
                style: const TextStyle(color: _textLight, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          // Status
          Expanded(flex: 2, child: _statusBadge(status)),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: _textGrey, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditClientDialog(client),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: _red, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteClient(client['_id'].toString()),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile card
  Widget _buildMobileCard(Map<String, dynamic> client) {
    final name = client['name']?.toString() ?? 'Unknown';
    final email = client['email']?.toString() ?? '-';
    final phone = client['phone']?.toString() ?? '-';
    final companyName = client['companyName']?.toString() ?? '-';
    final clientId = client['id']?.toString() ?? client['_id']?.toString() ?? '-';
    final status = client['status']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetailsSheet(context, client),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top
              Row(
                children: [
                  _avatar(name, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        if (clientId != '-')
                          Text(clientId,
                              style: const TextStyle(
                                  color: _textGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 12),
              // Details
              _cardRow(Icons.email_outlined, email),
              const SizedBox(height: 6),
              _cardRow(Icons.phone_outlined, phone),
              const SizedBox(height: 6),
              _cardRow(Icons.business_rounded, companyName),
              const SizedBox(height: 12),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditClientDialog(client),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _pink,
                        side: const BorderSide(color: _pink),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _deleteClient(client['_id'].toString()),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _textGrey, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: _textLight, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // Detail bottom sheet
  void _showDetailsSheet(BuildContext context, Map<String, dynamic> client) {
    final name = client['name']?.toString() ?? 'Unknown';
    final email = client['email']?.toString() ?? '-';
    final phone = client['phone']?.toString() ?? '-';
    final companyName = client['companyName']?.toString() ?? '-';
    final clientId = client['id']?.toString() ?? client['_id']?.toString() ?? '-';
    final status = client['status']?.toString() ?? '-';
    final address = client['address']?.toString() ?? '-';

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _avatar(name, radius: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          if (clientId != '-')
                            Text(clientId,
                                style: const TextStyle(
                                    color: _textGrey, fontSize: 13)),
                        ],
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: _border),
                const SizedBox(height: 16),
                _sheetRow('Email', email, Icons.email_outlined),
                _sheetRow('Phone', phone, Icons.phone_outlined),
                _sheetRow('Address', address, Icons.location_on_outlined),
                _sheetRow('Company', companyName, Icons.business_rounded),
                _sheetRow('Status', status, Icons.info_outline_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _textGrey, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: _textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // Edit client dialog
  void _showEditClientDialog(Map<String, dynamic> client) {
    final clientId = client['_id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: client['name'] ?? '');
    final emailCtrl = TextEditingController(text: client['email'] ?? '');
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: client['phone'] ?? '');
    final companyNameCtrl =
        TextEditingController(text: client['companyName'] ?? '');
    final notesCtrl =
        TextEditingController(text: client['clientNotes'] ?? '');

    bool isSubmitting = false;
    String? errorMessage;

    Widget fieldLabel(String label, {bool required = false}) => Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: _textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            if (required)
              const Text(' *', style: TextStyle(color: _red, fontSize: 13)),
          ],
        );

    Widget inputBox(TextEditingController ctrl,
        {String hint = '',
        bool obscure = false,
        int maxLines = 1,
        TextInputType? keyboardType}) {
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: 12, vertical: maxLines > 1 ? 10 : 0),
        decoration: BoxDecoration(
          color: _input,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textGrey.withOpacity(0.6)),
            border: InputBorder.none,
            isDense: maxLines == 1,
            contentPadding:
                maxLines == 1 ? const EdgeInsets.symmetric(vertical: 13) : null,
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.4), blurRadius: 24),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _pink.withOpacity(0.1),
                        _pink.withOpacity(0.04)
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                        bottom: BorderSide(
                            color: _border.withOpacity(0.3), width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _pink.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: _pink, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Edit Client',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Update client account details',
                                style: TextStyle(
                                    color: _textGrey, fontSize: 12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _border.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: _textGrey, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Phone row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Full Name', required: true),
                                  const SizedBox(height: 8),
                                  inputBox(nameCtrl, hint: 'John Smith'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  fieldLabel('Phone'),
                                  const SizedBox(height: 8),
                                  inputBox(phoneCtrl,
                                      hint: '+1 234 567 890',
                                      keyboardType: TextInputType.phone),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Email
                        fieldLabel('Email Address', required: true),
                        const SizedBox(height: 8),
                        inputBox(emailCtrl,
                            hint: 'client@company.com',
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        // Password
                        fieldLabel('New Password'),
                        const SizedBox(height: 4),
                        Text('Leave blank to keep current password',
                            style: TextStyle(
                                color: _textGrey.withOpacity(0.7),
                                fontSize: 11)),
                        const SizedBox(height: 8),
                        inputBox(passwordCtrl,
                            hint: 'Min 6 characters', obscure: true),
                        const SizedBox(height: 16),
                        // Client Company Name
                        fieldLabel('Client\'s Own Company Name'),
                        const SizedBox(height: 8),
                        inputBox(companyNameCtrl, hint: 'Acme Corp'),
                        const SizedBox(height: 16),
                        // Notes
                        fieldLabel('Notes (optional)'),
                        const SizedBox(height: 8),
                        inputBox(notesCtrl,
                            hint: 'Any relevant notes about this client',
                            maxLines: 3),
                        // Error
                        if (errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _red.withOpacity(0.5)),
                            ),
                            child: Text(errorMessage!,
                                style: const TextStyle(
                                    color: _red, fontSize: 12)),
                          ),
                        ],
                        const SizedBox(height: 22),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: isSubmitting
                                    ? null
                                    : () => Navigator.pop(ctx),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: _border.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _border.withOpacity(0.5)),
                                  ),
                                  child: const Text('Cancel',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        if (nameCtrl.text.trim().isEmpty ||
                                            emailCtrl.text.trim().isEmpty) {
                                          setS(() => errorMessage =
                                              'Name and Email are required');
                                          return;
                                        }
                                        setS(() {
                                          isSubmitting = true;
                                          errorMessage = null;
                                        });
                                        try {
                                          await AdminClientsService
                                              .updateClient(
                                            token: widget.token ?? '',
                                            clientId: clientId,
                                            name: nameCtrl.text.trim(),
                                            email: emailCtrl.text.trim(),
                                            phone: phoneCtrl.text.trim(),
                                            companyName:
                                                companyNameCtrl.text.trim(),
                                            password: passwordCtrl.text.isEmpty
                                                ? null
                                                : passwordCtrl.text,
                                            clientNotes: notesCtrl.text.trim(),
                                          );
                                          if (mounted) {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Client updated successfully'),
                                                  backgroundColor: _green),
                                            );
                                            _loadClients();
                                          }
                                        } catch (e) {
                                          setS(() {
                                            errorMessage = e
                                                .toString()
                                                .replaceAll('Exception: ', '');
                                            isSubmitting = false;
                                          });
                                        }
                                      },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      _pink,
                                      _pink.withOpacity(0.8)
                                    ]),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: _pink.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: isSubmitting
                                      ? const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        Colors.white)),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_rounded,
                                                color: Colors.white, size: 17),
                                            SizedBox(width: 6),
                                            Text('Save Changes',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Avatar
  Widget _avatar(String name, {double radius = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _avatarColor(name),
      child: Text(
        _initials(name),
        style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.65,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // Delete dialog
  Future<void> _deleteClient(String clientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Client',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to delete this client? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _border.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _red.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await AdminClientsService.deleteClient(
          token: widget.token ?? '',
          clientId: clientId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client deleted successfully'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: _red,
            ),
          );
        }
      }
    }
  }

  // Add client dialog
  void _showAddClientDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddClientDialog(
        token: widget.token,
        onClientAdded: _loadClients,
      ),
    );
  }

  // Empty / Error
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(color: _card, borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.people_outline_rounded,
                  color: _textGrey, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('No clients found',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Try adjusting your search or filters',
                style: TextStyle(color: _textGrey, fontSize: 13)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedStatus = '';
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _pink,
                side: const BorderSide(color: _pink),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50)),
              child:
                  const Icon(Icons.error_outline_rounded, color: _red, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load clients',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textGrey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadClients,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.black),
              label: const Text('Retry', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add Client Dialog Widget
class _AddClientDialog extends StatefulWidget {
  final String? token;
  final VoidCallback onClientAdded;

  const _AddClientDialog({
    required this.token,
    required this.onClientAdded,
  });

  @override
  State<_AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<_AddClientDialog> {
  // Theme colors
  static const Color _card = Color(0xFF141414);
  static const Color _input = Color(0xFF1C1C1C);
  static const Color _border = Color(0xFF2A2A2A);
  static const Color _pink = Color(0xFFFF8FA3);
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = Color(0xFFE0E0E0);
  static const Color _red = Color(0xFFEF5350);
  static const Color _green = Color(0xFF00C853);

  // Form fields
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _phone = '';
  String _email = '';
  String _password = '';
  String _clientCompanyName = '';
  String _notes = '';
  String _assignedCompanyId = '';

  List<Map<String, dynamic>> _companies = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final list = await AdminClientsService.getCompanies(widget.token ?? '');
    if (mounted) setState(() => _companies = list);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Client',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create a client account. They will have access to the chat panel only.',
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),
          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name & Phone row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Full Name',
                              hint: 'John Smith',
                              isRequired: true,
                              onChanged: (v) => _fullName = v,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'Phone',
                              hint: '+1 234 567 890',
                              onChanged: (v) => _phone = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      _buildTextField(
                        label: 'Email Address',
                        hint: 'client@company.com',
                        isRequired: true,
                        isEmail: true,
                        onChanged: (v) => _email = v,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildTextField(
                        label: 'Password',
                        hint: 'Min 6 characters',
                        isRequired: true,
                        isPassword: true,
                        minLength: 6,
                        onChanged: (v) => _password = v,
                      ),
                      const SizedBox(height: 16),

                      // Assign to HRMS Company
                      _buildCompanyDropdown(),
                      const SizedBox(height: 16),

                      // Client's Own Company Name
                      _buildTextField(
                        label: 'Client\'s Own Company Name',
                        hint: 'Acme Corp',
                        isRequired: true,
                        onChanged: (v) => _clientCompanyName = v,
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      _buildTextAreaField(
                        label: 'Notes (optional)',
                        hint: 'Any relevant notes about this client',
                        onChanged: (v) => _notes = v,
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _red.withOpacity(0.5)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: _red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: _border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                disabledBackgroundColor: _textGrey,
                              ),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation(Colors.black),
                                      ),
                                    )
                                  : const Icon(Icons.check, size: 18),
                              label: Text(
                                _isSubmitting ? 'Creating...' : 'Create Client',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    bool isRequired = false,
    bool isEmail = false,
    bool isPassword = false,
    int minLength = 0,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: _red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textGrey.withOpacity(0.6)),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
            validator: (v) {
              if (isRequired && (v == null || v.isEmpty)) {
                return '$label is required';
              }
              if (minLength > 0 && v != null && v.length < minLength) {
                return '$label must be at least $minLength characters';
              }
              if (isEmail && v != null && v.isNotEmpty) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                  return 'Enter a valid email';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textGrey.withOpacity(0.6)),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign to HRMS Company',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _assignedCompanyId.isEmpty ? null : _assignedCompanyId,
              hint: const Text(
                'Select company (optional)',
                style: TextStyle(color: _textGrey),
              ),
              items: _companies.map((c) {
                final id = c['_id']?.toString() ?? '';
                final name = c['name']?.toString() ?? id;
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(name,
                      style: const TextStyle(color: _textLight, fontSize: 14)),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => _assignedCompanyId = v ?? '');
              },
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: _textLight, fontSize: 14),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fullName.isEmpty || _email.isEmpty || _password.isEmpty || _clientCompanyName.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminClientsService.addClient(
        token: widget.token ?? '',
        name: _fullName,
        email: _email,
        phone: _phone,
        companyName: _clientCompanyName,
        password: _password,
        assignedCompanyId: _assignedCompanyId,
        clientNotes: _notes,
      );

      if (!mounted) return;

      if (result['success'] == true || result['data'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client created successfully'),
            backgroundColor: _green,
          ),
        );
        Navigator.pop(context);
        widget.onClientAdded();
      } else {
        setState(() =>
            _errorMessage = result['message'] ?? 'Failed to create client');
      }
    } catch (e) {
      setState(() =>
          _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
