import {FieldValue, Timestamp} from "firebase-admin/firestore";


export type TypeOfOperation = "deposito" | "pagar" | "transferencia";
export type OperationStatus = "pendente" | "aprovada" | "recusada";

export type OperationDocument = {
    targetDocumentId?: string;
    authorUid: string;
    amountCents: number;
    typeOfOperation: TypeOfOperation;
    status: OperationStatus;
    targetUserId?: string; // apenas para pagamentos / transferências
    text?: string; 
    createdAt?: FieldValue;
    completedAt?: Timestamp;
}

