// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o Firebase Auth para lidarmos com a autenticação (login com email/senha).
// É ele quem vai verificar se as credenciais do usuário batem com a base do Firebase.
import 'package:firebase_auth/firebase_auth.dart';

// Importa o Firestore porque precisamos buscar os dados extras do perfil do usuário.
// Lembra: o Auth só guarda email e senha. Dados como nome, CPF e telefone ficam no Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';

// Usamos o foundation para ter acesso ao debugPrint.
// Dica de senior: prefira debugPrint ao invés de print(), pois ele não corta logs muito longos e é otimizado.
import 'package:flutter/foundation.dart';

import 'package:mesclainvest_f/model/userModel.dart';

/// Exceção personalizada que criamos para isolar os erros de login.
/// Ao invés de jogar um erro genérico na cara do usuário, a gente empacota ele aqui
/// com uma mensagem bonitinha em português pra mostrar no SnackBar da tela.
class SignInException implements Exception {
  final String message;

  SignInException(this.message);

  @override
  String toString() => message;
}

/// Esse é o "garçom" do nosso login. Ele pega as informações da tela, leva lá no Firebase Auth,
/// depois passa no Firestore pra pegar os dados completos do usuário, e devolve tudo empacotado.
class SignInService {
  // Instância do Firebase Auth. O singleton (instance) garante que estamos usando sempre a mesma sessão.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instância do Firestore para ler/escrever no nosso banco de dados NoSQL.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Faz o login do usuário em 3 passos simples:
  /// 1. Autentica no Firebase Auth com email e senha.
  /// 2. Pega a "chave" (UID) dele e vai no Firestore buscar o resto dos dados.
  /// 3. Retorna um UserModel completo e pronto pra uso no app.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Passo 1: tenta autenticar. Isso aqui bate na internet, então precisa do "await".
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Pega o UID (identificador único gerado pelo Firebase). Esse cara é a identidade real do usuário.
      final String? uid = credential.user?.uid;

      if (uid != null) {
        // Passo 2: busca o documento do usuário na coleção "users".
        final doc = await _db.collection('users').doc(uid).get();

        if (doc.exists && doc.data() != null) {
          // Passo 3: Transforma aquele bando de dados soltos (Map) em um objeto organizado (UserModel).
          return UserModel.fromMap(doc.data()!, uid);
        }
      }

      // Se logou mas não achou os dados no Firestore (ex: usuário deletado parcialmente), retorna null.
      return null;
    } on FirebaseAuthException catch (e) {
      // Captura só os erros específicos de autenticação do Firebase.
      // Imprime o código no console para a gente poder debugar e traduz pro usuário.
      debugPrint('FirebaseAuthException code: ${e.code}');
      throw SignInException(_mapAuthError(e.code));
    } catch (e) {
      // Caiu aqui? Deu algum erro muito louco que não é do Firebase (ex: falha de hardware, sem internet).
      debugPrint('Erro inesperado no login: $e');
      throw SignInException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  /// Pega aquele código de erro feio do Firebase e transforma numa mensagem humana em PT-BR.
  /// Dica de segurança: O Firebase moderno unificou os erros de "senha incorreta" e "usuário não encontrado"
  /// para 'invalid-credential'. Isso é ótimo porque evita que um hacker fique testando e-mails
  /// só pra ver se eles existem no nosso banco.
  String _mapAuthError(String code) {
    switch (code) {
      // O código moderno. Não dizemos pro usuário qual dos dois ele errou!
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos ou usuário não existe.';

      // Códigos legados, mantidos caso o SDK do Firebase mude ou usemos uma versão antiga.
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

      // Proteção contra brute-force (cara tentando 100 senhas por segundo).
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';

      case 'operation-not-allowed':
        return 'Operação não permitida. O admin não ativou login por email/senha.';

      case 'app-not-authorized':
        return 'App não autorizado.';

      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique seu 4G/Wi-Fi.';

      case 'internal-error':
        return 'Erro interno do Firebase. Tente novamente mais tarde.';

      case 'expired-action-code':
        return 'Código de verificação expirado. Solicite um novo.';

      case 'invalid-action-code':
        return 'Código de verificação inválido. Solicite um novo.';

      // O 'channel-error' rola quando a gente nem consegue mandar o dado pro SDK nativo (tipo iOS/Android),
      // geralmente porque passamos uma String vazia pra senha ou email.
      case 'channel-error':
        return 'Preencha todos os campos antes de continuar.';

      // Fallback: se for um erro novo do Firebase que a gente não mapeou, pelo menos mostramos o código.
      default:
        return 'Erro ao entrar ($code). Tente novamente.';
    }
  }
}
