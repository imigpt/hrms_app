// lib/models/employee_model.dart
// Models for all /api/employees/* endpoints

import 'dart:convert';

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────
DateTime? _parseDate(dynamic v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

// ────────────────────────────────────────────────────────────────────────────
// Employee Profile   GET/PUT /api/employees/profile
// ────────────────────────────────────────────────────────────────────────────
EmployeeProfileResponse employeeProfileResponseFromJson(String str) =>
    EmployeeProfileResponse.fromJson(json.decode(str));

class EmployeeProfileResponse {
  final bool success;
  final String? message;
  final EmployeeProfile data;

  EmployeeProfileResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory EmployeeProfileResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeProfileResponse(
        success: json['success'] ?? false,
        message: json['message'],
        data: EmployeeProfile.fromJson(json['data'] ?? {}),
      );
}

class EmployeeProfile {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;
  final String department;
  final String position;
  final String status;
  final dynamic profilePhoto;
  final DateTime? dateOfBirth;
  final DateTime? joinDate;
  final Map<String, dynamic>? leaveBalance;
  final ReportingTo? reportingTo;
  final CompanyRef? company;

  EmployeeProfile({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    required this.department,
    required this.position,
    required this.status,
    this.profilePhoto,
    this.dateOfBirth,
    this.joinDate,
    this.leaveBalance,
    this.reportingTo,
    this.company,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) =>
      EmployeeProfile(
        id: json['_id'] ?? '',
        employeeId: json['employeeId'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        role: json['role'] ?? '',
        department: json['department'] ?? '',
        position: json['position'] ?? '',
        status: json['status'] ?? '',
        profilePhoto: json['profilePhoto'],
        dateOfBirth: _parseDate(json['dateOfBirth']),
        joinDate: _parseDate(json['joinDate']),
        leaveBalance: json['leaveBalance'] is Map
            ? Map<String, dynamic>.from(json['leaveBalance'])
            : null,
        reportingTo: json['reportingTo'] is Map
            ? ReportingTo.fromJson(json['reportingTo'])
            : null,
        company: json['company'] is Map
            ? CompanyRef.fromJson(json['company'])
            : null,
      );
}

class ReportingTo {
  final String id;
  final String name;
  final String email;
  final String position;
  final String? phone;

  ReportingTo({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    this.phone,
  });

  factory ReportingTo.fromJson(Map<String, dynamic> json) => ReportingTo(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        position: json['position'] ?? '',
        phone: json['phone'],
      );
}

class CompanyRef {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  CompanyRef({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory CompanyRef.fromJson(Map<String, dynamic> json) => CompanyRef(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'],
        phone: json['phone'],
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Change Password   PUT /api/employees/change-password
// ────────────────────────────────────────────────────────────────────────────
class ChangePasswordResponse {
  final bool success;
  final String message;

  ChangePasswordResponse({required this.success, required this.message});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) =>
      ChangePasswordResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
      );
}

// ────────────────────────────────────────────────────────────────────────────
// My Tasks   GET /api/employees/tasks
// ────────────────────────────────────────────────────────────────────────────
EmployeeTasksResponse employeeTasksResponseFromJson(String str) =>
    EmployeeTasksResponse.fromJson(json.decode(str));

class EmployeeTasksResponse {
  final bool success;
  final int count;
  final List<EmployeeTask> data;

  EmployeeTasksResponse(
      {required this.success, required this.count, required this.data});

  factory EmployeeTasksResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeTasksResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] is List
            ? List<EmployeeTask>.from(
                json['data'].map((x) => EmployeeTask.fromJson(x)))
            : [],
      );
}

class EmployeeTask {
  final String id;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime? deadline;
  final String? description;
  final TaskAssignedBy? assignedBy;

  EmployeeTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
    this.deadline,
    this.description,
    this.assignedBy,
  });

  factory EmployeeTask.fromJson(Map<String, dynamic> json) => EmployeeTask(
        id: json['_id'] ?? '',
        title: json['title'] ?? '',
        status: json['status'] ?? '',
        priority: json['priority'] ?? '',
        dueDate: _parseDate(json['dueDate']),
        deadline: _parseDate(json['deadline']),
        description: json['description'],
        assignedBy: json['assignedBy'] is Map
            ? TaskAssignedBy.fromJson(json['assignedBy'])
            : null,
      );
}

class TaskAssignedBy {
  final String id;
  final String name;
  final String email;
  final String position;

  TaskAssignedBy({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
  });

  factory TaskAssignedBy.fromJson(Map<String, dynamic> json) => TaskAssignedBy(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        position: json['position'] ?? '',
      );
}

// ────────────────────────────────────────────────────────────────────────────
// My Leaves   GET /api/employees/leaves
// ────────────────────────────────────────────────────────────────────────────
EmployeeLeavesResponse employeeLeavesResponseFromJson(String str) =>
    EmployeeLeavesResponse.fromJson(json.decode(str));

class EmployeeLeavesResponse {
  final bool success;
  final int count;
  final List<EmployeeLeave> data;

  EmployeeLeavesResponse(
      {required this.success, required this.count, required this.data});

  factory EmployeeLeavesResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeLeavesResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] is List
            ? List<EmployeeLeave>.from(
                json['data'].map((x) => EmployeeLeave.fromJson(x)))
            : [],
      );
}

class EmployeeLeave {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String reason;
  final String status;
  final DateTime createdAt;

