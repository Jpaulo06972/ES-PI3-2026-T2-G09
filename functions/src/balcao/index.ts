// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import cors from "cors";
import {
  buyTokensTransaction,
  sellTokensTransaction,
  createBalcaoOffer,
  cancelBalcaoOffer,
  listActiveOffers,
  getUserTokenHoldings,
  getPriceHistory,
  buyFromOrdersTransaction,
  approvePendingOfferTransaction,
  rejectPendingOfferTransaction,
  getPendingApprovals
} from "./repositories/balcaoRepository";

const corsHandler = cors({ origin: true });

interface AuthenticatedUser {
  uid: string;
  email?: string;
}

/**
 * Autentica o usuário a partir do cabeçalho Authorization (Bearer <ID_TOKEN>).
 * Se falhar, retorna null e já envia a resposta de erro 401.
 */
async function authenticateUser(req: any, res: any): Promise<AuthenticatedUser | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Cabeçalho de autorização inválido ou ausente." });
    return null;
  }

  const token = authHeader.split("Bearer ")[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return {
      uid: decodedToken.uid,
      email: decodedToken.email
    };
  } catch (error) {
    res.status(401).json({ error: "Sessão expirada ou token de autenticação inválido." });
    return null;
  }
}

/**
 * Endpoint unificado que atua como Roteador REST API (/api/balcao/*)
 */
export const api = onRequest({ invoker: "public" }, (req, res) => {
  corsHandler(req, res, async () => {
    const method = req.method;
    // Normaliza o path (ignora prefixo /api se houver)
    let path = req.path || "";
    if (path.startsWith("/api")) {
      path = path.slice(4);
    }
    
    // Remove barras no final para padronizar
    if (path.endsWith("/") && path.length > 1) {
      path = path.slice(0, -1);
    }

    try {
      // 1. POST /balcao/buy — Compra Direta de Tokens da Startup
      if (method === "POST" && path === "/balcao/buy") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const { startupId, quantity } = req.body as { startupId: string; quantity: number };
        if (!startupId || quantity === undefined || quantity <= 0) {
          res.status(400).json({ error: "Parâmetros startupId e quantity (maior que zero) são obrigatórios." });
          return;
        }

        try {
          const result = await buyTokensTransaction(user.uid, startupId, quantity);
          res.json({
            success: true,
            updatedBalance: result.updatedBalance,
            newTokenPrice: result.newTokenPrice
          });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao processar a compra direta de tokens." });
        }
        return;
      }

      // 2. POST /balcao/sell — Venda Direta de Tokens de volta para a Startup
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

      // 3. POST /balcao/buy-from-orders — Compra Casada (Multiprovadores / Secondary Market)
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
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao processar a compra de ofertas secundárias." });
        }
        return;
      }

      // 4. POST /balcao/offer — Registra Oferta Aberta ou Abaixo do Mercado
      if (method === "POST" && path === "/balcao/offer") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const { startupId, type, quantity, pricePerToken } = req.body as {
          startupId: string;
          type: "buy" | "sell";
          quantity: number;
          pricePerToken: number;
        };

        if (!startupId || !type || quantity === undefined || quantity <= 0 || pricePerToken === undefined || pricePerToken <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos para publicação de oferta." });
          return;
        }

        if (type !== "buy" && type !== "sell") {
          res.status(400).json({ error: "O tipo de oferta deve ser 'buy' ou 'sell'." });
          return;
        }

        try {
          const offerId = await createBalcaoOffer(user.uid, startupId, type, quantity, pricePerToken);
          res.json({ success: true, offerId });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao registrar oferta." });
        }
        return;
      }

      // 5. POST /balcao/offer/:offerId/approve — Aprovação de Oferta Abaixo do Mercado
      const matchApprove = path.match(/^\/balcao\/offer\/([^/]+)\/approve$/);
      if (method === "POST" && matchApprove) {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const offerId = matchApprove[1];
        try {
          const result = await approvePendingOfferTransaction(user.uid, offerId);
          res.json(result);
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao aprovar oferta pendente." });
        }
        return;
      }

      // 6. POST /balcao/offer/:offerId/reject — Recusa de Oferta Abaixo do Mercado
      const matchReject = path.match(/^\/balcao\/offer\/([^/]+)\/reject$/);
      if (method === "POST" && matchReject) {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const offerId = matchReject[1];
        try {
          await rejectPendingOfferTransaction(user.uid, offerId);
          res.json({ success: true });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao rejeitar oferta pendente." });
        }
        return;
      }

      // 7. DELETE /balcao/offer/:offerId — Cancela Oferta e Libera Reserva
      const matchCancelOffer = path.match(/^\/balcao\/offer\/([^/]+)$/);
      if (method === "DELETE" && matchCancelOffer) {
        const user = await authenticateUser(req, res);
        if (!user) return;

        const offerId = matchCancelOffer[1];
        try {
          await cancelBalcaoOffer(user.uid, offerId);
          res.json({ success: true });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao cancelar a oferta." });
        }
        return;
      }

      // 8. GET /balcao/pending-approvals — Lista Aprovações Pendentes para o Vendedor
      if (method === "GET" && path === "/balcao/pending-approvals") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        try {
          const pending = await getPendingApprovals(user.uid);
          res.json({ success: true, pending });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao listar aprovações pendentes." });
        }
        return;
      }

      // 9. GET /balcao/offers/:startupId — Lista Ofertas Ativas de Outros Usuários
      const matchOffers = path.match(/^\/balcao\/offers\/([^/]+)$/);
      if (method === "GET" && matchOffers) {
        const startupId = matchOffers[1];
        
        let requestingUserId: string | null = null;
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith("Bearer ")) {
          const token = authHeader.split("Bearer ")[1];
          try {
            const decodedToken = await admin.auth().verifyIdToken(token);
            requestingUserId = decodedToken.uid;
          } catch (e) {
            // Ignora erro sutil
          }
        }

        try {
          const offers = await listActiveOffers(requestingUserId, startupId);
          res.json({ success: true, offers });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar ofertas." });
        }
        return;
      }

      // 10. GET /balcao/my-tokens — Holdings de Tokens do Usuário Autenticado
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

      // 11. GET /balcao/price-history/:startupId — Histórico de Preços da Startup
      const matchPriceHistory = path.match(/^\/balcao\/price-history\/([^/]+)$/);
      if (method === "GET" && matchPriceHistory) {
        const startupId = matchPriceHistory[1];
        const period = req.query.period as string | undefined;

        try {
          const history = await getPriceHistory(startupId, period);
          res.json({ success: true, history });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao buscar histórico de preços." });
        }
        return;
      }

      res.status(404).json({ error: `Rota não encontrada: ${method} ${path}` });

    } catch (globalError: any) {
      res.status(500).json({ error: globalError.message || "Erro interno do servidor." });
    }
  });
});
