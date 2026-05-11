import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/userModel.dart';

class SignInException implements Exception {
  final String message;
  SignInException(this.message);

  @override
  String toString() => message;
}

class SignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Realiza o login do usuário.
  ///
  /// 1. Autentica no Firebase Auth (email + senha)
  /// 2. Busca os dados do perfil no Firestore (doc ID = uid)
  ///
  /// Retorna o [UserModel] em caso de sucesso.
  /// Lança [SignInException] com mensagem amigável em caso de erro.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autentica o usuário
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String? uid = credential.user?.uid;

      if (uid != null) {
        // 2. Busca os dados extras no Firestore
        final doc = await _db.collection('users').doc(uid).get();

        if (doc.exists && doc.data() != null) {
          // 3. Retorna o objeto UserModel completo
          return UserModel.fromMap(uid, doc.data()!);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw SignInException(_mapAuthError(e.code));
    } catch (e) {
      throw SignInException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  /// Converte códigos de erro do Firebase Auth em mensagens amigáveis.
  String _mapAuthError(String code) {
    switch (code) {
      // Código moderno — email ou senha incorretos (Firebase não diz qual dos dois)
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos ou usuário não existe.';
      // Códigos legados — mantidos para compatibilidade com versões mais antigas
      case 'wrong-password':
        return 'Senha incorreta. Verifique e tente novamente.';
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'user-disabled':
        return 'Este usuário está desativado. Contate o suporte.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'app-not-authorized':
        return 'App não autorizado.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      case 'internal-error':
        return 'Erro interno. Tente novamente mais tarde.';
      case 'expired-action-code':
        return 'Código de verificação expirado. Solicite um novo.';
      case 'invalid-action-code':
        return 'Código de verificação inválido. Solicite um novo.';
      case 'channel-error':
        return 'Preencha todos os campos antes de continuar.';
      default:
        return 'Erro ao entrar ($code). Tente novamente.';
    }
  }
}
