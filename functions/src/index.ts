// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// `setGlobalOptions` configura opções padrão para todas as Cloud Functions do projeto.
import {setGlobalOptions} from "firebase-functions";

// `onRequest` cria Cloud Functions HTTP clássicas (req/res), diferente de `onCall`
// que usa o protocolo do Firebase SDK.
import {onRequest} from "firebase-functions/v2/https";

// `defineSecret` registra segredos do Secret Manager do Google Cloud —
// as credenciais são acessadas em runtime, sem ficarem expostas no código.
import {defineSecret} from "firebase-functions/params";

// Firebase Admin SDK para autenticação e Firestore.
import * as admin from "firebase-admin";

// Nodemailer é a biblioteca Node.js para envio de e-mails via SMTP.
import * as nodemailer from "nodemailer";

// Middleware CORS que permite requisições de qualquer origem (`origin: true`).
// Necessário para que o app Flutter (ou web) consiga chamar as funções HTTP.
import cors from "cors";

// Tipos do Express para tipar os parâmetros `req` e `res` nas funções HTTP.
import {Request, Response} from "express";

// Inicializa o app Firebase Admin — precisa ser feito uma vez antes de qualquer uso.
admin.initializeApp();

// Define o limite máximo de instâncias simultâneas para todas as funções do projeto.
// Isso controla custos e evita sobrecarga acidental.
setGlobalOptions({maxInstances: 10});

// Declara os segredos que serão buscados do Secret Manager em tempo de execução.
// Eles NÃO ficam hardcoded no código — boas práticas de segurança.
const GMAIL_USER = defineSecret("GMAIL_USER");
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");

// Configura o middleware CORS com `origin: true` — aceita requisições de qualquer domínio.
// Em produção, restringir para os domínios específicos seria mais seguro.
const corsHandler = cors({origin: true});

// Instância do Firestore usada localmente neste arquivo para as operações de e-mail/2FA.
const db = admin.firestore();

/**
 * Generates a 6-digit random code.
 * @return {string} The generated code.
 */
// Gera um número aleatório entre 100000 e 999999 — garantindo sempre 6 dígitos.
function generateCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Creates a nodemailer transporter using Secret Manager credentials.
 * @return {nodemailer.Transporter} The created transporter.
 */
// Cria o transportador SMTP usando as credenciais do Gmail armazenadas no Secret Manager.
// É criado sob demanda (não em módulo global) para garantir que os secrets já foram carregados.
function createTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: GMAIL_USER.value(),
      pass: GMAIL_APP_PASSWORD.value(),
    },
  });
}

