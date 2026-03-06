import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payroll_model.dart';

/// Service for all payroll-related API calls (employee read-only).
class PayrollService {
  static const String _baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── My Salary ─────────────────────────────────────────────────────────────

  /// GET /api/payroll/salaries/me
  static Future<SalaryResponse> getMySalary({required String token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/salaries/me');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return salaryResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch salary'));
    } catch (e) {
      print('PayrollService.getMySalary error: $e');
      rethrow;
    }
  }

  // ── Salaries list ─────────────────────────────────────────────────────────

  /// GET /api/payroll/salaries
  static Future<SalaryListResponse> getSalaries({required String token}) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/salaries');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return salaryListResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch salaries'));
    } catch (e) {
      print('PayrollService.getSalaries error: $e');
      rethrow;
    }
  }

  // ── Pre-Payments ──────────────────────────────────────────────────────────

  /// GET /api/payroll/pre-payments
  static Future<PrePaymentListResponse> getPrePayments({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/pre-payments');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return prePaymentListResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch pre-payments'));
    } catch (e) {
      print('PayrollService.getPrePayments error: $e');
      rethrow;
    }
  }

  /// POST /api/payroll/pre-payments
  static Future<PrePayment> createPrePayment({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/pre-payments');
      final response = await http
          .post(uri, headers: _headers(token), body: json.encode(data))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return PrePayment.fromJson(decoded['data']);
      }
      throw Exception(_extractError(response, 'Failed to create pre-payment'));
    } catch (e) {
      print('PayrollService.createPrePayment error: $e');
      rethrow;
    }
  }

  /// PUT /api/payroll/pre-payments/:id
  static Future<PrePayment> updatePrePayment({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/pre-payments/$id');
      final response = await http
          .put(uri, headers: _headers(token), body: json.encode(data))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return PrePayment.fromJson(decoded['data']);
      }
      throw Exception(_extractError(response, 'Failed to update pre-payment'));
    } catch (e) {
      print('PayrollService.updatePrePayment error: $e');
      rethrow;
    }
  }

  /// DELETE /api/payroll/pre-payments/:id
  static Future<bool> deletePrePayment({
    required String token,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/pre-payments/$id');
      final response = await http
          .delete(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(_extractError(response, 'Failed to delete pre-payment'));
    } catch (e) {
      print('PayrollService.deletePrePayment error: $e');
      rethrow;
    }
  }

  // ── Increments / Promotions ───────────────────────────────────────────────

  /// GET /api/payroll/increments
  static Future<IncrementListResponse> getIncrements({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/increments');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return incrementListResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch increments'));
    } catch (e) {
      print('PayrollService.getIncrements error: $e');
      rethrow;
    }
  }

  /// GET /api/payroll/increments/:id
  static Future<IncrementPromotion> getIncrementById({
    required String token,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/increments/$id');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return IncrementPromotion.fromJson(decoded['data']);
      }
      throw Exception(_extractError(response, 'Failed to fetch increment'));
    } catch (e) {
      print('PayrollService.getIncrementById error: $e');
      rethrow;
    }
  }

  /// POST /api/payroll/increments
  static Future<IncrementPromotion> createIncrement({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/increments');
      final response = await http
          .post(uri, headers: _headers(token), body: json.encode(data))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return IncrementPromotion.fromJson(decoded['data']);
      }
      throw Exception(_extractError(response, 'Failed to create increment'));
    } catch (e) {
      print('PayrollService.createIncrement error: $e');
      rethrow;
    }
  }

  /// PUT /api/payroll/increments/:id
  static Future<IncrementPromotion> updateIncrement({
    required String token,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/increments/$id');
      final response = await http
          .put(uri, headers: _headers(token), body: json.encode(data))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return IncrementPromotion.fromJson(decoded['data']);
      }
      throw Exception(_extractError(response, 'Failed to update increment'));
    } catch (e) {
      print('PayrollService.updateIncrement error: $e');
      rethrow;
    }
  }

  /// DELETE /api/payroll/increments/:id
  static Future<bool> deleteIncrement({
    required String token,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/increments/$id');
      final response = await http
          .delete(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(_extractError(response, 'Failed to delete increment'));
    } catch (e) {
      print('PayrollService.deleteIncrement error: $e');
      rethrow;
    }
  }

  // ── My Payrolls ───────────────────────────────────────────────────────────

  /// GET /api/payroll/my-payrolls
  static Future<PayrollListResponse> getMyPayrolls({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/my-payrolls');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return payrollListResponseFromJson(response.body);
      }
      throw Exception(_extractError(response, 'Failed to fetch payrolls'));
    } catch (e) {
      print('PayrollService.getMyPayrolls error: $e');
      rethrow;
    }
  }

  /// GET /api/payroll/:id
  static Future<Payroll> getPayrollById({
    required String token,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payroll/$id');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return Payroll.fromJson(decoded['data']);
      }
      throw Exception(_extractError(response, 'Failed to fetch payroll'));
    } catch (e) {
      print('PayrollService.getPayrollById error: $e');
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _extractError(http.Response response, String fallback) {
    try {
      final body = json.decode(response.body);
      return body['message'] ?? fallback;
    } catch (_) {
      return '$fallback (${response.statusCode})';
    }
  }
}
