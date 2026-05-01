// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:mesclainvest_f/enum/userRole.dart';

// Modelo de dados do usuário — representa as informações de quem está logado
// É usado em todo o app para passar os dados do usuário entre telas e componentes
class UserModel {
  // ID único do usuário no Firebase (gerado automaticamente ao criar a conta)
  final String uid;

  // E-mail usado para login
  final String email;

  // Primeiro nome do usuário (ex: "João")
  final String firstName;

  // Sobrenome do usuário (ex: "Paulo")
  final String lastName;

  // CPF do usuário (opcional, pode ficar vazio)
  final String cpf;

  // Telefone do usuário (opcional, pode ficar vazio)
  final String telefone;

  // Data de nascimento do usuário (opcional, pode ficar vazio)
  final String dataNascimento;

  final UserRole role;

  final double saldo;

  // Construtor — uid e email são obrigatórios, o resto tem valor padrão vazio
  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.cpf = '',
    this.telefone = '',
    this.dataNascimento = '',
    required this.role,
    this.saldo = 0,
  });

  // Junta o primeiro nome e sobrenome para ter o nome completo
  // O trim() remove espaços extras se algum dos nomes estiver vazio
  String get fullName => '$firstName $lastName'.trim();

  // Cria um UserModel a partir de um documento do Firestore
  // O Firestore retorna os dados como Map<String, dynamic>, então precisamos
  // "traduzir" isso para o nosso modelo. O '?? ""' garante que se o campo
  // não existir no banco, ele não vai quebrar o app (fica como string vazia)
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      dataNascimento: map['dataNascimento'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? ''),
        orElse: () => UserRole.investidor,
      ),
      saldo: (map['saldo'] as num?)?.toDouble() ?? 0,
    );
  }

  // Converte o UserModel de volta para Map — usado quando queremos salvar
  // os dados do usuário no Firestore (o Firestore só aceita Map)
  // Obs: o uid não é incluído porque ele já é o ID do documento
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'cpf': cpf,
      'telefone': telefone,
      'dataNascimento': dataNascimento,
      'saldo': saldo,
    };
  }
}
