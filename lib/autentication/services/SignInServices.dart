// Importa o Firebase Auth para autenticação (login com email/senha)
import 'package:firebase_auth/firebase_auth.dart';
// Importa o Firestore para buscar os dados extras do usuário
import 'package:cloud_firestore/cloud_firestore.dart';
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
          return UserModel.fromMap(uid, doc.data()!);
        }
      }
      // Se não encontrou o perfil, retorna null
      return null;
    } on FirebaseAuthException catch (e) {
      // Erro do Firebase Auth — converte o código técnico em mensagem amigável
      throw SignInException(_mapAuthError(e.code));
    } catch (e) {
      // Erro genérico não esperado
      throw SignInException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  // Traduz os códigos de erro técnicos do Firebase Auth para mensagens
  // que o usuário consiga entender (em português)
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'user-disabled':
        return 'Este usuário está desativado.';
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
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
      default:
        return 'Erro ao entrar. Tente novamente.';
    }
  }
}
