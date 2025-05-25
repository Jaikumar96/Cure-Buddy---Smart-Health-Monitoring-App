import 'dart:convert';
import 'dart:io'; // Not directly used in the methods shown, but often kept for http overrides etc.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Base URL might be better sourced from dotenv if it changes between dev/prod
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.252.250:8080/api';


class ApiService {
  // static const String baseUrl = 'http://192.168.252.250:8080/api'; // Update if needed
  // Example using dotenv for baseUrl:
  static final String baseUrl = Platform.isAndroid
      ? (const bool.fromEnvironment('IS_EMULATOR') ? 'http://10.0.2.2:8080/api' : 'http://192.168.252.250:8080/api')
      : 'http://192.168.252.250:8080/api'; // For iOS simulator or physical device if backend is on same machine


  // LOGIN API
  static Future<Map<String, dynamic>> login(String email,
      String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "Login failed: Status ${response.statusCode}");
        } catch (_) {
          throw Exception("Login failed: Status ${response.statusCode}");
        }
      }
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  // REGISTER PATIENT
  static Future<String> registerPatient(String name, String email,
      String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": "PATIENT"
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "Patient registration failed: Status ${response.statusCode}");
        } catch (_) {
          throw Exception("Patient registration failed: Status ${response.statusCode}");
        }
      }
    } catch (e) {
      throw Exception("Patient registration failed: ${e.toString()}");
    }
  }

  // REGISTER DOCTOR
  static Future<String> registerDoctor(String name, String email,
      String password, String regNumber) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": "DOCTOR",
          "registrationNumber": regNumber
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "Doctor registration failed: Status ${response.statusCode}");
        } catch (_) {
          throw Exception("Doctor registration failed: Status ${response.statusCode}");
        }
      }
    } catch (e) {
      throw Exception("Doctor registration failed: ${e.toString()}");
    }
  }

// GET USER DETAILS
  static Future<Map<String, dynamic>> getUserDetails(String token) async {
    final url = Uri.parse('$baseUrl/user/me');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception("Failed to get user details: ${response.body}");
    } catch (e) {
      throw Exception("Failed to get user details: ${e.toString()}");
    }
  }

