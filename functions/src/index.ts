import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import cors from "cors";
import {Request, Response} from "express";

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const corsHandler = cors({origin: true});
const db = admin.firestore();

function generateCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function createTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_APP_PASSWORD,
    },
  });
}

// Gera um código de 6 dígitos, salva no Firestore e envia por e-mail
export const sendPasswordResetCode = onRequest(
  {invoker: "public"},
  (req: Request, res: Response) => {
    corsHandler(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      const {email} = req.body as {email: string};

      if (!email) {
        res.status(400).json({error: "E-mail é obrigatório."});
        return;
      }

      let uid: string;
      try {
        const user = await admin.auth().getUserByEmail(email);
        uid = user.uid;
      } catch {
        res.status(404).json({error: "E-mail não encontrado."});
        return;
      }

      const code = generateCode();
      const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000)
      );

      await db.collection("passwordResets").doc(email).set({
        code,
        expiresAt,
        uid,
        used: false,
      });

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

// Valida o código e redefine a senha do usuário
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

      await admin.auth().updateUser(data.uid as string, {password: newPassword});
      await doc.ref.update({used: true});

      res.json({success: true});
    });
  }
);
