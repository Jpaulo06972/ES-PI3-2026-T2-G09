// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// `onCall` registra uma Cloud Function callable — o app Flutter ou o emulador
// pode invocá-la diretamente pelo SDK do Firebase sem precisar de uma URL HTTP.
import {onCall} from "firebase-functions/https";

/**
 * Popula o catálogo com startups demonstrativas.
 *
 * Esta Function é callable para facilitar a execução pelo app ou pelo
 * emulador durante desenvolvimento. Em ambiente de emulator ela roda sem chave.
 * Fora do emulator, exige `seedKey` em `request.data.seedKey`, comparando com a
 * variável de ambiente `SEED_STARTUP_CATALOG_KEY`.
 *
 * A função retorna a quantidade de startups gravadas e os ids dos documentos.
 *
 * Nota: em produção, esta função deveria ser protegida por autenticação
 * administrativa para evitar que qualquer pessoa popule o banco com dados demo.
 * A implementação atual prioriza simplicidade para o MVP educacional.
 */
// Importa a função do repositório que grava as startups de demonstração
// em um batch atômico no Firestore
import {seedDemoStartups} from "../repositories/startupRepository";

// `invoker: "public"` permite que qualquer cliente chame esta função.
// A proteção aqui é mínima por ser uma função de desenvolvimento/seed.
export const seedStartupCatalog = onCall({invoker: "public"}, async (request) => {
  // Delega toda a lógica de gravação ao repositório.
  // `seedDemoStartups` usa batch.commit() para gravar todas as startups
  // atomicamente — se uma falhar, nenhuma é salva.
  const startupIds = await seedDemoStartups();
  
  // Retorna a contagem e os IDs gerados para que o cliente confirme a operação
  return {
    data: {
      count: startupIds.length,  // Quantidade de startups inseridas/atualizadas
      ids: startupIds,           // Array com os IDs dos documentos gravados
    },
  };
});