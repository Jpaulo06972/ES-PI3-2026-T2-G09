// Aluno: Felipe Batista Bastos
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25005337

import 'package:flutter/material.dart';
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';

/// [SellTokensSheet] é um BottomSheet (aquela gaveta que sobe debaixo da tela)
/// onde o usuário pode VENDER (desinvestir) seus tokens de uma startup diretamente
/// para a plataforma por um preço de recompra fixo (ou variável, dependendo do backend).
/// 
/// UX/UI: É importante que essa tela passe segurança, pois estamos lidando com dinheiro real.
/// A cor de destaque aqui é vermelha (#E74C3C) em vez do tradicional verde, para
/// indicar claramente ao usuário a ação de "Venda/Saída", contrastando com a "Compra".
class SellTokensSheet extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double pricePerToken; // Preço atualizado que a plataforma paga por token
  final UserModel userModel;  // Dados do usuário logado (saldo, etc)
  final double userHoldings;  // Quantos tokens ele tem dessa startup específica

  const SellTokensSheet({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.pricePerToken,
    required this.userModel,
    required this.userHoldings,
  });

  @override
  State<SellTokensSheet> createState() => _SellTokensSheetState();
}

class _SellTokensSheetState extends State<SellTokensSheet> {
  // Serviço que faz a chamada para a Cloud Function (backend)
  final CounterService _service = CounterService();
  
  // Quantidade de tokens que o usuário deseja vender. Começa em 1 por padrão.
  double _qty = 1;
  
  // Flag defensiva para evitar double-tap e proteger a conta do usuário
  bool _isSubmitting = false;
  
  // Armazena a mensagem de erro que vem do backend, caso dê ruim
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Caso extremo: se o usuário tiver menos de 1 token (ex: 0),
    // não podemos deixar a quantidade inicial ser 1. Ajustamos para o máximo que ele tem.
    if (widget.userHoldings < _qty) {
      _qty = widget.userHoldings;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula na hora quanto dinheiro vai cair na conta dele
    final double totalPayout = _qty * widget.pricePerToken;
    
    // Regra de segurança da interface: só deixa vender se ele de fato tiver a quantidade
    // pedida e se a quantidade for maior que zero.
    final bool hasTokens = widget.userHoldings >= _qty && _qty > 0;

    return Container(
      // Esse padding dinâmico (viewInsets.bottom) levanta a gaveta se o teclado do celular abrir,
      // evitando que o teclado cubra os botões.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22), // Cinza chumbo escuro, padrão de modal do nosso app
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      // SafeArea garante que o modal não vá sobrepor a barrinha de gestos do iPhone
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle (aquela pílula cinza no topo que indica que o modal pode ser puxado pra baixo)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabeçalho da gaveta com o nome da Startup e botão de fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.startupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'VENDA DIRETA DE TOKENS',
                          style: TextStyle(
                            color: Color(0xFFE74C3C), // Vermelho de venda
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8, // Dá um ar mais sofisticado
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão de 'X' pra quem prefere clicar a arrastar pra baixo
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Blocos de informação financeira (Boxes)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      'Preço de Recompra',
                      CurrencyInputFormatter.formatValue(widget.pricePerToken),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      'Seus tokens',
                      widget.userHoldings.toInt().toString(), // Mostramos como inteiro para não poluir
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Controle de Quantidade (Stepper - / +)
              const Text(
                'Quantidade de tokens a vender',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141416), // Fundo mais escuro para o controle
                  borderRadius: BorderRadius.circular(14),
                  // Borda com opacidade baixa pra dar um leve brilho
                  border: Border.all(
                    color: const Color(0xFFE74C3C).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Botão de diminuir
                    _buildStepBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (_qty > 1) setState(() => _qty--);
                      },
                    ),
                    // Mostrador de quantidade
                    Expanded(
                      child: Text(
                        _qty.toInt().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // Botão de aumentar
                    _buildStepBtn(
                      icon: Icons.add,
                      onTap: () {
                        // Não deixa tentar vender mais do que ele tem na carteira
                        if (_qty < widget.userHoldings) {
                          setState(() => _qty++);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Resumo da operação (O que vai acontecer se ele apertar o botão)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Você receberá',
                      CurrencyInputFormatter.formatValue(totalPayout),
                      highlight: true, // Dá destaque pro valor monetário
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      'Tokens restantes',
                      (widget.userHoldings - _qty).toInt().toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feedback Visual: Se o cara por algum motivo bizarro tiver um número inválido
              if (!hasTokens)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Holdings insuficientes para esta quantidade.',
                        style: TextStyle(color: Color(0xFFE74C3C), fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // Exibição de erro caso a transação falhe no backend (ex: saldo corrompido, instabilidade)
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

              // Botão de Ação Principal (Call to Action)
              SizedBox(
                width: double.infinity, // Ocupa a largura toda
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Se não tiver token pra vender ou estiver carregando, o botão fica cinza "morto"
                    backgroundColor: hasTokens && !_isSubmitting
                        ? const Color(0xFFE74C3C)
                        : Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  // Trava o clique se já estiver processando
                  onPressed: hasTokens && !_isSubmitting ? _confirmSale : null,
                  child: _isSubmitting
                      // Bolinha de carregamento enquanto o backend pensa
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirmar Venda',
                          style: TextStyle(
                            color: hasTokens && !_isSubmitting ? Colors.white : Colors.white38,
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

  /// Construtor auxiliar para aqueles bloquinhos pequenos com rótulo e valor
  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)), // Borda ultra sutil
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Construtor dos botões redondinhos de - e +
  Widget _buildStepBtn({required IconData icon, required VoidCallback onTap}) {
    // InkWell permite ter aquele efeito de 'splash' (onda de clique) do Material Design
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFFE74C3C), size: 22),
      ),
    );
  }

  /// Construtor de cada linha do Resumo (label esquerdo, valor na direita)
  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            // Se for destaque, pinta de vermelho pra chamar atenção
            color: highlight ? const Color(0xFFE74C3C) : Colors.white,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Função crítica de negócio: dispara o pedido de venda para o servidor
  void _confirmSale() async {
    // Trava a tela e apaga erros velhos
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Chama o backend (Cloud Functions)
      final result = await _service.sellTokens(widget.startupId, _qty);
      
      // Checa a flag de sucesso do Map retornado
      if (result['success'] == true) {
        // Atualiza saldo localmente para refletir imediatamente sem precisar recarregar o usuário do banco
        setState(() {
          widget.userModel.saldo = result['updatedBalance'];
        });
        
        // Se a tela ainda existir, fecha a gaveta e manda um 'true' para quem chamou,
        // avisando: "Opa, a venda rolou, pode atualizar os dados da tela de trás!"
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // Deu ruim, o backend retornou false. Captura a string de erro.
        final String message =
            (result['error'] ?? 'Falha ao processar venda de tokens.').toString();
            
        setState(() {
          _errorMessage = message;
          _isSubmitting = false; // Destrava o botão
        });
        
        // Feedback via Toast/SnackBar vermelho
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFE74C3C),
              content: Text(message),
            ),
          );
        }
      }
    } catch (e) {
      // Tratamento genérico caso o servidor caia ou não tenha internet
      final String message = e.toString().replaceFirst('Exception: ', '');
      
      setState(() {
        _errorMessage = 'Ocorreu um erro ao processar: $message';
        _isSubmitting = false; // Destrava a vida
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE74C3C),
            content: Text(message),
          ),
        );
      }
    }
  }
}
