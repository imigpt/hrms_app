import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';

class ExpenseService {
  static const String baseUrl = 'https://hrms-backend-zzzc.onrender.com/api';

  /// Get all expenses for the current user
  /// GET /expenses
  static Future<ExpenseListResponse> getExpenses({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/expenses');

      print('Fetching expenses:');
      print('URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return expenseListResponseFromJson(response.body);
      } else {
        print('Get Expenses Error Response: ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          final message = errorBody['message'] ?? errorBody['error'] ?? 'Failed to fetch expenses';
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Server error: ${response.statusCode}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Get Expenses Exception: $e');
      rethrow;
    }
  }

  /// Submit a new expense
  /// POST /expenses
  /// Supports multipart/form-data for file upload
  static Future<ExpenseSubmitResponse> submitExpense({
    required String token,
    required String category,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    File? receiptFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/expenses');

      print('Submitting expense:');
      print('URL: $uri');
      print('Category: $category');
      print('Amount: $amount $currency');
      print('Date: $date');
      print('Description: $description');
      print('Has receipt: ${receiptFile != null}');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['category'] = category;
      request.fields['amount'] = amount.toString();
      request.fields['currency'] = currency;
      request.fields['date'] = date.toIso8601String();
      request.fields['description'] = description;

      // Add file if provided
      if (receiptFile != null) {
        final fileStream = http.ByteStream(receiptFile.openRead());
        final fileLength = await receiptFile.length();
        final multipartFile = http.MultipartFile(
          'receipt',
          fileStream,
          fileLength,
          filename: receiptFile.path.split('/').last,
        );
        request.files.add(multipartFile);
        print('Receipt file added: ${receiptFile.path}');
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return expenseSubmitResponseFromJson(response.body);
      } else {
        print('Submit Expense Error Response: ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          final message = errorBody['message'] ?? errorBody['error'] ?? 'Failed to submit expense';
          
          // Check for validation errors
          if (errorBody['errors'] != null) {
            final errors = errorBody['errors'];
            if (errors is Map) {
              final errorMessages = errors.values.join(', ');
              throw Exception('$message: $errorMessages');
            } else if (errors is List) {
              final errorMessages = errors.join(', ');
              throw Exception('$message: $errorMessages');
            }
          }
          
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Server error: ${response.statusCode}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Submit Expense Exception: $e');
      rethrow;
    }
  }

  /// Update expense fields (JSON-only, no file — PUT /expenses/:id)
  /// Only works on pending/draft expenses the user owns.
  static Future<ExpenseSubmitResponse> updateExpenseStatus({
    required String token,
    required String expenseId,
    required String status,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/expenses/$expenseId');

      print('Updating expense status:');
      print('URL: $uri');
      print('Status: $status');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return expenseSubmitResponseFromJson(response.body);
      } else {
        print('Update Expense Error Response: ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          final message = errorBody['message'] ?? errorBody['error'] ?? 'Failed to update expense';
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Server error: ${response.statusCode}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Update Expense Exception: $e');
      rethrow;
    }
  }

  /// Get a specific expense by ID
  /// GET /expenses/:id
  static Future<ExpenseSubmitResponse> getExpenseById({
    required String token,
    required String expenseId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/expenses/$expenseId');

      print('Fetching expense by ID:');
      print('URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return expenseSubmitResponseFromJson(response.body);
      } else {
        print('Get Expense Error Response: ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          final message = errorBody['message'] ?? errorBody['error'] ?? 'Failed to fetch expense';
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Server error: ${response.statusCode}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Get Expense Exception: $e');
      rethrow;
    }
  }

  /// Update an expense (full update)
  /// PUT /expenses/:id
  /// Can only update pending expenses
  static Future<ExpenseSubmitResponse> updateExpense({
    required String token,
    required String expenseId,
    required String category,
    required double amount,
    required String currency,
    required DateTime date,
    required String description,
    File? receiptFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/expenses/$expenseId');

      print('Updating expense:');
      print('URL: $uri');
      print('Category: $category');
      print('Amount: $amount $currency');
      print('Date: $date');
      print('Description: $description');
      print('Has receipt: ${receiptFile != null}');

      // Create multipart request
      final request = http.MultipartRequest('PUT', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['category'] = category;
      request.fields['amount'] = amount.toString();
      request.fields['currency'] = currency;
      request.fields['date'] = date.toIso8601String();
      request.fields['description'] = description;

      // Add file if provided
      if (receiptFile != null) {
        final fileStream = http.ByteStream(receiptFile.openRead());
        final fileLength = await receiptFile.length();
        final multipartFile = http.MultipartFile(
          'receipt',
          fileStream,
          fileLength,
          filename: receiptFile.path.split('/').last,
        );
        request.files.add(multipartFile);
        print('Receipt file added: ${receiptFile.path}');
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return expenseSubmitResponseFromJson(response.body);
      } else {
        print('Update Expense Error Response: ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          final message = errorBody['message'] ?? errorBody['error'] ?? 'Failed to update expense';
          
          // Check for validation errors
          if (errorBody['errors'] != null) {
            final errors = errorBody['errors'];
            if (errors is Map) {
              final errorMessages = errors.values.join(', ');
              throw Exception('$message: $errorMessages');
            } else if (errors is List) {
              final errorMessages = errors.join(', ');
              throw Exception('$message: $errorMessages');
            }
          }
          
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Server error: ${response.statusCode}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Update Expense Exception: $e');
      rethrow;
    }
  }

  /// Get expense statistics for the current user
  /// GET /expenses/statistics
  static Future<ExpenseStatisticsResponse> getExpenseStatistics({
    required String token,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/expenses/statistics')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('Fetching expense statistics:');
      print('URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return expenseStatisticsResponseFromJson(response.body);
      } else {
        try {
          final errorBody = json.decode(response.body);
          final message =
              errorBody['message'] ?? errorBody['error'] ?? 'Failed to fetch statistics';
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) throw Exception('Server error: ${response.statusCode}');
          rethrow;
        }
      }
    } catch (e) {
      print('Get Statistics Exception: $e');
      rethrow;
    }
  }

  /// Delete an expense
  /// DELETE /expenses/:id
  static Future<void> deleteExpense({
    required String token,
    required String expenseId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/expenses/$expenseId');

      print('Deleting expense:');
      print('URL: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        print('Delete Expense Error Response: ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          final message = errorBody['message'] ?? errorBody['error'] ?? 'Failed to delete expense';
          throw Exception(message);
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Server error: ${response.statusCode}');
          }
          rethrow;
        }
      }
    } catch (e) {
      print('Delete Expense Exception: $e');
      rethrow;
    }
  }
}
