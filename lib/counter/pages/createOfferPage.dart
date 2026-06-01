// Aluno: Felipe Cesar Ferreira Lirani
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25007003

// Página de criação de novas ofertas (Order Maker) no Balcão de Negociação.
// Essa telinha é onde o usuário digita quantos tokens quer vender/comprar e o preço.
// Tem o formulário que calcula tudo on-the-fly (tempo real) pra mostrar o valor final.

import 'package:mesclainvest_f/components/currencyInputFormatter.dart';
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/counter/components/counterToggle.dart';
import 'package:mesclainvest_f/counter/services/counterService.dart';
import 'package:mesclainvest_f/model/offerModel.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/startups/components/startup_colors.dart';

/// Tela para criar ofertas ativas (Makers). 
/// Precisamos do usuário pra saber de quem cobrar e do serviço pra mandar pro Backend.
class CreateOfferPage extends StatefulWidget {
  // Passamos o user logado inteiro.
  final UserModel user;

  // Passamos a instância do CounterService injetada, pra evitar recriar na tela.
  final CounterService service;

  const CreateOfferPage({super.key, required this.user, required this.service});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  // Aba selecionada: 0 (Comprar) ou 1 (Vender). Fica lá no topo da tela.
  int _tabIndex = 0; 

  // Variáveis para guardar o que o investidor selecionou. Começam chumbadas como default.
  String _selectedStartup = 'EcoTech PUC';
  String _selectedStartupId = 'startup_eco';

  // Quantidade inicial setada num valor agradável.
  double _quantidade = 50;

  // Controlador do TextField de preço.
  // Já vem com R$ 1,45 pré-preenchido pra dar a ideia do formato pro usuário.
  final TextEditingController _precoController = TextEditingController(
    text: '1,45',
  );

  // Hardcode de startups pra popular o dropdown.
  // Na vida real isso deveria vir do backend por Stream ou Future. 
  // Mas como a lista de startups é pequena e estática, isso funciona bem como fallback.
  static const List<Map<String, String>> _startups = [
    {'nome': 'EcoTech PUC', 'id': 'startup_eco'},
    {'nome': 'MedConnect', 'id': 'startup_med'},
    {'nome': 'AgriSmart', 'id': 'startup_agri'},
    {'nome': 'FinEduca', 'id': 'startup_fin'},
  ];

  @override
  void dispose() {
    // Boa prática nº1 de Flutter: sempre matar o controller de texto pra liberar memória RAM.
    _precoController.dispose();
    super.dispose();
  }

