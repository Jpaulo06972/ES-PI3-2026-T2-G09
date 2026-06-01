// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o decorator do Firebase Functions v2 para criar Cloud Functions HTTP
import { onRequest } from "firebase-functions/v2/https";
// Admin SDK do Firebase — usado para verificar tokens JWT de autenticação
import * as admin from "firebase-admin";
// Middleware CORS: permite que o app Flutter (ou qualquer origem) chame esta API
import cors from "cors";

// Importa todas as funções de repositório do Balcão (mercado de tokens)
import {
  buyTokensTransaction,       // Compra direta da startup
  sellTokensTransaction,      // Venda direta de volta para a startup
  createBalcaoOffer,          // Cria oferta aberta no book de ordens
  cancelBalcaoOffer,          // Cancela oferta e libera reserva
  listActiveOffers,           // Lista ofertas visíveis de outros usuários
  getUserTokenHoldings,       // Retorna carteira de tokens do usuário
  getPriceHistory,            // Histórico de preços de uma startup
  buyFromOrdersTransaction,   // Compra casada com ofertas de venda de outros usuários
} from "./repositories/balcaoRepository";

// Importa as funções do módulo de operações entre investidores (mercado secundário)
import {
  buyFromStartup,             // Compra direta pela rota de operações
  buyFromUser,                // Cria oferta de compra P2P
  sell as sellOperation,      // Cria oferta de venda P2P
  acceptOperation,            // Vendedor aceita uma oferta de compra
  rejectOperation,            // Cancela/rejeita uma operação pendente
  getOperationsByUser,        // Lista operações de um usuário
  getOperationsByStartup,     // Lista operações de uma startup
  getPendingBuyOperations,    // Lista ofertas de compra pendentes (visíveis para vendedores)
} from "../operations/repositories/operationsRepository";

// Configura o CORS para aceitar requisições de qualquer origem.
// Em produção, seria ideal restringir a origem ao domínio do app.
const corsHandler = cors({ origin: true });

/**
 * Tipo auxiliar para representar o usuário autenticado extraído do token JWT.
 * Usamos apenas uid e email — não precisamos do payload completo.
 */
interface AuthenticatedUser {
  uid: string;
  email?: string;
}

/**
 * Função auxiliar de autenticação via Firebase ID Token (Bearer JWT).
 *
 * Toda rota protegida chama essa função primeiro. Se o token for inválido
 * ou ausente, ela já responde com 401 e retorna null — o caller só precisa
 * checar `if (!user) return;` para encerrar o fluxo com segurança.
 *
 * @param req  Objeto de requisição HTTP
 * @param res  Objeto de resposta HTTP
 * @returns    Dados do usuário autenticado ou null em caso de falha
 */
async function authenticateUser(req: any, res: any): Promise<AuthenticatedUser | null> {
  // Lê o cabeçalho Authorization — esperamos o formato "Bearer <TOKEN>"
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Cabeçalho de autorização inválido ou ausente." });
    return null;
  }

  // Extrai o token removendo o prefixo "Bearer "
  const token = authHeader.split("Bearer ")[1];
  try {
    // Valida o token JWT com o Firebase Admin SDK (verificação de assinatura + expiração)
    const decodedToken = await admin.auth().verifyIdToken(token);
    return {
      uid: decodedToken.uid,
      email: decodedToken.email
    };
  } catch (error) {
    // Token expirado, adulterado ou de outro projeto Firebase
    res.status(401).json({ error: "Sessão expirada ou token de autenticação inválido." });
    return null;
  }
}

/**
 * Cloud Function principal que age como um roteador REST unificado.
 *
 * Todas as rotas /balcao/* e /operations/* passam por aqui.
 * A função analisa o método HTTP (GET, POST, PATCH, DELETE) e o path
 * da requisição para decidir qual handler chamar — funcionando como
 * um mini Express.js sem precisar de um servidor dedicado.
 *
 * Isso simplifica o deploy: uma única Cloud Function cobre toda a API.
 */
