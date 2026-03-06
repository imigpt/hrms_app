import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/leave_balance_model.dart';
import '../services/leave_service.dart';
import '../services/token_storage_service.dart';
import '../theme/app_theme.dart';

class LeaveBalanceScreen extends StatefulWidget {
  final String? token;
  const LeaveBalanceScreen({super.key, this.token});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen>
    with TickerProviderStateMixin {
  // ── Theme constants ────────────────────────────────────────────────────────
  static const Color _bg = AppTheme.background;
  static const Color _card = Color(0xFF111111);
  static const Color _border = Color(0xFF1E1E1E);
  static const Color _primary = AppTheme.primaryColor;
  static const Color _green = AppTheme.secondaryColor;
  static const Color _red = AppTheme.errorColor;
  static const Color _blue = Color(0xFF4FC3F7);
  static const Color _amber = Color(0xFFFFB74D);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  String? _resolvedToken;
  List<LeaveBalanceEntry> _allEntries = [];

  String _roleFilter = 'all'; // all | hr | employee
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  final Set<String> _selectedIds = {};
  final Set<String> _processingIds = {};

  // Row entrance animations
  List<AnimationController> _rowAnims = [];

  // ── Computed ───────────────────────────────────────────────────────────────
  int get _totalCount => _allEntries.length;
  int get _hrCount => _allEntries.where((e) => e.role == 'hr').length;
  int get _employeeCount =>
      _allEntries.where((e) => e.role == 'employee').length;

  List<LeaveBalanceEntry> get _visible {
    if (_roleFilter == 'all' && _searchQuery.isEmpty) return _allEntries;
    final q = _searchQuery.toLowerCase();
    return _allEntries.where((e) {
      final matchRole = _roleFilter == 'all' || e.role == _roleFilter;
      final matchSearch =
          q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          (e.employeeId?.toLowerCase().contains(q) ?? false);
      return matchRole && matchSearch;
    }).toList();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _rowAnims) c.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    String? tok = widget.token;
    if (tok == null || tok.isEmpty) {
      tok = await TokenStorageService().getToken();
    }
    _resolvedToken = tok;
    await _fetchBalances();
  }

