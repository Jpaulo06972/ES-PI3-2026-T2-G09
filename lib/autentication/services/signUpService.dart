// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o Firebase Auth para criarmos contas com email e senha.
// Esse é o cara que vai realmente botar o usuário no nosso sistema de autenticação.
import 'package:firebase_auth/firebase_auth.dart';

// Importa o Firestore. Por que? Porque o Firebase Auth só guarda email e senha.
// O resto da vida do cara (nome, CPF, saldo) a gente vai guardar aqui.
import 'package:cloud_firestore/cloud_firestore.dart';

// Usamos o foundation para ter acesso ao debugPrint.
// Lembra: print() em produção pode ser cortado ou gerar gargalo, debugPrint é vida.
import 'package:flutter/foundation.dart';

import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/enum/userRole.dart';

/// Exceção customizada pra gente jogar quando der ruim no cadastro.
/// Assim como no login, isso ajuda a gente a mandar uma mensagem bonitinha pra UI (tela)
/// em vez de explodir um erro vermelho na cara do usuário.
class SignUpException implements Exception {
  final String message;

  SignUpException(this.message);

  @override
  String toString() => message;
}

/// Serviço responsável por receber os dados do formulário e matricular o cara no nosso app.
/// O fluxo aqui é duplo: primeiro Auth, depois Firestore.
class SignUpService {
  // Instância do Firebase Auth. A gente só precisa de uma, então pegamos do singleton.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instância do Firestore para gravar aquele JSON bonitão do perfil do cara.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Método principal de cadastro. Pega todos esses dados e faz a mágica acontecer.
  /// 1. Cria a credencial no Auth.
  /// 2. Monta o UserModel com os dados em memória.
  /// 3. Salva esse UserModel lá no Firestore atrelado ao UID do Auth.
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
      // Passo 1: Vai lá no Firebase criar a conta.
      // Se a senha for "123", ele já vai barrar aqui mesmo e jogar a exceção pro catch.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Pegamos o usuário que acabou de ser criado pra usar o UID dele.
      final user = credential.user;

      if (user != null) {
        // Passo 2: Montamos o nosso UserModel.
        // É melhor usar uma classe tipada do que um Map genérico para não errarmos os nomes dos campos.
        final userModel = UserModel(
          uid: user.uid, // O identificador único que o Firebase gerou.
          firstName: firstName,
          lastName: lastName,
          dataNascimento: dataNascimento,
          cpf: cpf,
          email: email,
          telefone: telefone,
          role: UserRole
              .investidor, // Todo mundo que chega já vira investidor por padrão.
          saldo: 0.00, // Começa pobrinho, depois a gente dá um jeito nisso.
        );

        // Convertendo pro formato que o Firestore entende (um Map chave-valor).
        final userData = userModel.toMap();

        // Adicionando carimbos de tempo (timestamps) de forma segura.
        // Dica de ouro: Use sempre FieldValue.serverTimestamp()!
        // Se você usar DateTime.now(), pega a hora do celular do cara, que pode estar errada e zoar a ordenação.
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['updatedAt'] = FieldValue.serverTimestamp();

        // Passo 3: Salva o documento no Firestore.
        // Note que estamos usando o UID como ID do documento, isso deixa tudo perfeitamente linkado.
        await _firestore.collection('users').doc(user.uid).set(userData);

        // Retorna o boneco montado pra tela poder exibir os dados dele.
        return userModel;
      }

      // Caiu num caso muito bizarro onde a conta criou mas o user veio nulo. Quase impossível.
      return null;
    } on FirebaseAuthException catch (e) {
      // Deu pau no lado do Auth (ex: e-mail já existe, senha fraca).
      debugPrint('FirebaseAuthException no cadastro: ${e.code}');
      throw SignUpException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      // Deu pau no lado do Firestore (ex: regras de segurança bloquearam a escrita).
      // Se caiu aqui, a conta no Auth foi criada, mas o perfil não gravou.
      // Idealmente, a gente deveria apagar o Auth num "rollback", mas para fins didáticos, só avisamos.
      debugPrint('FirebaseException no cadastro: ${e.code}');
      throw SignUpException(_mapFirestoreError(e.code));
    } catch (e) {
      // Algo explodiu no meio do caminho que nem o Firebase sabe o que é.
      debugPrint('Erro inesperado no cadastro: $e');
      throw SignUpException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  /// Pega o código de erro feião do Firebase Auth e traduz pro usuário.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Tente fazer login.';

      // O Firebase exige senhas de pelo menos 6 caracteres.
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';

      case 'invalid-email':
        return 'O e-mail informado é inválido. Verifique e tente novamente.';

      // Caso você vá no console do Firebase e desligue o login por email.
      case 'operation-not-allowed':
        return 'Cadastro por e-mail está desativado. Contate o suporte.';

      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';

      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';

      // Quando passa o campo vazio pro Android/iOS.
      case 'channel-error':
        return 'Preencha todos os campos antes de continuar.';

      case 'invalid-credential':
        return 'Dados inválidos. Verifique as informações e tente novamente.';

      default:
        debugPrint('Código de erro Auth não mapeado no cadastro: $code');
        return 'Erro ao criar conta ($code). Tente novamente.';
    }
  }

  /// Pega os erros que rolam no Firestore (Banco de Dados) e deixa bonito.
  String _mapFirestoreError(String code) {
    switch (code) {
      // Geralmente é problema nas Firestore Rules que você configurou no console.
      case 'permission-denied':
        return 'Sem permissão para salvar os dados. Contate o suporte.';

      case 'unavailable':
        return 'Servidor indisponível. Tente novamente mais tarde.';

      case 'deadline-exceeded':
        return 'A conexão demorou demais. Verifique sua internet e tente novamente.';

      case 'not-found':
        return 'Erro ao acessar os dados. Tente novamente.';

      default:
        debugPrint('Código de erro Firestore não mapeado: $code');
        return 'Erro ao salvar seu perfil ($code). Tente novamente.';
    }
  }
}
