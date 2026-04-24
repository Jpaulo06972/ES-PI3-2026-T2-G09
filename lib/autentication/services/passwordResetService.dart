import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordResetException implements Exception {
  final String message;
  const PasswordResetException(this.message);
}

class PasswordResetService {
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net';

  Future<void> sendResetCode(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sendPasswordResetCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw PasswordResetException(
        (body['error'] as String?) ?? 'Erro ao enviar o código.',
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/resetPassword'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw PasswordResetException(
        (body['error'] as String?) ?? 'Erro ao redefinir a senha.',
      );
    }
  }
}
