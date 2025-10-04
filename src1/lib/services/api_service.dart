import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3001';

  Future<AlertsResponse> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/alerts'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AlertsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  Future<AlertsResponse> fetchAlertsByDate(String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/alerts/$date'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AlertsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load alerts for date: $date');
      }
    } catch (e) {
      throw Exception('Failed to fetch alerts by date: $e');
    }
  }
}
