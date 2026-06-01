// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

// Importa o pacote base do Flutter para construir a interface visual (nossos "tijolos" para construir a tela)
import 'package:flutter/material.dart';

// Firestore — O banco de dados nas nuvens (NoSQL) do Firebase, onde os saldos e transações ficam guardados
import 'package:cloud_firestore/cloud_firestore.dart';

// Formatador de moeda — pega um número "feio" tipo 1250.0 e deixa "R$ 1.250,00"
import 'package:mesclainvest_f/components/currencyInputFormatter.dart';

// Cabeçalho padrão do app, que geralmente tem a foto do usuário e alguns ícones de ação
import 'package:mesclainvest_f/components/appBar.dart';

// Barra de navegação inferior (as abas principais lá no pé da tela)
import 'package:mesclainvest_f/components/navBar.dart';

// O "molde" do usuário logado (nome, quanto de dinheiro ele tem, o ID dele no banco, etc)
import 'package:mesclainvest_f/model/userModel.dart';

// O cartãozão verde bonito que diz "Seu Saldo" e tem o olho pra esconder/mostrar
import 'package:mesclainvest_f/wallet/components/saldoCard.dart';

// A barrinha com as opções rápidas: "Depositar", "Sacar", "Transferir"
import 'package:mesclainvest_f/wallet/components/quickActions.dart';

// Aquela seção onde tem "R$ 50", "R$ 100", e "Outro Valor" pra fazer um depósito rapidão
import 'package:mesclainvest_f/wallet/components/quickRecharge.dart';

// A lona com o histórico de transações que tem na tela principal
import 'package:mesclainvest_f/wallet/components/transactionHistory.dart';

// Componente especial que faz uma transição suave (fade e tamanho) quando os filtros de extrato abrem
import 'package:mesclainvest_f/wallet/components/animatedCrossFade.dart';

// Título grande "Minha Carteira" e aquele textinho de explicação debaixo
import 'package:mesclainvest_f/wallet/components/walletHeader.dart';

// Onde tá escrito "Extrato" na listagem rápida, junto com um botão de "Filtros"
import 'package:mesclainvest_f/wallet/components/statementHeader.dart';

// Um widget com imagem ou ícone pra quando a lista de transações tá zerada
import 'package:mesclainvest_f/wallet/components/emptyTransactions.dart';

// Serviço para ler operações. Puxa a lista de transações lá do Firebase
import 'package:mesclainvest_f/wallet/services/getListOperation.dart';

// Modelo da Operação. Ajuda a tratar uma operação não como um dicionário bagunçado, mas como um objeto.
import 'package:mesclainvest_f/model/operations.dart';

// Os tipos possíveis de operação num enum, pra gente não errar as palavras "deposito" ou "saque"
import 'package:mesclainvest_f/enum/typeOfOperation.dart';

// Serviço para "fazer as coisas acontecerem" (criar um depósito novo por exemplo, via Cloud Function)
import 'package:mesclainvest_f/wallet/services/operationService.dart';

// A tela que vai abrir quando clicar num "Sacar" ou "Depositar" para preencher dados
import 'package:mesclainvest_f/wallet/pages/transactionActionPage.dart';

// A tela que abre quando clicamos em "Ver Tudo" nas transações.
import 'package:mesclainvest_f/wallet/pages/statementPage.dart';

/// Tela principal da Carteira Digital.
/// Pense nisso como o "Hub" do usuário para falar com o seu dinheiro.
/// Aqui ele pode recarregar rapidamente a conta, ver o saldo, e checar as transações.
/// Usamos StatefulWidget porque a tela reage aos dados carregando, saldos escondidos ou filtros clicados.
class RechargeMoneyPage extends StatefulWidget {
  // Recebe o nosso "usuário logado". Vem de fora, de quando fizemos o login.
  final UserModel user;

  const RechargeMoneyPage({super.key, required this.user});

