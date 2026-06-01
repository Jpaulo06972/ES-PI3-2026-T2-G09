// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Este arquivo é o ponto de entrada (barrel) do módulo `balance`.
// Ele re-exporta as Cloud Functions do módulo para que possam ser registradas
// no `index.ts` principal com um simples `export * from "./balance"`.

// Re-exporta `listMyOperations` com o alias `getListOperations` — o alias
// é o nome que o app Flutter vai usar para chamar a função via Firebase SDK.
export {listMyOperations as getListOperations} from "./handlers/listMyOperations";

// Re-exporta `createOperation` diretamente, mantendo o mesmo nome de chamada.
export {createOperation} from "./handlers/createOperation";
