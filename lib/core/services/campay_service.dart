import 'dart:convert';
import 'package:http/http.dart' as http;

class CamPayService {
  // Remplacer par les vraies clés depuis https://campay.net
  static const _username = '0goIFcXOTBTPxnrEDInzjIX8fM5xV7PmtwQTKLAIrqT4hIbzkz7r0-pcq4Rmor3tevHBAyGET8COaQ3TFeM8hw';
  static const _password = 'WYwHmmgExmZGPEYTLfcJIH4h51Ajnzjf0r1oyWYsO2rQouW9IGQ8J3fejZO0k0jqzK_vhxNTGGh5I6r_6s5P9Q';

  // Sandbox: https://demo.campay.net/api
  // Production: https://campay.net/api
  static const _baseUrl = 'https://demo.campay.net/api';

  static String? _token;
  static DateTime? _tokenExpiry;

  // ── Auth ─────────────────────────────────────────────────────
  static Future<void> _authenticate() async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _username,
        'password': _password,
      }),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      _token = data['token'] as String;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    } else {
      throw Exception('CamPay auth failed: ${resp.body}');
    }
  }

  static Future<String> _getToken() async {
    if (_token == null ||
        _tokenExpiry == null ||
        DateTime.now().isAfter(_tokenExpiry!)) {
      await _authenticate();
    }
    return _token!;
  }

  // ── Collect (MTN ou Orange Money) ────────────────────────────
  /// [phone] format: 6XXXXXXXX (sans indicatif pays)
  /// [amount] en XAF (FCFA)
  /// [externalRef] référence unique de la commande
  static Future<CamPayResult> collect({
    required int amount,
    required String phone,
    required String externalRef,
    required String description,
  }) async {
    final token = await _getToken();
    final resp = await http.post(
      Uri.parse('$_baseUrl/collect/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'amount': '$amount',
        'currency': 'XAF',
        'from': phone,
        'description': description,
        'external_reference': externalRef,
      }),
    );
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 200) {
      return CamPayResult(
        reference: data['reference'] as String,
        status: data['status'] as String? ?? 'PENDING',
        ussdCode: data['ussd_code'] as String?,
        operator: data['operator'] as String?,
      );
    }
    throw Exception('CamPay collect error: ${resp.body}');
  }

  // ── Vérifier le statut d'une transaction ─────────────────────
  static Future<String> checkStatus(String reference) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('$_baseUrl/transaction/$reference/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['status'] as String? ?? 'PENDING';
    }
    throw Exception('CamPay status error: ${resp.body}');
  }

  // ── Polling jusqu'au résultat (max 2 min) ────────────────────
  static Future<bool> waitForPayment(String reference,
      {Duration timeout = const Duration(minutes: 2)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await Future.delayed(const Duration(seconds: 5));
      final status = await checkStatus(reference);
      if (status == 'SUCCESSFUL') return true;
      if (status == 'FAILED') return false;
    }
    return false;
  }
}

class CamPayResult {
  final String reference;
  final String status;
  final String? ussdCode;
  final String? operator;

  const CamPayResult({
    required this.reference,
    required this.status,
    this.ussdCode,
    this.operator,
  });
}
