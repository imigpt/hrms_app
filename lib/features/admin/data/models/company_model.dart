class Company {
  final String? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? industry;
  final String? size;
  final int? companySize;
  final String? status; // pending, active, inactive, suspended, rejected
  final int? employeeCount;
  final int? hrCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;

  Company({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.industry,
    this.size,
    this.companySize,
    this.status,
    this.employeeCount,
    this.hrCount,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      website: json['website'] as String?,
      industry: json['industry'] as String?,
      size: json['size'] as String?,
      companySize: json['companySize'] as int?,
      status: json['status'] as String?,
      employeeCount: json['employeeCount'] as int?,
      hrCount: json['hrCount'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'industry': industry,
      'size': size,
      'companySize': companySize,
      'status': status,
      'employeeCount': employeeCount,
      'hrCount': hrCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? industry,
    String? size,
    int? companySize,
    String? status,
    int? employeeCount,
    int? hrCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rejectionReason,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      companySize: companySize ?? this.companySize,
      status: status ?? this.status,
      employeeCount: employeeCount ?? this.employeeCount,
      hrCount: hrCount ?? this.hrCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
