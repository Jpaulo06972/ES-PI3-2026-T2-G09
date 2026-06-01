// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

// ════════════════════════════════════════════════════════════════════════════
// Router REST: /api/operations/*
//
// Este arquivo implementa um mini-roteador REST usando uma única Cloud Function
// HTTP (`onRequest`). Em vez de criar uma função separada para cada endpoint,
// todas as rotas de operações P2P passam por aqui e são roteadas por
// método HTTP + path, funcionando como um Express.js simplificado.
// ════════════════════════════════════════════════════════════════════════════

// `onRequest` cria uma Cloud Function HTTP clássica que recebe (req, res).
// Diferente de `onCall`, ela não faz parsing automático do body — precisamos
// lidar com req.body e res.json() manualmente.
import { onRequest } from "firebase-functions/v2/https";

// Firebase Admin SDK — necessário para verificar tokens JWT (autenticação)
import * as admin from "firebase-admin";

// Middleware CORS para permitir requisições de qualquer origem (domínio).
// Necessário porque o app Flutter/web faz chamadas cross-origin para a API.
import cors from "cors";

// Importa todas as funções do repositório de operações P2P.
// Cada função encapsula uma transação atômica no Firestore para garantir
// consistência de saldo, holdings e operações.
import {
  buyFromStartup,           // Compra tokens diretamente do estoque da startup
  buyFromUser,              // Cria oferta de compra P2P (pendente de aceitação)
  sell,                     // Cria oferta de venda P2P (pendente de comprador)
  acceptOperation,          // Vendedor aceita uma oferta de compra pendente
  rejectOperation,          // Cancela/rejeita uma operação pendente (libera reserva)
  getOperationsByUser,      // Lista todas as operações de um usuário (comprador + vendedor)
  getOperationsByStartup,   // Lista todas as operações de uma startup específica
  getPendingBuyOperations,  // Lista ofertas de compra pendentes (para vendedores verem)
} from "./repositories/operationsRepository";

// Configura o middleware CORS para aceitar qualquer origem.
// Em produção, seria mais seguro restringir a `origin` ao domínio do app.
const corsHandler = cors({ origin: true });

/**
 * Tipo auxiliar para representar o usuário autenticado extraído do token JWT.
 * Usamos apenas uid e email — não precisamos do payload completo do token.
 */
interface AuthUser { uid: string; email?: string; }

/**
 * Função auxiliar de autenticação via Firebase ID Token (Bearer JWT).
 *
 * Toda rota protegida chama essa função primeiro. Se o token for inválido
 * ou ausente, ela já responde com 401 e retorna null — o caller só precisa
 * checar `if (!user) return;` para encerrar o fluxo com segurança.
 *
 * Esse padrão evita duplicar o código de autenticação em cada rota.
 *
 * @param req  Objeto de requisição HTTP
 * @param res  Objeto de resposta HTTP
 * @returns    Dados do usuário autenticado ou null em caso de falha
 */
async function authenticateUser(req: any, res: any): Promise<AuthUser | null> {
  // Lê o cabeçalho Authorization — esperamos "Bearer <TOKEN>"
  const authHeader = req.headers.authorization;

  // Se o cabeçalho não existir ou não começar com "Bearer ", rejeita com 401
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Cabeçalho de autorização inválido ou ausente." });
    return null;
  }

  // Extrai apenas o token JWT, removendo o prefixo "Bearer "
  const token = authHeader.split("Bearer ")[1];
  try {
    // Verifica assinatura, expiração e projeto do token JWT via Firebase Admin SDK
    const decoded = await admin.auth().verifyIdToken(token);
    return { uid: decoded.uid, email: decoded.email };
  } catch {
    // Token expirado, adulterado ou emitido por outro projeto Firebase
    res.status(401).json({ error: "Sessão expirada ou token inválido." });
    return null;
  }
}

/**
 * Cloud Function principal que age como roteador REST unificado.
 *
 * Analisa o método HTTP (GET, POST, PATCH) e o path da requisição
 * para decidir qual handler (função do repositório) chamar.
 *
 * `invoker: "public"` significa que a função aceita requisições de qualquer
 * cliente — a autenticação real é feita manualmente via authenticateUser.
 */
