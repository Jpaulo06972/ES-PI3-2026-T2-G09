// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {addOperation, incrementUserBalance, decrementUserBalance, getUserBalance} from "../repositories/balanceRepository";
import {OperationDocument, TypeOfOperation} from "../types";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../shared/firebase";


/**
 * Cria uma nova operação financeira (depósito, saque, pagamento, transferência, etc) e atualiza o saldo.
 */
export const createOperation = onCall({ invoker: "public" }, async (request) => {
    // Garante que o usuário está logado
    const user = requireAuthenticatedUser(request);
    
    const { amount, type, text, targetIdentifier } = request.data as {
        amount: number;
        type: TypeOfOperation;
        text?: string;
        targetIdentifier?: string; // Pode ser email ou UID
    };

    // Validações básicas
    if (amount === undefined || amount <= 0) {
        throw new HttpsError("invalid-argument", "O valor da operação deve ser maior que zero.");
    }

    if (!type) {
        throw new HttpsError("invalid-argument", "O tipo de operação é obrigatório.");
    }

    // Se for uma operação que retira dinheiro, verifica o saldo primeiro
    if (type !== "deposito") {
        const currentBalance = await getUserBalance(user.uid);
        if (currentBalance < amount) {
            throw new HttpsError("failed-precondition", "Saldo insuficiente para realizar esta operação.");
        }
    }

    let finalTargetUserId = "";
    let finalOperationText = text || `${type.charAt(0).toUpperCase() + type.slice(1)} realizada via App`;

    // Lógica especializada para cada tipo
    if (type === "transferencia") {
        if (!targetIdentifier) {
            throw new HttpsError("invalid-argument", "O destinatário (e-mail) é obrigatório para transferências.");
        }

        const userQuery = await db.collection("users")
            .where("email", "==", targetIdentifier.trim())
            .get();

        if (userQuery.empty) {
            throw new HttpsError("not-found", "Destinatário não encontrado. Verifique o e-mail informado.");
        }

        finalTargetUserId = userQuery.docs[0].id;

        if (finalTargetUserId === user.uid) {
            throw new HttpsError("invalid-argument", "Você não pode transferir para si mesmo.");
        }
        
        finalOperationText = `Transferência para ${targetIdentifier}`;
    } else if (type === "saque") {
        if (targetIdentifier) {
            finalOperationText = `Saque para: ${targetIdentifier}`;
        }
    }

    // Prepara o documento da operação
    const operation: OperationDocument = {
        authorUid: user.uid,
        amountCents: amount,
        typeOfOperation: type,
        status: "aprovada",
        text: finalOperationText || `${type.charAt(0).toUpperCase() + type.slice(1)} realizado via App`,
        targetUserId: finalTargetUserId,
        createdAt: FieldValue.serverTimestamp(),
    };

    try {
        const currentBalance = await getUserBalance(user.uid);
        //console.log(`[createOperation] User: ${user.uid}, Type: ${type}, Current Balance: ${currentBalance}, Requested Amount: ${amount}`);

        if (type !== "deposito") {
            if (currentBalance < amount) {
                //console.warn(`[createOperation] Insufficient balance for user ${user.uid}. Required: ${amount}, Available: ${currentBalance}`);
                throw new HttpsError("failed-precondition", "Saldo insuficiente para realizar esta operação.");
            }
        }

        // 1. Salva o registro da operação no histórico
        const operationId = await addOperation(operation);

        // 2. Lógica de atualização de saldo baseada no tipo
        switch (type) {
            case "deposito":
                //console.log(`[createOperation] Incrementing balance for ${user.uid} by ${amount}`);
                await incrementUserBalance(user.uid, amount);
                break;
            
            case "transferencia":
                //console.log(`[createOperation] Transfer from ${user.uid} to ${finalTargetUserId} of ${amount}`);
                await decrementUserBalance(user.uid, amount);
                await incrementUserBalance(finalTargetUserId, amount);
                break;

            case "saque":
            case "pagar":
            case "investimento":
                //console.log(`[createOperation] Decrementing balance for ${user.uid} by ${amount}`);
                await decrementUserBalance(user.uid, amount);
                break;
        }

        return { 
            success: true, 
            operationId,
            message: "Operação financeira processada com sucesso."
        };
    } catch (error) {
        //console.error("Erro ao processar createOperation:", error);
        throw new HttpsError("internal", "Não foi possível completar a transação financeira.");
    }
});
