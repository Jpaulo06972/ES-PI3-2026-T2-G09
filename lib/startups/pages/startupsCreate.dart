// dart:io é importado para podermos usar a classe 'File', que representa arquivos (fotos/vídeos) no celular
import 'dart:io';

// Importação do pacote principal do Flutter para construir a interface do usuário (UI)
import 'package:flutter/material.dart';

// Importação do pacote de Cloud Functions para conectar com o backend
import 'package:cloud_functions/cloud_functions.dart';

// ============================================================================
// IMPORTAÇÃO DOS NOSSOS COMPONENTES VISUAIS (WIDGETS PERSONALIZADOS)
// ============================================================================
// O NameField é usado para campos de texto simples (Nome, Descrição, Setor)
import '../../components/textField.dart'; 

// O NumberField é o nosso campo numérico com máscara de dinheiro (Capital e Tokens)
import '../components/numberField.dart';

// O DropdownField é o campo de múltipla escolha (para o Estágio da startup)
import '../components/dropdownField.dart';

// O MediaPickerField é o botão especial que abre a câmera ou galeria
import '../components/mediaPickerField.dart';

// O PrimaryButton é o botãozão verde principal que salva as informações
import '../../autentication/components/primaryButton.dart';

// ============================================================================
// IMPORTAÇÃO DE MODELOS E ENUMS (ESTRUTURA DE DADOS)
// ============================================================================
// StageStartup é a lista (enum) dos estágios: Nova, Em Operação, Em Expansão
import 'package:mesclainvest_f/enum/stageStartup.dart';

// StatusStartup é a lista (enum) que define se a startup tá ativa, inativa, etc.
import 'package:mesclainvest_f/enum/statusStartup.dart';

// UserModel representa o usuário que está logado no app agora
import 'package:mesclainvest_f/model/userModel.dart';

// ============================================================================
// TELA PRINCIPAL DE CRIAÇÃO DE STARTUPS
// ============================================================================
// É um StatefulWidget porque a tela precisa se redesenhar (mudar de estado) 
// quando o usuário digita algo, escolhe uma foto ou clica em salvar (mostrando loading).
class StartupsCreate extends StatefulWidget {
  // Recebemos os dados do usuário logado (passado pelo NavBar) para saber quem é o "dono" da startup
  final UserModel userModel;

  // Construtor: exige que a tela receba o usuário na hora de ser aberta
  const StartupsCreate({super.key, required this.userModel});

  @override
  State<StartupsCreate> createState() => _StartupsCreateState();
}

class _StartupsCreateState extends State<StartupsCreate> {
  // O _formKey é a "chave" do nosso formulário. Com ele conseguimos validar todos os campos de uma vez só!
  final _formKey = GlobalKey<FormState>();

  // ============================================================================
  // CONTROLADORES DOS CAMPOS DE TEXTO (TEXT EDITING CONTROLLERS)
  // Eles servem como "caderninhos" que anotam o que o usuário digita em cada campo.
  // ============================================================================
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _shortDescController = TextEditingController(); // Novo: Descrição Curta
  final _execSummaryController = TextEditingController(); // Novo: Resumo Executivo
  final _setorController = TextEditingController();
  final _capitalAportadoController = TextEditingController();
  final _tokensEmitidosController = TextEditingController();

  // ============================================================================
  // VARIÁVEIS DE ESTADO (Para campos que não são de digitar texto)
  // ============================================================================
  // Guarda o estágio que o usuário selecionou na listinha. Começa vazio (null)
  StageStartup? _selectedStage;
  
  // Guarda o arquivo da foto (Logo) e do vídeo (Pitch) que o usuário tirou/escolheu
  File? _selectedImage;
  File? _selectedVideo;

  // Controla se a tela está "carregando" (processando o salvamento). 
  // Quando for 'true', o botão de salvar fica girando a bolinha e não deixa clicar de novo.
  bool _isLoading = false;

