// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {TypeOfOperation, OperationStatus} from "../types";

export const allowedStages: TypeOfOperation[] = [
    "deposito",
    "pagar",
    "transferencia",
];

export const allowedStatuses: OperationStatus[] = [
    "pendente",
    "aprovada",
    "recusada",
];
