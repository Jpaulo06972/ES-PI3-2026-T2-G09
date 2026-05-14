import 'dart:convert';
import 'package:http/http.dart' as http;

class TwoFactorException implements Exception {
  final String message;
  const TwoFactorException(this.message);
}

class TwoFactorService {
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net';

  Future<void> sendCode(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/send2FACode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw TwoFactorException(
        (body['error'] as String?) ?? 'Erro ao enviar o código.',
      );
    }
  }

  Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verify2FACode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw TwoFactorException(
        (body['error'] as String?) ?? 'Código inválido.',
      );
    }
  }
}