  // A função 'dispose' serve para limpar a memória do celular quando o usuário fecha a tela.
  // É muito importante "jogar fora" os controladores de texto para não deixar o app lento.
  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _shortDescController.dispose();
    _execSummaryController.dispose();
    _setorController.dispose();
    _capitalAportadoController.dispose();
    _tokensEmitidosController.dispose();
    super.dispose();
  }

  // ============================================================================
  // FUNÇÃO DE SALVAR A STARTUP
  // ============================================================================
  // Essa função é chamada quando o usuário clica no botão "Salvar Dados Básicos"
  Future<void> _onCreateStartup() async {
    // Passo 1: O '_formKey.currentState!.validate()' dispara as regras de validação 
    // de TODOS os campos (se tá vazio, se o número tá certo).
    if (_formKey.currentState!.validate()) {
      
      // Passo 2: O Dropdown de estágio não é validado automaticamente pelo formKey 
      // do mesmo jeito que o texto, então checamos manualmente se ele está vazio.
      if (_selectedStage == null) {
        // Se estiver vazio, mostra um aviso (SnackBar) na parte de baixo da tela
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o estágio da startup.')),
        );
        return; // 'return' faz a função parar aqui e não continua o salvamento
      }

      // Passo 3: Se passou nas validações, ativamos o loading! A tela se redesenha com a bolinha girando.
      setState(() => _isLoading = true);

      try {
        // Passo 4: Preparar os dados numéricos (remover formatação e converter para centavos)
        final capitalString = _capitalAportadoController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final capitalCents = int.tryParse(capitalString) ?? 0;
        
        final tokensString = _tokensEmitidosController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final tokens = int.tryParse(tokensString) ?? 0;

        // Passo 5: Conectar com a Cloud Function do backend
        // 'startups-createStartup' é o nome da função gerada pelo Firebase baseada no nosso index.ts
        final callable = FirebaseFunctions.instance.httpsCallable('startups-createStartup');
        
        // Passo 6: Chamar a função passando o "pacote" (payload) de dados no formato que o backend espera
        final response = await callable.call(<String, dynamic>{
          'name': _nomeController.text,
          'stage': _selectedStage!.name, // Enum convertido para string (ex: 'nova')
          'shortDescription': _shortDescController.text,
          'description': _descricaoController.text,
          'executiveSummary': _execSummaryController.text,
          'capitalRaisedCents': capitalCents,
          'totalTokensIssued': tokens,
          'currentTokenPriceCents': 0, // Preço inicial, pode ser atualizado depois
          
          // Enviando listas vazias temporárias conforme acordado no planejamento
          'founders': [],
          'externalMembers': [],
          'demoVideos': [],
          
          // Colocamos o setor como uma "tag" inicial
          'tags': [_setorController.text], 
        });

        // Pega o ID que o backend devolveu
        final newStartupId = response.data['id'];
        debugPrint("Sucesso! Startup criada com ID: $newStartupId");

        // Passo 7: Mostra o aviso verde de Sucesso!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Startup criada com sucesso!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );
          // Navigator.pop(context); // Descomente para voltar de tela após salvar
        }
      } catch (e) {
        // Se der erro na internet ou o backend rejeitar, cai aqui
        debugPrint("Erro ao criar startup: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Passo 8: Terminou de salvar (com sucesso ou erro)? Desliga o loading!
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ============================================================================
  // CONSTRUÇÃO DA INTERFACE VISUAL (TELA)
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    // Scaffold é o "esqueleto" básico de qualquer tela (ele dá suporte pra barra superior, menus, etc)
    return Scaffold(
      // Barra superior (AppBar) com o título centralizado
      appBar: AppBar(title: const Text('Nova Startup'), centerTitle: true),
      
      // Corpo da tela centralizado
      body: Center(
        // SingleChildScrollView permite que a tela role pra baixo (scroll) caso o teclado abra
        // ou o celular seja pequeno
        child: SingleChildScrollView(
          // Espaçamentos das bordas (24 nas laterais, 16 em cima/baixo)
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          
          // Form agrupa todos os campos de texto para podermos validar tudo de uma vez
          child: Form(
            key: _formKey, // A chave que declaramos lá no topo
            
            // Column organiza os elementos de cima para baixo (em coluna)
            child: Column(
              // stretch: Faz com que todos os campos estiquem e ocupem a largura toda da tela
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Texto de subtítulo e instrução
                const Text(
                  'Preencha os dados básicos da sua startup',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                
                // Espaçamento vazio pra dar um respiro visual
                const SizedBox(height: 24),

                // CAMPO 1: Nome da Startup (Texto)
                NameField(
                  controller: _nomeController,
                  label: 'Nome da Startup',
                ),
                const SizedBox(height: 16),

                // CAMPO 2: Descrição da Startup (Texto)
                NameField(
                  controller: _descricaoController,
                  label: 'Descrição Longa / Propósito',
                ),
                const SizedBox(height: 16),

                // CAMPO 2.1: Descrição Curta (Exigido pelo backend)
                NameField(
                  controller: _shortDescController,
                  label: 'Descrição Curta (Resumo em 1 frase)',
                ),
                const SizedBox(height: 16),

                // CAMPO 2.2: Resumo Executivo (Exigido pelo backend)
                NameField(
                  controller: _execSummaryController,
                  label: 'Resumo Executivo (Pitch de negócio)',
                ),
                const SizedBox(height: 16),

                // CAMPO 3: Setor de atuação (Texto)
                NameField(
                  controller: _setorController,
                  label: 'Setor (Ex: Saúde)',
                ),
                const SizedBox(height: 16),

                // CAMPO 4: Estágio da startup (Lista suspensa / Dropdown)
                DropdownField(
                  value: _selectedStage,
                  label: 'Estágio',
                  // Quando o cara escolhe na lista, salva o valor na nossa variável '_selectedStage'
                  onChanged: (StageStartup? newValue) {
                    setState(() {
                      _selectedStage = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // CAMPO 5: Dinheiro já investido nela (Números formatados com vírgula)
                NumberField(
                  controller: _capitalAportadoController,
                  label: 'Capital (R\$)',
                ),
                const SizedBox(height: 16),

                // CAMPO 6: Quantidade de tokens criados (Números formatados com vírgula)
                NumberField(
                  controller: _tokensEmitidosController,
                  label: 'Tokens Emitidos',
                ),
                const SizedBox(height: 24),

                // CAMPO 7: Foto da galeria ou câmera (Apenas Imagem)
                MediaPickerField(
                  label: 'Adicionar Logo/Capa (Imagem)',
                  isVideo: false, // isVideo=false significa que é foto
                  onMediaSelected: (file) {
                    setState(() {
                      _selectedImage = file;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // CAMPO 8: Vídeo da galeria ou câmera (Apenas Vídeo)
                MediaPickerField(
                  label: 'Adicionar Pitch (Vídeo)',
                  isVideo: true, // isVideo=true significa que vai gravar/pegar vídeo
                  onMediaSelected: (file) {
                    setState(() {
                      _selectedVideo = file;
                    });
                  },
                ),
                const SizedBox(height: 32), // Espaço maior antes do botão

                // BOTÃO DE SALVAR
                PrimaryButton(
                  label: 'Salvar Dados Básicos', // Texto do botão
                  isLoading: _isLoading, // Se for true, mostra bolinha girando
                  onPressed: _onCreateStartup, // Função que roda quando clica
                ),

                const SizedBox(height: 16),
                
                // Texto de aviso lá no rodapé
                const Text(
                  '* Participação e Sócios serão adicionados na próxima etapa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