  /// Limpa e converte a string zoada do InputField "R$ 1.234,56" para um double puro do Dart (1234.56).
  /// Sem essa limpeza regex-like, a matemática depois ia dar um Crash lindo.
  double get _preco {
    final raw = _precoController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '') // No BR, o ponto separa milhar, tiramos ele fora.
        .replaceAll(',', '.'); // E a vírgula vira o dot decimal universal.
    return double.tryParse(raw) ?? 0.0;
  }

  /// Getter esperto que faz o (qtd * preco) sem precisarmos suar a camisa chamando funções toda hora.
  double get _total => _quantidade * _preco;

  /// Função bala de prata que monta a bagagem e atira pro Firebase via Serviço.
  void _submit() {
    // Basicão de validação de formulário: zero quantidades ou zero preço = bloqueio.
    if (_quantidade <= 0 || _preco <= 0) {
      _showSnackBar('Preencha todos os campos corretamente.', isError: true);
      return;
    }

    // Criamos o JSON chique (Model) que será enviado.
    final offer = OfferModel(
      // Gera um ID na mão usando a data/hora em milisegundos. Resolve bem o lance de IDs únicos no MVP.
      id: 'offer_${DateTime.now().millisecondsSinceEpoch}',
      startupId: _selectedStartupId,
      startupNome: _selectedStartup,
      vendedorId: widget.user.uid,
      vendedorNome: widget.user.firstName,
      quantidade: _quantidade,
      precoPorToken: _preco,
      // Define se ele tá vendendo ou comprando pela aba selecionada no topo.
      tipo: _tabIndex == 0 ? OrderType.compra : OrderType.venda,
      criadoEm: DateTime.now(),
    );

    // Manda a braba pro serviço adicionar no book de ofertas gerais.
    widget.service.addOffer(offer);
    
    // Mostra o verdão de sucesso pro camarada.
    _showSnackBar('Oferta publicada com sucesso!');
    
    // Mata a tela e volta pra de onde veio. Retorna "true" como um aviso de que "fiz a oferta!".
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Fundo escuro total, sem emendas.
        elevation: 0,
        // Ícone de voltar bonitinho no estilo do iOS.
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Balcão',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Rótulo na ponta da AppBar dizendo onde o cara está.
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                'Nova Oferta',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      // SingleChildScrollView é fundamental em formulários para o teclado não comer metade da tela e dar overflow.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch grandão Comprar / Vender
            CounterToggle(
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
              tabs: const ['Comprar', 'Vender'],
            ),

            const SizedBox(height: 28),

            // ── Área: Seleção de Startup ──────────────────────────────────
            const _FieldLabel(text: 'Startup'),
            const SizedBox(height: 8),
            _buildDropdown(),

            const SizedBox(height: 24),

            // ── Área: Stepper de Quantidade ───────────────────────────────
            const _FieldLabel(text: 'Quantidade de tokens'),
            const SizedBox(height: 8),
            _buildQuantityInput(),

            const SizedBox(height: 24),

            // ── Área: Preço por Token (o TextField) ───────────────────────
            const _FieldLabel(text: 'Preço por token (R\$)'),
            const SizedBox(height: 8),
            _buildPriceInput(),

            const SizedBox(height: 28),

            // ── Área: Cartão de Resumo Financeiro ─────────────────────────
            // Mostra mastigado o total do impacto pro cara entender.
            _buildSummary(),

            const SizedBox(height: 28),

            // ── Botão de Submit ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107649),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _submit,
                child: Text(
                  // O título do botão se molda a aba selecionada.
                  _tabIndex == 0
                      ? 'Publicar Ordem de Compra'
                      : 'Publicar Ordem de Venda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Caixa seletora das startups (Dropdown) com tema noturno.
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF262629), // Um cinza quase preto, elegante.
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      // HideUnderline tira o traço default horroroso que o Material traz no Dropdown.
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStartup,
          isExpanded: true,
          dropdownColor: const Color(0xFF262629),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          // Mapeia o dicionário estático pros itens do dropdown.
          items: _startups
              .map(
                (s) =>
                    DropdownMenuItem(value: s['nome'], child: Text(s['nome']!)),
              )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            // Acha o ID vinculado ao Nome pra mandar no modelo (no banco sempre entra o ID).
            final match = _startups.firstWhere((s) => s['nome'] == val);
            setState(() {
              _selectedStartup = match['nome']!;
              _selectedStartupId = match['id']!;
            });
          },
        ),
      ),
    );
  }

  /// Controles com os botõezinhos [-] Valor [+] pra definir os tokens.
  Widget _buildQuantityInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF107649).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Botão Menos
          _buildStepButton(Icons.remove, () {
            // Proteção pro cara não vender 0 ou -5 tokens e bugar a contabilidade da base.
            if (_quantidade > 1) setState(() => _quantidade--);
          }),
          // Texto gordo no meio da tela com o valor.
          Expanded(
            child: Text(
              _quantidade.toInt().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Botão Mais
          _buildStepButton(Icons.add, () => setState(() => _quantidade++)),
        ],
      ),
    );
  }

  /// Construtor de botões isolado pro +/- (Componentização marota para não repetir código).
  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          // Fundo esverdeado bem suave. Dá um visual Premium pro stepper.
          color: const Color(0xFF107649).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF107649), size: 22),
      ),
    );
  }

  /// Caixa onde o cara digita com teclado o preço que ele quer no token dele.
  Widget _buildPriceInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF107649).withValues(alpha: 0.4),
        ),
      ),
      child: TextField(
        controller: _precoController,
        // Teclado numérico liberando casa decimal (ponto ou vírgula).
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          // Põe o R$ chumbado de modo estático na esquerda do input.
          prefixText: 'R\$ ',
          prefixStyle: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        // Truque de mestre: Ao digitar, chama um setState nulo! 
        // Pra que? Só pra forçar a tela a renderizar e o widget do Resumo Financeiro(_total) calcular ao vivo.
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  /// O Quadrado final que mostra a matemática já resolvida, sem sustos na hora do submit.
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262629),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Linha a Linha o resumo da ópera.
          _SummaryRow(label: 'Tokens', value: '${_quantidade.toInt()}'),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Preço/token',
            value: CurrencyInputFormatter.formatValue(_preco),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF3A3A3A), height: 1), // Divisoria estetica.
          ),
          // Total Estourando no verde pra chamar atenção.
          _SummaryRow(
            label: 'Total estimado',
            value: CurrencyInputFormatter.formatValue(_total),
            highlight: true,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Saldo atual',
            value: CurrencyInputFormatter.formatValue(widget.user.saldo),
          ),
        ],
      ),
    );
  }

  /// Pop-up de Toast no padrão do app pra alertar no rodapé.
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFE74C3C)
            : const Color(0xFF107649),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Helper Label. Centraliza a formatação do Text pra não jogar boilerplate nas colunas.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Helper Row. A linha flexível Label ------ Valor que vai dentro do Resumo Financeiro.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            // Se tiver o destaque, usa o verdão chamativo e fonte negrito.
            color: highlight ? const Color(0xFF1A9B5F) : Colors.white,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
