// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

/// Enum que define os "chapéus" (papéis ou roles) que os usuários podem usar no MesclaInvest.
///
/// Sabe aquele crachá que diz onde você pode entrar na empresa? O Role é exatamente isso.
/// Ele molda toda a experiência do usuário dentro do app:
/// - Se for [investidor], a home mostra o catálogo e a carteira de ativos.
/// - Se for [empreendedor], abre a dashboard de gestão da startup dele.
/// - Se for [admin], abre as telas de moderação (o "painel de controle" do app).
///
/// Dica de arquitetura: Armazenar isso como enum no model evita aquele erro clássico 
/// de `if (role == "adminn")` passar batido e criar uma falha de segurança ou navegação.
enum UserRole {
  /// O "cliente" principal do app. Quem tem o dinheiro e está buscando oportunidades 
  /// em startups promissoras. Só vê o que está público (status.ativa).
  investidor,

  /// O dono do negócio. Ele que cria a startup, emite os tokens e pede captação.
  /// A interface dele é focada em métricas e gestão de sócios.
  empreendedor,

  /// O superusuário. Tem o poder de aprovar/reprovar startups, cancelar operações 
  /// suspeitas e gerenciar a plataforma como um todo. Cuidado com quem recebe isso!
  admin,
}