export const operationsApi = onRequest({ invoker: "public" }, (req, res) => {
  // Aplica o middleware CORS antes de processar qualquer lógica
  corsHandler(req, res, async () => {
    // Captura o método HTTP (GET, POST, PATCH, DELETE)
    const method = req.method;

    // Normaliza o path: remove o prefixo "/api" caso o proxy o adicione
    let path = req.path || "";
    if (path.startsWith("/api")) path = path.slice(4);

    // Remove barra final para padronizar (ex: "/operations/sell/" → "/operations/sell")
    if (path.endsWith("/") && path.length > 1) path = path.slice(0, -1);

    try {
      // ─── Rota 1: POST /operations/buy-from-startup ──────────────────────
      // Compra tokens diretamente do estoque da startup ao preço de mercado.
      // O saldo é debitado e os tokens são creditados ao comprador.
      if (method === "POST" && path === "/operations/buy-from-startup") {
        const user = await authenticateUser(req, res);
        if (!user) return; // authenticateUser já enviou o 401

        // Extrai e valida os parâmetros obrigatórios do body
        const { startupId, quantity } = req.body as { startupId: string; quantity: number };
        if (!startupId || !quantity || quantity <= 0) {
          res.status(400).json({ error: "startupId e quantity (>0) são obrigatórios." });
          return;
        }

        try {
          // Executa a compra em transação atômica no Firestore
          const result = await buyFromStartup(user.uid, startupId, quantity);
          res.json({ success: true, ...result });
        } catch (err: any) {
          // Erros de negócio: saldo insuficiente, tokens esgotados, etc.
          res.status(400).json({ error: err.message || "Erro ao comprar tokens da startup." });
        }
        return;
      }

      // ─── Rota 2: POST /operations/buy-from-user ──────────────────────────
      // Cria uma oferta de compra P2P: o comprador reserva saldo e aguarda
      // que um vendedor aceite a oferta. O saldo fica "travado" até a oferta
      // ser aceita ou cancelada.
      if (method === "POST" && path === "/operations/buy-from-user") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        // pricePerTokenCents: preço que o comprador está disposto a pagar por token (em centavos)
        // validityDays: por quantos dias a oferta fica ativa (padrão: 1 dia)
        const { startupId, quantity, pricePerTokenCents, validityDays } = req.body as {
          startupId: string; quantity: number;
          pricePerTokenCents: number; validityDays?: number;
        };

        // Validação: todos os campos numéricos devem ser positivos
        if (!startupId || !quantity || quantity <= 0 || !pricePerTokenCents || pricePerTokenCents <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos." });
          return;
        }

        try {
          // validityDays ?? 1 garante o valor padrão de 1 dia quando não informado
          const result = await buyFromUser(user.uid, startupId, quantity, pricePerTokenCents, validityDays ?? 1);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao criar oferta de compra." });
        }
        return;
      }

      // ─── Rota 3: POST /operations/sell ───────────────────────────────────
      // Cria uma oferta de venda P2P: o vendedor anuncia tokens com um preço
      // pedido, aguardando que um comprador interessado aceite.
      if (method === "POST" && path === "/operations/sell") {
        const user = await authenticateUser(req, res);
        if (!user) return;

        // askedPricePerTokenCents: preço pedido pelo vendedor por token (em centavos)
        const { startupId, quantity, askedPricePerTokenCents } = req.body as {
          startupId: string; quantity: number; askedPricePerTokenCents: number;
        };

        // Todos os campos devem ser positivos e presentes
        if (!startupId || !quantity || quantity <= 0 || !askedPricePerTokenCents || askedPricePerTokenCents <= 0) {
          res.status(400).json({ error: "Parâmetros inválidos." });
          return;
        }

        try {
          // Chama a função `sell` do repositório (importada sem alias aqui)
          const result = await sell(user.uid, startupId, quantity, askedPricePerTokenCents);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao criar oferta de venda." });
        }
        return;
      }

      // ─── Rota 4: PATCH /operations/:id/accept ───────────────────────────
      // Um vendedor aceita uma oferta de compra pendente criada por outro usuário.
      // A transação transfere tokens do vendedor para o comprador e ajusta saldos.
      // O regex captura o ID dinâmico da operação no path.
      const matchAccept = path.match(/^\/operations\/([^/]+)\/accept$/);
      if (method === "PATCH" && matchAccept) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          // matchAccept[1] é o ID da operação capturado pelo grupo regex ([^/]+)
          const result = await acceptOperation(user.uid, matchAccept[1]);
          res.json({ success: true, ...result });
        } catch (err: any) {
          res.status(400).json({ error: err.message || "Erro ao aceitar oferta." });
        }
        return;
      }

      // ─── Rota 5: PATCH /operations/:id/reject ───────────────────────────
      // Cancela/rejeita uma operação pendente. Apenas o criador da oferta
      // pode rejeitá-la. Se for oferta de compra, o saldo reservado é liberado.
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

      // ─── Rota 6: GET /operations/pending/:startupId ─────────────────────
      // Lista todas as ofertas de compra pendentes (type=buy_from_user, status=pending)
      // de uma startup. Usado por vendedores para encontrar ofertas que podem aceitar.
      const matchPending = path.match(/^\/operations\/pending\/([^/]+)$/);
      if (method === "GET" && matchPending) {
        const user = await authenticateUser(req, res);
        if (!user) return;
        try {
          // matchPending[1] é o startupId capturado pelo regex
          const ops = await getPendingBuyOperations(matchPending[1]);
          res.json({ success: true, operations: ops });
        } catch (err: any) {
          res.status(500).json({ error: err.message || "Erro ao listar operações pendentes." });
        }
        return;
      }

      // ─── Rota 7: GET /operations/user/:userId ───────────────────────────
      // Lista todas as operações de um usuário (como comprador e como vendedor).
      // O repositório faz duas queries e elimina duplicatas pelo ID do documento.
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

      // ─── Rota 8: GET /operations/startup/:startupId ─────────────────────
      // Lista todas as operações registradas para uma startup específica.
      // Útil para o painel administrativo ou auditoria de negociações.
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

      // Se nenhuma rota acima foi correspondida, retorna 404 com a rota tentada
      // para facilitar o diagnóstico de chamadas incorretas.
      res.status(404).json({ error: `Rota não encontrada: ${method} ${path}` });
    } catch (globalError: any) {
      // Captura qualquer erro inesperado não tratado pelos try/catch internos.
      // Retorna 500 genérico para não expor detalhes internos ao cliente.
      res.status(500).json({ error: globalError.message || "Erro interno do servidor." });
    }
  });
});
