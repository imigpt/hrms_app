import 'dart:convert';

DashboardStatsResponse dashboardStatsResponseFromJson(String str) =>
    DashboardStatsResponse.fromJson(json.decode(str));

String dashboardStatsResponseToJson(DashboardStatsResponse data) =>
    json.encode(data.toJson());

class DashboardStatsResponse {
  bool success;
  DashboardData data;

  DashboardStatsResponse({
    required this.success,
    required this.data,
  });

  factory DashboardStatsResponse.fromJson(Map<String, dynamic> json) =>
      DashboardStatsResponse(
        success: json["success"] ?? false,
        data: DashboardData.fromJson(json["data"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data.toJson(),
      };
}

class DashboardData {
  DashboardUser? user;
  DashboardStats stats;
  AttendanceStatus attendance;
  List<DashboardTask> tasks;
  List<DashboardAnnouncement> announcements;

  DashboardData({
    this.user,
    required this.stats,
    required this.attendance,
    required this.tasks,
    required this.announcements,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        user: json["user"] != null
            ? DashboardUser.fromJson(json["user"])
            : null,
        stats: DashboardStats.fromJson(json["stats"] ?? {}),
        attendance: AttendanceStatus.fromJson(json["attendance"] ?? {}),
        tasks: json["tasks"] != null
            ? List<DashboardTask>.from(
                json["tasks"].map((x) => DashboardTask.fromJson(x)))
            : [],
        announcements: json["announcements"] != null
            ? List<DashboardAnnouncement>.from(json["announcements"]
                .map((x) => DashboardAnnouncement.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        "user": user?.toJson(),
        "stats": stats.toJson(),
        "attendance": attendance.toJson(),
        "tasks": List<dynamic>.from(tasks.map((x) => x.toJson())),
        "announcements":
            List<dynamic>.from(announcements.map((x) => x.toJson())),
      };
}

class DashboardUser {
  String name;

  DashboardUser({
    required this.name,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) => DashboardUser(
        name: json["name"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "name": name,
      };
}

class LeaveBalance {
  int annual;
  int sick;
  int casual;
  int maternity;
  int paternity;
  int unpaid;

  LeaveBalance({
    required this.annual,
    required this.sick,
    required this.casual,
    required this.maternity,
    required this.paternity,
    required this.unpaid,
  });

  /// Total usable leave balance (annual + sick + casual)
  int get total => annual + sick + casual;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        annual: json["annual"] ?? 0,
        sick: json["sick"] ?? 0,
        casual: json["casual"] ?? 0,
        maternity: json["maternity"] ?? 0,
        paternity: json["paternity"] ?? 0,
        unpaid: json["unpaid"] ?? 0,
      );

  factory LeaveBalance.zero() => LeaveBalance(
        annual: 0,
        sick: 0,
        casual: 0,
        maternity: 0,
        paternity: 0,
        unpaid: 0,
      );

  Map<String, dynamic> toJson() => {
        "annual": annual,
        "sick": sick,
        "casual": casual,
        "maternity": maternity,
        "paternity": paternity,
        "unpaid": unpaid,
      };
}

class DashboardStats {
  LeaveBalance leaveBalance;
  int activeTasks;
  double pendingExpenses;
  double attendancePercentage;

  DashboardStats({
    required this.leaveBalance,
    required this.activeTasks,
    required this.pendingExpenses,
    required this.attendancePercentage,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        leaveBalance: json["leaveBalance"] is Map
            ? LeaveBalance.fromJson(
                Map<String, dynamic>.from(json["leaveBalance"]))
            : LeaveBalance.zero(),
        activeTasks: json["activeTasks"] ?? 0,
        pendingExpenses: (json["pendingExpenses"] ?? 0).toDouble(),
        attendancePercentage: (json["attendancePercentage"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "leaveBalance": leaveBalance.toJson(),
        "activeTasks": activeTasks,
        "pendingExpenses": pendingExpenses,
        "attendancePercentage": attendancePercentage,
      };
}

class AttendanceStatus {
  bool isPunchedIn;
  String punchTime;
  String workingHours;
  int workProgress;
  int workTarget;

  AttendanceStatus({
    required this.isPunchedIn,
    required this.punchTime,
    required this.workingHours,
    required this.workProgress,
    required this.workTarget,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) =>
      AttendanceStatus(
        isPunchedIn: json["isPunchedIn"] ?? false,
        punchTime: json["punchTime"] ?? "",
        workingHours: json["workingHours"] ?? "0h 0m",
        workProgress: json["workProgress"] ?? 0,
        workTarget: json["workTarget"] ?? 8,
      );

  Map<String, dynamic> toJson() => {
        "isPunchedIn": isPunchedIn,
        "punchTime": punchTime,
        "workingHours": workingHours,
        "workProgress": workProgress,
        "workTarget": workTarget,
      };
}

class DashboardTask {
  String id;
  String title;
  String status;
  String priority;
  DateTime? deadline;

  DashboardTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.deadline,
  });

  factory DashboardTask.fromJson(Map<String, dynamic> json) => DashboardTask(
        id: json["_id"] ?? "",
        title: json["title"] ?? "",
        status: json["status"] ?? "",
        priority: json["priority"] ?? "",
        deadline: json["deadline"] != null
            ? DateTime.parse(json["deadline"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "status": status,
        "priority": priority,
        "deadline": deadline?.toIso8601String(),
      };
}

class DashboardAnnouncement {
  String id;
  String title;
  String message;
  DateTime createdAt;

  DashboardAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory DashboardAnnouncement.fromJson(Map<String, dynamic> json) =>
      DashboardAnnouncement(
        id: json["_id"] ?? "",
        title: json["title"] ?? "",
        message: json["message"] ?? "",
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "title": title,
        "message": message,
        "createdAt": createdAt.toIso8601String(),
      };
}
