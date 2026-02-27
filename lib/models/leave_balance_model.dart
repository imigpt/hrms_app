/// Models for GET /api/leave-balance (admin view)
/// Response shape:
/// { success: true, count: N, data: [ { _id, name, email, employeeId, role,
///   department, position, balance: { _id?, paid, sick, unpaid,
///   usedPaid, usedSick, usedUnpaid } } ] }

class LeaveBalanceListResponse {
  final bool success;
  final int count;
  final List<LeaveBalanceEntry> data;

  const LeaveBalanceListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory LeaveBalanceListResponse.fromJson(Map<String, dynamic> json) =>
      LeaveBalanceListResponse(
        success: json['success'] as bool? ?? false,
        count:   (json['count'] as num?)?.toInt() ?? 0,
        data:    (json['data'] as List<dynamic>? ?? [])
            .map((e) => LeaveBalanceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LeaveBalanceEntry {
  final String  id;
  final String  name;
  final String  email;
  final String? employeeId;
  final String  role;         // 'hr' | 'employee'
  final String? department;
  final String? position;
  final String? profilePhoto;
  final UserBalance balance;

  const LeaveBalanceEntry({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId,
    required this.role,
    this.department,
    this.position,
    this.profilePhoto,
    required this.balance,
  });

  factory LeaveBalanceEntry.fromJson(Map<String, dynamic> json) =>
      LeaveBalanceEntry(
        id:           json['_id'] as String? ?? '',
        name:         json['name'] as String? ?? '',
        email:        json['email'] as String? ?? '',
        employeeId:   json['employeeId'] as String?,
        role:         json['role'] as String? ?? 'employee',
        department:   json['department'] as String?,
        position:     json['position'] as String?,
        profilePhoto: json['profilePhoto'] as String?,
        balance: UserBalance.fromJson(
            json['balance'] as Map<String, dynamic>? ?? {}),
      );
}

class UserBalance {
  final String? id;
  final int paid;
  final int sick;
  final int unpaid;
  final int usedPaid;
  final int usedSick;
  final int usedUnpaid;

  const UserBalance({
    this.id,
    required this.paid,
    required this.sick,
    required this.unpaid,
    required this.usedPaid,
    required this.usedSick,
    required this.usedUnpaid,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) => UserBalance(
        id:         json['_id'] as String?,
        paid:       (json['paid']       as num?)?.toInt() ?? 0,
        sick:       (json['sick']       as num?)?.toInt() ?? 0,
        unpaid:     (json['unpaid']     as num?)?.toInt() ?? 0,
        usedPaid:   (json['usedPaid']   as num?)?.toInt() ?? 0,
        usedSick:   (json['usedSick']   as num?)?.toInt() ?? 0,
        usedUnpaid: (json['usedUnpaid'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'paid':       paid,
        'sick':       sick,
        'unpaid':     unpaid,
        'usedPaid':   usedPaid,
        'usedSick':   usedSick,
        'usedUnpaid': usedUnpaid,
      };
}
