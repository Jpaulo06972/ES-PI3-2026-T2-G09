class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String cpf;
  final String telefone;
  final String dataNascimento;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.cpf = '',
    this.telefone = '',
    this.dataNascimento = '',
  });

  /// Nome completo do usuário (ex: "João Paulo")
  String get fullName => '$firstName $lastName'.trim();

  /// Fábrica para converter o documento do Firestore para UserModel
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      cpf: map['cpf'] ?? '',
      telefone: map['telefone'] ?? '',
      dataNascimento: map['dataNascimento'] ?? '',
    );
  }

  /// Converte o UserModel para Map (útil para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'cpf': cpf,
      'telefone': telefone,
      'dataNascimento': dataNascimento,
    };
  }
}
