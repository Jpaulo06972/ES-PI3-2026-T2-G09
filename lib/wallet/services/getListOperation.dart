// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o Firestore — o banco de dados oficial do Firebase que guarda as coisas como "Documentos" e "Coleções"
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço que funciona como o "leitor" do nosso aplicativo.
/// Ele vai ao Firestore e traz todas as operações financeiras relacionadas ao usuário (extrato).
///
/// Por que não botar essa lógica lá na tela?
/// Imagina se o encanamento estivesse exposto no meio da sala. Separar a regra de leitura
/// da interface (UI) deixa tudo mais limpo. A tela apenas diz: "Traga minhas transações!" e essa classe resolve o como.
class GetListOperation {
  // Uma pontezinha de conexão para a instância raiz do Firebase.
  // Pense nisso como a chave pra acessar as gavetas de arquivo do banco de dados.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Função demorada (async) que busca os "papeizinhos" (Documentos) de transação.
  ///
  /// Se fulano fez um depósito, o "authorUid" (ou "authorID" no sistema antigo) é dele.
  /// Se fulano recebeu um pix, o "targetUserId" é dele.
  /// Logo, temos que varrer as gavetas procurando por todas essas 3 chances.
  Future<List<Map<String, dynamic>>> getOperations({String? userId}) async {
    try {
      // Regra de segurança: se não passarem o ID de ninguém, a gente devolve vazio (nada pra buscar).
      if (userId == null) return [];

      // O Firestore é meio ruim em lidar com "busca isto OU aquilo". Pra contornar,
      // fazemos três buscas separadas mas AO MESMO TEMPO (usando o `Future.wait`).
      // Isso significa que chamamos os 3 arquivos simultaneamente e depois juntamos tudo — é super rápido.
      final results = await Future.wait([
        // Gaveta 1: Onde o usuário é o autor mais recente (usando authorUid)
        _firestore
            .collection('operations')
            .where('authorUid', isEqualTo: userId)
            .get(),
        // Gaveta 2: Onde o usuário é o autor do sistema velho (legado - authorID)
        _firestore
            .collection('operations')
            .where('authorID', isEqualTo: userId)
            .get(),
        // Gaveta 3: Onde o usuário foi quem recebeu a grana (destinatário - targetUserId)
        _firestore
            .collection('operations')
            .where('targetUserId', isEqualTo: userId)
            .get(),
      ]);

      // E se a pessoa "transferiu para ela mesma"? A mesma transação ia voltar na gaveta 1 e na gaveta 3.
      // Pra não mostrar em duplicidade, a gente joga num Map (Dicionário), usando a ID da transação como a Chave.
      // Map sobrescreve coisas iguais, então ele elimina os duplicados! (Deduplicação de dados).
      final Map<String, Map<String, dynamic>> mergedOperations = {};

      // Pra cada pasta de respostas das nossas 3 buscas...
      for (var snapshot in results) {
        // Pra cada papel (Documento) dentro da pasta...
        for (var doc in snapshot.docs) {
          // Se a gente AINDA NÃO tiver guardado esse ID (ou seja, é novidade)
          if (!mergedOperations.containsKey(doc.id)) {
            // A gente tira uma foto dos dados
            final data = doc.data();
            // Injeta o "ID da folha" dentro dos dados (porque ele geralmente vem fora do json)
            data['id'] = doc.id;
            // Guarda bonitinho no nosso dicionário fundido
            mergedOperations[doc.id] = data;
          }
        }
      }

      // No fim, a gente pega os valores (sem as chaves duplicadas) e transforma numa Lista de novo.
      // O app agora tem as transações fresquinhas para pintar na tela!
      return mergedOperations.values.toList();
    } catch (e) {
      // Deu pau? Joga a fofoca adiante num erro pra tela capturar e colocar a culpa na internet.
      throw Exception('Erro ao listar operações: $e');
    }
  }
}