  @override
  State<RechargeMoneyPage> createState() =>
      _RechargeMoneyPageState(userModel: user);
}

/// É aqui onde a mágica acontece. O Estado.
/// Controlamos se o olho do saldo está aberto, o que ele filtrou, ou se os dados já vieram da internet.
class _RechargeMoneyPageState extends State<RechargeMoneyPage> {
  // Instância do nosso usuário. Salvamos aqui no estado pra gente poder atualizar o saldo
  // visualmente depois de um depósito (sem precisar recarregar todo o app).
  final UserModel userModel;

  // Um atalho (getter) para pegar o saldo mais fácil sem precisar digitar "userModel.saldo".
  double get saldo => userModel.saldo;

  // Nosso motor que manda comandos lá pro servidor pra "Criar" as operações (Escrita)
  final OperationService _operationCommandService = OperationService();

  /// Realiza um depósito (ou "Recarga").
  /// Essa função conversa com a nossa "Cloud Function" lá no Firebase pra que seja uma transação segura.
  Future<void> setRecharge(double money) async {
    // Pede ao backend para criar o depósito. Ele retorna true se deu bom.
    final success = await _operationCommandService.createOperation(
      amount: money,
      type: TypeOfOperation.deposito,
      text: "Depósito via App",
    );

    if (success) {
      // Deu bom! Vamos calcular como vai ficar o dinheiro do cara.
      final newSaldo = userModel.saldo + money;
      // Chamamos setState pra dizer ao Flutter: "Refaça a tela! Temos dinheiro novo!"
      setState(() => userModel.saldo = newSaldo);
      try {
        // Tentamos atualizar o saldo que tá guardado solto no cadastro do cara (firestore docs).
        // Isso porque a Cloud Function gera a "fatura" do depósito, mas talvez a gente precise
        // garantir que o cadastro do cara fique atualizado também logo de cara.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userModel.uid)
            .update({'saldo': newSaldo, 'balance': newSaldo});
      } catch (_) {}
      // Agora chamamos uma função que vai pegar a lista de transações de novo, pra o novo depósito aparecer lá
      _fetchOperations();
      // Exibe um alerta rápido e verde dizendo que deu certo.
      _showSnackBar(
        'Depósito de ${CurrencyInputFormatter.formatValue(money)} realizado!',
      );
    } else {
      // Se não rolou, avisa com Snack. (Talvez o Firebase bloqueou).
      _showSnackBar("Erro ao processar depósito no servidor.");
    }
  }

  /// Realiza um pagamento. A lógica é parecida com o depósito,
  /// só que muda o "TypeOfOperation" e o texto.
  Future<void> setPay(double money) async {
    final success = await _operationCommandService.createOperation(
      amount: money,
      type: TypeOfOperation.pagar,
      text: "Pagamento realizado",
    );

    if (success) {
      // Aqui, em vez de gente fazer a matemática ("saldo - money"), a gente confia e
      // puxa direto do banco usando `_refreshUserBalance`, o que previne problemas caso ocorram várias na hora.
      await _refreshUserBalance();
      _fetchOperations(); // Traz a nova listagem de operações com o pagamento recém feito.
    } else {
      _showSnackBar("Erro ao processar pagamento no servidor.");
    }
  }

  // A chavinha que controla se o saldo aparece ou se vira "••••" pra privacidade.
  bool _saldoVisible = true;

  // Guarda o valor que o usuário tocou lá naqueles chips rápidos ("R$ 50", etc).
  // Se estiver nulo, quer dizer que ele não clicou em nenhum ou resolveu digitar manual.
  double? _selectedQuickValue;

