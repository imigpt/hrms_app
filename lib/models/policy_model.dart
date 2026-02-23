import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Response wrappers
// ─────────────────────────────────────────────────────────────────────────────

PolicyListResponse policyListResponseFromJson(String str) =>
    PolicyListResponse.fromJson(json.decode(str));

PolicyDetailResponse policyDetailResponseFromJson(String str) =>
    PolicyDetailResponse.fromJson(json.decode(str));

// ─────────────────────────────────────────────────────────────────────────────
// Policy List — GET /api/policies
// ─────────────────────────────────────────────────────────────────────────────

class PolicyListResponse {
  final bool success;
  final int count;
  final List<CompanyPolicy> data;

  PolicyListResponse({required this.success, required this.count, required this.data});

  factory PolicyListResponse.fromJson(Map<String, dynamic> json) => PolicyListResponse(
        success: json['success'] ?? false,
        count: json['count'] ?? 0,
        data: json['data'] != null
            ? List<CompanyPolicy>.from(json['data'].map((x) => CompanyPolicy.fromJson(x)))
            : [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Policy Detail — GET /api/policies/:id
// ─────────────────────────────────────────────────────────────────────────────

class PolicyDetailResponse {
  final bool success;
  final CompanyPolicy? data;

  PolicyDetailResponse({required this.success, this.data});

  factory PolicyDetailResponse.fromJson(Map<String, dynamic> json) => PolicyDetailResponse(
        success: json['success'] ?? false,
        data: json['data'] != null ? CompanyPolicy.fromJson(json['data']) : null,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CompanyPolicy
// ─────────────────────────────────────────────────────────────────────────────

class CompanyPolicy {
  final String id;
  final String title;
  final String description;
  final String location;
  final PolicyFile? file;
  final PolicyCreator? createdBy;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyPolicy({
    required this.id,
    required this.title,
    this.description = '',
    this.location = 'Head Office',
    this.file,
    this.createdBy,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyPolicy.fromJson(Map<String, dynamic> json) => CompanyPolicy(
        id: json['_id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        location: json['location'] ?? 'Head Office',
        file: json['file'] != null ? PolicyFile.fromJson(json['file']) : null,
        createdBy: json['createdBy'] != null
            ? (json['createdBy'] is Map
                ? PolicyCreator.fromJson(json['createdBy'])
                : PolicyCreator(id: json['createdBy'], name: null))
            : null,
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      );

  bool get hasFile => file != null && file!.url != null && file!.url!.isNotEmpty;
}

class PolicyFile {
  final String? url;
  final String? publicId;
  final String? originalName;
  final String? mimeType;

  PolicyFile({this.url, this.publicId, this.originalName, this.mimeType});

  factory PolicyFile.fromJson(Map<String, dynamic> json) => PolicyFile(
        url: json['url'],
        publicId: json['publicId'],
        originalName: json['originalName'],
        mimeType: json['mimeType'],
      );

  String get displayName => originalName ?? 'Document';

  String get fileExtension {
    if (originalName != null && originalName!.contains('.')) {
      return originalName!.split('.').last.toUpperCase();
    }
    if (mimeType != null) {
      if (mimeType!.contains('pdf')) return 'PDF';
      if (mimeType!.contains('word') || mimeType!.contains('docx')) return 'DOCX';
      if (mimeType!.contains('excel') || mimeType!.contains('xlsx')) return 'XLSX';
    }
    return 'FILE';
  }
}

class PolicyCreator {
  final String? id;
  final String? name;
  final String? email;

  PolicyCreator({this.id, this.name, this.email});

  factory PolicyCreator.fromJson(Map<String, dynamic> json) => PolicyCreator(
        id: json['_id'],
        name: json['name'],
        email: json['email'],
      );
}
