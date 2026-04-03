import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:hrms_app/features/attendance/data/services/attendance_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/features/attendance/data/models/attendance_records_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _selectedFilter = 'All';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _filters = [
    'All',
    'Present',
    'Absent',
    'Late',
    'Half Day',
    'Leave',
  ];
  // API state
  bool _isLoading = true;
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  // Fetch attendance records from API
  Future<void> _fetchAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await TokenStorageService().getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      // Calculate start and end dates for the selected month
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Always fetch ALL records (no status filter)
      final records = await AttendanceService.getAttendanceRecords(
        token: token,
        startDate: startDateStr,
        endDate: endDateStr,
        month: _selectedMonth,
        year: _selectedYear,
        status: null, // Always fetch all records
      );

      print('Fetched ${records.count} total records');
      print('Records data length: ${records.data.length}');
      if (records.data.isNotEmpty) {
        print('Sample record status: ${records.data.first.status}');
      }

      if (mounted) {
        setState(() {
          _records = records.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attendance records: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load attendance records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter records based on selected filter
  List<AttendanceRecord> get _filteredRecords {
    if (_selectedFilter == 'All') {
      return _records;
    }

    // Filter records by status (handle Half Day separately)
    return _records.where((record) {
      final recordStatus = record.status.toLowerCase();
      final filterLower = _selectedFilter.toLowerCase();

      // Handle "Half Day" filter matching both "halfday" and "half_day"
      if (filterLower == 'half day') {
        return recordStatus == 'halfday' ||
            recordStatus == 'half_day' ||
            recordStatus == 'half day' ||
            recordStatus == 'half-day';
      }

      return recordStatus == filterLower;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter Chips
                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            // No need to fetch again, just update UI filter
                          },
                          backgroundColor: const Color(0xFF1A1A1A),
                          selectedColor: const Color(
                            0xFFFF8B94,
                          ).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF8B94)
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFF8B94)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Summary Stats (Always show counts from ALL records)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildStatItem('Total', '${_records.length}', Colors.blue),
                _buildStatItem(
                  'Present',
                  '${_records.where((r) => r.status.toLowerCase() == 'present').length}',
                  Colors.green,
                ),
                _buildStatItem(
                  'Absent',
                  '${_records.where((r) => r.status.toLowerCase() == 'absent').length}',
                  Colors.red,
                ),
                _buildStatItem(
                  'Late',
                  '${_records.where((r) => r.status.toLowerCase() == 'late').length}',
                  Colors.orange,
                ),
                _buildStatItem(
                  'Half Day',
                  '${_records.where((r) {
                    final status = r.status.toLowerCase();
                    return status == 'halfday' || status == 'half_day' || status == 'half day' || status == 'half-day';
                  }).length}',
                  Colors.amber,
                ),
                _buildStatItem(
                  'Leave',
                  '${_records.where((r) => r.status.toLowerCase() == 'leave').length}',
                  Colors.purple,
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      return _buildAttendanceCard(record, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record, int index) {
    final rawStatus = record.status.toLowerCase();

    // Normalize status for display label
    String status;
    switch (rawStatus) {
      case 'halfday':
      case 'half_day':
      case 'half day':
      case 'half-day':
        status = 'Half Day';
        break;
      default:
        status =
            record.status.substring(0, 1).toUpperCase() +
            record.status.substring(1);
    }

    // Format times
    final checkInTime = DateFormat(
      'hh:mm a',
    ).format(record.checkIn.time.toLocal());
    final checkOutTime = record.checkOut != null
        ? DateFormat('hh:mm a').format(record.checkOut!.time.toLocal())
        : '-';

    // Calculate duration - show for all employees including those still clocked in
    String duration = '-';
    double displayHours = 0.0;
    
    // Start with API's workHours value
    if (record.workHours != null && record.workHours > 0) {
      displayHours = record.workHours.toDouble();
    } else if (record.checkOut == null && record.checkIn.time != null) {
      // If no checkOut yet, calculate from check-in to now
      final checkInDateTime = record.checkIn.time;
      final nowTime = DateTime.now();
      final diffMs = nowTime.difference(checkInDateTime).inMilliseconds;
      displayHours = diffMs / (1000 * 60 * 60); // Convert to hours
    }
    
    // Format duration - show if at least 1 minute (0.017 hours)
    if (displayHours >= 0.017) {
      final hours = displayHours.floor();
      final minutes = ((displayHours - hours) * 60).round();
      if (hours == 0) {
        duration = '${minutes}m';
      } else {
        duration = '${hours}h ${minutes}m';
      }
    }

    // Check if has photo (check-in photo)
    final hasPhoto = record.checkIn.photo.url.isNotEmpty;

    // Format date
    final dateStr = DateFormat('MMM d, y').format(record.date);

    Color statusColor;
    Color statusBgColor;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.15);
        break;
      case 'absent':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.15);
        break;
      case 'leave':
        statusColor = Colors.purple;
        statusBgColor = Colors.purple.withOpacity(0.15);
        break;
      case 'halfday':
      case 'half_day':
      case 'half day':
      case 'half-day':
        statusColor = Colors.amber;
        statusBgColor = Colors.amber.withOpacity(0.15);
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (status.toLowerCase() == 'present' ||
                status.toLowerCase() == 'late' ||
                status.toLowerCase() == 'halfday' ||
                status.toLowerCase() == 'half_day' ||
                status.toLowerCase() == 'half day') ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF1A1A1A), height: 1),
              const SizedBox(height: 12),

              // Time Details
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      'Check In',
                      checkInTime,
                      Icons.login,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeInfo(
                      'Check Out',
                      checkOutTime,
                      Icons.logout,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeInfo(
                      'Duration',
                      duration,
                      Icons.access_time,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1A1A1A), height: 1),
              const SizedBox(height: 12),

              // Location and Photo Info
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: (record.checkIn.location != null || record.checkOut?.location != null)
                          ? () {
                              final loc = record.checkIn.location ?? record.checkOut!.location!;
                              _openGoogleMaps(loc.latitude, loc.longitude);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'View',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: hasPhoto
                          ? () => _showPhotoDialog(record.checkIn.photo.url)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasPhoto
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasPhoto
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasPhoto
                                  ? Icons.image
                                  : Icons.image_not_supported,
                              size: 16,
                              color: hasPhoto ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasPhoto ? 'View' : 'No Photo',
                              style: TextStyle(
                                color: hasPhoto ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // For Absent and Leave - show only location and photo status
            if (status.toLowerCase() == 'absent' ||
                status.toLowerCase() == 'leave') ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF1A1A1A), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            status.toLowerCase() == 'absent'
                                ? 'No attendance recorded'
                                : 'On leave',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Open Google Maps with coordinates
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    // Try multiple methods to open maps

    // Method 1: Use geo: scheme (native Android maps)
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Geo URI failed: $e');
    }

    // Method 2: Use Google Maps URL
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Google Maps URL failed: $e');
    }

    // Method 3: Try direct Google Maps app link
    final mapsAppUri = Uri.parse(
      'https://maps.google.com/?q=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(mapsAppUri)) {
        await launchUrl(mapsAppUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Maps app URL failed: $e');
    }

    // If all methods fail, show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Google Maps. Please install Google Maps app.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Show photo in full screen dialog
  void _showPhotoDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Export to Excel
  Future<void> _exportToExcel() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records available to export'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Generating Excel file...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      // Create Excel workbook
      var excel = Excel.createExcel();
      excel.delete('Sheet1'); // Delete default sheet
      var sheet = excel['Attendance Records'];

      // Define headers
      final headers = [
        'Date',
        'Status',
        'Check In',
        'Check Out',
        'Duration',
        'Location',
      ];

      print('📊 Starting Excel export with ${_records.length} records...');

      // Add header row
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          backgroundColorHex: '#FF8FA3',
          fontColorHex: '#FFFFFF',
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      print('✓ Headers added');

      // Add data rows
      for (int i = 0; i < _records.length; i++) {
        final record = _records[i];

        // Format status
        String status = record.status;
        if (status.toLowerCase() == 'halfday' ||
            status.toLowerCase() == 'half_day') {
          status = 'Half Day';
        } else {
          status = status[0].toUpperCase() + status.substring(1);
        }

        // Format times
        final checkInTime =
            DateFormat('hh:mm a').format(record.checkIn.time.toLocal());
        final checkOutTime = record.checkOut != null
            ? DateFormat('hh:mm a').format(record.checkOut!.time.toLocal())
            : '-';

        // Calculate duration - show for all employees including those still clocked in
        String duration = '-';
        double displayHours = 0.0;
        
        // Start with API's workHours value
        if (record.workHours != null && record.workHours > 0) {
          displayHours = record.workHours.toDouble();
        } else if (record.checkOut == null && record.checkIn.time != null) {
          // If no checkOut yet, calculate from check-in to now
          final checkInDateTime = record.checkIn.time;
          final nowTime = DateTime.now();
          final diffMs = nowTime.difference(checkInDateTime).inMilliseconds;
          displayHours = diffMs / (1000 * 60 * 60); // Convert to hours
        }
        
        // Format duration - show if at least 1 minute (0.017 hours)
        if (displayHours >= 0.017) {
          final hours = displayHours.floor();
          final minutes = ((displayHours - hours) * 60).round();
          if (hours == 0) {
            duration = '${minutes}m';
          } else {
            duration = '${hours}h ${minutes}m';
          }
        }

        // Format date
        final dateStr = DateFormat('MMM d, yyyy').format(record.date);

        // Get location (Latitude, Longitude) - read from checkIn or checkOut (null-safe)
        String location = '-';
        try {
          final loc = record.checkIn.location ?? record.checkOut?.location;
          if (loc != null) {
            final lat = loc.latitude;
            final lon = loc.longitude;
            final latitude = lat.toStringAsFixed(6);
            final longitude = lon.toStringAsFixed(6);
            location = 'Lat: $latitude, Lon: $longitude';
          }
        } catch (_) {
          location = '-';
        }

        final rowData = [
          dateStr,
          status,
          checkInTime,
          checkOutTime,
          duration,
          location,
        ];

        // Add row data
        for (int j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
          );
          cell.value = rowData[j];
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      print('✓ ${_records.length} data rows added');

      // Set column widths (use double values to match excel API)
      final List<double> columnWidths = [18.0, 14.0, 14.0, 14.0, 14.0, 40.0];
      for (int col = 0; col < columnWidths.length; col++) {
        sheet.setColWidth(col, columnWidths[col]);
      }

      // Get downloads directory
      print('📱 Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Desktop/Web'}');

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (e) {
          print('Downloads dir not available, using Documents');
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      // Create directory structure
      final attendanceDir =
          Directory('${downloadsDir!.path}/HRMS/Attendance');
      print('📁 Save directory: ${downloadsDir.path}');

      if (!await attendanceDir.exists()) {
        await attendanceDir.create(recursive: true);
        print('✓ Directory created: ${attendanceDir.path}');
      }

      // Generate filename with timestamp
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy_MM_dd_HHmmss').format(now);
      final fileName = 'Attendance_$timestamp.xlsx';
      final filePath = '${attendanceDir.path}/$fileName';

      // Encode and save file
      print('💾 Encoding Excel file...');
      List<int>? fileBytes = excel.encode();

      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        print('✓ File encoded, size: ${fileBytes.length} bytes');
        print('✓ File saved successfully!');
        print('📄 File path: $filePath');
        print('✓ Records exported: ${_records.length}');

        // Close loading dialog
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        // Auto-open file after 500ms
        Future.delayed(const Duration(milliseconds: 500), () {
          OpenFile.open(filePath);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ File Downloaded!\n$fileName\n${_records.length} records',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      print('❌ Error exporting records: $e');

      // Close loading dialog
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export records: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