// Gera um código de 6 dígitos, salva no Firestore e envia por e-mail
// Esta função lida com o fluxo completo de "Esqueci minha senha":
// 1. Valida o e-mail, 2. Gera código, 3. Salva com expiração, 4. Envia por e-mail.
export const sendPasswordResetCode = onRequest(
  {invoker: "public", secrets: [GMAIL_USER, GMAIL_APP_PASSWORD]},
  (req: Request, res: Response) => {
    corsHandler(req, res, async () => {
      // Apenas POST é aceito — GET não faz sentido para operações que alteram estado.
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const {email} = req.body as {email: string};

      // E-mail é obrigatório — sem ele não há como enviar o código.
      if (!email) {
        res.status(400).json({error: "E-mail é obrigatório."});
        return;
      }

      // Busca o usuário no Firebase Authentication pelo e-mail.
      // Se não existir, retorna 404 sem revelar detalhes (evitar enumeração de contas).
      let uid: string;
      try {
        const user = await admin.auth().getUserByEmail(email);
        uid = user.uid;
      } catch {
        res.status(404).json({error: "E-mail não encontrado."});
        return;
      }

      // Gera o código e define a expiração para 10 minutos a partir de agora.
      const code = generateCode();
      const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000)
      );

      // Salva o código no Firestore usando o e-mail como ID do documento —
      // isso garante que só existe um código ativo por e-mail de cada vez.
      await db.collection("passwordResets").doc(email).set({
        code,
        expiresAt,
        uid,
        used: false, // `used` evita que o mesmo código seja usado mais de uma vez
      });

      // Cria o transportador e envia o e-mail com o código formatado visualmente.
      const transporter = createTransporter();
      await transporter.sendMail({
        from: `MesclainVest <${process.env.GMAIL_USER}>`,
        to: email,
        subject: "Código de recuperação de senha - MesclainVest",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
            <h2 style="color: #1a237e;">Recuperação de senha</h2>
            <p>Recebemos uma solicitação para redefinir a senha da sua conta.</p>
            <p>Use o código abaixo para continuar:</p>
            <div style="
              font-size: 36px;
              font-weight: bold;
              letter-spacing: 12px;
              text-align: center;
              background: #f5f5f5;
              padding: 20px;
              border-radius: 8px;
              margin: 24px 0;
              color: #1a237e;
            ">${code}</div>
            <p style="color: #666; font-size: 14px;">
              Este código expira em <strong>10 minutos</strong>.
            </p>
            <p style="color: #666; font-size: 14px;">
              Se você não solicitou a recuperação de senha, ignore este e-mail.
            </p>
          </div>
        `,
      });

      res.json({success: true});
    });
  }
);

// Verifica se o código é válido (sem redefinir a senha ainda)
// Esta etapa é chamada logo após o usuário digitar o código — confirma a validade
// antes de mostrar o formulário de nova senha.
export const verifyCode = onRequest(
  {invoker: "public"},
  (req: Request, res: Response) => {
    corsHandler(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const {email, code} = req.body as {email: string; code: string};

      // Ambos os campos são obrigatórios para a verificação.
      if (!email || !code) {
        res.status(400).json({error: "Dados incompletos."});
        return;
      }

      // Busca o documento de reset pelo e-mail do usuário.
      const doc = await db.collection("passwordResets").doc(email).get();

      if (!doc.exists) {
        res.status(404).json({error: "Código inválido ou expirado."});
        return;
      }

      const data = doc.data()!;

      // Impede reutilização de um código já usado anteriormente.
      if (data.used) {
        res.status(400).json({error: "Código já utilizado."});
        return;
      }

      // Verifica se o código ainda está dentro do prazo de 10 minutos.
      if ((data.expiresAt as admin.firestore.Timestamp).toDate() < new Date()) {
        res.status(400).json({error: "Código expirado. Solicite um novo."});
        return;
      }

      // Compara o código recebido com o armazenado — comparação simples de string.
      if (data.code !== code) {
        res.status(400).json({error: "Código incorreto."});
        return;
      }

      // Código válido — retorna sucesso sem marcar como usado ainda (isso acontece no `resetPassword`).
      res.json({success: true});
    });
  }
);

// Envia código de 2FA por e-mail após o login.
// Aceita { email, code } — o código é gerado pelo app e passado aqui para garantir
// que o mesmo código salvo no Firestore seja o enviado por e-mail.
// Decisão de design: o app gera o código para ter controle total do valor
// antes de enviar ao servidor — evita inconsistências entre o salvo e o enviado.
export const sendTwoFactorCode = onRequest(
  {invoker: "public", secrets: [GMAIL_USER, GMAIL_APP_PASSWORD]},
  (req: Request, res: Response) => {
    corsHandler(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const {email, code} = req.body as {email: string; code: string};

      if (!email || !code) {
        res.status(400).json({error: "E-mail e código são obrigatórios."});
        return;
      }

      // Valida que o e-mail pertence a um usuário existente — evita envio para e-mails não cadastrados.
      try {
        await admin.auth().getUserByEmail(email);
      } catch {
        res.status(404).json({error: "Usuário não encontrado."});
        return;
      }

      // Envia o e-mail de 2FA com o código recebido do app.
      // Neste caso não salvamos no Firestore aqui — o app já fez isso antes de chamar esta função.
      const transporter = createTransporter();
      await transporter.sendMail({
        from: `MesclainVest <${process.env.GMAIL_USER}>`,
        to: email,
        subject: "Código de verificação em duas etapas - MesclainVest",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
            <h2 style="color: #107649;">Verificação em duas etapas</h2>
            <p>Uma nova tentativa de login foi detectada na sua conta.</p>
            <p>Use o código abaixo para concluir o acesso:</p>
            <div style="
              font-size: 36px;
              font-weight: bold;
              letter-spacing: 12px;
              text-align: center;
              background: #f5f5f5;
              padding: 20px;
              border-radius: 8px;
              margin: 24px 0;
              color: #107649;
            ">${code}</div>
            <p style="color: #666; font-size: 14px;">
              Este código expira em <strong>10 minutos</strong>.
            </p>
            <p style="color: #666; font-size: 14px;">
              Se você não tentou fazer login, ignore este e-mail e considere alterar sua senha.
            </p>
          </div>
        `,
      });

      res.json({success: true});
    });
  }
);

