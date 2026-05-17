// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

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
 */
export const seedStartupCatalog = onCall({invoker: "public"}, async (request) => {
  /*
  const startupIds = await seedDemoStartups();
  
  return {
    data: {
      count: startupIds.length,
      ids: startupIds,
    },
  };
  */
  return { data: { message: "Seed desativado no momento." } };
});