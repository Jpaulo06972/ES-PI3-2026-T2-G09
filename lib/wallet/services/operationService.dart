// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Cloud Functions — o "pedreiro" do Firebase que roda códigos escondido no lado do servidor.
import 'package:cloud_functions/cloud_functions.dart';

// Foundation — pacote que contém coisas básicas, como o "debugPrint" pra gente jogar mensagens de terminal sem travar.
import 'package:flutter/foundation.dart';

// Enum com os tipos de operação financeira (aquela lista fechada que diz que pode ter "deposito", "saque", etc)
import 'package:mesclainvest_f/enum/typeOfOperation.dart';

/// Serviço responsável por dizer "Haja dinheiro!" ou "Voe dinheiro!".
/// A ideia aqui não é "salvar no banco de dados direto". É CHamar uma função (Cloud Function)
/// num servidor fechado para que ela crie a operação.
///
/// Qual a vantagem?
/// 1. Se um hacker tentar "criar um depósito de 1 bilhão", o celular não deixa ele escrever direto no banco,
///    pois a nossa Cloud Function faz um monte de cálculos no lado oculto pra ver se ele tá de caô.
/// 2. Alterar o dinheiro envolve tirar daqui e pôr ali. A cloud function garante que as duas etapas não quebrem no meio do caminho.
class OperationService {
  // A nossa "linha de telefone" oficial pro servidor da Google Cloud Functions
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Telefona pro servidor pedindo que rodem a função chamada "createOperation".
  /// E passa todas as fofocas como dinheiro e tipo, no formato que o servidor entende.
  ///
  /// Ele devolve "true" ou "false". Basicamente um joinha ou dedão pra baixo.
  Future<bool> createOperation({
    required double amount, // Quantidade da bufunfa
    required TypeOfOperation type, // O verbo (sacar, enviar...)
    String? text, // "Faltou os 10 centavos daquela balada", etc
    String?
    targetIdentifier, // Só obrigatório se eu tô enviando pro amigo (email dele)
  }) async {
    try {
      // "Pega o ramal do atendente chamado 'createOperation'"
      final callable = _functions.httpsCallable("createOperation");

      // Pede pra chamar o servidor passando essa listinha de dados
      final response = await callable.call(<String, dynamic>{
        'amount': amount,
        'type': type
            .name, // Extrai a palavra ("deposito") em vez de passar o enum "TypeOfOperation.deposito"
        'text': text,
        'targetIdentifier':
            targetIdentifier, // Como pode ser vazio, lá no json vai 'null' se n preencher.
      });

      // O servidor retorna. A gente pega o miolo dessa resposta e lê o campo "success" pra ver a resposta
      final result = response.data as Map<String, dynamic>;

      // Retornou algo bizarro? O '?? false' garante que na dúvida é "não!".
      return result['success'] ?? false;
    } catch (e) {
      // Caiu a net? Servidor fora do ar? A gente loga o erro invisível pros programadores
      debugPrint('Erro ao criar operação via Functions: $e');
      // E responde "false" pro app saber que deu bosta e mostrar um aviso bonito.
      return false;
    }
  }
}
