// Importa a biblioteca para fazer requisições HTTP (chamadas ao backend)
import 'dart:convert';
import 'package:http/http.dart' as http;

// Exceção personalizada para erros no fluxo de reset de senha
// Contém uma mensagem amigável para exibir ao usuário
class PasswordResetException implements Exception {
  // Mensagem de erro que será exibida no SnackBar
  final String message;
  const PasswordResetException(this.message);
}

// Serviço que comunica com o backend (Cloud Functions) para recuperação de senha
// Tem dois métodos: enviar código e redefinir a senha
class PasswordResetService {
  // URL base das Cloud Functions do Firebase do projeto MesclaInvest
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net';

  // Envia um código de 6 dígitos para o e-mail do usuário
  // Chama a Cloud Function "sendPasswordResetCode"
  Future<void> sendResetCode(String email) async {
    // Faz uma requisição POST enviando o e-mail no corpo da requisição
    final response = await http.post(
      Uri.parse('$_baseUrl/sendPasswordResetCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    // Se o status não for 200 (sucesso), lança uma exceção com a mensagem do backend
    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw PasswordResetException(
        (body['error'] as String?) ?? 'Erro ao enviar o código.',
      );
    }
  }

  // Redefine a senha do usuário usando o código de verificação
  // Chama a Cloud Function "resetPassword" com e-mail, código e nova senha
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // Faz uma requisição POST com todos os dados necessários
    final response = await http.post(
      Uri.parse('$_baseUrl/resetPassword'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    // Se o status não for 200, lança exceção com a mensagem do backend
    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw PasswordResetException(
        (body['error'] as String?) ?? 'Erro ao redefinir a senha.',
      );
    }
  }
}
