// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Classe de exceção customizada para isolarmos os problemas de reset de senha.
/// É muito melhor lançar essa exceção do que uma Exception genérica, porque assim
/// a UI (tela) sabe exatamente que o erro foi no processo de redefinição e pode
/// mostrar uma mensagem amigável pro usuário, em vez de um erro maluco de sistema.
class PasswordResetException implements Exception {
  final String message;
  const PasswordResetException(this.message);
}

/// Serviço que faz a ponte entre o nosso app e o backend (Cloud Functions do Firebase).
/// Ele concentra toda a lógica de recuperar senha em 3 passos: pedir código, validar código e mudar senha.
class PasswordResetService {
  // Esse é o endereço das nossas Cloud Functions lá no Google Cloud.
  // Toda chamada vai bater nessa URL base.
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net';

  /// Passo 1: O usuário não lembra a senha e digita o e-mail.
  /// A gente chama essa função, que pede pro backend mandar um código pro e-mail dele.
  Future<void> sendResetCode(String email) async {
    // Mandamos um POST pra função 'sendPasswordResetCode'.
    // Importante enviar como JSON e colocar o header 'application/json'
    // senão o backend não consegue ler o corpo da requisição.
    final response = await http.post(
      Uri.parse('$_baseUrl/sendPasswordResetCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    // Se o status não for 200 (OK), deu ruim. Pode ser e-mail não encontrado, limite excedido, etc.
    if (response.statusCode != 200) {
      String errorMessage = 'Erro ao enviar o código.';
      try {
        // A gente tenta ler a resposta de erro que o backend mandou.
        // O jsonDecode transforma a String da resposta num Map que a gente pode ler.
        final body = json.decode(response.body) as Map<String, dynamic>;
        errorMessage = (body['error'] as String?) ?? errorMessage;
      } catch (_) {
        // Se a resposta nem for um JSON (ex: erro de servidor 500 do Firebase),
        // engolimos a exceção do decode e usamos o 'Erro ao enviar o código.' padrão.
      }
      // Lança a nossa exceção customizada para quem chamou o serviço lidar.
      throw PasswordResetException(errorMessage);
    }
  }

  /// Passo 2: O usuário recebeu o código no e-mail e digitou na tela.
  /// Agora vamos perguntar pro backend se esse código bate com o que ele guardou.
  Future<void> verifyCode({required String email, required String code}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verifyCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    // Se o código for errado, expirou, ou for de outro e-mail, vai cair aqui.
    if (response.statusCode != 200) {
      String errorMessage = 'Código inválido ou expirado.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        errorMessage = (body['error'] as String?) ?? errorMessage;
      } catch (_) {}
      throw PasswordResetException(errorMessage);
    }
  }

  /// Passo 3: O código era válido e o usuário digitou a senha nova.
  /// Mandamos o e-mail, o código e a nova senha para o backend aplicar no Firebase Auth.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // Mandamos o código de novo como uma camada extra de segurança.
    // Assim, alguém não consegue chamar essa rota direto só sabendo o e-mail.
    final response = await http.post(
      Uri.parse('$_baseUrl/resetPassword'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    // Se a senha for muito fraca ou o código já tiver sido usado nesse meio tempo, dá erro.
    if (response.statusCode != 200) {
      String errorMessage = 'Erro ao redefinir a senha.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        errorMessage = (body['error'] as String?) ?? errorMessage;
      } catch (_) {}
      throw PasswordResetException(errorMessage);
    }
  }
}
