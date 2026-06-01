// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Importa a função de autenticação do Firebase Admin SDK.
import {getAuth} from "firebase-admin/auth";

// `getApps` retorna a lista de apps Firebase já inicializados.
// `initializeApp` inicializa o app Firebase Admin com as credenciais do ambiente.
import {getApps, initializeApp} from "firebase-admin/app";

// `getFirestore` retorna a instância do banco de dados Firestore.
import {getFirestore} from "firebase-admin/firestore";

// Garante que o Firebase Admin só é inicializado uma vez.
// Em ambientes de Cloud Functions, o módulo pode ser carregado múltiplas vezes — essa
// verificação evita o erro "Firebase app named '[DEFAULT]' already exists".
if (getApps().length === 0) {
  initializeApp();
}

// Exporta a instância de autenticação para ser usada nos módulos que precisam verificar
// ou criar usuários programaticamente.
export const auth = getAuth();

// Exporta a instância do Firestore — todos os módulos importam `db` daqui,
// garantindo que sempre usem a mesma conexão ao banco.
export const db = getFirestore();
