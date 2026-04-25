// Importa o Firebase Auth para criar conta com email/senha
import 'package:firebase_auth/firebase_auth.dart';
// Importa o Firestore para salvar os dados do perfil do usuário
import 'package:cloud_firestore/cloud_firestore.dart';
// Importa o modelo de dados do usuário
import 'package:mesclainvest_f/model/userModel.dart';

// Exceção personalizada para erros de cadastro
// Contém uma mensagem amigável para exibir no SnackBar ao usuário
class SignUpException implements Exception {
  final String message;
  SignUpException(this.message);

  @override
  String toString() => message;
}

// Serviço responsável pelo cadastro de novos usuários
// Cria a conta no Firebase Auth e salva o perfil completo no Firestore
class SignUpService {
  // Instância do Firebase Auth — usada para criar a conta
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Instância do Firestore — usada para salvar o perfil
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cadastra um novo usuário em 3 passos:
  // 1. Cria a conta no Firebase Auth (email + senha)
  // 2. Monta o UserModel com todos os dados pessoais
  // 3. Salva o perfil no Firestore (coleção "users", documento = uid)
  // Retorna o UserModel criado, ou lança SignUpException se der erro
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
      // Passo 1: cria a conta no Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Pega o usuário criado
      final user = credential.user;

      if (user != null) {
        // Passo 2: monta o modelo com todos os dados
        final userModel = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          dataNascimento: dataNascimento,
          cpf: cpf,
          email: email,
          telefone: telefone,
        );

        // Converte para Map e adiciona timestamps de criação/atualização
        final userData = userModel.toMap();
        // serverTimestamp() pega a hora do servidor Firebase (mais confiável que o celular)
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['updatedAt'] = FieldValue.serverTimestamp();

        // Passo 3: salva no Firestore (users/{uid})
        await _firestore.collection('users').doc(user.uid).set(userData);

        return userModel;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      // Erro do Firebase Auth — converte para mensagem amigável
      throw SignUpException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      // Erro do Firestore — converte para mensagem amigável
      throw SignUpException(_mapFirestoreError(e.code));
    } catch (e) {
      // Erro genérico não esperado
      throw SignUpException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  // Traduz códigos de erro do Firebase Auth para mensagens em português
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

  // Traduz códigos de erro do Firestore para mensagens em português
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