  Future<void> _fetchBalances() async {
    for (final c in _rowAnims) c.dispose();
    _rowAnims = [];
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resp = await LeaveService.getLeaveBalances(
        token: _resolvedToken ?? '',
      );
      if (!mounted) return;
      setState(() {
        _allEntries = resp.data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = v.trim());
    });
  }

  // ── Assign balance ─────────────────────────────────────────────────────────
  Future<void> _editBalance(LeaveBalanceEntry entry) async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditBalanceSheet(
        entry: entry,
        card: _card,
        border: _border,
        primary: _primary,
        green: _green,
        red: _red,
      ),
    );
    if (result == null) return;

    setState(() => _processingIds.add(entry.id));
    try {
      await LeaveService.assignLeaveBalance(
        token: _resolvedToken ?? '',
        userId: entry.id,
        paid: result['paid']!,
        sick: result['sick']!,
        unpaid: result['unpaid']!,
      );
      _snack('Balance updated for ${entry.name}', _green);
      await _fetchBalances();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception:', '').trim(), _red);
    } finally {
      if (mounted) setState(() => _processingIds.remove(entry.id));
    }
  }

  Future<void> _bulkEdit() async {
    if (_selectedIds.isEmpty) return;
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BulkEditSheet(
        count: _selectedIds.length,
        card: _card,
        border: _border,
        primary: _primary,
        green: _green,
        red: _red,
      ),
    );
    if (result == null) return;

    setState(() {
      for (final id in _selectedIds) _processingIds.add(id);
    });
    try {
      await LeaveService.bulkAssignLeaveBalance(
        token: _resolvedToken ?? '',
        userIds: _selectedIds.toList(),
        paid: result['paid']!,
        sick: result['sick']!,
        unpaid: result['unpaid']!,
      );
      _snack('Balances updated for ${_selectedIds.length} users', _green);
      setState(() => _selectedIds.clear());
      await _fetchBalances();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception:', '').trim(), _red);
    } finally {
      if (mounted) setState(() => _processingIds.removeAll(_selectedIds));
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMob = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _bulkEdit,
              backgroundColor: _primary,
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
              label: Text(
                'Edit ${_selectedIds.length} Selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(isMob),
            Expanded(
              child: _isLoading
                  ? _buildLoader()
                  : _error != null
                  ? _buildError()
                  : _buildBody(isMob),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isMob) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMob ? 14 : 20, 14, isMob ? 14 : 20, 14),
      decoration: BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: _primary,
                      size: isMob ? 18 : 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Leave Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isMob ? 17 : 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Assign and manage leave balances for HR & Employees',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: isMob ? 11 : 12.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchBalances,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loader / Error ─────────────────────────────────────────────────────────
  Widget _buildLoader() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
        const SizedBox(height: 14),
        const Text(
          'Loading leave balances...',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: _red, size: 52),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _fetchBalances,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    ),
  );

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(bool isMob) {
    return RefreshIndicator(
      onRefresh: _fetchBalances,
      color: _primary,
      backgroundColor: _card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMob ? 12 : 20,
                18,
                isMob ? 12 : 20,
                0,
              ),
              child: _buildStats(isMob),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMob ? 12 : 20,
                20,
                isMob ? 12 : 20,
                0,
              ),
              child: _buildTableSection(isMob),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStats(bool isMob) {
    final cards = [
      _StatCard(
        icon: Icons.people_alt_rounded,
        iconColor: _primary,
        bgColor: _primary.withOpacity(0.12),
        count: _totalCount,
        label: 'Total Users',
      ),
      _StatCard(
        icon: Icons.manage_accounts_rounded,
        iconColor: _blue,
        bgColor: _blue.withOpacity(0.12),
        count: _hrCount,
        label: 'HR Users',
      ),
      _StatCard(
        icon: Icons.badge_rounded,
        iconColor: _green,
        bgColor: _green.withOpacity(0.12),
        count: _employeeCount,
        label: 'Employees',
      ),
    ];

    if (isMob) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _statWidget(c),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: e.key < cards.length - 1 ? 12 : 0,
                ),
                child: _statWidget(e.value),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _statWidget(_StatCard c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(c.icon, color: c.iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                height: 1.1,
              ),
            ),
            Text(
              c.label,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Table section ──────────────────────────────────────────────────────────
  Widget _buildTableSection(bool isMob) {
    final rows = _visible;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave Balances',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Click Edit to assign or change leave balances',
                  style: TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                // Filters
                _buildFilters(isMob),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Divider(color: _border, height: 1),
          // Empty state
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, color: Colors.white12, size: 42),
                    const SizedBox(height: 10),
                    const Text(
                      'No records found',
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            isMob ? _buildMobileCards(rows) : _buildDesktopTable(rows),
        ],
      ),
    );
  }

  // ── Filters ────────────────────────────────────────────────────────────────
  Widget _buildFilters(bool isMob) {
    if (isMob) {
      return Column(
        children: [
          // Search
          _searchField(),
          const SizedBox(height: 8),
          // Role chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _roleChip('all', 'All Roles'),
                const SizedBox(width: 8),
                _roleChip('hr', 'HR'),
                const SizedBox(width: 8),
                _roleChip('employee', 'Employee'),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Role dropdown
        _roleDropdown(),
        const SizedBox(width: 12),
        Expanded(child: _searchField()),
      ],
    );
  }

  Widget _searchField() => SizedBox(
    height: 38,
    child: TextField(
      controller: _searchCtrl,
      onChanged: _onSearchChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search by name or email...',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.white24,
          size: 18,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white24,
                  size: 16,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primary.withOpacity(0.6)),
        ),
      ),
    ),
  );

  Widget _roleDropdown() {
    final labels = {'all': 'All Roles', 'hr': 'HR', 'employee': 'Employee'};
    return PopupMenuButton<String>(
      initialValue: _roleFilter,
      onSelected: (v) => setState(() => _roleFilter = v),
      color: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: _border),
      ),
      itemBuilder: (_) => labels.entries
          .map(
            (e) => PopupMenuItem(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(
                  color: _roleFilter == e.key ? _primary : Colors.white70,
                  fontSize: 13,
                  fontWeight: _roleFilter == e.key
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 14,
              color: _roleFilter == 'all' ? Colors.white38 : _primary,
            ),
            const SizedBox(width: 8),
            Text(
              labels[_roleFilter]!,
              style: TextStyle(
                color: _roleFilter == 'all' ? Colors.white70 : _primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _roleFilter == 'all' ? Colors.white38 : _primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label) {
    final active = _roleFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _primary.withOpacity(0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _primary.withOpacity(0.5) : _border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _primary : Colors.white54,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Desktop table ──────────────────────────────────────────────────────────
  Widget _buildDesktopTable(List<LeaveBalanceEntry> rows) {
    const hdStyle = TextStyle(
      color: Colors.white38,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    );

    final allSelected = _selectedIds.containsAll(rows.map((r) => r.id));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              color: const Color(0xFF0D0D0D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Checkbox(
                      value: allSelected,
                      onChanged: (v) => setState(() {
                        if (v == true)
                          _selectedIds.addAll(rows.map((r) => r.id));
                        else
                          _selectedIds.removeAll(rows.map((r) => r.id));
                      }),
                      activeColor: _primary,
                      checkColor: Colors.white,
                      side: BorderSide(color: Colors.white24),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 220,
                    child: Text('Employee', style: hdStyle),
                  ),
                  const SizedBox(
                    width: 110,
                    child: Text('Role', style: hdStyle),
                  ),
                  const SizedBox(
                    width: 120,
                    child: Text('Paid Leave', style: hdStyle),
                  ),
                  const SizedBox(
                    width: 120,
                    child: Text('Sick Leave', style: hdStyle),
                  ),
                  const SizedBox(
                    width: 130,
                    child: Text('Unpaid Leave', style: hdStyle),
                  ),
                  const SizedBox(
                    width: 70,
                    child: Text('Action', style: hdStyle),
                  ),
                ],
              ),
            ),
            Divider(color: _border, height: 1),
            // Data rows
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              _ensureAnim(i);
              return _FadeSlide(
                animation: _rowAnims[i],
                child: _buildDesktopRow(row, i),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _ensureAnim(int i) {
    if (_rowAnims.length <= i) {
      final ctrl = AnimationController(
        duration: const Duration(milliseconds: 320),
        vsync: this,
      );
      _rowAnims.add(ctrl);
      ctrl.forward();
    }
  }

  Widget _buildDesktopRow(LeaveBalanceEntry entry, int index) {
    final isEven = index % 2 == 0;
    final isSelected = _selectedIds.contains(entry.id);
    final isProcessing = _processingIds.contains(entry.id);

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          color: isSelected
              ? _primary.withOpacity(0.06)
              : isEven
              ? Colors.transparent
              : const Color(0xFF0A0A0A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              SizedBox(
                width: 36,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v == true)
                      _selectedIds.add(entry.id);
                    else
                      _selectedIds.remove(entry.id);
                  }),
                  activeColor: _primary,
                  checkColor: Colors.white,
                  side: BorderSide(color: Colors.white24),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Employee
              SizedBox(
                width: 220,
                child: Row(
                  children: [
                    _avatar(entry),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            entry.email,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Role badge
              SizedBox(width: 110, child: _roleBadge(entry.role)),
              // Paid
              SizedBox(
                width: 120,
                child: _balanceCell(
                  entry.balance.usedPaid,
                  entry.balance.paid,
                  _green,
                ),
              ),
              // Sick
              SizedBox(
                width: 120,
                child: _balanceCell(
                  entry.balance.usedSick,
                  entry.balance.sick,
                  _blue,
                ),
              ),
              // Unpaid
              SizedBox(
                width: 130,
                child: _balanceCell(
                  entry.balance.usedUnpaid,
                  entry.balance.unpaid,
                  _amber,
                ),
              ),
              // Action
              SizedBox(
                width: 70,
                child: GestureDetector(
                  onTap: () => _editBalance(entry),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: _primary),
                      const SizedBox(width: 5),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Divider(color: _border, height: 1),
        ),
      ],
    );
  }

  // ── Mobile cards ───────────────────────────────────────────────────────────
  Widget _buildMobileCards(List<LeaveBalanceEntry> rows) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          _ensureAnim(i);
          return _FadeSlide(
            animation: _rowAnims[i],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildMobileCard(row),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(LeaveBalanceEntry entry) {
    final isSelected = _selectedIds.contains(entry.id);
    final isProcessing = _processingIds.contains(entry.id);

    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected)
          _selectedIds.remove(entry.id);
        else
          _selectedIds.add(entry.id);
      }),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? _primary.withOpacity(0.08)
                  : const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primary.withOpacity(0.4) : _border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Row(
                    children: [
                      // Checkbox
                      Transform.scale(
                        scale: 0.85,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (v) => setState(() {
                            if (v == true)
                              _selectedIds.add(entry.id);
                            else
                              _selectedIds.remove(entry.id);
                          }),
                          activeColor: _primary,
                          checkColor: Colors.white,
                          side: BorderSide(color: Colors.white24),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _avatar(entry),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              entry.email,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _roleBadge(entry.role),
                    ],
                  ),
                ),
                Divider(color: _border, height: 1),
                // Balance row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _mobileBalanceTile(
                          'Paid Leave',
                          entry.balance.usedPaid,
                          entry.balance.paid,
                          _green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mobileBalanceTile(
                          'Sick Leave',
                          entry.balance.usedSick,
                          entry.balance.sick,
                          _blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _mobileBalanceTile(
                          'Unpaid',
                          entry.balance.usedUnpaid,
                          entry.balance.unpaid,
                          _amber,
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _border)),
                  ),
                  child: GestureDetector(
                    onTap: () => _editBalance(entry),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: _primary),
                          const SizedBox(width: 6),
                          Text(
                            'Edit Balance',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isProcessing)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reusable small widgets ──────────────────────────────────────────────────
  Widget _avatar(LeaveBalanceEntry entry) {
    final photo = entry.profilePhoto;
    final initials = entry.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: _primary.withOpacity(0.2),
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: _primary.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final isHr = role.toLowerCase() == 'hr';
    final color = isHr ? _blue : _green;
    final label = isHr ? 'HR' : 'EMPLOYEE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _balanceCell(int used, int total, Color color) {
    return Row(
      children: [
        Text(
          '$used',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '/$total',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  Widget _mobileBalanceTile(String label, int used, int total, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$used',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '/$total',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Balance Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditBalanceSheet extends StatefulWidget {
  final LeaveBalanceEntry entry;
  final Color card, border, primary, green, red;
  const _EditBalanceSheet({
    required this.entry,
    required this.card,
    required this.border,
    required this.primary,
    required this.green,
    required this.red,
  });

  @override
  State<_EditBalanceSheet> createState() => _EditBalanceSheetState();
}

class _EditBalanceSheetState extends State<_EditBalanceSheet> {
  late final TextEditingController _paidCtrl;
  late final TextEditingController _sickCtrl;
  late final TextEditingController _unpaidCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.entry.balance;
    _paidCtrl = TextEditingController(text: '${b.paid}');
    _sickCtrl = TextEditingController(text: '${b.sick}');
    _unpaidCtrl = TextEditingController(text: '${b.unpaid}');
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    _sickCtrl.dispose();
    _unpaidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.entry.balance;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: widget.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: widget.border),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.primary.withOpacity(0.2),
                  child: Text(
                    widget.entry.name
                        .trim()
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: widget.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        widget.entry.email,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: widget.border),
            const SizedBox(height: 16),
            const Text(
              'Assign Leave Balances',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set the total number of days for each leave type.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _inputTile(
              label: 'Paid Leave',
              ctrl: _paidCtrl,
              usedLabel: '${b.usedPaid}/${b.paid} used',
              color: widget.green,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 14),
            _inputTile(
              label: 'Sick Leave',
              ctrl: _sickCtrl,
              usedLabel: '${b.usedSick}/${b.sick} used',
              color: const Color(0xFF4FC3F7),
              icon: Icons.healing_rounded,
            ),
            const SizedBox(height: 14),
            _inputTile(
              label: 'Unpaid Leave',
              ctrl: _unpaidCtrl,
              usedLabel: '${b.usedUnpaid}/${b.unpaid} used',
              color: const Color(0xFFFFB74D),
              icon: Icons.money_off_rounded,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.border),
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Save Balance'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputTile({
    required String label,
    required TextEditingController ctrl,
    required String usedLabel,
    required Color color,
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                usedLabel,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: TextFormField(
            controller: ctrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              filled: true,
              fillColor: color.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _submit() {
    final paid = int.tryParse(_paidCtrl.text.trim()) ?? 0;
    final sick = int.tryParse(_sickCtrl.text.trim()) ?? 0;
    final unpaid = int.tryParse(_unpaidCtrl.text.trim()) ?? 0;
    Navigator.pop(context, {'paid': paid, 'sick': sick, 'unpaid': unpaid});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bulk Edit Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BulkEditSheet extends StatefulWidget {
  final int count;
  final Color card, border, primary, green, red;
  const _BulkEditSheet({
    required this.count,
    required this.card,
    required this.border,
    required this.primary,
    required this.green,
    required this.red,
  });

  @override
  State<_BulkEditSheet> createState() => _BulkEditSheetState();
}

class _BulkEditSheetState extends State<_BulkEditSheet> {
  final _paidCtrl = TextEditingController(text: '0');
  final _sickCtrl = TextEditingController(text: '0');
  final _unpaidCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _paidCtrl.dispose();
    _sickCtrl.dispose();
    _unpaidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: widget.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: widget.border),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: widget.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Edit — ${widget.count} Users',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Text(
                        'Same balance will be applied to all selected users.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: widget.border),
            const SizedBox(height: 16),
            _row('Paid Leave', _paidCtrl, widget.green),
            const SizedBox(height: 12),
            _row('Sick Leave', _sickCtrl, const Color(0xFF4FC3F7)),
            const SizedBox(height: 12),
            _row('Unpaid Leave', _unpaidCtrl, const Color(0xFFFFB74D)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.border),
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      final paid = int.tryParse(_paidCtrl.text.trim()) ?? 0;
                      final sick = int.tryParse(_sickCtrl.text.trim()) ?? 0;
                      final unpaid = int.tryParse(_unpaidCtrl.text.trim()) ?? 0;
                      Navigator.pop(context, {
                        'paid': paid,
                        'sick': sick,
                        'unpaid': unpaid,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Apply to All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, TextEditingController ctrl, Color color) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(
        width: 80,
        child: TextFormField(
          controller: ctrl,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: color.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color),
            ),
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper data class + utility widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final int count;
  final String label;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.count,
    required this.label,
  });
}

class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}