  EmployeeLeave({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory EmployeeLeave.fromJson(Map<String, dynamic> json) => EmployeeLeave(
        id: json['_id'] ?? '',
        leaveType: json['leaveType'] ?? '',
        startDate:
            _parseDate(json['startDate']) ?? DateTime.now(),
        endDate: _parseDate(json['endDate']) ?? DateTime.now(),
        days: json['days'] ?? 0,
        reason: json['reason'] ?? '',
        status: json['status'] ?? '',
        createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// My Expenses   GET /api/employees/expenses
// ────────────────────────────────────────────────────────────────────────────
EmployeeExpensesResponse employeeExpensesResponseFromJson(String str) =>
    EmployeeExpensesResponse.fromJson(json.decode(str));

class EmployeeExpensesResponse {
  final bool success;
  final int count;
  final List<EmployeeExpense> data;

  EmployeeExpensesResponse(
      {required this.success, required this.count, required this.data});

  factory EmployeeExpensesResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeExpensesResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] is List
            ? List<EmployeeExpense>.from(
                json['data'].map((x) => EmployeeExpense.fromJson(x)))
            : [],
      );
}

class EmployeeExpense {
  final String id;
  final String category;
  final double amount;
  final String currency;
  final String description;
  final String status;
  final DateTime date;
  final DateTime createdAt;

  EmployeeExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    required this.date,
    required this.createdAt,
  });

  factory EmployeeExpense.fromJson(Map<String, dynamic> json) =>
      EmployeeExpense(
        id: json['_id'] ?? '',
        category: json['category'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        currency: json['currency'] ?? 'INR',
        description: json['description'] ?? '',
        status: json['status'] ?? '',
        date: _parseDate(json['date']) ?? DateTime.now(),
        createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// My Attendance   GET /api/employees/attendance
// ────────────────────────────────────────────────────────────────────────────
EmployeeAttendanceResponse employeeAttendanceResponseFromJson(String str) =>
    EmployeeAttendanceResponse.fromJson(json.decode(str));

class EmployeeAttendanceResponse {
  final bool success;
  final List<EmployeeAttendanceRecord> data;
  final AttendanceStats stats;

  EmployeeAttendanceResponse(
      {required this.success, required this.data, required this.stats});

  factory EmployeeAttendanceResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeAttendanceResponse(
        success: json['success'] ?? false,
        data: json['data'] is List
            ? List<EmployeeAttendanceRecord>.from(
                json['data'].map((x) => EmployeeAttendanceRecord.fromJson(x)))
            : [],
        stats: json['stats'] is Map
            ? AttendanceStats.fromJson(json['stats'])
            : AttendanceStats.empty(),
      );
}

class EmployeeAttendanceRecord {
  final String id;
  final DateTime date;
  final String status;
  final double? totalHours;
  final Map<String, dynamic>? checkIn;
  final Map<String, dynamic>? checkOut;

  EmployeeAttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.totalHours,
    this.checkIn,
    this.checkOut,
  });

  factory EmployeeAttendanceRecord.fromJson(Map<String, dynamic> json) =>
      EmployeeAttendanceRecord(
        id: json['_id'] ?? '',
        date: _parseDate(json['date']) ?? DateTime.now(),
        status: json['status'] ?? '',
        totalHours: json['totalHours'] != null
            ? (json['totalHours']).toDouble()
            : null,
        checkIn:
            json['checkIn'] is Map ? Map<String, dynamic>.from(json['checkIn']) : null,
        checkOut: json['checkOut'] is Map
            ? Map<String, dynamic>.from(json['checkOut'])
            : null,
      );
}

class AttendanceStats {
  final int total;
  final int present;
  final int late;
  final int absent;
  final double averageHours;

  AttendanceStats({
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.averageHours,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      AttendanceStats(
        total: json['total'] ?? 0,
        present: json['present'] ?? 0,
        late: json['late'] ?? 0,
        absent: json['absent'] ?? 0,
        averageHours: (json['averageHours'] ?? 0).toDouble(),
      );

  factory AttendanceStats.empty() =>
      AttendanceStats(total: 0, present: 0, late: 0, absent: 0, averageHours: 0);
}

// ────────────────────────────────────────────────────────────────────────────
// Leave Balance   GET /api/employees/leave-balance
// ────────────────────────────────────────────────────────────────────────────
class EmployeeLeaveBalanceResponse {
  final bool success;
  final Map<String, dynamic> data;

  EmployeeLeaveBalanceResponse({required this.success, required this.data});

  factory EmployeeLeaveBalanceResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeLeaveBalanceResponse(
        success: json['success'] ?? false,
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'])
            : {},
      );

  int get annual => (data['annual'] ?? 0) as int;
  int get sick => (data['sick'] ?? 0) as int;
  int get casual => (data['casual'] ?? 0) as int;
  int get maternity => (data['maternity'] ?? 0) as int;
  int get paternity => (data['paternity'] ?? 0) as int;
  int get unpaid => (data['unpaid'] ?? 0) as int;
}

// ────────────────────────────────────────────────────────────────────────────
// Team Members   GET /api/employees/team
// ────────────────────────────────────────────────────────────────────────────
EmployeeTeamResponse employeeTeamResponseFromJson(String str) =>
    EmployeeTeamResponse.fromJson(json.decode(str));

class EmployeeTeamResponse {
  final bool success;
  final int count;
  final List<TeamMember> data;

  EmployeeTeamResponse(
      {required this.success, required this.count, required this.data});

  factory EmployeeTeamResponse.fromJson(Map<String, dynamic> json) =>
      EmployeeTeamResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] is List
            ? List<TeamMember>.from(
                json['data'].map((x) => TeamMember.fromJson(x)))
            : [],
      );
}

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String position;
  final String status;
  final dynamic profilePhoto;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.status,
    this.profilePhoto,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        position: json['position'] ?? '',
        status: json['status'] ?? '',
        profilePhoto: json['profilePhoto'],
      );
}
