// Grupo: G09 — PI3-2026-T2
// Router REST: /api/operations/*

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import cors from "cors";
import {
  buyFromStartup,
  buyFromUser,
  sell,
  acceptOperation,
  rejectOperation,
  getOperationsByUser,
  getOperationsByStartup,
  getPendingBuyOperations,
} from "./repositories/operationsRepository";

const corsHandler = cors({ origin: true });

interface AuthUser { uid: string; email?: string; }

async function authenticateUser(req: any, res: any): Promise<AuthUser | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Cabeçalho de autorização inválido ou ausente." });
    return null;
  }
  const token = authHeader.split("Bearer ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return { uid: decoded.uid, email: decoded.email };
  } catch {
    res.status(401).json({ error: "Sessão expirada ou token inválido." });
    return null;
  }
}

export const operationsApi = onRequest({ invoker: "public" }, (req, res) => {
  corsHandler(req, res, async () => {
    const method = req.method;
    let path = req.path || "";
    if (path.startsWith("/api")) path = path.slice(4);
    if (path.endsWith("/") && path.length > 1) path = path.slice(0, -1);

    try {
      // POST /operations/buy-from-startup
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
          res.status(400).json({ error: err.message || "Erro ao comprar tokens da startup." });
        }
        return;
      }

      // POST /operations/buy-from-user
      if (method === "POST" && path === "/operations/buy-from-user") {
        const user = await authenticateUser(req, res);
        if (!user) return;
        const { startupId, quantity, pricePerTokenCents, validityDays } = req.body as {
          startupId: string; quantity: number;
          pricePerTokenCents: number; validityDays?: number;
        };
        if (!startupId || !quantity || quantity <= 0 || !pricePerTokenCents || pricePerTokenCents <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos." });
          return;
        }
        try {
          const result = await buyFromUser(user.uid, startupId, quantity, pricePerTokenCents, validityDays ?? 1);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao criar oferta de compra." });
        }
        return;
      }

      // POST /operations/sell
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
          const result = await sell(user.uid, startupId, quantity, askedPricePerTokenCents);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao criar oferta de venda." });
        }
        return;
      }

      // PATCH /operations/:id/accept
      const matchAccept = path.match(/^\/operations\/([^/]+)\/accept$/);
      if (method === "PATCH" && matchAccept) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const result = await acceptOperation(user.uid, matchAccept[1]);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao aceitar oferta." });
        }
        return;
      }

      // PATCH /operations/:id/reject
      const matchReject = path.match(/^\/operations\/([^/]+)\/reject$/);
      if (method === "PATCH" && matchReject) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          await rejectOperation(user.uid, matchReject[1]);
          res.json({ success: true });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao cancelar oferta." });
        }
        return;
      }

      // GET /operations/pending/:startupId — Ofertas de compra pendentes (para vendedores)
      const matchPending = path.match(/^\/operations\/pending\/([^/]+)$/);
      if (method === "GET" && matchPending) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const ops = await getPendingBuyOperations(matchPending[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações pendentes." });
        }
        return;
      }

      // GET /operations/user/:userId
      const matchUser = path.match(/^\/operations\/user\/([^/]+)$/);
      if (method === "GET" && matchUser) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const ops = await getOperationsByUser(matchUser[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações do usuário." });
        }
        return;
      }

      // GET /operations/startup/:startupId
      const matchStartup = path.match(/^\/operations\/startup\/([^/]+)$/);
      if (method === "GET" && matchStartup) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          const ops = await getOperationsByStartup(matchStartup[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações da startup." });
        }
        return;
      }

      res.status(404).json({ error: `Rota não encontrada: ${method} ${path}` });
    } catch (globalError: any) {
      res.status(500).json({ error: globalError.message || "Erro interno do servidor." });
    }
  });
});
