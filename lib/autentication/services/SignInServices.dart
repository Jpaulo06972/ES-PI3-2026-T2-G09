// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o Firebase Auth para autenticação (login com email/senha)
import 'package:firebase_auth/firebase_auth.dart';
// Importa o Firestore para buscar os dados extras do usuário
import 'package:cloud_firestore/cloud_firestore.dart';
// Importa o Flutter foundation para usar debugPrint (logs no console)
import 'package:flutter/foundation.dart';
// Importa o modelo de usuário do projeto
import 'package:mesclainvest_f/model/userModel.dart';

// Exceção personalizada para erros de login
// Contém uma mensagem amigável que será exibida ao usuário no SnackBar
class SignInException implements Exception {
  final String message;
  SignInException(this.message);

  @override
  String toString() => message;
}

// Serviço responsável pelo login do usuário
// Autentica no Firebase Auth e busca os dados completos no Firestore
class SignInService {
  // Instância do Firebase Auth — usada para autenticar email/senha
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Instância do Firestore — usada para buscar o perfil do usuário
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Realiza o login do usuário em 3 passos:
  // 1. Autentica no Firebase Auth com email e senha
  // 2. Busca os dados extras do perfil no Firestore (nome, CPF, telefone, etc.)
  // 3. Retorna um UserModel completo com tudo junto
  // Se der erro, lança SignInException com mensagem amigável
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Passo 1: tenta autenticar o usuário no Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Pega o UID (identificador único) do usuário autenticado
      final String? uid = credential.user?.uid;

      if (uid != null) {
        // Passo 2: busca os dados do perfil no Firestore (coleção "users", documento = uid)
        final doc = await _db.collection('users').doc(uid).get();

        if (doc.exists && doc.data() != null) {
          // Passo 3: converte o documento do Firestore para UserModel e retorna
          return UserModel.fromMap(doc.data()!, uid);
        }
      }
      // Se não encontrou o perfil, retorna null
      return null;
    } on FirebaseAuthException catch (e) {
      // Erro do Firebase Auth — imprime o código real para debug e converte em mensagem amigável
      debugPrint('FirebaseAuthException code: ${e.code}');
      throw SignInException(_mapAuthError(e.code));
    } catch (e) {
      // Imprime o erro real no console para facilitar o debug
      debugPrint('Erro inesperado no login: $e');
      throw SignInException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  // Traduz os códigos de erro técnicos do Firebase Auth para mensagens
  // que o usuário consiga entender (em português)
  // NOTA: O Firebase Auth moderno unificou 'wrong-password' e 'user-not-found'
  // no código 'invalid-credential' por motivos de segurança
  String _mapAuthError(String code) {
    switch (code) {
      // Código moderno — email ou senha incorretos (Firebase não diz qual dos dois)
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos. Verifique e tente novamente.';
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
        // Imprime o código desconhecido para podermos adicionar no futuro
        debugPrint('Código de erro Auth não mapeado: $code');
        return 'Erro ao entrar ($code). Tente novamente.';
    }
  }
}
