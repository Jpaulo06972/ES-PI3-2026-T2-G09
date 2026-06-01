// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesclainvest_f/enum/typeOfOperation.dart';
import 'package:mesclainvest_f/model/operations.dart';

/// Utilitário que converte os dados brutos (JSON/Map) vindos do Firestore
/// em mapas prontos e padronizados para exibição na tela.
///
/// Por que criar uma classe só para isso?
/// Imagina que a tela de "Carteira" e a tela de "Extrato" precisam mostrar
/// as mesmas transações. Antes, a lógica de "se for depósito é verde, se for
/// saque é laranja" estava duplicada nos dois arquivos. Isso é um pesadelo
/// de manutenção! Se criarmos um novo tipo de transação, teríamos que mudar
/// em dois lugares. Centralizando aqui (Princípio DRY - Don't Repeat Yourself),
/// mudamos apenas 1 vez e o app inteiro reflete a mudança.
class OperationMapper {
  /// Ordena a lista bruta por data, da mais recente para a mais antiga (descendente).
  ///
  /// O Firestore, ao ler uma coleção ou cache, nem sempre traz os documentos
  /// na ordem que o humano espera. Aqui garantimos a ordem cronológica correta.
  static void sortByDateDesc(List<Map<String, dynamic>> rawData) {
    // sort() altera a lista "in-place", ou seja, modifica a própria variável original.
    rawData.sort((a, b) {
      final dateA = a['createdAt'];
      final dateB = b['createdAt'];

      // O Firestore guarda datas como Timestamp, mas se a data vier do CACHE offline,
      // ela pode vir serializada como um Map (ex: {'seconds': 162..., 'nanoseconds': ...}).
      // Esse é um bug/pegadinha clássica do Firestore! É preciso checar os dois tipos.
      int secA = 0;
      if (dateA is Timestamp) {
        secA = dateA.seconds;
      } else if (dateA is Map) {
        // Se vier como Map, o nome da chave pode ser '_seconds' ou 'seconds'
        // (depende de como a lib serializou). O ?? 0 garante um fallback seguro.
        secA = (dateA['_seconds'] ?? dateA['seconds'] ?? 0);
      }

      int secB = 0;
      if (dateB is Timestamp) {
        secB = dateB.seconds;
      } else if (dateB is Map) {
        secB = (dateB['_seconds'] ?? dateB['seconds'] ?? 0);
      }

      // Ao inverter (secB comparando com secA), garantimos ordem Decrescente.
      // Se fosse secA.compareTo(secB), a ordem seria Crescente (mais antigos primeiro).
      return secB.compareTo(secA);
    });
  }

