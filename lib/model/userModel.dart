// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import 'package:mesclainvest_f/enum/userRole.dart';

/// A classe que é o "RG" do usuário dentro do nosso app.
///
/// Tudo que diz respeito à pessoa (ou empresa) que está usando o aplicativo fica aqui.
/// Ela é a ponte entre as telas do app e o nosso banco de dados (Firestore).
class UserModel {
  // O CPF digital do usuário no Firebase Authentication. Não se muda nunca!
  String uid;

  // E-mail de cadastro, onde mandamos os comprovantes.
  String email;

  // Primeiro nome para a gente chamar o cara pelo nome nas telas.
  String firstName;

  // O resto do nome. Separar isso ajuda se a gente quiser fazer um "Olá, João!".
  String lastName;

  // Quando o usuário nasceu. Serve pra validar maioridade (investimento é papo sério).
  String dataNascimento;

  // CPF validado do investidor.
  String cpf;

  // Telefone para contato e alertas de segurança.
  String telefone;

  // A grana livre que o cara tem na conta virtual para poder brincar no balcão.
  double saldo;

  // Qual a "carteirada" desse usuário? Ele é investidor? Empreendedor? Admin?
  UserRole role;

  // A URL da fotinha dele hospedada lá no Firebase Storage. Pode ser nulo (null) se ele não upou.
  String? profilePicUrl;

  // Trava de segurança: ele ativou o 2FA (Verificação em duas etapas)?
  bool twoFactorEnabled;

  // Um atalho genial: ao invés da UI ter que ficar somando firstName + " " + lastName,
  // a gente já entrega o nome completo limpinho aqui. O .trim() tira os espaços sobrando.
  String get nome => "$firstName $lastName".trim();

  // Alias em inglês caso o time prefira chamar 'fullName' nas views.
  String get fullName => nome;

  // O construtor completo. Exigimos o básico e damos um valor padrão pros opcionais.
  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.dataNascimento = '',
    this.cpf = '',
    this.telefone = '',
    this.saldo = 0.0,
    this.role = UserRole.investidor,
    this.profilePicUrl,
    this.twoFactorEnabled = false,
  });

  /// A nossa fábrica mágica: Pega o JSON do Firebase e monta o nosso objeto Flutter.
  ///
  /// Dica de Sênior: O banco muda, os campos mudam o nome. Perceba como a gente 
  /// usa o operador `??` (fallback). Se o banco mandar 'firstName', legal. 
  /// Se mandar 'nome', beleza também. Isso garante que versões antigas do app não quebrem.
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      // Retrocompatibilidade é vida!
      firstName: data['firstName'] ?? data['nome'] ?? 'Usuário',
      lastName: data['lastName'] ?? '',
      dataNascimento: data['dataNascimento'] ?? '',
      cpf: data['cpf'] ?? '',
      telefone: data['telefone'] ?? '',
      
      // Saldo é dinheiro. Se o Firebase devolver int (ex: 50), o Dart vai chiar querendo double (50.0).
      // .toDouble() resolve essa briga na hora.
      saldo: (data['saldo'] ?? data['balance'] ?? 0.0).toDouble(),
      
      // O banco guarda String, a gente converte pro nosso Enum seguro.
      role: _parseRole(data['role']),
      profilePicUrl: data['profilePicUrl'],
      
      // Booleano também pode vir nulo no banco. O as bool? avisa o Dart dessa possibilidade.
      twoFactorEnabled: data['twoFactorEnabled'] as bool? ?? false,
    );
  }

  /// Alias histórico: Alguns devs antigos do time usavam fromFirestore, então mantivemos isso
  /// só pra repassar pro fromMap e não quebrar o código do coleguinha.
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) =>
      UserModel.fromMap(data, uid);

  /// Como empacotar nossos dados para mandar pro banco de volta.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dataNascimento': dataNascimento,
      'cpf': cpf,
      'telefone': telefone,
      'saldo': saldo,
      // .name pega "investidor" e não "UserRole.investidor", que é o que o banco quer ler.
      'role': role.name,
      'profilePicUrl': profilePicUrl,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }

  /// A função secreta que transforma a String caótica do banco no nosso pacato Enum.
  static UserRole _parseRole(dynamic roleData) {
    // Se não tiver nada, é um investidor padrão.
    if (roleData == null) return UserRole.investidor;
    final roleStr = roleData.toString().toLowerCase();
    
    // Procura na lista de roles quem tem o mesmo nome.
    // O orElse é o nosso cinto de segurança se vier um cargo maluco.
    return UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.investidor,
    );
  }
}
