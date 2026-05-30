import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:mesclainvest_f/model/operationModel.dart';

class TradeService {
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net/api';

  Future<Map<String, String>> _getHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Compra direta da startup ───────────────────────────────────────────────

  Future<Map<String, dynamic>> buyFromStartup({
    required String startupId,
    required int quantity,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/operations/buy-from-startup'),
      headers: headers,
      body: json.encode({'startupId': startupId, 'quantity': quantity}),
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) return body;
    throw Exception(body['error'] ?? 'Erro ao comprar tokens da startup.');
  }

  // ── Oferta de compra a outro investidor ───────────────────────────────────

  Future<Map<String, dynamic>> buyFromUser({
    required String startupId,
    required int quantity,
    required int pricePerTokenCents,
    required int validityDays,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/operations/buy-from-user'),
      headers: headers,
      body: json.encode({
        'startupId': startupId,
        'quantity': quantity,
        'pricePerTokenCents': pricePerTokenCents,
        'validityDays': validityDays,
      }),
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) return body;
    throw Exception(body['error'] ?? 'Erro ao criar oferta de compra.');
  }

  // ── Criar oferta de venda ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> sell({
    required String startupId,
    required int quantity,
    required int askedPricePerTokenCents,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/operations/sell'),
      headers: headers,
      body: json.encode({
        'startupId': startupId,
        'quantity': quantity,
        'askedPricePerTokenCents': askedPricePerTokenCents,
      }),
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) return body;
    throw Exception(body['error'] ?? 'Erro ao criar oferta de venda.');
  }

  // ── Aceitar oferta de compra (vendedor) ───────────────────────────────────

  Future<void> acceptOperation(String operationId) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/operations/$operationId/accept'),
      headers: headers,
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['error'] ?? 'Erro ao aceitar oferta.');
    }
  }

  // ── Cancelar oferta pendente (comprador) ──────────────────────────────────

  Future<void> rejectOperation(String operationId) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/operations/$operationId/reject'),
      headers: headers,
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['error'] ?? 'Erro ao cancelar oferta.');
    }
  }

  // ── Histórico de operações do usuário ─────────────────────────────────────

  Future<List<OperationModel>> getOperationsByUser(String userId) async {
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/operations/user/$userId'),
        headers: headers,
      );
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final list = body['operations'] as List<dynamic>? ?? [];
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return OperationModel.fromMap(m['id'] as String? ?? '', m);
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Ofertas de compra pendentes para uma startup (para vendedores) ─────────

  Future<List<OperationModel>> getPendingBuyOperations(String startupId) async {
    final headers = await _getHeaders();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/operations/pending/$startupId'),
        headers: headers,
      );
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final list = body['operations'] as List<dynamic>? ?? [];
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return OperationModel.fromMap(m['id'] as String? ?? '', m);
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
