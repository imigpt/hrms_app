import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_model.dart';
import '../services/payroll_service.dart';
import '../services/token_storage_service.dart';

class IncrementPromotionScreen extends StatefulWidget {
  const IncrementPromotionScreen({super.key});

  @override
  State<IncrementPromotionScreen> createState() => _IncrementPromotionScreenState();
}

class _IncrementPromotionScreenState extends State<IncrementPromotionScreen> {
  String? _token;
  List<IncrementPromotion> _increments = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await TokenStorageService().getToken();
    if (token == null || !mounted) return;
    setState(() => _token = token);
    await _fetchIncrements(token);
  }

  Future<void> _fetchIncrements(String token) async {
    try {
      final res = await PayrollService.getIncrements(token: token);
      if (mounted) {
        setState(() {
          _increments = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Increments fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<IncrementPromotion> _getFilteredIncrements() {
    if (_selectedFilter == 'All') return _increments;
    return _increments.where((ip) => ip.type.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Increment / Promotion',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'View your increment and promotion history',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Filter Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All'),
                                _buildFilterChip('Increment'),
                                _buildFilterChip('Promotion'),
                                _buildFilterChip('Inc/Promo'),
                                _buildFilterChip('Decrement'),
                                _buildFilterChip('Demotion'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats
                          _buildStatsCard(),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filtered = _getFilteredIncrements();
                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.trending_up_rounded,
                                    size: 64,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No records found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final increment = filtered[index];
                        return _buildIncrementCard(increment);
                      },
                      childCount: _getFilteredIncrements().isEmpty ? 1 : _getFilteredIncrements().length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[900] : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue[200] : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final filtered = _getFilteredIncrements();
    final totalAmount = filtered.fold<double>(
      0,
      (sum, ip) => sum + (ip.newCTC ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3A1A).withOpacity(0.5),
            const Color(0xFF1A2A4A).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Total Records', '${filtered.length}'),
          Container(width: 1, height: 40, color: Colors.grey[800]),
          _buildStatItem('New Amount', _currency(totalAmount)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIncrementCard(IncrementPromotion increment) {
    final isPositive = increment.type.toLowerCase().contains('increment') || 
                        increment.type.toLowerCase().contains('promotion');
    final typeColor = isPositive ? Colors.green : Colors.orange;
    final changeAmount = (increment.newCTC ?? 0) - (increment.previousCTC ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _showDetails(increment),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[900]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatType(increment.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          increment.effectiveDate != null ? DateFormat('dd MMM yyyy').format(increment.effectiveDate!) : 'N/A',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.orange).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isPositive ? Colors.green : Colors.orange).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      (changeAmount > 0 ? '+' : '') + _currency(changeAmount),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currency(increment.previousCTC ?? 0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.grey[700]),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'New',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currency(increment.newCTC ?? 0),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(IncrementPromotion increment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _detailItem('Type', _formatType(increment.type)),
                _detailItem('Effective Date', increment.effectiveDate != null ? DateFormat('dd MMM yyyy').format(increment.effectiveDate!) : 'N/A'),
                _detailItem('Previous Designation', increment.currentDesignation),
                _detailItem('New Designation', increment.newDesignation ?? 'N/A'),
                _detailItem('Previous Salary', _currency(increment.previousCTC ?? 0)),
                _detailItem('New Salary', _currency(increment.newCTC ?? 0)),
                if (increment.reason != null) _detailItem('Reason', increment.reason ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    return type
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' / ');
  }

  String _currency(double amount) => '\u{20B9}${NumberFormat('#,##,###.##').format(amount)}';
}
