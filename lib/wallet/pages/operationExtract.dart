// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote base do Flutter para construir a interface visual (as "peças de Lego" da tela)
import 'package:flutter/material.dart';

// Formatador de moeda — transforma um double (como 1250.0) em string formatada ("R$ 1.250,00")
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

/// Tela de Comprovante de Operação (Extrato da Operação).
/// Pense nela como o recibozinho de papel que o caixa eletrônico imprime,
/// mas numa versão digital e bonita, seguindo o padrão visual limpo.
/// Exibe os detalhes de uma transação específica no formato de recibo,
/// sem campos de edição (pois transações passadas não mudam).
///
/// Essa tela é navegada a partir dos tiles (cartões) de transação — ao tocar em
/// qualquer operação do extrato, o usuário é levado para cá para ver os detalhes.
class OperationExtractPage extends StatelessWidget {
  // Mapa com os dados da transação (como um envelope cheio de informações).
  // Esperamos chaves como: icon, title, date, value, isCredit, type, id, subtitle.
  final Map<String, dynamic> tx;

  // Construtor: exige os dados da transação para poder montar a tela.
  const OperationExtractPage({super.key, required this.tx});

  // Cor principal da aplicação — nosso verde "MesclaInvest", salvo aqui para facilitar o uso.
  static const Color primaryGreen = Color(0xFF107649);

