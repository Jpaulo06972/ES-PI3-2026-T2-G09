// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {QuestionVisibility, StartupStage} from "../types";

export const allowedStages: StartupStage[] = [
  "nova",
  "em_operacao",
  "em_expansao",
];

export const allowedVisibilities: QuestionVisibility[] = [
  "publica",
  "privada",
];
