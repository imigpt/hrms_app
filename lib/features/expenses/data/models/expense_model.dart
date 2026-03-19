import 'dart:convert';

// Parse list of expenses
ExpenseListResponse expenseListResponseFromJson(String str) =>
    ExpenseListResponse.fromJson(json.decode(str));

String expenseListResponseToJson(ExpenseListResponse data) =>
    json.encode(data.toJson());

// Parse single expense submission response
ExpenseSubmitResponse expenseSubmitResponseFromJson(String str) =>
    ExpenseSubmitResponse.fromJson(json.decode(str));

String expenseSubmitResponseToJson(ExpenseSubmitResponse data) =>
    json.encode(data.toJson());

// Parse expense statistics response
ExpenseStatisticsResponse expenseStatisticsResponseFromJson(String str) =>
    ExpenseStatisticsResponse.fromJson(json.decode(str));

String expenseStatisticsResponseToJson(ExpenseStatisticsResponse data) =>
    json.encode(data.toJson());

class ExpenseListResponse {
  bool success;
  int count;
  List<Expense> data;

  ExpenseListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseListResponse(
        success: json["success"] ?? false,
        count: json["count"] ?? 0,
        data: json["data"] != null
            ? List<Expense>.from(json["data"].map((x) => Expense.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "count": count,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class ExpenseSubmitResponse {
  bool success;
  String message;
  Expense data;

  ExpenseSubmitResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ExpenseSubmitResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseSubmitResponse(
        success: json["success"] ?? false,
        message: json["message"] ?? "",
        data: Expense.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data.toJson(),
  };
}

class Expense {
  String id;
  ExpenseUser? user;
  dynamic company;
  String category;
  double amount;
  String currency;
  DateTime date;
  String description;
  Receipt? receipt;
  String status;
  bool isLocked;
  // Review/payment tracking fields
  String? reviewedBy; // Reviewer user ID (populated or ObjectId string)
  DateTime? reviewedAt;
  String? reviewNote;
  DateTime? paidAt;
  String? paidBy; // Payer user ID
  DateTime createdAt;
  DateTime updatedAt;

  Expense({
    required this.id,
    this.user,
    this.company,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
    this.receipt,
    required this.status,
    required this.isLocked,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.paidAt,
    this.paidBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json["_id"] ?? "",
    user: json["user"] != null
        ? (json["user"] is String ? null : ExpenseUser.fromJson(json["user"]))
        : null,
    company: json["company"],
    category: json["category"] ?? "",
    amount: (json["amount"] ?? 0).toDouble(),
    currency: json["currency"] ?? "INR",
    date: json["date"] != null ? DateTime.parse(json["date"]) : DateTime.now(),
    description: json["description"] ?? "",
    receipt: json["receipt"] != null ? Receipt.fromJson(json["receipt"]) : null,
    status: json["status"] ?? "pending",
    isLocked: json["isLocked"] ?? false,
    reviewedBy: json["reviewedBy"] is String
        ? json["reviewedBy"]
        : (json["reviewedBy"]?["_id"]),
    reviewedAt: json["reviewedAt"] != null
        ? DateTime.parse(json["reviewedAt"])
        : null,
    reviewNote: json["reviewNote"],
    paidAt: json["paidAt"] != null ? DateTime.parse(json["paidAt"]) : null,
    paidBy: json["paidBy"] is String
        ? json["paidBy"]
        : (json["paidBy"]?["_id"]),
    createdAt: json["createdAt"] != null
        ? DateTime.parse(json["createdAt"])
        : DateTime.now(),
    updatedAt: json["updatedAt"] != null
        ? DateTime.parse(json["updatedAt"])
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "user": user?.toJson(),
    "company": company,
    "category": category,
    "amount": amount,
    "currency": currency,
    "date": date.toIso8601String(),
    "description": description,
    "receipt": receipt?.toJson(),
    "status": status,
    "isLocked": isLocked,
    if (reviewedBy != null) "reviewedBy": reviewedBy,
    if (reviewedAt != null) "reviewedAt": reviewedAt!.toIso8601String(),
    if (reviewNote != null) "reviewNote": reviewNote,
    if (paidAt != null) "paidAt": paidAt!.toIso8601String(),
    if (paidBy != null) "paidBy": paidBy,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}

class ExpenseUser {
  String id;
  String employeeId;
  String name;
  String department;
  String position;

  ExpenseUser({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.department,
    required this.position,
  });

  factory ExpenseUser.fromJson(Map<String, dynamic> json) => ExpenseUser(
    id: json["_id"] ?? "",
    employeeId: json["employeeId"] ?? "",
    name: json["name"] ?? "",
    department: json["department"] ?? "",
    position: json["position"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "employeeId": employeeId,
    "name": name,
    "department": department,
    "position": position,
  };
}

class Receipt {
  String url;
  String publicId;

  Receipt({required this.url, required this.publicId});

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      Receipt(url: json["url"] ?? "", publicId: json["publicId"] ?? "");

  Map<String, dynamic> toJson() => {"url": url, "publicId": publicId};
}

// ── Expense Statistics ────────────────────────────────────────────────────────

class ExpenseStatisticsResponse {
  bool success;
  ExpenseStatistics data;

  ExpenseStatisticsResponse({required this.success, required this.data});

  factory ExpenseStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseStatisticsResponse(
        success: json["success"] ?? false,
        data: ExpenseStatistics.fromJson(json["data"] ?? {}),
      );

  Map<String, dynamic> toJson() => {"success": success, "data": data.toJson()};
}

class ExpenseStatistics {
  int total;
  int draft;
  int pending;
  int approved;
  int rejected;
  int paid;
  double totalAmount;
  double approvedAmount;
  double paidAmount;
  double pendingAmount;
  Map<String, double> byCategory;

  ExpenseStatistics({
    required this.total,
    required this.draft,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.paid,
    required this.totalAmount,
    required this.approvedAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.byCategory,
  });

  factory ExpenseStatistics.fromJson(Map<String, dynamic> json) {
    final rawByCategory = json["byCategory"];
    final Map<String, double> byCategory = {};
    if (rawByCategory is Map) {
      rawByCategory.forEach((k, v) {
        byCategory[k.toString()] = (v ?? 0).toDouble();
      });
    }
    return ExpenseStatistics(
      total: json["total"] ?? 0,
      draft: json["draft"] ?? 0,
      pending: json["pending"] ?? 0,
      approved: json["approved"] ?? 0,
      rejected: json["rejected"] ?? 0,
      paid: json["paid"] ?? 0,
      totalAmount: (json["totalAmount"] ?? 0).toDouble(),
      approvedAmount: (json["approvedAmount"] ?? 0).toDouble(),
      paidAmount: (json["paidAmount"] ?? 0).toDouble(),
      pendingAmount: (json["pendingAmount"] ?? 0).toDouble(),
      byCategory: byCategory,
    );
  }

  Map<String, dynamic> toJson() => {
    "total": total,
    "draft": draft,
    "pending": pending,
    "approved": approved,
    "rejected": rejected,
    "paid": paid,
    "totalAmount": totalAmount,
    "approvedAmount": approvedAmount,
    "paidAmount": paidAmount,
    "pendingAmount": pendingAmount,
    "byCategory": byCategory,
  };
}
