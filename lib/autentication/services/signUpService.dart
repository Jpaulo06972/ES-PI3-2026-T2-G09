import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/model/userModel.dart';

/// Exceção customizada para erros de cadastro.
/// Contém uma [message] amigável para exibir ao usuário.
class SignUpException implements Exception {
  final String message;
  SignUpException(this.message);

  @override
  String toString() => message;
}

/// Service responsável pelo cadastro de novos usuários.
/// Cria a conta no Firebase Auth e salva o perfil no Firestore.
class SignUpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cadastra um novo usuário.
  ///
  /// 1. Cria a conta no Firebase Auth (email + senha)
  /// 2. Salva os dados do perfil no Firestore (doc ID = uid)
  ///
  /// Retorna o [UserModel] criado em caso de sucesso.
  /// Lança [SignUpException] com mensagem amigável em caso de erro.
  Future<UserModel?> signUp({
    required String firstName,
    required String lastName,
    required String dataNascimento,
    required String cpf,
    required String email,
    required String password,
    required String telefone,
  }) async {
    try {
      // 1. Criar usuário no Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        // 2. Cria o UserModel
        final userModel = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          dataNascimento: dataNascimento,
          cpf: cpf,
          email: email,
          telefone: telefone,
        );

        final userData = userModel.toMap();
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['updatedAt'] = FieldValue.serverTimestamp();

        // 3. Salvar perfil no Firestore (users/{uid})
        await _firestore.collection('users').doc(user.uid).set(userData);

        return userModel;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw SignUpException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      throw SignUpException(_mapFirestoreError(e.code));
    } catch (e) {
      throw SignUpException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  /// Converte códigos de erro do Firebase Auth em mensagens amigáveis.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail está desativado. Contate o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Erro ao criar conta. Tente novamente.';
    }
  }

  /// Converte códigos de erro do Firestore em mensagens amigáveis.
  String _mapFirestoreError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Sem permissão para salvar os dados. Contate o suporte.';
      case 'unavailable':
        return 'Servidor indisponível. Tente novamente mais tarde.';
      default:
        return 'Erro ao salvar seu perfil. Tente novamente.';
    }
  }
}
