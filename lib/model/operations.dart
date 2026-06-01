// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote do Firestore. Aqui dentro mora a classe Timestamp que precisamos pras datas.
import 'package:cloud_firestore/cloud_firestore.dart';

// Trazemos nossos enums para garantir a integridade dos dados (Adeus Strings mágicas!)
import 'package:mesclainvest_f/enum/operationStatus.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';

/// Model que gerencia a 'Conta Corrente' do usuário no app.
///
/// Atenção! Não confunda com a classe do balcão. Esse OperationModel aqui 
/// lida com saldo geral (Depósito PIX, Saques, Transferências e o evento do investimento).
/// Cada item dessa classe é uma linha no extrato do usuário.
class OperationModel {
  /// ID da operação. Geralmente o ID aleatório gerado pelo Firestore.
  final String id;

  /// UID (User ID) do cara que disparou a operação. O "dono" da conta.
  final String authorID;

  /// O tamanho da brincadeira. O valor em R$ envolvido.
  final double amount;

  /// O que exatamente foi feito? Depositou? Sacou? Transferiu?
  final TypeOfOperation operation;

  /// Deu certo ou tá pendente?
  final OperationStatus status;

  /// Se foi transferência (ou se envolver terceiros), pra quem foi a grana?
  final String targetUserId;

  /// Aquele recadinho da transação ("Depósito via PIX", "Estorno", etc)
  final String? text;

  /// Quando a operação nasceu. Mantemos String formatada direto aqui
  /// para facilitar a vida do Widget Text() lá no Front.
  final String? createdAt;

  /// Quando a operação foi finalizada. Pode ser nulo se ainda estiver pendente.
  final String? completedAt;

  // Nosso construtor completo. Pede tudo.
  OperationModel({
    required this.id,
    required this.authorID,
    required this.amount,
    required this.operation,
    required this.status,
    required this.targetUserId,
    required this.text,
    required this.createdAt,
    required this.completedAt,
  });

  // --- Getters ---
  // Usar getters é uma prática legal em Dart para proteger os campos de modificações indesejadas
  // e permitir injetar formatações futuras (ex: retornar 'R$ amount' de forma transparente).
  String get getId => id;
  String get getAuthorID => authorID;
  double get getAmount => amount;
  TypeOfOperation get getOperation => operation;
  OperationStatus get getStatus => status;
  String get getTargetUserId => targetUserId;
  String? get getText => text;
  String? get getCreatedAt => createdAt;
  String? get getCompletedAt => completedAt;

  // --- Setters ---
  // Liberamos a alteração só de campos mutáveis no fluxo. Não faz sentido mudar o autor, né?
  // Mas o status e a data de fim mudam quando a transação passa no banco.
  set setStatus(OperationStatus status) => status = status;
  set setCompletedAt(String? completedAt) => completedAt = completedAt;

  /// O coração da nossa resiliência: fromMap. Pega o dado cru do banco e monta o objeto.
  ///
  /// Como o backend mudou bastante ao longo dos sprints, temos vários legados.
  /// O fromMap aqui é um verdadeiro "limpa-trilhos", lidando com vários nomes 
  /// de campos antigos para nada quebrar na tela do usuário final.
  factory OperationModel.fromMap(String id, Map<String, dynamic> map) {
    // Busca o valor. Pode vir como amountCents, amount, valor... a gente tenta de tudo!
    final dynamic rawAmount = map['amountCents'] ?? map['amount'] ?? map['valor'] ?? 0;

    // Busca o tipo de operação, cobrindo o padrão novo e o velho.
    final String typeStr = map['typeOfOperation'] ?? map['operation'] ?? '';

    return OperationModel(
      id: id,
      // Pega o UID com o nome novo ou com o nome antigo
      authorID: map['authorUid']?.toString() ?? map['authorID']?.toString() ?? '',
      
      // Essa é genial: não importa se o banco devolveu int ou double, 
      // toDouble() força a barra e entrega nosso tipo certinho.
      amount: rawAmount.toDouble(),
      
      // firstWhere salva a pátria achando o Enum pelo nome da String.
      operation: TypeOfOperation.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => TypeOfOperation.investimento,
      ),
      
      status: OperationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OperationStatus.pendente,
      ),
      
      targetUserId: map['targetUserId']?.toString() ?? '',
      text: map['text']?.toString(),
      
      // Chamamos nossa função privada para arrumar a bagunça das datas
      createdAt: _parseDate(map['createdAt']),
      completedAt: _parseDate(map['completedAt']),
    );
  }

  /// O triturador de datas. O Firebase às vezes manda Timestamp, 
  /// mas se vier de uma Cloud Function pode virar um JSON com _seconds. 
  /// Essa função normaliza qualquer formato pra uma String no formato dd/MM/yyyy.
  static String? _parseDate(dynamic date) {
    if (date == null) return null;
    // Se o banco já mandou uma string linda e formatada, só repassa.
    if (date is String) return date;

    DateTime? dt;
    if (date is Timestamp) {
      // É o tipo padrão do Firestore, só converter.
      dt = date.toDate();
    } else if (date is Map) {
      // Ops, passou pelo parser do JSON e virou um Map. A gente puxa os segundos.
      final seconds = date['_seconds'] ?? date['seconds'];
      if (seconds != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    if (dt != null) {
      // PadLeft(2, '0') é o truque de sênior para garantir que o "dia 1" vire "01".
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    // Se falhou em tudo, converte pro que for pra não dar crash nulo
    return date.toString();
  }

  /// Função pra salvar ou dar update no banco depois. Só devolver o Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorID': authorID,
      'amount': amount,
      'operation': operation.name, // A gente envia .name pra salvar como String.
      'status': status.name,
      'targetUserId': targetUserId,
      'text': text,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  /// Esse toString é pra nós, Devs! 
  /// Quando damos um print() no console, em vez de ver `Instance of OperationModel`,
  /// vemos todos os dados lindinhos e fáceis de debugar.
  @override
  String toString() {
    return 'OperationModel{id: $id, authorID: $authorID, amount: $amount, operation: $operation, status: $status, targetUserId: $targetUserId, text: $text, createdAt: $createdAt, completedAt: $completedAt}';
  }
}
