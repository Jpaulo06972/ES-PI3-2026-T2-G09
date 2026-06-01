// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Exceção customizada para isolar falhas na verificação em duas etapas (2FA).
/// Quando a gente joga essa exceção, a tela sabe que o erro foi no 2FA e
/// pode mostrar a mensagem amigável no SnackBar.
class TwoFactorException implements Exception {
  final String message;
  const TwoFactorException(this.message);
}

/// Serviço encarregado de cuidar do código 2FA.
/// Ele é tipo um porteiro: gera a senha temporária, anota na prancheta (Firestore),
/// manda o e-mail, e depois checa se a senha que o cara devolveu tá certa e não venceu.
class TwoFactorService {
  // Endereço base (URL) das nossas Cloud Functions lá no Google Cloud.
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net';

  // Instância do Firestore para ler e atualizar dados do usuário direto no banco de dados.
  final _db = FirebaseFirestore.instance;

  /// Gera um código de 6 dígitos, salva no Firestore com validade de 10 min,
  /// e chama a Cloud Function pra disparar o e-mail pro usuário.
  Future<void> sendCode(String uid, String email) async {
    // Gera um código matemático aleatório entre 100.000 e 999.999.
    // É o famoso "código que chegou no seu e-mail".
    final code = (100000 + Random().nextInt(900000)).toString();

    // Define que esse código só vale por 10 minutinhos.
    // Passou disso, vira abóbora.
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    // Salva o código e a data de validade no documento desse usuário lá no Firestore.
    // Isso é super seguro, porque mesmo se o app for fechado, o código tá salvo no banco.
    await _db.collection('users').doc(uid).update({
      'twoFactorCode': code,
      'twoFactorCodeExpiry': Timestamp.fromDate(expiry),
    });

    // Pede pra Cloud Function disparar o e-mail pra pessoa.
    // Lembra de mandar o Content-Type como json!
    final response = await http.post(
      Uri.parse('$_baseUrl/sendTwoFactorCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    // Se o envio do e-mail deu ruim lá no servidor, a gente precisa avisar o app.
    if (response.statusCode != 200) {
      String errorMessage = 'Erro ao enviar código de verificação.';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>;
        errorMessage = (body['error'] as String?) ?? errorMessage;
      } catch (_) {
        // Se a resposta nem JSON for, usamos a mensagem padrão mesmo.
      }
      throw TwoFactorException(errorMessage);
    }
  }

  /// Compara o código que o cara digitou na tela com o que a gente anotou na prancheta (Firestore).
  Future<bool> verifyCode(String uid, String code) async {
    // Busca o cadastro do usuário.
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();

    // Se o usuário sumiu (alguém apagou?), já era, retorna falso.
    if (data == null) return false;

    // Recupera o que tava salvo no banco.
    final storedCode = data['twoFactorCode'] as String?;
    final expiryTs = data['twoFactorCodeExpiry'] as Timestamp?;

    // Se não tem código salvo, o cara não deveria nem estar tentando validar. Bloqueia!
    if (storedCode == null || expiryTs == null) return false;

    // Checa se o relógio de agora já passou da data de expiração.
    // Se passou, o código expirou.
    if (DateTime.now().isAfter(expiryTs.toDate())) return false;

    // Checa se o cara digitou certinho.
    if (storedCode != code) return false;

    // REGRA DE OURO DA SEGURANÇA:
    // Se o código tá certo e a pessoa passou, você TEM QUE apagar ele do banco.
    // Se não, o cara pode usar esse mesmo código de novo daqui a 2 minutos pra invadir a conta.
    await _db.collection('users').doc(uid).update({
      'twoFactorCode': FieldValue.delete(),
      'twoFactorCodeExpiry': FieldValue.delete(),
    });

    // Tudo certinho, pode deixar o cara entrar!
    return true;
  }
}
