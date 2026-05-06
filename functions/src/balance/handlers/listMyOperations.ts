// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import {onCall} from "firebase-functions/https";
import {requireAuthenticatedUser} from "../../shared/auth";
import {listOperations} from "../repositories/balanceRepository";

export const listMyOperations = onCall({ invoker: "public" }, async (request) => {
    console.log(`listMyOperations chamado pelo UID: ${request.auth?.uid}`);

    const user = requireAuthenticatedUser(request);
    const operations = await listOperations(user.uid);

    return {
        count: operations.length,
        data: operations,
    };
});
