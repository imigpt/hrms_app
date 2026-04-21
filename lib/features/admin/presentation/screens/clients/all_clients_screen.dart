import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/admin/data/services/admin_clients_service.dart';
import 'package:hrms_app/core/utils/responsive_utils.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';
import 'package:hrms_app/features/admin/presentation/providers/clients_notifier.dart';

class AllClientsScreen extends StatefulWidget {
  final String? token;

  const AllClientsScreen({super.key, this.token});

  @override
  State<AllClientsScreen> createState() => _AllClientsScreenState();
}

class _AllClientsScreenState extends State<AllClientsScreen> {
  // Theme constants
  static const Color _bg = AppTheme.background;
  static const Color _card = AppTheme.cardColor;
  static const Color _input = AppTheme.surface;
  static const Color _border = AppTheme.outline;
  static const Color _pink = AppTheme.primaryColor;
  static const Color _green = AppTheme.successColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _textGrey = Color(0xFF9E9E9E);
  static const Color _textLight = AppTheme.onSurface;
  static const Color _tableHeader = AppTheme.surfaceVariant;

  @override
  void initState() {
    super.initState();
    // Load data using the Provider when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientsNotifier>().loadClients(widget.token ?? '');
    });
  }

  // --- Helpers ---
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFFAF52DE), Color(0xFF007AFF), Color(0xFF34C759),
      Color(0xFFFF9500), Color(0xFFFF3B30), Color(0xFF5AC8FA),
      Color(0xFFFF2D55), Color(0xFF4CD964),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Widget _avatar(String name, {double radius = 20}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _avatarColor(name),
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white, 
          fontSize: radius * 0.8, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
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
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isMobile = responsive.isMobile;
    final state = context.watch<ClientsNotifier>().state;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(isMobile),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: _pink))
            : state.error != null
            ? _buildError(state.error!)
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
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 12 : 20),
          child: _addClientBtn(compact: isMobile),
        ),
      ],
    );
  }

  Widget _buildBody(bool isMobile, ResponsiveUtils responsive) {
    final notifier = context.watch<ClientsNotifier>();
    final filtered = notifier.filteredClients;
    final allClients = notifier.state.clients;
    
    return RefreshIndicator(
      color: _pink,
      backgroundColor: _card,
      onRefresh: () => notifier.loadClients(widget.token ?? ''),
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
                isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 16,
              ),
              child: _buildStatsRow(isMobile, allClients),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: isMobile ? _buildMobileFilters(notifier) : _buildDesktopFilters(notifier),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 4,
              ),
              child: Text(
                'Showing ${filtered.length} of ${allClients.length} clients',
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // List / Table
          if (filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else if (isMobile)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildMobileCard(filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _buildTable(filtered)),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // --- Add Client Button & Methods ---
  Widget _addClientBtn({required bool compact}) {
    return ElevatedButton.icon(
      onPressed: () => _showAddClientDialog(context),
      icon: Icon(Icons.add, size: compact ? 16 : 18, color: Colors.black),
      label: Text(
        compact ? 'Add' : 'Add Client',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 13 : 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _pink,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  void _showAddClientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddClientDialog(
        token: widget.token,
        onClientAdded: () {
          context.read<ClientsNotifier>().loadClients(widget.token ?? '');
        },
      ),
    );
  }

  // --- Stats Row ---
  Widget _buildStatsRow(bool isMobile, List<dynamic> allClients) {
    final activeCount = allClients.where((c) => c['status'] == 'active').length;
    final inactiveCount = allClients.where((c) => c['status'] == 'inactive').length;

    final stats = [
      {
        'label': 'Total Clients',
        'value': allClients.length,
        'icon': Icons.people_rounded,
        'iconColor': _pink,
        'iconBg': _pink.withOpacity(0.15),
      },
      {
        'label': 'Active',
        'value': activeCount,
        'icon': Icons.check_circle_rounded,
        'iconColor': _green,
        'iconBg': _green.withOpacity(0.15),
      },
      {
        'label': 'Inactive',
        'value': inactiveCount,
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
          childAspectRatio: 1.95,
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
            padding: i < stats.length - 1
                ? const EdgeInsets.only(right: 14)
                : EdgeInsets.zero,
            child: _statsCard(s),
          ),
        );
      }).toList(),
    );
  }

  Widget _statsCard(Map<String, dynamic> stat) {
    final accent = stat['iconColor'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (stat['iconBg'] as Color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(stat['icon'] as IconData, color: accent, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stat['value']}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        color: AppTheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filters ---
  Widget _buildMobileFilters(ClientsNotifier notifier) {
    return Column(
      children: [
        _searchField(notifier), 
        const SizedBox(height: 10), 
        _statusDropdown(notifier)
      ],
    );
  }

  Widget _buildDesktopFilters(ClientsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _searchField(notifier)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _statusDropdown(notifier)),
        ],
      ),
    );
  }

  Widget _searchField(ClientsNotifier notifier) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: TextField(
        style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
        onChanged: (v) => notifier.setSearchQuery(v),
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(
            color: AppTheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          icon: Icon(
            Icons.search_rounded,
            color: AppTheme.onSurface.withOpacity(0.6),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _statusDropdown(ClientsNotifier notifier) {
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
          value: notifier.state.statusFilter.isEmpty ? '' : notifier.state.statusFilter,
          onChanged: (v) => notifier.setStatusFilter(v ?? ''),
          items: const [
            DropdownMenuItem(value: '', child: Text('All Status')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
          ].map((item) {
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
          }).toList(),
          dropdownColor: const Color(0xFF1E1E1E),
          iconEnabledColor: _textGrey,
          style: const TextStyle(color: _textLight, fontSize: 13),
          isExpanded: true,
        ),
      ),
    );
  }

  // --- Data Table (Desktop) ---
  Widget _buildTable(List<dynamic> filtered) {
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
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(color: _border, height: 1),
            itemBuilder: (_, i) => _buildTableRow(filtered[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      color: _textGrey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,
    );
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
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _avatar(name, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: _textGrey, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(color: _textLight, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: _textGrey, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(color: _textLight, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              companyName,
              style: const TextStyle(color: _textLight, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              clientId,
              style: const TextStyle(color: _textLight, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: _statusBadge(status)),
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

  // --- Mobile Cards ---
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
              Row(
                children: [
                  _avatar(name, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (clientId != '-')
                          Text(
                            clientId,
                            style: const TextStyle(color: _textGrey, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 12),
              _cardRow(Icons.email_outlined, email),
              const SizedBox(height: 6),
              _cardRow(Icons.phone_outlined, phone),
              const SizedBox(height: 6),
              _cardRow(Icons.business_rounded, companyName),
              const SizedBox(height: 12),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 12),
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
                      onPressed: () => _deleteClient(client['_id'].toString()),
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
        Icon(icon, color: _textGrey, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _textLight, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- Modals & Sheets ---
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2),
                ),
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
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (clientId != '-')
                        Text(
                          clientId,
                          style: const TextStyle(color: _textGrey, fontSize: 13),
                        ),
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
            child: Text(
              label,
              style: const TextStyle(
                color: _textGrey, fontSize: 13, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(Map<String, dynamic> client) {
    final clientId = client['_id']?.toString() ?? '';
    final nameCtrl = TextEditingController(text: client['name'] ?? '');
    final emailCtrl = TextEditingController(text: client['email'] ?? '');
    final phoneCtrl = TextEditingController(text: client['phone'] ?? '');
    final companyNameCtrl = TextEditingController(text: client['companyName'] ?? '');
    final notesCtrl = TextEditingController(text: client['notes'] ?? '');
    
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setS) {
            return Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_pink.withOpacity(0.1), _pink.withOpacity(0.04)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        border: Border(
                          bottom: BorderSide(color: _border.withOpacity(0.3), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _pink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _pink.withOpacity(0.3), width: 1),
                            ),
                            child: const Icon(Icons.edit_rounded, color: _pink, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Edit Client',
                                  style: TextStyle(
                                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Update client account details',
                                  style: TextStyle(color: _textGrey, fontSize: 12),
                                ),
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
                              child: const Icon(Icons.close_rounded, color: _textGrey, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(errorMessage!, style: const TextStyle(color: _red, fontSize: 13)),
                            ),
                          TextField(
                            controller: nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Full Name'),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: emailCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: phoneCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Phone'),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: companyNameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Company'),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: notesCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Notes'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: isSubmitting ? null : () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    decoration: BoxDecoration(
                                      color: _border.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _border.withOpacity(0.5)),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: isSubmitting
                                      ? null
                                      : () async {
                                          if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                            setS(() => errorMessage = 'Name and Email are required');
                                            return;
                                          }
                                          setS(() {
                                            isSubmitting = true;
                                            errorMessage = null;
                                          });
                                          try {
                                            await AdminClientsService.updateClient(
                                              token: widget.token ?? '',
                                              clientId: clientId,
                                              name: nameCtrl.text.trim(),
                                              email: emailCtrl.text.trim(),
                                              phone: phoneCtrl.text.trim(),
                                              companyName: companyNameCtrl.text.trim(),
                                              clientNotes: notesCtrl.text.trim(),
                                            );
                                            if (mounted) {
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Client updated successfully'),
                                                  backgroundColor: _green,
                                                ),
                                              );
                                              context.read<ClientsNotifier>().loadClients(widget.token ?? '');
                                            }
                                          } catch (e) {
                                            setS(() {
                                              errorMessage = e.toString().replaceAll('Exception: ', '');
                                              isSubmitting = false;
                                            });
                                          }
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_pink, _pink.withOpacity(0.8)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _pink.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: isSubmitting
                                        ? const Center(
                                            child: SizedBox(
                                              width: 18, height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white),
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteClient(String clientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border.withOpacity(0.5)),
          ),
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
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
                              color: _red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
        await AdminClientsService.deleteClient(token: widget.token ?? '', clientId: clientId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client deleted successfully'), backgroundColor: _green),
          );
          context.read<ClientsNotifier>().loadClients(widget.token ?? '');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete client'), backgroundColor: _red),
          );
        }
      }
    }
  }

  // --- Utility Widgets ---
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded, size: 48, color: _textGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No clients found', style: TextStyle(color: _textLight, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildError(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.error_outline_rounded, color: _red, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load clients',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<ClientsNotifier>().loadClients(widget.token ?? ''),
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.black),
              label: const Text('Retry', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Add Client Dialog Widget ---
class _AddClientDialog extends StatefulWidget {
  final String? token;
  final VoidCallback onClientAdded;

  const _AddClientDialog({required this.token, required this.onClientAdded});

  @override
  State<_AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<_AddClientDialog> {
  static const Color _card = AppTheme.cardColor;
  static const Color _input = AppTheme.surface;
  static const Color _border = AppTheme.outline;
  static const Color _textGrey = Color(0xFF9E9E9E);

  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _clientCompanyName = '';
  String _assignedCompanyId = '';
  String _notes = '';
  bool _isSubmitting = false;
  String? _errorMessage;

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
          const SnackBar(content: Text('Client created successfully'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context);
        widget.onClientAdded();
      } else {
        setState(() => _errorMessage = result['message'] ?? 'Failed to create client');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isMobileView = responsive.isMobile;
    final horizontalPadding = responsive.horizontalPadding;
    final verticalSpacing = responsive.smallSpacing;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: isMobileView ? double.infinity : 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Client',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: responsive.headingFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a client account.',
                          style: TextStyle(color: _textGrey, fontSize: responsive.captionFontSize),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: _border, height: 1),
            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: verticalSpacing),
                            child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                          ),
                        isMobileView
                            ? Column(
                                children: [
                                  _buildTextField(label: 'Full Name', hint: 'John Smith', isRequired: true, onChanged: (v) => _fullName = v),
                                  SizedBox(height: verticalSpacing),
                                  _buildTextField(label: 'Phone', hint: '+1 234 567 890', onChanged: (v) => _phone = v),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(label: 'Full Name', hint: 'John Smith', isRequired: true, onChanged: (v) => _fullName = v),
                                  ),
                                  SizedBox(width: responsive.smallSpacing),
                                  Expanded(
                                    child: _buildTextField(label: 'Phone', hint: '+1 234 567 890', onChanged: (v) => _phone = v),
                                  ),
                                ],
                              ),
                        SizedBox(height: verticalSpacing),
                        _buildTextField(label: 'Email Address', hint: 'client@company.com', isRequired: true, isEmail: true, onChanged: (v) => _email = v),
                        SizedBox(height: verticalSpacing),
                        _buildTextField(label: 'Password', hint: 'Min 6 characters', isRequired: true, isPassword: true, minLength: 6, onChanged: (v) => _password = v),
                        SizedBox(height: verticalSpacing),
                        _buildTextField(label: 'Company Name', hint: 'Acme Corp', isRequired: true, onChanged: (v) => _clientCompanyName = v),
                        SizedBox(height: verticalSpacing),
                        _buildTextAreaField(label: 'Notes', hint: 'Optional client notes', onChanged: (v) => _notes = v),
                        SizedBox(height: verticalSpacing * 2),

                        isMobileView
                            ? Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: responsive.buttonHeight,
                                    child: OutlinedButton(
                                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.onSurface, side: const BorderSide(color: _border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  SizedBox(height: responsive.smallSpacing),
                                  SizedBox(
                                    width: double.infinity,
                                    height: responsive.buttonHeight,
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        disabledBackgroundColor: _textGrey,
                                      ),
                                      icon: _isSubmitting
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                                          : const Icon(Icons.check, size: 18),
                                      label: Text(_isSubmitting ? 'Creating...' : 'Create Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.onSurface, side: const BorderSide(color: _border),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  SizedBox(width: responsive.smallSpacing),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        disabledBackgroundColor: _textGrey,
                                      ),
                                      icon: _isSubmitting
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                                          : const Icon(Icons.check, size: 18),
                                      label: Text(_isSubmitting ? 'Creating...' : 'Create Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, required String hint, bool isRequired = false, bool isEmail = false, bool isPassword = false, int minLength = 0, required Function(String) onChanged,
  }) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.onSurface, fontSize: responsive.captionFontSize + 2, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: responsive.smallSpacing),
        Container(
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding / 2),
          decoration: BoxDecoration(color: _input, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: TextFormField(
            obscureText: isPassword,
            style: TextStyle(color: AppTheme.onSurface, fontSize: responsive.bodyFontSize),
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: _textGrey)),
            onChanged: onChanged,
            validator: (v) {
              if (isRequired && (v == null || v.isEmpty)) return 'This field is required';
              if (minLength > 0 && v != null && v.length < minLength) return '$label must be at least $minLength characters';
              if (isEmail && v != null && v.isNotEmpty) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) return 'Enter a valid email';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label, required String hint, required Function(String) onChanged,
  }) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.onSurface, fontSize: responsive.captionFontSize + 2, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: responsive.smallSpacing),
        Container(
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding / 2, vertical: responsive.smallSpacing),
          decoration: BoxDecoration(color: _input, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: TextFormField(
            style: TextStyle(color: AppTheme.onSurface, fontSize: responsive.bodyFontSize),
            maxLines: 4, minLines: 3,
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: _textGrey)),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}