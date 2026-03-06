import 'dart:convert';
import 'profile_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Response wrappers
// ─────────────────────────────────────────────────────────────────────────────

PayrollListResponse payrollListResponseFromJson(String str) =>
    PayrollListResponse.fromJson(json.decode(str));

SalaryResponse salaryResponseFromJson(String str) =>
    SalaryResponse.fromJson(json.decode(str));

SalaryListResponse salaryListResponseFromJson(String str) =>
    SalaryListResponse.fromJson(json.decode(str));

PrePaymentListResponse prePaymentListResponseFromJson(String str) =>
    PrePaymentListResponse.fromJson(json.decode(str));

IncrementListResponse incrementListResponseFromJson(String str) =>
    IncrementListResponse.fromJson(json.decode(str));

// ─────────────────────────────────────────────────────────────────────────────
// Payroll List Response  — GET /api/payroll/my-payrolls
// ─────────────────────────────────────────────────────────────────────────────

class PayrollListResponse {
  final bool success;
  final int count;
  final List<Payroll> data;

  PayrollListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory PayrollListResponse.fromJson(Map<String, dynamic> json) =>
      PayrollListResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] != null
            ? List<Payroll>.from(json['data'].map((x) => Payroll.fromJson(x)))
            : [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Payroll
// ─────────────────────────────────────────────────────────────────────────────

class Payroll {
  final String id;
  final String? userId;
  final String? userName;
  final int month;
  final int year;
  final double basicSalary;
  final List<PayrollItem> allowances;
  final List<PayrollItem> deductions;
  final double prePaymentDeductions;
  final double grossSalary;
  final double totalDeductions;
  final double netSalary;
  final DateTime? paymentDate;
  final String status; // generated, paid, pending
  final String? notes;
  final DateTime? createdAt;

  Payroll({
    required this.id,
    this.userId,
    this.userName,
    required this.month,
    required this.year,
    required this.basicSalary,
    this.allowances = const [],
    this.deductions = const [],
    this.prePaymentDeductions = 0,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netSalary,
    this.paymentDate,
    this.status = 'generated',
    this.notes,
    this.createdAt,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return Payroll(
      id: json['_id'] ?? '',
      userId: user is Map ? user['_id'] : (user is String ? user : null),
      userName: user is Map ? user['name'] : null,
      month: json['month'] ?? 1,
      year: json['year'] ?? 2025,
      basicSalary: (json['basicSalary'] ?? 0).toDouble(),
      allowances: json['allowances'] != null
          ? List<PayrollItem>.from(
              json['allowances'].map((x) => PayrollItem.fromJson(x)),
            )
          : [],
      deductions: json['deductions'] != null
          ? List<PayrollItem>.from(
              json['deductions'].map((x) => PayrollItem.fromJson(x)),
            )
          : [],
      prePaymentDeductions: (json['prePaymentDeductions'] ?? 0).toDouble(),
      grossSalary: (json['grossSalary'] ?? 0).toDouble(),
      totalDeductions: (json['totalDeductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'])
          : null,
      status: json['status'] ?? 'generated',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get monthName {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

class PayrollItem {
  final String name;
  final double amount;

  PayrollItem({required this.name, required this.amount});

  factory PayrollItem.fromJson(Map<String, dynamic> json) => PayrollItem(
    name: json['name'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Employee Salary — GET /api/payroll/salaries/me
// ─────────────────────────────────────────────────────────────────────────────

class SalaryResponse {
  final bool success;
  final EmployeeSalary? data;

  SalaryResponse({required this.success, this.data});

  factory SalaryResponse.fromJson(Map<String, dynamic> json) => SalaryResponse(
    success: json['success'] ?? false,
    data: json['data'] != null ? EmployeeSalary.fromJson(json['data']) : null,
  );
}

class SalaryListResponse {
  final bool success;
  final int count;
  final List<EmployeeSalary> data;

  SalaryListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory SalaryListResponse.fromJson(Map<String, dynamic> json) =>
      SalaryListResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] != null
            ? List<EmployeeSalary>.from(
                json['data'].map((x) => EmployeeSalary.fromJson(x)),
              )
            : [],
      );
}

class EmployeeSalary {
  final String id;
  final double basicSalary;
  final List<SalaryComponent> allowances;
  final List<SalaryComponent> deductions;
  final String status; // active, inactive
  final DateTime? effectiveFrom;
  final String? salaryGroup;
  final String? notes;
  final double totalAllowances;
  final double totalDeductions;
  final double netSalary;

  EmployeeSalary({
    required this.id,
    required this.basicSalary,
    this.allowances = const [],
    this.deductions = const [],
    this.status = 'active',
    this.effectiveFrom,
    this.salaryGroup,
    this.notes,
    this.totalAllowances = 0,
    this.totalDeductions = 0,
    this.netSalary = 0,
  });

  factory EmployeeSalary.fromJson(Map<String, dynamic> json) => EmployeeSalary(
    id: json['_id'] ?? '',
    basicSalary: (json['basicSalary'] ?? 0).toDouble(),
    allowances: json['allowances'] != null
        ? List<SalaryComponent>.from(
            json['allowances'].map((x) => SalaryComponent.fromJson(x)),
          )
        : [],
    deductions: json['deductions'] != null
        ? List<SalaryComponent>.from(
            json['deductions'].map((x) => SalaryComponent.fromJson(x)),
          )
        : [],
    status: json['status'] ?? 'active',
    effectiveFrom: json['effectiveFrom'] != null
        ? DateTime.tryParse(json['effectiveFrom'])
        : null,
    salaryGroup: json['salaryGroup'],
    notes: json['notes'],
    totalAllowances: (json['totalAllowances'] ?? 0).toDouble(),
    totalDeductions: (json['totalDeductions'] ?? 0).toDouble(),
    netSalary: (json['netSalary'] ?? 0).toDouble(),
  );
}

class SalaryComponent {
  final String name;
  final double amount;
  final String type; // fixed, percentage

  SalaryComponent({
    required this.name,
    required this.amount,
    this.type = 'fixed',
  });

  factory SalaryComponent.fromJson(Map<String, dynamic> json) =>
      SalaryComponent(
        name: json['name'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        type: json['type'] ?? 'fixed',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pre-Payment — GET /api/payroll/pre-payments
// ─────────────────────────────────────────────────────────────────────────────

class PrePaymentListResponse {
  final bool success;
  final int count;
  final List<PrePayment> data;

  PrePaymentListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory PrePaymentListResponse.fromJson(Map<String, dynamic> json) =>
      PrePaymentListResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] != null
            ? List<PrePayment>.from(
                json['data'].map((x) => PrePayment.fromJson(x)),
              )
            : [],
      );
}

class PrePayment {
  final String id;
  final double amount;
  final String? deductMonth;
  final String? description;
  final String status; // pending, deducted, cancelled
  final BankDetails? bankDetails;
  final DateTime? createdAt;
  final ProfileUser? user;

  PrePayment({
    required this.id,
    required this.amount,
    this.deductMonth,
    this.description,
    this.status = 'pending',
    this.bankDetails,
    this.createdAt,
    this.user,
  });

  factory PrePayment.fromJson(Map<String, dynamic> json) => PrePayment(
    id: json['_id'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    deductMonth: json['deductMonth'],
    description: json['description'],
    status: json['status'] ?? 'pending',
    bankDetails: json['bankDetails'] != null
        ? BankDetails.fromJson(json['bankDetails'])
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'])
        : null,
    user: json['user'] != null ? ProfileUser.fromJson(json['user']) : null,
  );
}

class BankDetails {
  final String? accountNumber;
  final String? bankName;

  BankDetails({this.accountNumber, this.bankName});

  factory BankDetails.fromJson(Map<String, dynamic> json) => BankDetails(
    accountNumber: json['accountNumber'],
    bankName: json['bankName'],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Increment / Promotion — GET /api/payroll/increments
// ─────────────────────────────────────────────────────────────────────────────

class IncrementListResponse {
  final bool success;
  final int count;
  final List<IncrementPromotion> data;

  IncrementListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory IncrementListResponse.fromJson(Map<String, dynamic> json) =>
      IncrementListResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] != null
            ? List<IncrementPromotion>.from(
                json['data'].map((x) => IncrementPromotion.fromJson(x)),
              )
            : [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Increment User (nested user info in increment/promotion records)
// ─────────────────────────────────────────────────────────────────────────────

class IncrementUser {
  final String id;
  final String? name;
  final String? email;
  final String? employeeId;
  final String? position;
  final String? department;
  final String? profilePhoto;

  IncrementUser({
    required this.id,
    this.name,
    this.email,
    this.employeeId,
    this.position,
    this.department,
    this.profilePhoto,
  });

  factory IncrementUser.fromJson(Map<String, dynamic> json) => IncrementUser(
    id: json['_id'] ?? '',
    name: json['name'],
    email: json['email'],
    employeeId: json['employeeId'],
    position: json['position'],
    department: json['department'],
    profilePhoto: json['profilePhoto'],
  );
}

class IncrementPromotion {
  final String id;
  final IncrementUser? user;
  final String
  type; // increment, promotion, increment-promotion, decrement, decrement-demotion
  final String currentDesignation;
  final String? newDesignation;
  final double? previousCTC;
  final double? newCTC;
  final DateTime? effectiveDate;
  final String? reason;
  final String? description;
  final DateTime? createdAt;

  IncrementPromotion({
    required this.id,
    this.user,
    required this.type,
    required this.currentDesignation,
    this.newDesignation,
    this.previousCTC,
    this.newCTC,
    this.effectiveDate,
    this.reason,
    this.description,
    this.createdAt,
  });

  factory IncrementPromotion.fromJson(Map<String, dynamic> json) =>
      IncrementPromotion(
        id: json['_id'] ?? '',
        user: json['user'] != null
            ? IncrementUser.fromJson(json['user'])
            : null,
        type: json['type'] ?? 'increment',
        currentDesignation: json['currentDesignation'] ?? '',
        newDesignation: json['newDesignation'],
        previousCTC: json['previousCTC']?.toDouble(),
        newCTC: json['newCTC']?.toDouble(),
        effectiveDate: json['effectiveDate'] != null
            ? DateTime.tryParse(json['effectiveDate'])
            : null,
        reason: json['reason'],
        description: json['description'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );

  String get typeLabel {
    switch (type) {
      case 'increment':
        return 'Increment';
      case 'promotion':
        return 'Promotion';
      case 'increment-promotion':
        return 'Increment & Promotion';
      case 'decrement':
        return 'Decrement';
      case 'decrement-demotion':
        return 'Decrement & Demotion';
      default:
        return type;
    }
  }
}
