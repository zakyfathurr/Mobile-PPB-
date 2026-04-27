// lib/services/api_service.dart
// Communicates with the Node.js/Express REST API backend.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import 'auth_service.dart';

class ApiService {
  // 10.0.2.2 = khusus emulator bawaan Android Studio (akses ke localhost laptop)
  // 192.168.8.102 = IP Wi-Fi laptop, wajib dipakai jika run di HP fisik lewat Wi-Fi
  static const String _baseUrl = 'http://192.168.8.102:3000';

  /// Timeout untuk semua HTTP request — gagal cepat, bukan hang lama.
  static const Duration _timeout = Duration(seconds: 10);

  final AuthService _authService = AuthService();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _checkStatus(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw Exception('[$context] ${response.statusCode}: ${body['error']}');
    }
  }

  /// Membungkus HTTP call dengan timeout + pesan error yang jelas.
  Future<http.Response> _withTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'Server tidak merespons (timeout 10 detik).\n'
        'Pastikan:\n'
        '• Backend sudah dijalankan: node src/index.js\n'
        '• Windows Firewall tidak memblokir port 3000\n'
        '• HP dan laptop terhubung ke Wi-Fi yang sama',
      );
    } on SocketException catch (e) {
      throw Exception(
        'Tidak dapat terhubung ke server: ${e.message}.\n'
        'Pastikan backend sudah berjalan di port 3000.',
      );
    }
  }

  // ─── POST /trash ──────────────────────────────────────────────────────────

  /// Save a scan result to the backend.
  Future<ScanResult> saveScan({
    required String imageUrl,
    required String detectedLabel,
    required String category,
  }) async {
    final headers = await _authHeaders();
    final response = await _withTimeout(
      http.post(
        Uri.parse('$_baseUrl/trash'),
        headers: headers,
        body: jsonEncode({
          'image_url': imageUrl,
          'detected_label': detectedLabel,
          'category': category,
        }),
      ),
    );
    _checkStatus(response, 'saveScan');
    final data = jsonDecode(response.body)['data'];
    return ScanResult.fromJson(data);
  }

  // ─── GET /trash ───────────────────────────────────────────────────────────

  /// Get all scan results for the current user.
  Future<List<ScanResult>> getScans() async {
    final headers = await _authHeaders();
    final response = await _withTimeout(
      http.get(
        Uri.parse('$_baseUrl/trash'),
        headers: headers,
      ),
    );
    _checkStatus(response, 'getScans');
    final List<dynamic> data = jsonDecode(response.body)['data'];
    return data.map((item) => ScanResult.fromJson(item)).toList();
  }

  // ─── PUT /trash/:id ───────────────────────────────────────────────────────

  /// Update a scan result by [id].
  Future<ScanResult> updateScan({
    required int id,
    String? imageUrl,
    String? detectedLabel,
    String? category,
  }) async {
    final headers = await _authHeaders();
    final body = <String, String>{};
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (detectedLabel != null) body['detected_label'] = detectedLabel;
    if (category != null) body['category'] = category;

    final response = await _withTimeout(
      http.put(
        Uri.parse('$_baseUrl/trash/$id'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    _checkStatus(response, 'updateScan');
    final data = jsonDecode(response.body)['data'];
    return ScanResult.fromJson(data);
  }

  // ─── DELETE /trash/:id ────────────────────────────────────────────────────

  /// Delete a scan result by [id].
  Future<void> deleteScan(int id) async {
    final headers = await _authHeaders();
    final response = await _withTimeout(
      http.delete(
        Uri.parse('$_baseUrl/trash/$id'),
        headers: headers,
      ),
    );
    _checkStatus(response, 'deleteScan');
  }
}
