// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o Firebase Auth para criar conta com email/senha
import 'package:firebase_auth/firebase_auth.dart';
// Importa o Firestore para salvar os dados do perfil do usuário
import 'package:cloud_firestore/cloud_firestore.dart';
// Importa o Flutter foundation para usar debugPrint (logs no console)
import 'package:flutter/foundation.dart';
// Importa o modelo de dados do usuário
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/enum/userRole.dart';

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
          role: UserRole.investidor,
          saldo: 0.00,
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
      // Imprime o código real do erro para facilitar o debug
      debugPrint('FirebaseAuthException no cadastro: ${e.code}');
      throw SignUpException(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      // Imprime o código real do erro do Firestore
      debugPrint('FirebaseException no cadastro: ${e.code}');
      throw SignUpException(_mapFirestoreError(e.code));
    } catch (e) {
      // Imprime o erro genérico no console
      debugPrint('Erro inesperado no cadastro: $e');
      throw SignUpException(
        'Ocorreu um erro inesperado. Tente novamente mais tarde.',
      );
    }
  }

  // Traduz códigos de erro do Firebase Auth para mensagens em português
  // NOTA: O Firebase Auth moderno pode usar códigos diferentes das versões antigas
  String _mapAuthError(String code) {
    switch (code) {
      // E-mail já cadastrado
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Tente fazer login.';
      // Senha muito fraca (menos de 6 caracteres)
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      // E-mail com formato inválido
      case 'invalid-email':
        return 'O e-mail informado é inválido. Verifique e tente novamente.';
      // Cadastro por e-mail desativado no console do Firebase
      case 'operation-not-allowed':
        return 'Cadastro por e-mail está desativado. Contate o suporte.';
      // Muitas tentativas seguidas
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';
      // Sem internet
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      // Campos vazios (quando o Flutter não consegue enviar os dados)
      case 'channel-error':
        return 'Preencha todos os campos antes de continuar.';
      // Credencial inválida (código moderno do Firebase)
      case 'invalid-credential':
        return 'Dados inválidos. Verifique as informações e tente novamente.';
      default:
        // Mostra o código do erro na mensagem para facilitar o debug
        debugPrint('Código de erro Auth não mapeado no cadastro: $code');
        return 'Erro ao criar conta ($code). Tente novamente.';
    }
  }

  // Traduz códigos de erro do Firestore para mensagens em português
  String _mapFirestoreError(String code) {
    switch (code) {
      // Sem permissão para escrever no Firestore (regras de segurança)
      case 'permission-denied':
        return 'Sem permissão para salvar os dados. Contate o suporte.';
      // Servidor indisponível
      case 'unavailable':
        return 'Servidor indisponível. Tente novamente mais tarde.';
      // Tempo de conexão esgotado
      case 'deadline-exceeded':
        return 'A conexão demorou demais. Verifique sua internet e tente novamente.';
      // Documento não encontrado
      case 'not-found':
        return 'Erro ao acessar os dados. Tente novamente.';
      default:
        debugPrint('Código de erro Firestore não mapeado: $code');
        return 'Erro ao salvar seu perfil ($code). Tente novamente.';
    }
  }
}
