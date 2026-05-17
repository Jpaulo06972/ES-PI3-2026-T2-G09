import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class TwoFactorException implements Exception {
  final String message;
  const TwoFactorException(this.message);
}

class TwoFactorService {
  static const _baseUrl =
      'https://us-central1-mesclainvest-5ee48.cloudfunctions.net';

  final _db = FirebaseFirestore.instance;

  // Gera um código de 6 dígitos, salva no Firestore com expiração de 10 min
  // e chama a Cloud Function para enviar por e-mail
  Future<void> sendCode(String uid, String email) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('users').doc(uid).update({
      'twoFactorCode': code,
      'twoFactorCodeExpiry': Timestamp.fromDate(expiry),
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/sendTwoFactorCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200) {
      throw const TwoFactorException('Erro ao enviar código de verificação.');
    }
  }

  // Lê o código do Firestore, compara com o informado e verifica a expiração
  // Apaga o código após uso para não reutilizar
  Future<bool> verifyCode(String uid, String code) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;

    final storedCode = data['twoFactorCode'] as String?;
    final expiryTs = data['twoFactorCodeExpiry'] as Timestamp?;

    if (storedCode == null || expiryTs == null) return false;
    if (DateTime.now().isAfter(expiryTs.toDate())) return false;
    if (storedCode != code) return false;

    await _db.collection('users').doc(uid).update({
      'twoFactorCode': FieldValue.delete(),
      'twoFactorCodeExpiry': FieldValue.delete(),
    });
    return true;
  }
}
