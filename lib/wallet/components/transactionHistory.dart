// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote básico de UI do Flutter (como a caixa de ferramentas de construção)
import 'package:flutter/material.dart';

// Importa a paleta de cores oficial do módulo de startups para manter consistência visual (identidade visual)
import 'package:mesclainvest_f/startups/components/startup_colors.dart';
// Importa o formatador de moeda para garantir que o dinheiro seja exibido corretamente (ex: R$ 10,00)
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
// Importa a página de detalhes da transação (para onde vamos ao clicar em um item)
import 'package:mesclainvest_f/wallet/pages/operationExtract.dart';

/// Exibe o histórico de transações recentes no estilo das telas de startups.
/// Cada transação é um card com fundo cardBg, bordas sutis e valores coloridos.
/// Pense nisso como um mini-extrato bancário que fica na tela principal da carteira.
class TransactionHistory extends StatelessWidget {
  // Lista de transações — cada item é um Map com icon, title, date, value, isCredit.
  // Recebemos essa lista de fora para que o componente seja reutilizável e apenas "mostre" os dados.
  final List<Map<String, dynamic>> transactions;

  // Callback (função) quando o botão "Ver tudo" é tocado.
  // Isso permite que o "pai" deste widget decida para onde o usuário vai ao clicar.
  final VoidCallback onViewAll;

  // Construtor: exige as transações e a função de clique.
  const TransactionHistory({
    super.key,
    required this.transactions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos Column porque os elementos estão empilhados verticalmente (cabeçalho em cima, lista embaixo)
    return Column(
      // Alinha tudo à esquerda
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção no padrão _SectionTitle + botão "Ver tudo" verde
        // Row permite colocar o título de um lado e o botão do outro
        Row(
          // Espalha os filhos (um fica na extrema esquerda, outro na extrema direita)
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Título da seção
            const Text(
              "ÚLTIMAS TRANSAÇÕES",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                // Dá um espacinho entre as letras para ficar mais elegante
                letterSpacing: 1.5,
              ),
            ),
            // Botão interativo "Ver tudo"
            // GestureDetector é o que faz o texto reagir ao toque
            GestureDetector(
              onTap: onViewAll, // Chama a função passada no construtor
              child: const Text(
                "Ver tudo",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        // Um pequeno espaço entre o cabeçalho e a lista
        const SizedBox(height: 12),

        // Lista de transações renderizada dinamicamente
        // O '.map' transforma cada "dado" (map) em um "visual" (widget)
        // O '...' (spread operator) espalha a lista resultante dentro dos filhos da Column
        ...transactions.map((tx) => _buildTransactionTile(context, tx)),
      ],
    );
  }

  /// Constrói um tile individual de transação no estilo cardBg das startups.
  /// Recebe o `context` (para navegação) e o `tx` (os dados da transação).
  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> tx) {
    // Verifica se a transação é de entrada (crédito) ou saída (débito)
    final bool isCredit = tx['isCredit'] as bool;

    // Verde para créditos, vermelho para débitos — mesmo padrão de cores das startups
    // Isso ajuda o usuário a bater o olho e entender se ganhou ou perdeu dinheiro
    final Color valueColor = isCredit
        ? const Color(0xFF107649) // Verde escuro elegante
        : const Color(0xFFE74C3C); // Vermelho clássico de alerta

    // Container age como uma "caixa" que engloba a transação
    return Container(
      // Espaço entre um card e outro (margem em baixo)
      margin: const EdgeInsets.only(bottom: 10),
      // Espaço interno (padding) para o conteúdo não colar na borda
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Mesmo fundo cardBg das telas de startups (consistência visual)
        color: StartupColors.cardBg,
        // Deixa os cantos arredondados
        borderRadius: BorderRadius.circular(16),
        // Borda super sutil (branca quase transparente) para dar um efeito de profundidade
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      // InkWell dá o efeito de "onda" (ripple) ao clicar
      child: InkWell(
        onTap: () {
          // Quando clicado, navega para a página de detalhes daquela transação
          Navigator.push(
            context,
            MaterialPageRoute(
              // Passa os dados 'tx' para a tela OperationExtractPage
              builder: (_) => OperationExtractPage(tx: tx),
            ),
          );
        },
        // O raio do InkWell deve acompanhar o raio do Container para o efeito visual não vazar
        borderRadius: BorderRadius.circular(16),
        // Row para colocar o ícone à esquerda, os textos no meio, e o valor à direita
        child: Row(
          children: [
            // Ícone dentro de círculo com cor de fundo translúcida
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                // Usa a mesma cor do valor (verde ou vermelho), mas bem transparente (0.15)
                color: valueColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                // O ícone em si, pintado com a cor forte
                child: Icon(
                  tx['icon'] as IconData,
                  color: valueColor,
                  size: 20,
                ),
              ),
            ),
            // Espaçamento entre o ícone e os textos
            const SizedBox(width: 12),
            // Expanded faz com que essa coluna do meio ocupe todo o espaço restante disponível
            // Isso empurra o valor (o último filho da Row) lá para o final à direita
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título da transação (ex: "Depósito", "Investimento em Startup X")
                  Text(
                    tx['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    // Se o texto for muito longo, corta e coloca "..." (ellipsis)
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Data da transação com texto menor e mais opaco para não roubar a atenção
                  Text(
                    tx['date'] as String,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Valor da transação com sinal de + ou - em verde/vermelho
            Text(
              // Monta a string: sinal + ou - , espaço, e o valor formatado bonitinho em R$
              "${isCredit ? '+' : '-'} ${CurrencyInputFormatter.formatValue(tx['value'] as double)}",
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
