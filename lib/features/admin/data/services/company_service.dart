import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hrms_app/core/config/api_config.dart';
import 'package:hrms_app/features/admin/data/models/company_model.dart';

class CompanyService {
  final String? token;

  CompanyService({this.token});

  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// GET /api/admin/company - Get all companies
  Future<List<Company>> getCompanies() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/company'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final companies = body['data'] ?? body['companies'] ?? [];
        if (companies is List) {
          return companies
              .map((json) => Company.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching companies: $e');
    }
  }

  /// GET /api/admin/company/:id - Get company details
  Future<Company> getCompanyDetail(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/company/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final company = body['data'] ?? body;
        return Company.fromJson(company);
      }
      throw Exception('Failed to fetch company details');
    } catch (e) {
      throw Exception('Error fetching company details: $e');
    }
  }

  /// POST /api/admin/company - Create company
  Future<Company> createCompany({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? industry,
    String? size,
    int? companySize,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (website != null && website.isNotEmpty) 'website': website,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
        if (size != null && size.isNotEmpty) 'size': size,
        if (companySize != null) 'companySize': companySize,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/company'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to create company');
    } catch (e) {
      throw Exception('Error creating company: $e');
    }
  }

  /// PATCH /api/admin/company/:id - Update company
  Future<Company> updateCompany({
    required String id,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? industry,
    String? size,
    int? companySize,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (website != null && website.isNotEmpty) 'website': website,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
        if (size != null && size.isNotEmpty) 'size': size,
        if (companySize != null) 'companySize': companySize,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await http
          .patch(
            Uri.parse('$_baseUrl/admin/company/$id'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to update company');
    } catch (e) {
      throw Exception('Error updating company: $e');
    }
  }

  /// DELETE /api/admin/company/:id - Delete company
  Future<void> deleteCompany(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/admin/company/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to delete company');
      }
    } catch (e) {
      throw Exception('Error deleting company: $e');
    }
  }

  /// POST /api/admin/company/:id/approve - Approve company
  Future<Company> approveCompany(String id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/company/$id/approve'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to approve company');
    } catch (e) {
      throw Exception('Error approving company: $e');
    }
  }

  /// POST /api/admin/company/:id/reject - Reject company
  Future<Company> rejectCompany(String id, String reason) async {
    try {
      final body = {'reason': reason};

      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/company/$id/reject'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respBody = jsonDecode(response.body) as Map<String, dynamic>;
        final company = respBody['data'] ?? respBody;
        return Company.fromJson(company);
      }
      throw Exception('Failed to reject company');
    } catch (e) {
      throw Exception('Error rejecting company: $e');
    }
  }

  /// GET /api/admin/company/:id/overview - Get company overview
  Future<Map<String, dynamic>> getCompanyOverview(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/company/$id/overview'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['data'] ?? body;
      }
      throw Exception('Failed to fetch company overview');
    } catch (e) {
      throw Exception('Error fetching company overview: $e');
    }
  }
}
