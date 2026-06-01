// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa os tipos definidos no módulo de tipos do balance para garantir
// que as constantes aqui declaradas são compatíveis com o sistema de tipos.
import {TypeOfOperation, OperationStatus} from "../types";

// Lista dos tipos de operação permitidos no sistema de balcão/carteira.
// Centralizar aqui evita "magic strings" espalhadas pelo código —
// se precisar adicionar um novo tipo, basta incluir aqui e o TypeScript
// acusará qualquer lugar que precise ser atualizado.
export const allowedStages: TypeOfOperation[] = [
    "deposito",
    "pagar",
    "transferencia",
];

// Lista dos status possíveis para uma operação financeira.
// Usado para validar payloads recebidos e filtrar operações por estado.
export const allowedStatuses: OperationStatus[] = [
    "pendente",
    "aprovada",
    "recusada",
];