  /// Atualiza os números da conta diretamente olhando para o documento do usuário no Firestore.
  /// Como um "F5" pra ter certeza de que estamos alinhados com a realidade da nuvem.
  Future<void> _refreshUserBalance() async {
    try {
      // Pede o "papel" de informações desse usuário pro Firebase
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.uid)
          .get();

      if (doc.exists) {
        // Papel existe! Lê os dados (que são como um dicionário).
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Saldo. Algumas contas podem estar usando "balance" no banco ou "saldo", a gente aceita ambos.
          userModel.saldo = (data['saldo'] ?? data['balance'] ?? 0.0)
              .toDouble();
        });
      }
    } catch (e) {
      // Se deu erro (falta de rede etc), a gente ignora calado. Melhor não apagar a tela dele.
    }
  }

  /// Navega para a tela focada só numa ação (Exemplo: Abre a tela grandona de sacar).
  void _navigateToTransaction(TypeOfOperation type) async {
    // O comando await Navigator.push significa que o app vai abrir uma página e "ficar esperando"
    // a página retornar um valor.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Passamos quem tá logado e se é pra Sacar, Transferir, etc
        builder: (context) =>
            TransactionActionPage(user: userModel, type: type),
      ),
    );

    // Se a página de ação fechou devolvendo "true", é porque algo aconteceu (ex: saque rolou)
    if (result == true) {
      // Então bora recarregar a tela aqui e atualizar tudo.
      _fetchOperations();
      await _refreshUserBalance();
    }
  }

  // É a "caneta" que a gente dá na mão do campo de texto (onde se digita o valor pra recarga customizada).
  // A gente precisa dele pra ler depois ou limpar.
  final TextEditingController _customValueController = TextEditingController();

  // Guarda o tipo de filtro atual ("saque", "deposito"...). Nulo quer dizer que o usuário quer ver todas.
  String? _selectedFilter;

  // Aquela seção dos "botõezinhos de filtrar" está aberta/visível agora?
  bool _showFilters = false;

  // Uma listinha com as opções que o usuário pode escolher nos filtros
  static const Map<String?, String> _filterOptions = {
    null: 'Todas',
    'deposito': 'Depósitos',
    'saque': 'Saques',
    'transferencia': 'Transferências',
  };

  // Motor para ler operações passadas
  final GetListOperation _operationService = GetListOperation();

  // Uma caixinha pra guardar as operações processadas antes de mandar pra tela pintar
  List<Map<String, dynamic>> _transactions = [];

  // Variável que diz "calma aí, tô pensando" e aciona o ícone de girar.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Assim que a tela é criada (uma única vez), ela já diz: "Ei, me traga o que tem de operação"
    _fetchOperations();
  }

  /// Vai no banco e traz o extrato do usuário, arrumando ele e ordenando antes de mostrar.
  Future<void> _fetchOperations() async {
    try {
      // Fala "estou ocupado" pra tela colocar um loading
      setState(() => _isLoading = true);

      // Pede ao Firestore tudo envolvendo o id desse usuário (seja lá ele fazendo depósito ou alguém mandando pra ele)
      final rawData = await _operationService.getOperations(
        userId: userModel.uid,
      );

      // --- Ordenação Manual: A mais nova primeiro! ---
      // Como o Firestore nem sempre retorna na ordem certinha, a gente ordena comparando os "Timestamps"
      rawData.sort((a, b) {
        final dateA = a['createdAt'];
        final dateB = b['createdAt'];

        // Trabalhamos com segundos porque é mais fácil. E tratamos o fato de que pode vir como Timestamp oficial
        // ou como um Mapa dependendo de como as requisições estão em cache
        int secA = 0;
        if (dateA is Timestamp)
          secA = dateA.seconds;
        else if (dateA is Map)
          secA = (dateA['_seconds'] ?? dateA['seconds'] ?? 0);

        int secB = 0;
        if (dateB is Timestamp)
          secB = dateB.seconds;
        else if (dateB is Map)
          secB = (dateB['_seconds'] ?? dateB['seconds'] ?? 0);

        // Inverte b.compareTo(a) pra que o número maior (data maior, mais perto de agora) venha primeiro.
        return secB.compareTo(secA);
      });

      // Aqui entra o trabalho braçal de converter os dados de "como o programador entende (firebase)"
      // para "como o designer quer ver (ícones, cores)".
      final mapped = rawData.map((data) {
        // Transforma o dicionário bruto num Objeto organizado OperationModel
        final op = OperationModel.fromMap(data['id'] ?? '', data);

        // Verificamos de quem é a transação e se não foi a gente que criou, pra ver se recebemos algo.
        bool souDestinatario = data['targetUserId'] == userModel.uid;
        bool souAutor =
            (data['authorUid'] ?? data['authorID']) == userModel.uid;

        // Se for uma operação desconhecida, fica com essa carinha padrão
        IconData icon = Icons.help_outline;
        String title = op.text ?? 'Operação';
        bool isCredit = false; // "Saindo dinheiro" a princípio

        // SE eu fui o destino, mas não fui eu que comecei, quer dizer que eu RECEBI dinheiro.
        // O famoso Pix que caiu! (é um crédito)
        if (souDestinatario && !souAutor) {
          isCredit = true;
          icon = Icons.move_to_inbox_rounded;
          title = op.text ?? 'Transferência Recebida';
        } else {
          // Mas se fui eu mesmo mexendo (depósito meu, saque meu), a gente vai checar pelo enum.
          switch (op.operation) {
            case TypeOfOperation.deposito: // Coloquei dinheiro
              icon = Icons.add_circle;
              title = op.text ?? 'Depósito Realizado';
              isCredit = true; // Saldo sobe
              break;
            case TypeOfOperation.pagar: // Paguei alguém
              icon = Icons.payment_rounded;
              title = op.text ?? 'Pagamento Realizado';
              isCredit = false; // Saldo desce
              break;
            case TypeOfOperation.transferencia: // Transferi pra alguém
              icon = Icons.swap_horiz_rounded;
              title = op.text ?? 'Transferência Enviada';
              isCredit = false; // Saldo desce
              break;
            case TypeOfOperation.saque: // Tirei do app
              icon = Icons.account_balance_wallet_rounded;
              title = op.text ?? 'Saque Realizado';
              isCredit = false; // Saldo desce
              break;
            case TypeOfOperation.investimento: // Botei em startup
              icon = Icons.rocket_launch;
              title = op.text ?? 'Investimento Efetuado';
              isCredit = false; // Saldo desce
              break;
          }
        }

        // Pra não bugar nosso filtro (lembra os chips de "Saque, Deposito, Transferência"?),
        // se eu recebi grana, considero como "transferencia" também.
        String filterType;
        if (souDestinatario && !souAutor) {
          filterType = 'transferencia';
        } else {
          filterType = op
              .operation
              .name; // Pega só o nome em string do enum. Ex: "deposito"
        }

        // Retorna tudo arrumadinho pro nosso Widget TransactionHistory usar
        return {
          'icon': icon,
          'title': title,
          'date': op.createdAt ?? 'Data não informada',
          'value': op.amount,
          'isCredit': isCredit,
          'type': filterType,
          'id': op
              .id, // O ID é usado caso a pessoa clique em cima pra ver o comprovante.
        };
      }).toList(); // Transforma o Map resultante em List

      // Beleza! Os dados estão mastigados. Chamamos setState pra dizer "tela, tira o carregando e põe os dados".
      setState(() {
        _transactions = mapped;
        _isLoading = false;
      });
    } catch (e) {
      // Se não der, a gente avisa
      setState(() => _isLoading = false);
      _showSnackBar("Erro ao carregar extrato dinâmico.");
    }
  }

  // O nosso construtor maroto, tem que receber o modelo.
  _RechargeMoneyPageState({required this.userModel});

  @override
  void dispose() {
    // A caneta (TextEditingController) gasta memória do sistema.
    // Sempre que fechamos a tela de forma definitiva (tipo sair do app ou logoff),
    // a gente fala pro celular pra "jogar no lixo" (dispose) pra não travar tudo lá na frente (memory leak).
    _customValueController.dispose();
    super.dispose();
  }

  // Um facilitador (getter). Ele pega a lista grandona `_transactions`
  // e filtra só pra o tipo de transação que a gente escolheu (ex: mostra só as de saque).
  // Se não escolhemos filtro nenhum, ele joga a lista toda.
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == null) return _transactions;
    return _transactions.where((tx) => tx['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Só por conveniência, a gente salva a lista que vai ser pintada agora
    final filtered = _filteredTransactions;

    // A folha em branco da nossa página. O Scaffold monta a estrutura básica do Material.
    return Scaffold(
      // AppBar: o cabeçalho superior que não vai rolar e geralmente tem as fotinhas de user.
      appBar: CustomHeader(userModel: userModel),

      // O "Corpo" (body) vai ser uma ListView.
      // E por que ListView e não Column? Porque a Column não rola nativamente!
      // Se esticarmos os dedinhos e faltar espaço, a ListView garante que você consiga descer.
      body: ListView(
        // Esse physics deixa rolar com aquele efeitinho puxando e quicando. É charmoso.
        physics: const BouncingScrollPhysics(),
        // Um pequeno padding em volta de tudo pra nada grudar na parede da tela.
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Título e Subtítulo "Minha Carteira" ────────────────────────
          const WalletHeader(),

          const SizedBox(height: 28),

          // ── O Mega Cartão de Saldo ─────────────────────────────────
          // Nós passamos o saldo, se está visível e a função que altera o olho!
          SaldoCard(
            saldo: saldo,
            isVisible: _saldoVisible,
            onToggleVisibility: () {
              // Quando clica lá no olho do SaldoCard, ele dispara essa função
              // e aqui a gente inverte o valor! (Se era true, vira false e vice versa).
              setState(() {
                _saldoVisible = !_saldoVisible;
              });
            },
          ),

          const SizedBox(height: 24),

          // ── Ações Rápidas (Depositar, Sacar, Transferir) ───────────
          // Quando clica, navegamos pra aquela tela específica passando o "TypeOfOperation"
          QuickActions(
            onDepositar: () => _navigateToTransaction(TypeOfOperation.deposito),
            onSacar: () => _navigateToTransaction(TypeOfOperation.saque),
            onTransferir: () =>
                _navigateToTransaction(TypeOfOperation.transferencia),
          ),

          const SizedBox(height: 28),

          // ── O Bloco de Recarga Rápida (Depositar na lata) ───────────
          QuickRecharge(
            selectedValue: _selectedQuickValue,
            customValueController:
                _customValueController, // Passamos a nossa canetinha
            onValueSelected: (value) {
              // O usuário escolheu ou cancelou um chip predefinido ("R$ 50")
              setState(() {
                _selectedQuickValue = value;
                _customValueController
                    .clear(); // O texto some pq usamos o chip.
              });
            },
            onCustomValueChanged: (value) {
              // Se a pessoa resolver digitar um valor por conta própria, o chip é cancelado!
              if (value.isNotEmpty) {
                setState(() {
                  _selectedQuickValue = null;
                });
              }
            },
            // Se clicar em confirmar, roda essa nossa lógica complexa aí embaixo.
            onConfirm: _handleRechargeConfirm,
          ),

          const SizedBox(height: 32),

          // ── Parte das Transações (Cabeçalho do Extrato) ─────────────────
          StatementHeader(
            // Fala pro cabeçalho quantas transações achou
            count: filtered.length,
            // Fala se é pra mostrar a caixinha de filtros que sobe/desce
            showFilters: _showFilters,
            // Avida pra colocar uma bolinha diferente caso tenha filtro rodando.
            hasActiveFilter: _selectedFilter != null,
            onToggleFilters: () {
              // Quando clica no icone de filtro, ele abre ou fecha o gaveteiro
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),

          // ── E o próprio gaveteiro dos Filtros que usa Fade Animado ────────
          FilterCrossFade(
            showFilters:
                _showFilters, // Se false, ele esconde. Se true, mostra os botõezinhos redondos.
            filterOptions: _filterOptions,
            selectedFilter: _selectedFilter,
            onFilterSelected: (key) {
              // O usuário mudou de filtro (ex: clicou em Saque). Atualiza.
              setState(() {
                _selectedFilter = key;
              });
            },
          ),

          const SizedBox(height: 16),

          // ── Lista em si! ────────────────────────────────────────────────
          // Se tiver carregando o Firebase, só exibe o "Circulozinho girando" verdinho
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF107649)),
              ),
            )
          // E se não tem mais carregando mas a lista ta sem nada?
          // Mostramos a "EmptyTransactions", tipo um desenho de fantasma ou cofre vazio.
          else if (filtered.isEmpty)
            const EmptyTransactions()
          // Se tiver dados mesmo, chama a lista da pesada!
          else
            TransactionHistory(
              transactions: filtered, // Passamos só a lista filtradinha
              onViewAll: () {
                // Ao clicar em "Ver tudo" na listinha menor, a gente o leva pra página enorme StatementPage.
                // Usamos "push" para empilhar a tela de extrato. Quando ele voltar (usando "then"),
                // sabemos que ele pode ter atualizado algo, então puxamos do Firebase de novo.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatementPage(user: userModel),
                  ),
                ).then((_) {
                  _fetchOperations();
                  _refreshUserBalance();
                });
              },
            ),

          const SizedBox(height: 30),
        ],
      ),

      // Rodapé, aquelas opções de "Home, Notificações, Carteira, Perfil"
      // "currentIndex: 3" significa "Deixa pintado a aba número 3 (que é a Carteira)"
      bottomNavigationBar: CustomNavBar(userModel: userModel, currentIndex: 3),
    );
  }

  // ── FUNÇÕES DE NEGÓCIO DA TELA ────────────────────────────────────────

  /// Entende o que o cara quis fazer no depósito rápido.
  void _handleRechargeConfirm() {
    // Primeiro vê se ele apertou num botão pronto (tipo 100 reais).
    double? valor = _selectedQuickValue;
    // Se não, vê se ele escreveu algo do próprio bolso na caixa de texto.
    if (valor == null && _customValueController.text.isNotEmpty) {
      // Como a gente gosta de ponto pra conta (1.50) e no Brasil usamos vírgula (1,50),
      // a gente troca a vírgula antes de transformar a string em número real (double)
      valor = double.tryParse(_customValueController.text.replaceAll(',', '.'));
    }
    // Se ele colocou um valor legal e positivo
    if (valor != null && valor > 0) {
      // Roda nosso método de falar com o servidor
      setRecharge(valor).then((_) {
        // Se a promessa de depósito terminou, a gente zera e limpa os campos ali pra ele não clicar 2x e depositar errado.
        setState(() {
          _selectedQuickValue = null;
          _customValueController.clear();
        });
        // Joga um aviso pra falar que foi.
        _showSnackBar("Solicitação de depósito enviada!");
      });
    } else {
      // Se não, o valor era 0 ou texto nada a ver, briga com ele.
      _showSnackBar("Selecione ou digite um valor válido.");
    }
  }

  /// Um alerta rápido que brota no pé do celular (A tal da SnackBar).
  void _showSnackBar(String message) {
    // Of(context) pega qual é o "gerente geral de popups" desta tela e manda exibir a snack.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF107649), // Pintado do nosso verde.
        behavior: SnackBarBehavior
            .floating, // Deixa ela voando invés de grudar no pé tipo rodapé preso.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // Bordas arredondadas nela também
        duration: const Duration(seconds: 3), // some dps de 3 segundos
      ),
    );
  }
}