  /// Pega a gororoba que vem do banco e transforma em algo bonitinho pra UI.
  ///
  /// [rawData] é a lista que acabou de ser lida do Firestore e ordenada.
  /// [currentUserId] é vital: precisamos saber quem é você para decidir se uma
  /// transferência foi enviada por você (dinheiro saiu) ou recebida por você (entrou).
  /// [useStatementIcons] adapta o visual: a home usa ícones mais preenchidos,
  /// enquanto a tela de extrato usa ícones mais "limpos" (outlines).
  static List<Map<String, dynamic>> mapOperations({
    required List<Map<String, dynamic>> rawData,
    required String currentUserId,
    bool useStatementIcons = false,
  }) {
    // Usamos .map() para iterar e transformar elemento por elemento.
    return rawData.map((data) {
      // O OperationModel faz o parse bruto do Map e valida as tipagens (double, string, etc).
      final op = OperationModel.fromMap(data['id'] ?? '', data);

      // Verificação essencial de paternidade da transação.
      // Se eu sou o 'targetUserId', significa que a transação veio para mim.
      bool souDestinatario = data['targetUserId'] == currentUserId;
      // Se eu sou o 'authorUid', fui eu quem fiz o pix/transferência.
      bool souAutor = (data['authorUid'] ?? data['authorID']) == currentUserId;

      // Valores default antes de aplicar a lógica. Se der algo errado e
      // cairmos aqui, vai aparecer um ícone de interrogação seguro.
      IconData icon = Icons.help_outline;
      String title = op.text ?? 'Operação';
      bool isCredit = false;
      String subtitle = '';

      // === PRIORIDADE 1: FUI EU QUEM RECEBI? ===
      // Em uma transferência P2P (entre usuários), o documento no banco é um só!
      // Se eu sou apenas o destinatário (não o autor), significa que recebi grana.
      // E dinheiro entrando = Crédito = Cor verde na UI.
      if (souDestinatario && !souAutor) {
        isCredit = true;
        icon = Icons
            .move_to_inbox_rounded; // Ícone que lembra uma caixa recebendo algo.
        // Muda o texto se estiver no Extrato (statement) ou na Home.
        title = useStatementIcons
            ? 'Transferência recebida'
            : (op.text ?? 'Transferência Recebida');
        subtitle = useStatementIcons ? (op.text ?? '') : '';
      }
      // === PRIORIDADE 2: FUI EU QUEM FIZ ===
      else {
        // Usa o Enum gravado no banco para determinar qual foi a ação.
        switch (op.operation) {
          case TypeOfOperation.deposito:
            // Depósito: O usuário gerou um boleto ou fez Pix pra conta dele. É crédito!
            icon = useStatementIcons
                ? Icons.add_circle_outline_rounded
                : Icons.add_circle;
            title = useStatementIcons
                ? 'Depósito'
                : (op.text ?? 'Depósito Realizado');
            subtitle = useStatementIcons
                ? (op.text ?? 'Conta MesclaInvest')
                : '';
            isCredit = true;
            break;

          case TypeOfOperation.pagar:
            // Pagar uma conta. Dinheiro saiu = Débito (isCredit = false).
            icon = Icons.payment_rounded;
            title = useStatementIcons
                ? 'Pagamento'
                : (op.text ?? 'Pagamento Realizado');
            subtitle = useStatementIcons ? (op.text ?? '') : '';
            isCredit = false;
            break;

          case TypeOfOperation.transferencia:
            // Eu enviei uma transferência para alguém. Dinheiro saiu = Débito.
            icon = useStatementIcons
                ? Icons
                      .arrow_upward_rounded // Seta pra cima: "foi embora"
                : Icons.swap_horiz_rounded; // Setinhas trocando: "transferindo"
            title = useStatementIcons
                ? 'Transferência enviada'
                : (op.text ?? 'Transferência Enviada');
            subtitle = useStatementIcons ? (op.text ?? '') : '';
            isCredit = false;
            break;

          case TypeOfOperation.saque:
            // Retirou o dinheiro da carteira pro banco pessoal. Saiu = Débito.
            icon = useStatementIcons
                ? Icons.arrow_downward_rounded
                : Icons.account_balance_wallet_rounded;
            title = useStatementIcons
                ? 'Saque'
                : (op.text ?? 'Saque Realizado');
            subtitle = useStatementIcons ? (op.text ?? 'Conta bancária') : '';
            isCredit = false;
            break;

          case TypeOfOperation.investimento:
            // Comprou tokens. O saldo da carteira em Reais reduziu. Saiu = Débito.
            icon = useStatementIcons
                ? Icons.rocket_launch_rounded
                : Icons.rocket_launch; // Foguetinho, porque investimento é lua!
            title = useStatementIcons
                ? 'Investimento'
                : (op.text ?? 'Investimento Efetuado');
            subtitle = useStatementIcons ? (op.text ?? '') : '';
            isCredit = false;
            break;
        }
      }

      // === FILTROS DA TELA ===
      // A UI do extrato tem chips lá no topo: "Todos", "Saques", "Depósitos", etc.
      // Esse 'filterType' é a string secreta que liga a transação ao botão de filtro.
      String filterType;
      // Se recebi transferência, não é um "depósito", é uma "transferência".
      if (souDestinatario && !souAutor) {
        filterType = 'transferencia';
      } else {
        // Para o resto, usamos o nome bonitinho do enum em minúsculas (ex: "saque").
        filterType = op.operation.name;
      }

      // Finalmente, retornamos um Map padronizado.
      // Quem for usar isso (ListTiles) não precisa fazer nenhum if/else,
      // as cores, textos e ícones já estão prontinhos pra renderizar!
      return {
        'icon': icon,
        'title': title,
        'subtitle': subtitle,
        'date':
            op.createdAt ??
            'Data não informada', // Fallback caso não tenha data
        'value': op.amount,
        'isCredit':
            isCredit, // A UI usa isso pra pintar de Verde (true) ou Branco (false)
        'type': filterType,
        'id': op.id,
      };
    }).toList(); // Transforma o Iterable resultante do .map() numa List definitiva.
  }
}
