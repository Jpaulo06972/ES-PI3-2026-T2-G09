// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

/// Uma BottomSheet (Puxadinho que sobe da tela) super elegante para a compra primária de tokens.
///
/// Imagina que o usuário clicou no botão "Investir" na tela da startup. Em vez de
/// jogar ele pra outra tela e tirar do contexto, a gente sobe esse cardzinho com 
/// a matemática já mastigada para ele finalizar a compra ali mesmo!
class DirectPurchaseSheet extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double pricePerToken;
  final UserModel userModel;
  
  // Isso aqui ajuda na UX: fala pro usuário quantos ele já tem na bag.
  final double userHoldings;

  const DirectPurchaseSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.pricePerToken,
    required this.userModel,
    required this.userHoldings,
  });

  @override
  State<DirectPurchaseSheet> createState() => _DirectPurchaseSheetState();
}

class _DirectPurchaseSheetState extends State<DirectPurchaseSheet> {
  // O Service é quem de fato suja as mãos e chama as APIs ou o Firestore!
  final CounterService _service = CounterService();
  
  // A quantidade de tokens. A gente sempre começa vendendo pelo menos 1, certo?
  double _qty = 1;
  
  // Proteção dupla! Se tiver true, mostramos um spinner no botão e não deixamos ele clicar duas vezes.
  bool _isSubmitting = false;
  
  // Guarda o textinho do erro que o servidor cuspiu, caso aconteça alguma zika.
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    // Calculadora do App: multiplica a quantia escolhida pelo preço. Simples.
    final double totalCost = _qty * widget.pricePerToken;
    final double availableBalance = widget.userModel.saldo;
    
    // O cara tem grana suficiente na carteira?
    final bool hasBalance = availableBalance >= totalCost;

    return Container(
      // Esse padding é o pulo do gato! Ele levanta o sheet automaticamente quando o teclado virtual abre
      // garantindo que os botões não sumam debaixo dos dedos do usuário.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22), // Fundo quase preto (Dark mode style)
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Só ocupa o espaço que ele realmente precisa!
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aquele "tracinho" no topo que indica para o usuário que a janela pode ser arrastada pra baixo.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // O Cabeçalho: Nome e o fechar.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.startupName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'COMPRA DIRETA DA STARTUP',
                          style: TextStyle(
                            color: Color(0xFF1A9B5F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botãozinho "X" no topo direito pra fechar se o cara desistir.
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Aqui tem dois blocos dividindo a tela. Um pro Preço e outro pra Bag.
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      'Preço por token',
                      // Passa o valor no formatador mágico que já bota o "R$" e a pontuação br.
                      CurrencyInputFormatter.formatValue(widget.pricePerToken),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      'Seus tokens',
                      widget.userHoldings.toInt().toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Componente interativo! O clássico Stepper: [-] Valor [+]
              const Text(
                'Quantidade de tokens',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF107649).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    // Botãozinho de menos
                    _buildStepBtn(
                      icon: Icons.remove,
                      onTap: () {
                        // Não pode comprar 0 tokens, né? Travamos no mínimo 1.
                        if (_qty > 1) setState(() => _qty--);
                      },
                    ),
                    Expanded(
                      child: Text(
                        _qty.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    // Botãozinho de mais
                    _buildStepBtn(
                      icon: Icons.add,
                      onTap: () {
                        setState(() => _qty++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // O Sumário de Compra. Isso aqui que vai doer no bolso.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF141416), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Total a pagar',
                      CurrencyInputFormatter.formatValue(totalCost),
                      highlight: true, // Mostra o valor pintadão de verde
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      'Saldo disponível',
                      CurrencyInputFormatter.formatValue(availableBalance),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feedbacks de erro para o usuário não ficar frustrado com botão cinza.
              // A gente tem que avisar ele do porquê o botão travou!
              if (!hasBalance)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Saldo disponível insuficiente',
                        style: TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE74C3C), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // O Botão de Check-out Final.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Se a conta fecha e não ta rodando, bota verde. Se não, fica cinza fosco (desativado).
                    backgroundColor: hasBalance && !_isSubmitting ? const Color(0xFF107649) : Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  // Desliga o OnPressed passando null quando faltou grana ou tá rodando request.
                  onPressed: hasBalance && !_isSubmitting ? _confirmPurchase : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Confirmar Compra',
                          style: TextStyle(
                            color: hasBalance && !_isSubmitting ? Colors.white : Colors.white38,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Célula reutilizável para mostrar dados no cabeçalho
  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Construir o botão interativo + ou -
  Widget _buildStepBtn({required IconData icon, required VoidCallback onTap}) {
    // Usamos InkWell pra dar a ondinha gostosa do toque nativo do sistema
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }

  // Linhas das totalizações
  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF1A9B5F) : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// O coração do componente! Dispara a request de compra pro Backend.
  void _confirmPurchase() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null; // Limpamos erros passados
    });

    try {
      // Mandamos a bronca pro Service
      final result = await _service.buyTokens(widget.startupId, _qty);
      
      // Avaliamos o retorno num formato legal de Map que o Service montou
      if (result['success'] == true) {
        // Obba! O Firebase subtraiu a grana. A gente atualiza o banco local da view na hora!
        setState(() {
          widget.userModel.saldo = result['updatedBalance'];
        });
        
        // Antes do pop, a gente verifica se o componente ainda existe na árvore.
        if (mounted) {
          // Navigator.pop e passamos TRUE para avisar o chamador: "A transação brilhou!"
          Navigator.pop(context, true);
        }
      } else {
        // Se a Cloud Function lá no Firestore deu erro de validação (ex: Startup tá sem tokens livres).
        setState(() {
          _errorMessage = result['error'] ?? 'Falha ao processar compra de tokens.';
          _isSubmitting = false; // Soltamos o botão pra tentar de novo
        });
      }
    } catch (e) {
      // Se não teve nem rede pra alcançar o servidor, pegamos no catch brabo.
      setState(() {
        _errorMessage = 'Ocorreu um erro ao processar: $e';
        _isSubmitting = false;
      });
    }
  }
}
