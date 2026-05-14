// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:mesclainvest_f/enum/userRole.dart';

/// Classe que representa o modelo de dados completo de um usuário no sistema.
class UserModel {
  String uid;
  String email;
  String firstName;
  String lastName;
  String dataNascimento;
  String cpf;
  String telefone;
  double saldo;
  UserRole role;
  String? profilePicUrl;

  // Nome completo derivado (útil para exibição)
  String get nome => "$firstName $lastName".trim();

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dataNascimento,
    required this.cpf,
    required this.telefone,
    this.saldo = 0.0,
    this.role = UserRole.investidor,
    this.profilePicUrl,
  });

  /// Construtor de fábrica para criar o modelo a partir de um mapa (Firestore/Auth)
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? data['nome'] ?? 'Usuário',
      lastName: data['lastName'] ?? '',
      dataNascimento: data['dataNascimento'] ?? '',
      cpf: data['cpf'] ?? '',
      telefone: data['telefone'] ?? '',
      saldo: (data['saldo'] ?? data['balance'] ?? 0.0).toDouble(),
      role: _parseRole(data['role']),
      profilePicUrl: data['profilePicUrl'],
    );
  }

  /// Alias para manter compatibilidade com chamadas antigas que usavam fromFirestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) => 
      UserModel.fromMap(data, uid);

  /// Transforma o objeto em um mapa para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dataNascimento': dataNascimento,
      'cpf': cpf,
      'telefone': telefone,
      'saldo': saldo,
      'role': role.name, // Salva o nome do enum como String
      'profilePicUrl': profilePicUrl,
    };
  }

  /// Auxiliar para converter a String do banco de volta para o Enum UserRole
  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.investidor;
    final roleStr = roleData.toString().toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.investidor,
    );
  }
}