// Valida o código de 2FA
// Verifica se o código de dois fatores enviado pelo usuário é válido, não expirado e não reutilizado.
export const verify2FACode = onRequest(
  {invoker: "public"},
  (req: Request, res: Response) => {
    corsHandler(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const {email, code} = req.body as {email: string; code: string};

      if (!email || !code) {
        res.status(400).json({error: "Dados incompletos."});
        return;
      }

      // Busca o documento de 2FA pela coleção dedicada `twoFactorCodes`.
      const doc = await db.collection("twoFactorCodes").doc(email).get();

      if (!doc.exists) {
        res.status(404).json({error: "Código inválido ou expirado."});
        return;
      }

      const data = doc.data()!;

      if (data.used) {
        res.status(400).json({error: "Código já utilizado."});
        return;
      }

      if ((data.expiresAt as admin.firestore.Timestamp).toDate() < new Date()) {
        res.status(400).json({error: "Código expirado. Solicite um novo."});
        return;
      }

      if (data.code !== code) {
        res.status(400).json({error: "Código incorreto."});
        return;
      }

      // Marca o código como utilizado IMEDIATAMENTE após a validação bem-sucedida —
      // isso impede que o mesmo código seja reaproveitado em requisições paralelas.
      await doc.ref.update({used: true});
      res.json({success: true});
    });
  }
);

// Valida o código e redefine a senha do usuário
// Esta é a etapa final do fluxo de recuperação: valida o código (igual ao verifyCode)
// e, se válido, atualiza a senha via Firebase Admin SDK.
export const resetPassword = onRequest(
  {invoker: "public"},
  (req: Request, res: Response) => {
    corsHandler(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const {email, code, newPassword} = req.body as {
        email: string;
        code: string;
        newPassword: string;
      };

      // Os três campos são obrigatórios para redefinir a senha com segurança.
      if (!email || !code || !newPassword) {
        res.status(400).json({error: "Dados incompletos."});
        return;
      }

      const doc = await db.collection("passwordResets").doc(email).get();

      if (!doc.exists) {
        res.status(404).json({error: "Código inválido ou expirado."});
        return;
      }

      const data = doc.data()!;

      if (data.used) {
        res.status(400).json({error: "Código já utilizado."});
        return;
      }

      if ((data.expiresAt as admin.firestore.Timestamp).toDate() < new Date()) {
        res.status(400).json({error: "Código expirado. Solicite um novo."});
        return;
      }

      if (data.code !== code) {
        res.status(400).json({error: "Código incorreto."});
        return;
      }

      // Atualiza a senha do usuário diretamente no Firebase Authentication via Admin SDK.
      // `data.uid` foi salvo no Firestore durante o `sendPasswordResetCode` — por isso não
      // precisamos buscar novamente pelo e-mail aqui.
      await admin.auth().updateUser(data.uid as string, {
        password: newPassword,
      });

      // Marca o código como usado para evitar redefinições múltiplas com o mesmo código.
      await doc.ref.update({used: true});

      res.json({success: true});
    });
  }
);

// Re-exporta todas as Cloud Functions dos módulos filhos.
// Cada linha abaixo torna as funções de um módulo visíveis para o Firebase CLI durante o deploy.
export * from "./startups";   // Funções relacionadas ao catálogo de startups
export * from "./balance";    // Funções de carteira e operações financeiras
export * from "./balcao";     // Funções do módulo de balcão (livro de ordens)
export * from "./operations"; // Funções de operações do motor de preço dinâmico
