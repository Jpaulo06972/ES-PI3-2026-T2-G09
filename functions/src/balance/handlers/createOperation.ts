// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o helper `onCall` para criar Cloud Functions acessíveis pelo app Flutter,
// e `HttpsError` para lançar erros padronizados com código HTTP + mensagem amigável.
import {onCall, HttpsError} from "firebase-functions/v2/https";

// Função utilitária que garante que a requisição vem de um usuário autenticado.
import {requireAuthenticatedUser} from "../../shared/auth";

// Funções do repositório responsáveis por ler/escrever dados de saldo e operações no Firestore.
import {addOperation, incrementUserBalance, decrementUserBalance, getUserBalance} from "../repositories/balanceRepository";

// Tipos TypeScript que descrevem a forma de um documento de operação e os tipos possíveis.
import {OperationDocument, TypeOfOperation} from "../types";

// FieldValue do Firestore — usado aqui especificamente para `serverTimestamp()`,
// que registra o momento exato em que o dado foi gravado no servidor (não no cliente).
import {FieldValue} from "firebase-admin/firestore";

// Instância do Firestore, já inicializada no módulo compartilhado.
import {db} from "../../shared/firebase";


/**
 * Cria uma nova operação financeira (depósito, saque, pagamento, transferência, etc) e atualiza o saldo.
 */