  @override
  Widget build(BuildContext context) {
    // Determina se a operação é um crédito (entrada de dinheiro, ex: depósito recebido).
    // O ?? false é uma proteção: se não vier essa informação, assumimos que é débito para não dar erro.
    final bool isCredit = tx['isCredit'] ?? false;

    // Define a cor do valor: verde para crédito (ganho), vermelho para débito (gasto).
    // Isso é crucial para o usuário bater o olho e já saber se a conta "engordou" ou "emagreceu".
    final Color valueColor = isCredit
        ? const Color(0xFF2ECC71) // Verde vivo — dinheiro entrando
        : const Color(0xFFE74C3C); // Vermelho de alerta — dinheiro saindo

    // Scaffold é a estrutura básica da página (tela), como as paredes de uma casa
    return Scaffold(
      // AppBar é o cabeçalho superior. Aqui fazemos ele transparente com botão de fechar (X)
      // no lugar da seta padrão de voltar. Isso dá uma cara de "modal" (janela sobreposta).
      appBar: AppBar(
        backgroundColor: Colors
            .transparent, // Fundo transparente para não quebrar a cor da tela
        elevation: 0, // Sem sombra, estilo flat e moderno
        // leading é o botão que fica no começo (esquerda)
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          // Ao pressionar, chamamos Navigator.pop para fechar este recibo e voltar de onde viemos
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Corpo da tela envolto em SafeArea para evitar que a UI fique sob o notch ou barra de status
      body: SafeArea(
        // SingleChildScrollView permite rolar a tela se o conteúdo for maior que a altura do celular.
        // Muito importante para evitar o temido erro de overflow (faixa amarela e preta) em telas menores.
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(), // Efeito de "borracha" ao puxar no limite da tela (estilo iOS)
          child: Padding(
            // Margens laterais (horizontal) e superior/inferior (vertical) para dar respiro
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .center, // Centraliza os elementos no meio da tela
              children: [
                // ── Cabeçalho do Comprovante ──────────────────────────
                // Ícone circular grande no topo para identificar visualmente o tipo de operação
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    // Fundo verde translúcido para criar uma "cama" suave para o ícone
                    color: primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle, // Deixa a caixa redonda
                  ),
                  child: Center(
                    child: Icon(
                      // Tenta usar o ícone que veio nos dados; se não tiver, usa um ícone de recibo genérico
                      tx['icon'] as IconData? ?? Icons.receipt_long_rounded,
                      color: primaryGreen,
                      size: 32, // Ícone grandão
                    ),
                  ),
                ),
                // Espacinho vertical de respiro
                const SizedBox(height: 24),

                // Título principal do comprovante (ex: "Depósito", "Transferência enviada")
                Text(
                  tx['title'] ?? 'Comprovante',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700, // Negrito para chamar atenção
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Data e hora da operação.
                // Usamos uma cor com opacidade (alpha: 0.5) para ficar mais discreto e não competir com o título.
                Text(
                  tx['date'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Card com o Valor da Transação ──────────────────────────────
                // Este é o elemento mais importante do recibo, então colocamos dentro de uma caixa destacada
                Container(
                  width: double.infinity, // Ocupa toda a largura disponível
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    // Fundo quase transparente para criar uma leve diferença em relação ao fundo da tela
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // Cantos bem arredondados
                    border: Border.all(
                      // Uma bordinha super fina para dar noção de limite do cartão
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Texto de ajuda (label) avisando o que é aquele número gigante abaixo
                      Text(
                        'Valor da Operação',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // O valor em si, formatado bonitinho com o R$
                      Text(
                        CurrencyInputFormatter.formatValue(
                          tx['value'] as double? ?? 0.0,
                        ),
                        style: TextStyle(
                          // A cor aqui já foi decidida lá em cima: verde se entrou, vermelho se saiu
                          color: valueColor,
                          fontSize: 36, // Fonte enorme
                          fontWeight: FontWeight.w800, // Extra bold
                          letterSpacing:
                              -1, // Aproxima um pouco os números para parecer mais compacto e elegante
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Card de Detalhes Adicionais ─────────────────────────────
                // Exibe informações técnicas, como tipo real da operação, descrição e ID no banco de dados.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    // Mesmo estilo visual do card de cima para manter a consistência
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Linha 1: Tipo da operação no sistema (ex: "DEPOSITO")
                      _buildDetailRow(
                        'Tipo',
                        tx['type']?.toString().toUpperCase() ?? 'DESCONHECIDO',
                      ),
                      // Linha separadora, bem sutil
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white12, height: 1),
                      ),
                      // Linha 2: Descrição ou recado deixado na operação
                      _buildDetailRow(
                        'Descrição',
                        tx['subtitle']?.isNotEmpty == true
                            ? tx['subtitle']
                            : 'Sem descrição', // Se o recado for vazio, a gente avisa
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white12, height: 1),
                      ),
                      // Linha 3: O RG da transação no banco de dados (Firestore)
                      // Isso é ótimo pra suporte, caso o usuário precise reclamar de um erro.
                      _buildDetailRow(
                        'ID da Transação',
                        tx['id'] ?? 'Não disponível',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Botão de Voltar ─────────────────────────────────────
                // Botão de ação principal pra fechar e sair daqui.
                SizedBox(
                  width: double.infinity, // Estica até as bordas
                  height: 56, // Altura confortável para o dedo tocar sem errar
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context), // Equivalente ao X lá de cima
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF107649,
                      ), // Nosso verde padrão
                      foregroundColor: Colors.white, // Cor do texto do botão
                      elevation:
                          0, // Tiramos a sombra pra ficar mais flat/moderno
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ), // Espaço extra no fim da tela, pra quem rola até o talo
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói uma linha de detalhe no formato "chave — valor".
  /// Por exemplo: "Tipo" na esquerda, "SAQUE" na direita.
  /// Transformamos isso num método separado (`_buildDetailRow`) para não poluir
  /// a árvore de widgets (o `build`) escrevendo a mesma lógica 3 vezes.
  Widget _buildDetailRow(String label, String value) {
    // Row emparelha coisas lado a lado na horizontal
    return Row(
      // spaceBetween joga o primeiro filho pra esquerda e o último pra direita
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // Alinha os topos (útil caso o texto da direita quebre em várias linhas)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O "rótulo" (chave) fica com uma cor mais apagada pra criar uma hierarquia visual.
        // Se ambos tivessem a mesma cor forte, nosso cérebro demoraria mais pra ler.
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          width: 16,
        ), // Dá uma distância de segurança caso os dois textos se encontrem
        // O valor propriamente dito.
        // O `Expanded` garante que, se o texto for gigante, ele desce pra próxima linha
        // em vez de quebrar a tela (overflow).
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600, // Destacado
            ),
            textAlign: TextAlign.right, // Mantém ele empurrado pra direita
          ),
        ),
      ],
    );
  }
}
