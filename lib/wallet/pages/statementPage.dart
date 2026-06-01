// Aluno: João Paulo Ferreira
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25000684

// Importa o pacote base do Flutter para construir a interface visual
import 'package:flutter/material.dart';

// Serviço responsável por buscar a lista de operações financeiras do usuário no Firestore (banco de dados)
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';

// Modelo de dados do usuário logado — é o crachá do usuário, contém uid, saldo, nome etc.
import 'package:mesclainvest_f/model/userModel.dart';

// Componente que exibe uma mensagem amigável (ilustração) quando não há transações para mostrar
import 'package:mesclainvest_f/wallet/components/emptyTransactions.dart';

// Utilitário que transforma os dados "feios e brutos" do Firestore em mapas "bonitinhos" prontos para a UI
import 'package:mesclainvest_f/wallet/components/operationMapper.dart';

// Banner verde no topo da tela com resumo de saldo, total de entradas e saídas (o cabeçalho do extrato)
import 'package:mesclainvest_f/wallet/components/statementSummaryBanner.dart';

// Chips de filtro horizontais (aqueles botõezinhos redondos: Tudo, Entradas, Saques, etc.) para o extrato
import 'package:mesclainvest_f/wallet/components/statementFilterChips.dart';

// Lista de transações agrupada por data, separando por dias com aquelas linhas sutis
import 'package:mesclainvest_f/wallet/components/groupedTransactionList.dart';

/// Tela de extrato completo (StatementPage).
/// É o histórico geral da conta do usuário. Exibe todas as transações,
/// agrupadas por data, com filtros e um resumo no topo.
/// É um StatefulWidget porque a lista de operações, filtros e as animações
/// podem mudar enquanto o usuário navega por aqui.
class StatementPage extends StatefulWidget {
  // Recebe o modelo do usuário logado para saber de quem buscar o histórico e qual o saldo atual
  final UserModel user;

