// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// HttpsError lança erros padronizados com código HTTP + mensagem amigável para o app Flutter.
// onCall registra a função como callable — o SDK do Firebase no app chama diretamente.
import {HttpsError, onCall} from "firebase-functions/https";

// Lista centralizada dos estágios válidos — evita "magic strings" espalhadas pelo código
import {allowedStages} from "../shared/constants";

// Utilitário que valida autenticação e lança erro se o token for ausente/inválido
import {requireAuthenticatedUser} from "../../shared/auth";

// normalizeString remove espaços extras e trata null/undefined uniformemente
import {normalizeString} from "../../shared/validation";

// Função do repositório que busca até 100 startups do Firestore
import {listStartupItems} from "../repositories/startupRepository";

// Tipo TypeScript que define os valores aceitos para o campo "stage"
import {StartupStage} from "../types";

/**
  * Lista as startups cadastradas no catálogo do MesclaInvest.
  *
  * Esta Function é callable porque será consumida diretamente pelo app mobile.
  * O app pode enviar, em `data`, os campos:
  *
  * - `stage`: filtro opcional por estágio (nova, em_operacao, em_expansao).
  * - `search`: texto opcional para buscar no catálogo (nome, descrição, tags).
  *
  * A função exige usuário autenticado e retorna um objeto com:
  *
  * - `count`: quantidade de startups retornadas.
  * - `filters`: filtros aplicados e estágios disponíveis.
  * - `data`: lista resumida de startups para uso em telas de catálogo.
  *
  * Decisão de design: a filtragem por stage e search é feita em memória
  * (client-side filtering) porque o volume de startups é pequeno (< 100).
  * Para catálogos maiores, seria necessário usar queries compostas no Firestore.
  */
export const listStartups = onCall({invoker: "public"}, async (request) => {
  // Log de diagnóstico — mostra qual UID chamou a função no Firebase Console
  console.log("listStartups called by:", request.auth?.uid);

  // Verifica que o usuário está autenticado — lança HttpsError se não estiver
  requireAuthenticatedUser(request);
  
  // Normaliza o filtro de estágio recebido do app (remove espaços, trata undefined)
  const stage = normalizeString(request.data?.stage);
  
  // Normaliza o texto de busca e converte para minúsculas usando locale pt-BR.
  // Isso garante que a busca seja case-insensitive e respeite regras de localização
  // brasileira (ex: acentos tratados de forma consistente).
  const search = normalizeString(request.data?.search)
    ?.toLocaleLowerCase("pt-BR");
    
  // Se o stage foi informado mas não está na lista branca, rejeita com erro claro.
  // Isso evita que o app envie valores arbitrários que não fazem sentido para o sistema.
  if (stage && !allowedStages.includes(stage as StartupStage)) {
    throw new HttpsError(
      "invalid-argument",
      "Filtro stage invalido. Use nova, em_operacao ou em_expansao."
    );
  }
  
  // Pipeline de filtragem:
  // 1. Busca todas as startups do repositório (até 100)
  // 2. Filtra por stage (se informado)
  // 3. Filtra por texto de busca (se informado)
  // 4. Ordena alfabeticamente por nome usando locale pt-BR
  const startups = (await listStartupItems())
    // Filtro 1: mantém apenas startups do estágio selecionado (ou todas, se stage for null)
    .filter((startup) => !stage || startup.stage === stage)
    // Filtro 2: busca textual — concatena nome, descrição, estágio e tags em uma string
    // e verifica se o termo de busca está contido nessa string.
    // Essa abordagem é simples mas eficaz para catálogos pequenos.
    .filter((startup) => {
      if (!search) {
        return true; // Sem filtro de busca → mantém todas
      }
      
      // Cria uma string "pesquisável" juntando todos os campos relevantes
      const searchable = [
        startup.name,
        startup.shortDescription,
        startup.stage,
        ...startup.tags, // Spread das tags para que cada uma vire parte do texto
      ].join(" ").toLocaleLowerCase("pt-BR");
      
      // Verifica se o texto de busca aparece em qualquer parte da string concatenada
      return searchable.includes(search);
    })
    // Ordenação alfabética usando localeCompare com locale pt-BR para tratar
    // caracteres especiais e acentos corretamente (ex: "É" antes de "F")
    .sort((left, right) => (left.name ?? "").localeCompare(right.name ?? "", "pt-BR"));
    
  // Retorna o resultado com metadados úteis para o app:
  // - count: para exibir "X startups encontradas"
  // - filters: para o app saber quais filtros estão ativos e disponíveis
  // - data: a lista filtrada e ordenada de startups
  return {
    count: startups.length,
    filters: {
      availableStages: allowedStages, // Permite que o app construa dropdowns dinamicamente
      stage: stage ?? null,           // Filtro de estágio aplicado (null se nenhum)
      search: search ?? null,         // Texto de busca aplicado (null se nenhum)
    },
    data: startups,
  };
});
