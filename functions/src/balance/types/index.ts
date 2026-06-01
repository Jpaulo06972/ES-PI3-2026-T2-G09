// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Tipos do módulo de balance — MesclaInvest
// Grupo: G09 | Trabalho: PI3-2026-T2-G09

// Importa os tipos de data do Firestore para tipar corretamente os campos de timestamp.
import {FieldValue, Timestamp} from "firebase-admin/firestore";


// Define os tipos válidos de operação financeira no sistema.
// Union type: o TypeScript garante que apenas esses 5 valores são aceitos onde `TypeOfOperation` for usado.
export type TypeOfOperation = "deposito" | "saque" | "pagar" | "transferencia" | "investimento";

// Define os possíveis estados de uma operação financeira.
// "pendente" = aguardando processamento, "aprovada" = concluída, "recusada" = rejeitada.
export type OperationStatus = "pendente" | "aprovada" | "recusada";

// Formato do documento que representa uma operação financeira no Firestore.
// Campos opcionais (?) indicam que podem não estar presentes em todos os documentos
// (ex: transferências têm `targetUserId`, saques simples não têm).
export type OperationDocument = {
    targetDocumentId?: string;        // ID de um documento relacionado (ex: ordem de compra no balcão)
    authorUid: string;                // UID do usuário que iniciou a operação — campo obrigatório
    amountCents: number;              // Valor da operação (em centavos ou unidade monetária do sistema)
    typeOfOperation: TypeOfOperation; // Tipo da operação — validado pelo union type acima
    status: OperationStatus;          // Estado atual da operação
    targetUserId?: string;            // apenas para pagamentos / transferências — UID do destinatário
    text?: string;                    // Descrição legível da operação, exibida no histórico do app
    createdAt?: FieldValue;           // Timestamp de criação — preenchido pelo servidor com serverTimestamp()
    completedAt?: Timestamp;          // Timestamp de conclusão — preenchido quando status muda para "aprovada"
}