export const api = onRequest({ invoker: "public" }, (req, res) => {
  // Aplica o middleware CORS em toda requisição antes de processar a lógica
  corsHandler(req, res, async () => {
    const method = req.method;

    // Normaliza o path: remove o prefixo "/api" caso o cliente o envie
    let path = req.path || "";
    if (path.startsWith("/api")) {
      path = path.slice(4);
    }

    // Remove a barra final para padronizar (ex: "/balcao/buy/" → "/balcao/buy")
    if (path.endsWith("/") && path.length > 1) {
      path = path.slice(0, -1);
    }

    try {
      // ─── Rota 1: POST /balcao/buy ────────────────────────────────────────────
      // O usuário compra tokens diretamente da startup ao preço de mercado atual.
      // O saldo é debitado e o motor de preços atualiza o valor do token.
      if (method === "POST" && path === "/balcao/buy") {
        const user = await authenticateUser(req, res);
        if (!user) return; // Token inválido — authenticateUser já enviou o 401

        // Valida os parâmetros obrigatórios do body
        const { startupId, quantity } = req.body as { startupId: string; quantity: number };
        if (!startupId || quantity === undefined || quantity <= 0) {
          res.status(400).json({ error: "Parâmetros startupId e quantity (maior que zero) são obrigatórios." });
          return;
        }

        try {
          // Executa a compra em transação atômica no Firestore
          const result = await buyTokensTransaction(user.uid, startupId, quantity);
          res.json({
            success: true,
            updatedBalance: result.updatedBalance,
            newTokenPrice: result.newTokenPrice
          });
        } catch (err: any) {
          // Erros de negócio (saldo insuficiente, tokens esgotados, etc.)
          res.status(400).json({ error: err.message || "Erro ao processar a compra direta de tokens." });
        }
        return;
      }

      // ─── Rota 2: POST /balcao/sell ───────────────────────────────────────────
      // O usuário vende tokens de volta para a startup ao preço atual.
      // O saldo é creditado e o motor de preços é atualizado com a pressão de venda.
      if (method === "POST" && path === "/balcao/sell") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const { startupId, quantity } = req.body as { startupId: string; quantity: number };
        if (!startupId || quantity === undefined || quantity <= 0) {
          res.status(400).json({ error: "Parâmetros startupId e quantity (maior que zero) são obrigatórios." });
          return;
        }

        try {
          const result = await sellTokensTransaction(user.uid, startupId, quantity);
          res.json({
            success: true,
            updatedBalance: result.updatedBalance,
            newTokenPrice: result.newTokenPrice
          });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao processar a venda direta de tokens." });
        }
        return;
      }

      // ─── Rota 3: POST /balcao/buy-from-orders ────────────────────────────────
      // Compra casada no mercado secundário: o comprador absorve ofertas de venda
      // abertas de outros investidores, da mais barata para a mais cara (greedy).
      if (method === "POST" && path === "/balcao/buy-from-orders") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const { startupId, quantity } = req.body as { startupId: string; quantity: number };
        if (!startupId || quantity === undefined || quantity <= 0) {
          res.status(400).json({ error: "Parâmetros startupId e quantity são obrigatórios." });
          return;
        }

        try {
          const result = await buyFromOrdersTransaction(user.uid, startupId, quantity);
          // Responde com o spread operator: filledQuantity, totalPaid, operations[], etc.
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao processar a compra de ofertas secundárias." });
        }
        return;
      }

      // ─── Rota 4: POST /balcao/offer ──────────────────────────────────────────
      // Publica uma oferta aberta no book de ordens do Balcão.
      // Ofertas do tipo "buy" abaixo do preço de mercado ficam pendentes de aprovação.
      // Ofertas do tipo "buy" reservam o saldo do usuário para garantir liquidez.
      if (method === "POST" && path === "/balcao/offer") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        // Tipagem explícita do body para facilitar a validação
        const { startupId, type, quantity, pricePerToken } = req.body as {
          startupId: string;
          type: "buy" | "sell";
          quantity: number;
          pricePerToken: number;
        };

        // Validação completa: todos os campos são obrigatórios e com valores positivos
        if (!startupId || !type || quantity === undefined || quantity <= 0 || pricePerToken === undefined || pricePerToken <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos para publicação de oferta." });
          return;
        }

        // Garante que o tipo da oferta seja apenas "buy" ou "sell"
        if (type !== "buy" && type !== "sell") {
          res.status(400).json({ error: "O tipo de oferta deve ser 'buy' ou 'sell'." });
          return;
        }

        try {
          // Cria a oferta e retorna o ID gerado pelo Firestore
          const offerId = await createBalcaoOffer(user.uid, startupId, type, quantity, pricePerToken);
          res.json({ success: true, offerId });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao registrar oferta." });
        }
        return;
      }

      // ─── Rota 5: DELETE /balcao/offer/:offerId ────────────────────────────────
      // Cancela uma oferta aberta ou pendente pertencente ao usuário autenticado.
      // Se for oferta de compra, o saldo reservado é liberado de volta.
      // Usamos regex para capturar o ID dinâmico do path.
      const matchCancelOffer = path.match(/^\/balcao\/offer\/([^/]+)$/);
      if (method === "DELETE" && matchCancelOffer) {
        const user = await authenticateUser(req, res);
        if (!user) return;

        // matchCancelOffer[1] é o ID capturado pelo grupo regex ([^/]+)
        const offerId = matchCancelOffer[1];
        try {
          await cancelBalcaoOffer(user.uid, offerId);
          res.json({ success: true });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao cancelar a oferta." });
        }
        return;
      }

      // ─── Rota 6: GET /balcao/offers/:startupId ────────────────────────────────
      // Lista as ofertas abertas de outros investidores para uma startup específica.
      // As próprias ofertas do usuário são filtradas para não aparecer para si mesmo.
      // A autenticação aqui é opcional (tentamos, mas não bloqueamos se falhar).
      const matchOffers = path.match(/^\/balcao\/offers\/([^/]+)$/);
      if (method === "GET" && matchOffers) {
        const startupId = matchOffers[1];

        // Tenta obter o userId para filtrar as próprias ofertas, mas não exige autenticação
        let requestingUserId: string | null = null;
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith("Bearer ")) {
          const token = authHeader.split("Bearer ")[1];
          try {
            const decodedToken = await admin.auth().verifyIdToken(token);
            requestingUserId = decodedToken.uid;
          } catch (e) {
            // Ignora erro sutil — usuário não autenticado verá todas as ofertas sem filtro
          }
        }

        try {
          // Passa o userId (ou null) para que o repositório possa filtrar corretamente
          const offers = await listActiveOffers(requestingUserId, startupId);
          res.json({ success: true, offers });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar ofertas." });
        }
        return;
      }

      // ─── Rota 10: GET /balcao/my-tokens ──────────────────────────────────────
      // Retorna todos os tokens que o usuário autenticado possui, com o valor atual
      // de cada startup. Usado para popular a carteira de investimentos do app.
      if (method === "GET" && path === "/balcao/my-tokens") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        try {
          const holdings = await getUserTokenHoldings(user.uid);
          res.json({ success: true, holdings });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao buscar holdings de tokens." });
        }
        return;
      }

      // ─── Rota 11: GET /balcao/price-history/:startupId ───────────────────────
      // Retorna o histórico de variação de preço de uma startup.
      // Aceita o query param `period` para filtrar: "daily", "weekly", "monthly", etc.
      const matchPriceHistory = path.match(/^\/balcao\/price-history\/([^/]+)$/);
      if (method === "GET" && matchPriceHistory) {
        const startupId = matchPriceHistory[1];
        // `period` é opcional — sem ele, retorna todo o histórico disponível
        const period = req.query.period as string | undefined;

        try {
          const history = await getPriceHistory(startupId, period);
          res.json({ success: true, history });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao buscar histórico de preços." });
        }
        return;
      }

      // ════════════════════════════════════════════════════════════════════════
      // Rotas do módulo /operations/* — mercado P2P entre investidores
      // Essas rotas usam a coleção "operations" (diferente de "tokenOperations")
      // e suportam o fluxo de negociação bilateral: criar oferta → aceitar → executar
      // ════════════════════════════════════════════════════════════════════════

      // ─── POST /operations/buy-from-startup ────────────────────────────────────
      // Alternativa para compra direta da startup via módulo de operações.
      // Registra na coleção "operations" (em vez de "tokenOperations").
      if (method === "POST" && path === "/operations/buy-from-startup") {
        const user = await authenticateUser(req, res);
        if (!user) return;
        const { startupId, quantity } = req.body as { startupId: string; quantity: number };
        if (!startupId || !quantity || quantity <= 0) {
          res.status(400).json({ error: "startupId e quantity (>0) são obrigatórios." });
          return;
        }
        try {
          const result = await buyFromStartup(user.uid, startupId, quantity);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao comprar tokens." });
        }
        return;
      }

      // ─── POST /operations/buy-from-user ──────────────────────────────────────
      // Cria uma oferta de compra P2P: o comprador reserva saldo e aguarda
      // que um vendedor com tokens disponíveis aceite a oferta.
      // `validityDays` define por quantos dias a oferta fica ativa (padrão: 1 dia).
      if (method === "POST" && path === "/operations/buy-from-user") {
        const user = await authenticateUser(req, res);
        if (!user) return;
        const { startupId, quantity, pricePerTokenCents, validityDays } = req.body as {
          startupId: string; quantity: number; pricePerTokenCents: number; validityDays?: number;
        };
        if (!startupId || !quantity || quantity <= 0 || !pricePerTokenCents || pricePerTokenCents <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos." });
          return;
        }
        try {
          // validityDays ?? 1 garante o valor padrão de 1 dia se não enviado
          const result = await buyFromUser(user.uid, startupId, quantity, pricePerTokenCents, validityDays ?? 1);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao criar oferta de compra." });
        }
        return;
      }

      // ─── POST /operations/sell ────────────────────────────────────────────────
      // Cria uma oferta de venda P2P: o vendedor anuncia tokens disponíveis
      // com um preço pedido, aguardando um comprador interessado.
      if (method === "POST" && path === "/operations/sell") {
        const user = await authenticateUser(req, res);
        if (!user) return;
        const { startupId, quantity, askedPricePerTokenCents } = req.body as {
          startupId: string; quantity: number; askedPricePerTokenCents: number;
        };
        if (!startupId || !quantity || quantity <= 0 || !askedPricePerTokenCents || askedPricePerTokenCents <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos." });
          return;
        }
        try {
          // Renomeamos `sell` para `sellOperation` no import para evitar conflito de nomes
          const result = await sellOperation(user.uid, startupId, quantity, askedPricePerTokenCents);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao criar oferta de venda." });
        }
        return;
      }

      // ─── PATCH /operations/:id/accept ─────────────────────────────────────────
      // Um vendedor aceita uma oferta de compra pendente criada por outro usuário.
      // A transação transfere tokens do vendedor para o comprador e debita/credita saldos.
      const matchOpAccept = path.match(/^\/operations\/([^/]+)\/accept$/);
      if (method === "PATCH" && matchOpAccept) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          // matchOpAccept[1] é o ID da operação capturado pelo regex
          const result = await acceptOperation(user.uid, matchOpAccept[1]);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao aceitar oferta." });
        }
        return;
      }

      // ─── PATCH /operations/:id/reject ─────────────────────────────────────────
      // Cancela/rejeita uma operação pendente. Apenas o próprio usuário que
      // criou a oferta pode rejeitá-la. Libera saldo reservado se for oferta de compra.
      const matchOpReject = path.match(/^\/operations\/([^/]+)\/reject$/);
      if (method === "PATCH" && matchOpReject) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          await rejectOperation(user.uid, matchOpReject[1]);
          res.json({ success: true });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao cancelar oferta." });
        }
        return;
      }

      // ─── GET /operations/pending/:startupId ───────────────────────────────────
      // Lista todas as ofertas de compra abertas (type=buy_from_user, status=pending)
      // de uma startup específica. Usado por vendedores que querem aceitar ofertas.
      const matchOpPending = path.match(/^\/operations\/pending\/([^/]+)$/);
      if (method === "GET" && matchOpPending) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const ops = await getPendingBuyOperations(matchOpPending[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações pendentes." });
        }
        return;
      }

      // ─── GET /operations/user/:userId ─────────────────────────────────────────
      // Lista todas as operações (como comprador e como vendedor) de um usuário.
      // O resultado une as duas queries e elimina duplicatas pelo ID do documento.
      const matchOpUser = path.match(/^\/operations\/user\/([^/]+)$/);
      if (method === "GET" && matchOpUser) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const ops = await getOperationsByUser(matchOpUser[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações do usuário." });
        }
        return;
      }

      // ─── GET /operations/startup/:startupId ───────────────────────────────────
      // Lista todas as operações registradas para uma startup específica.
      // Útil para o painel administrativo ou para auditoria de negociações.
      const matchOpStartup = path.match(/^\/operations\/startup\/([^/]+)$/);
      if (method === "GET" && matchOpStartup) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const ops = await getOperationsByStartup(matchOpStartup[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações da startup." });
        }
        return;
      }

      // Se nenhuma rota acima foi correspondida, retorna 404 com a rota tentada
      res.status(404).json({ error: `Rota não encontrada: ${method} ${path}` });

    } catch (globalError: any) {
      // Captura qualquer erro inesperado que não foi tratado pelos try/catch internos
      res.status(500).json({ error: globalError.message || "Erro interno do servidor." });
    }
  });
});