// GET PATIENT SCHEDULES
  static Future<List<dynamic>> getPatientSchedules(String token) async {
    final url = Uri.parse('$baseUrl/patient/my-schedules');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception("Failed to get schedules: ${response.body}");
    } catch (e) {
      throw Exception("Failed to get schedules: ${e.toString()}");
    }
  }

  static Future<void> scheduleCheckup(String token,
      String vitalName,
      DateTime dateTime,
      String frequency,) async {
    final url = Uri.parse('$baseUrl/patient/schedule');
    final body = {
      "vitalName": vitalName,
      "scheduledDateTime": dateTime.toIso8601String(),
      "frequency": frequency
    };
    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('Schedule failed [${res.statusCode}]: ${res.body}');
      }
    } catch (e) {
      throw Exception('Schedule failed: ${e.toString()}');
    }
  }

  static Future<void> deleteSchedule(String token, String id) async {
    final url = Uri.parse('$baseUrl/patient/delete-schedule/$id');
    try {
      final res = await http.delete(url, headers: {
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds:10));
      if (res.statusCode != 200) throw Exception('Delete failed: ${res.body}');
    } catch(e) {
      throw Exception('Delete failed: ${e.toString()}');
    }
  }

  static Future<void> updateSchedule(String token,
      String id,
      String email,
      String vitalName,
      DateTime dateTime,
      String frequency,) async {
    final url = Uri.parse('$baseUrl/patient/update-schedule/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'patientEmail': email,
          'vitalName': vitalName,
          'scheduledDateTime': dateTime.toIso8601String(),
          'frequency': frequency,
        }),
      ).timeout(const Duration(seconds:15));

      if (response.statusCode != 200) {
        throw Exception('Failed to update schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update schedule: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getMyReports(String token) async {
    final url = Uri.parse('$baseUrl/patient/my-reports');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to get reports: ${response.body}');
    } catch (e) {
      throw Exception('Failed to get reports: ${e.toString()}');
    }
  }

  static Future<String> getReportAnalysis(String token, String reportId) async {
    final url = Uri.parse('$baseUrl/patient/report-analysis/$reportId');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to analyze report: ${response.body}');
    } catch (e) {
      throw Exception('Failed to analyze report: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getInsights(String token) async {
    final url = Uri.parse('$baseUrl/patient/insights');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds:10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to get insights: ${response.body}');
    } catch (e) {
      throw Exception('Failed to get insights: ${e.toString()}');
    }
  }

  static Future<List<String>> getHealthTipsForRisk(String token, String risk) async {
    final url = Uri.parse('$baseUrl/patient/health-tips/$risk');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds:10));
      if (response.statusCode == 200) return List<String>.from(jsonDecode(response.body));
      throw Exception('Failed to get health tips: ${response.body}');
    } catch (e) {
      throw Exception('Failed to get health tips: ${e.toString()}');
    }
  }

  static Future<List<Map<String, String>>> getFeaturedHealthTips(String? token) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      {'title': 'Stay Hydrated', 'description': 'Drink at least 8 glasses of water daily.', 'icon': 'water_drop'},
      {'title': 'Move More', 'description': 'Aim for 30 minutes of moderate exercise most days.', 'icon': 'fitness_center'},
      {'title': 'Eat Balanced Meals', 'description': 'Include fruits, vegetables, and lean protein.', 'icon': 'restaurant'},
      {'title': 'Prioritize Sleep', 'description': 'Get 7-9 hours of quality sleep per night.', 'icon': 'bedtime'},
      {'title': 'Manage Stress', 'description': 'Practice mindfulness or deep breathing exercises.', 'icon': 'self_improvement'},
    ];
  }

  static Future<List<dynamic>> getDoctorPatientReports(String token) async {
    final url = Uri.parse('$baseUrl/doctor/patient-reports');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch patient reports: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch patient reports: ${e.toString()}');
    }
  }

  static Future<void> addDoctorResponse(String token,
      String reportId,
      String remarks,
      String advice,) async {
    final url = Uri.parse('$baseUrl/doctor/respond/$reportId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "remarks": remarks,
          "advice": advice,
        }),
      ).timeout(const Duration(seconds:15));
      if (response.statusCode != 200) {
        throw Exception('Failed to add doctor response: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add doctor response: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getPatientHistory(String token,
      String patientEmail) async {
    final url = Uri.parse('$baseUrl/doctor/patient-history/$patientEmail');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch patient history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch patient history: ${e.toString()}');
    }
  }

  static Future<void> updateUserProfile(String token,
      String name,
      String? password,
      ) async {
    final url = Uri.parse('$baseUrl/user/update');
    Map<String, String> body = {
      "name": name,
    };
    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds:15));

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getAdminDashboardStats(
      String token) async {
    final url = Uri.parse('$baseUrl/admin/dashboard');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch admin dashboard stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch admin dashboard stats: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getAdminAllUsers(String token) async {
    final url = Uri.parse('$baseUrl/admin/users');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }

  static Future<void> deleteAdminUser(String token, String userId) async {
    final url = Uri.parse('$baseUrl/admin/delete-user/$userId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:10));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  static Future<void> verifyDoctorLicense(String token,
      String doctorEmail) async {
    final url = Uri.parse('$baseUrl/auth/admin/verify-doctor/$doctorEmail');
    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode != 200) {
        throw Exception('Failed to verify doctor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to verify doctor: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getAdminAllReports(String token) async {
    final url = Uri.parse('$baseUrl/admin/reports');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds:15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch admin reports: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch admin reports: ${e.toString()}');
    }
  }

  // --- LAB SERVICES ---

  static Future<List<dynamic>> getLabProviders(String token, String state, String? district) async {
    Map<String, String> queryParams = {'state': state};
    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }

    final url = Uri.parse('$baseUrl/labs/providers').replace(queryParameters: queryParams);
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "Failed to load lab providers: Status ${response.statusCode}");
        } catch (_) {
          throw Exception("Failed to load lab providers: Status ${response.statusCode}, Body: ${response.body}");
        }
      }
    } catch (e) {
      throw Exception("Failed to load lab providers: ${e.toString()}");
    }
  }

  static Future<String> bookLabTest(String token, String providerName, String testName, double price) async {
    final url = Uri.parse('$baseUrl/labs/book');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "providerName": providerName,
          "selectedTest": testName,
          "price": price,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "Failed to book lab test: Status ${response.statusCode}");
        } catch (_) {
          throw Exception("Failed to book lab test: Status ${response.statusCode}, Body: ${response.body}");
        }
      }
    } catch (e) {
      throw Exception("Failed to book lab test: ${e.toString()}");
    }
  }

  static Future<List<dynamic>> getMyLabBookings(String token) async {
    final url = Uri.parse('$baseUrl/labs/my-bookings');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? "Failed to load lab bookings: Status ${response.statusCode}");
        } catch (_) {
          throw Exception("Failed to load lab bookings: Status ${response.statusCode}, Body: ${response.body}");
        }
      }
    } catch (e) {
      throw Exception("Failed to load lab bookings: ${e.toString()}");
    }
  }
}