// `onCall` com `invoker: "public"` significa que qualquer cliente autenticado (ou não)
// pode chamar essa função pelo SDK do Firebase — a autenticação é verificada manualmente logo abaixo.
export const createOperation = onCall({ invoker: "public" }, async (request) => {
    // Garante que o usuário está logado
    // Se não houver token de autenticação, `requireAuthenticatedUser` lança HttpsError("unauthenticated").
    const user = requireAuthenticatedUser(request);

    // Desestrutura os campos enviados pelo app Flutter no corpo da requisição.
    // `amount`: valor da operação (em centavos ou unidade monetária do sistema).
    // `type`: tipo da operação (deposito, saque, pagar, transferencia, investimento).
    // `text`: descrição opcional enviada pelo usuário.
    // `targetIdentifier`: e-mail ou UID do destinatário — usado apenas em transferências.
    const { amount, type, text, targetIdentifier } = request.data as {
        amount: number;
        type: TypeOfOperation;
        text?: string;
        targetIdentifier?: string; // Pode ser email ou UID
    };

    // Validações básicas
    // Rejeita se o valor não foi enviado ou é inválido (zero ou negativo não fazem sentido financeiramente).
    if (amount === undefined || amount <= 0) {
        throw new HttpsError("invalid-argument", "O valor da operação deve ser maior que zero.");
    }

    // O tipo de operação é obrigatório para saber o que fazer com o saldo.
    if (!type) {
        throw new HttpsError("invalid-argument", "O tipo de operação é obrigatório.");
    }

    // Se for uma operação que retira dinheiro, verifica o saldo primeiro
    // Apenas depósitos aumentam o saldo — todos os demais tipos debitam. Por isso,
    // antes de prosseguir, consultamos o saldo atual do usuário para evitar saldo negativo.
    if (type !== "deposito") {
        const currentBalance = await getUserBalance(user.uid);
        if (currentBalance < amount) {
            throw new HttpsError("failed-precondition", "Saldo insuficiente para realizar esta operação.");
        }
    }

    // Variável que será preenchida com o UID do destinatário, caso seja uma transferência.
    let finalTargetUserId = "";

    // Monta o texto descritivo da operação: usa o texto enviado pelo app ou gera um texto padrão
    // capitalizando a primeira letra do tipo (ex: "Deposito realizada via App").
    let finalOperationText = text || `${type.charAt(0).toUpperCase() + type.slice(1)} realizada via App`;

    // Lógica especializada para cada tipo
    if (type === "transferencia") {
        // Transferência exige um destinatário identificado por e-mail.
        if (!targetIdentifier) {
            throw new HttpsError("invalid-argument", "O destinatário (e-mail) é obrigatório para transferências.");
        }

        // Busca o usuário destinatário no Firestore pelo campo `email`.
        // `.trim()` remove espaços acidentais que o usuário possa ter digitado.
        const userQuery = await db.collection("users")
            .where("email", "==", targetIdentifier.trim())
            .get();

        // Se nenhum documento for retornado, o e-mail não existe na base.
        if (userQuery.empty) {
            throw new HttpsError("not-found", "Destinatário não encontrado. Verifique o e-mail informado.");
        }

        // O primeiro (e único esperado) documento é o do destinatário — guarda o ID.
        finalTargetUserId = userQuery.docs[0].id;

        // Impede que o usuário transfira para si mesmo — isso não tem sentido financeiro
        // e poderia gerar inconsistências no histórico.
        if (finalTargetUserId === user.uid) {
            throw new HttpsError("invalid-argument", "Você não pode transferir para si mesmo.");
        }

        // Atualiza o texto para identificar claramente para quem foi a transferência.
        finalOperationText = `Transferência para ${targetIdentifier}`;
    } else if (type === "saque") {
        // Para saque, o `targetIdentifier` pode indicar o banco/conta de destino — apenas informativo.
        if (targetIdentifier) {
            finalOperationText = `Saque para: ${targetIdentifier}`;
        }
    }

    // Prepara o documento da operação
    // Monta o objeto que será salvo na coleção `operations` do Firestore.
    // `status: "aprovada"` significa que nesta implementação as operações são aprovadas imediatamente,
    // sem etapa de aprovação manual — decisão de design simplificado para o MVP.
    const operation: OperationDocument = {
        authorUid: user.uid,               // quem iniciou a operação
        amountCents: amount,               // valor da operação
        typeOfOperation: type,             // tipo: deposito, saque, etc.
        status: "aprovada",                // aprovação imediata
        text: finalOperationText || `${type.charAt(0).toUpperCase() + type.slice(1)} realizado via App`,
        targetUserId: finalTargetUserId,   // destinatário (vazio se não for transferência)
        createdAt: FieldValue.serverTimestamp(), // timestamp do servidor, não do cliente
    };

    try {
        // Consulta novamente o saldo atual — segunda verificação dentro do bloco try
        // para garantir consistência caso haja chamadas concorrentes (race condition básico).
        const currentBalance = await getUserBalance(user.uid);
        //console.log(`[createOperation] User: ${user.uid}, Type: ${type}, Current Balance: ${currentBalance}, Requested Amount: ${amount}`);

        if (type !== "deposito") {
            if (currentBalance < amount) {
                //console.warn(`[createOperation] Insufficient balance for user ${user.uid}. Required: ${amount}, Available: ${currentBalance}`);
                throw new HttpsError("failed-precondition", "Saldo insuficiente para realizar esta operação.");
            }
        }

        // 1. Salva o registro da operação no histórico
        // `addOperation` retorna o ID do documento criado — útil para auditoria e retorno ao app.
        const operationId = await addOperation(operation);

        // 2. Lógica de atualização de saldo baseada no tipo
        // Cada caso do switch executa a movimentação correta de saldo.
        switch (type) {
            case "deposito":
                //console.log(`[createOperation] Incrementing balance for ${user.uid} by ${amount}`);
                // Depósito: apenas adiciona ao saldo do usuário que fez a operação.
                await incrementUserBalance(user.uid, amount);
                break;

            case "transferencia":
                //console.log(`[createOperation] Transfer from ${user.uid} to ${finalTargetUserId} of ${amount}`);
                // Transferência: debita do remetente e credita no destinatário atomicamente (em sequência).
                await decrementUserBalance(user.uid, amount);
                await incrementUserBalance(finalTargetUserId, amount);
                break;

            case "saque":
            case "pagar":
            case "investimento":
                //console.log(`[createOperation] Decrementing balance for ${user.uid} by ${amount}`);
                // Saque, pagamento e investimento: todos apenas debitam do saldo do usuário.
                await decrementUserBalance(user.uid, amount);
                break;
        }

        // Retorna confirmação ao app com o ID gerado para a operação.
        return {
            success: true,
            operationId,
            message: "Operação financeira processada com sucesso."
        };
    } catch (error) {
        //console.error("Erro ao processar createOperation:", error);
        // Qualquer erro inesperado é encapsulado em um HttpsError genérico para não expor
        // detalhes internos do servidor ao cliente.
        throw new HttpsError("internal", "Não foi possível completar a transação financeira.");
    }
});