  const StatementPage({super.key, required this.user});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

/// Estado da tela de extrato.
/// O `SingleTickerProviderStateMixin` é o motorzinho que permite criar animações fluídas,
/// sincronizando os frames da tela (60fps) com o nosso AnimationController.
/// Precisamos dele por causa do efeito de "fade in e slide" ao entrar na página.
class _StatementPageState extends State<StatementPage>
    with SingleTickerProviderStateMixin {
  // Serviço para buscar operações do Firestore — nosso "leitor" do banco de dados
  final GetListOperation _operationService = GetListOperation();

  // Lista de transações que a gente vai exibir na tela
  List<Map<String, dynamic>> _transactions = [];

  // Flag de carregamento. Começa como true pra exibir o "spinner" enquanto não chegam os dados.
  bool _isLoading = true;

  // Guarda qual filtro está selecionado no momento. Se for null, não tem filtro (mostra tudo).
  String? _selectedFilter;

  // Constante para o nosso verde principal, pra não ficar digitando o hexadecimal toda hora
  static const Color primaryGreen = Color(0xFF107649);

  // O "maestro" da nossa animação de entrada (fade in + slide pra cima)
  late AnimationController _entryAnimController;

  // A animação em si que altera a opacidade: começa "transparente" (0.0) e vai até "visível" (1.0)
  late Animation<double> _fadeIn;

  // A animação de posição: começa um pouco abaixo (0.06 do eixo Y) e sobe até a posição original (zero)
  late Animation<Offset> _slideUp;

  // Mapa com as opções de filtro.
  // A chave é o que a gente compara com o tipo da transação no banco,
  // e o valor é o texto amigável que vai aparecer no botãozinho.
  static const Map<String?, String> _filterOptions = {
    null: 'Tudo',
    'deposito': 'Entradas',
    'saque': 'Saques',
    'transferencia': 'Transferências',
    'pagar': 'Pagamentos',
    'investimento': 'Investimentos',
  };

  @override
  void initState() {
    super.initState();

    // Configura a animação para durar meio segundo (500ms)
    _entryAnimController = AnimationController(
      vsync: this, // O TickerProvider
      duration: const Duration(milliseconds: 500),
    );

    // Tween é a "jornada". Aqui dizemos: "vá de opacidade 0 até 1"
    // CurvedAnimation deixa o movimento mais natural (começa rápido e termina devagar)
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
    );

    // Tween de posição: começa 6% abaixo da tela e termina na posição normal.
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOut),
        );

    // Dá o "play" na animação assim que a tela abre
    _entryAnimController.forward();

    // Inicia a busca das operações financeiras no servidor
    _fetchOperations();
  }

  @override
  void dispose() {
    // Regra de ouro: sempre destrua os controllers no dispose.
    // Se não fizer isso, eles continuam "vivos" consumindo memória mesmo depois da tela fechar (memory leak).
    _entryAnimController.dispose();
    super.dispose();
  }

  /// Vai no Firebase, pega as operações do usuário, ordena e converte num formato que a tela entende.
  /// O uso de `async/await` diz que essa função é demorada, então a gente "espera" a resposta do banco.
  Future<void> _fetchOperations() async {
    try {
      // Liga a animação de carregamento (caso tenha mudado)
      setState(() => _isLoading = true);

      // Puxa os dados brutos (Maps de JSON) usando o UID do nosso usuário
      final rawData = await _operationService.getOperations(
        userId: widget.user.uid,
      );

      // Ordena por data do mais recente pro mais antigo
      OperationMapper.sortByDateDesc(rawData);

      // Converte a maçaroca de dados do Firebase numa lista bonitinha de Maps que a tela sabe desenhar.
      // E avisa o mapper pra usar os ícones específicos do extrato (useStatementIcons: true).
      final mapped = OperationMapper.mapOperations(
        rawData: rawData,
        currentUserId: widget.user.uid,
        useStatementIcons: true,
      );

      // Atualiza o estado da tela com os dados prontos e desliga o carregamento.
      setState(() {
        _transactions = mapped;
        _isLoading = false;
      });
    } catch (e) {
      // Deu ruim? Tira o loading pra não ficar girando infinito.
      // O ideal aqui seria mostrar uma mensagem de erro na tela também.
      setState(() => _isLoading = false);
    }
  }

  // Uma "propriedade calculada" (getter) que retorna apenas as transações que passam no filtro.
  List<Map<String, dynamic>> get _filteredTransactions {
    // Se o filtro for nulo, devolvemos tudo
    if (_selectedFilter == null) return _transactions;
    // Se não, só os que tem o 'type' igual ao que selecionamos
    return _transactions.where((tx) => tx['type'] == _selectedFilter).toList();
  }

  /// Pega as transações filtradas, procura as de "crédito", e soma todos os valores.
  /// Assim sabemos quanto entrou no período ou tipo selecionado.
  double get _totalEntradas {
    return _filteredTransactions
        .where((tx) => tx['isCredit'] == true) // Pega só dinheiro que entrou
        .fold(
          0.0,
          (total, tx) => total + (tx['value'] as double),
        ); // Soma (como um reduce do Javascript)
  }

  /// Pega as transações filtradas, procura as de "débito" (saída) e soma.
  double get _totalSaidas {
    return _filteredTransactions
        .where((tx) => tx['isCredit'] == false) // Pega só dinheiro que saiu
        .fold(0.0, (total, tx) => total + (tx['value'] as double));
  }

  @override
  Widget build(BuildContext context) {
    // Chama o getter que filtra a lista (isso ocorre sempre que o estado muda ou o build roda)
    final filtered = _filteredTransactions;

    // Scaffold de sempre, a "página" em branco.
    return Scaffold(
      // ── AppBar limpa ──────────────────────────────────────
      appBar: AppBar(
        elevation: 0, // Tiramos a sombra que dividia a AppBar do corpo
        // Botão de voltar customizado pra usar a setinha estilo iOS.
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context), // Volta de onde viemos
        ),
        // O título da página
        title: const Text(
          'Extrato',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true, // Pra garantir que o título fica bem no meio
        actions: [
          // Ícone de lupa pra busca. Por enquanto não faz nada (onPressed vazio),
          // mas já fica preparado para quando a funcionalidade for feita.
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      // O corpo principal, com as animações envolvendo tudo.
      // Quando a tela abrir, essa árvore inteira vai aparecer suavemente e subir.
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          // Column empilha as coisas verticalmente: Resumo -> Filtros -> Lista
          child: Column(
            children: [
              // ── Banner superior verde ────────────
              // Aquele cartãozão no topo mostrando o Saldo e a soma de Entradas/Saídas.
              StatementSummaryBanner(
                saldo: widget.user.saldo,
                totalEntradas: _totalEntradas,
                totalSaidas: _totalSaidas,
              ),

              const SizedBox(height: 16),

              // ── A régua de filtros ────────────────────────
              // Os botõezinhos redondos pra filtrar: "Tudo", "Entradas", "Saques"...
              StatementFilterChips(
                filterOptions: _filterOptions, // Os nossos filtros lá de cima
                selectedFilter: _selectedFilter, // O botão que está ativo agora
                onFilterSelected: (key) {
                  // Quando clicar num filtro, a gente muda o state.
                  // Isso faz a tela toda renderizar de novo, recalculando os totais
                  // e mostrando apenas as transações escolhidas.
                  setState(() {
                    _selectedFilter = key;
                  });
                },
              ),

              const SizedBox(height: 12),

              // ── A lista de extrato em si ──────────────
              // Expanded faz esse filho ocupar todo o resto da tela (o espaço vertical que sobrar).
              Expanded(
                // Aqui usamos ifs (ternários) para decidir o que mostrar:
                child: _isLoading
                    // 1. Está carregando? Mostra o "spinner" (roda-roda) no meio da tela.
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      )
                    // 2. Não tá carregando, mas não tem itens com esse filtro? Mostra o Empty State.
                    : filtered.isEmpty
                    ? const EmptyTransactions()
                    // 3. Tudo deu certo e temos itens? Desenhamos a lista agrupada (ex: Separando Hoje, Ontem).
                    : GroupedTransactionList(transactions: filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
