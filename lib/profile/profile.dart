// Aluno: Tomás de Paula Michelon Toniato
// Grupo: G09
// Trabalho: PI3-2026-T2-G09
// RA: 25004211

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mesclainvest_f/autentication/pages/signin.dart';
import 'package:mesclainvest_f/startups/services/price_simulator.dart';
import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';

/// Nossa tela central de Perfil do Usuário.
///
/// Aqui o cara edita o nome, vê os dados e (muito importante!) liga e desliga o 2FA.
/// Como a gente tem campos de texto que mudam e regras de salvamento, isso aqui
/// TEM que ser um StatefulWidget, pra mantermos o estado da tela "vivo".
class ProfilePage extends StatefulWidget {
  // A gente recebe o model do usuário já carregado pela tela anterior,
  // pra não ter que bater no banco de novo à toa.
  final UserModel userModel;

  const ProfilePage({super.key, required this.userModel});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Flags de controle do nosso estado:
  // Essa aqui lembra se o 2FA tá ligado ou não localmente na UI.
  late bool isTwoFactorEnabled;

  // A chavinha que troca o visual da tela de "Leitura" para "Edição".
  bool isEditing = false;

  // Mostra a "rodinha girando" enquanto o banco tá salvando o status do 2FA.
  bool _savingTwoFactor = false;

  // Controladores dos TextFields. Pense neles como cadernos que anotam cada tecla pressionada.
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController cpfController;
  late TextEditingController telefoneController;
  late TextEditingController emailController;
  late TextEditingController dataNascimentoController;

  // Nossa paleta de cores. Deixar isso como constante em cima é ótimo pra manter o padrão.
  static const Color primaryGreen = Color(0xFF1A9B5F);
  static const Color backgroundColor = Color(0xFF0B0F0D);
  static const Color cardColor = Color(0xFF161A18);
  static const Color inputColor = Color(0xFF222624);

  /// Quando a tela nasce, o initState roda UMA vez só.
  /// Excelente lugar pra instanciar nossos controllers com os dados que já temos.
  @override
  void initState() {
    super.initState();

    isTwoFactorEnabled = widget.userModel.twoFactorEnabled;

    firstNameController = TextEditingController(text: widget.userModel.firstName);
    lastNameController = TextEditingController(text: widget.userModel.lastName);
    cpfController = TextEditingController(text: widget.userModel.cpf);
    telefoneController = TextEditingController(text: widget.userModel.telefone);
    emailController = TextEditingController(text: widget.userModel.email);
    dataNascimentoController = TextEditingController(text: widget.userModel.dataNascimento);
  }

  /// A regra de ouro do Flutter: se você abriu (criou controller), você fecha!
  /// Se não der o .dispose(), esses controllers ficam na RAM chupando memória (Memory Leak).
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    dataNascimentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // A barra de cima que fizemos num componente à parte pra não sujar o código aqui.
      appBar: CustomHeader(userModel: widget.userModel),
      body: SafeArea(
        // Usamos ListView porque em celular pequeno os campos iam espremer ou dar o erro 
        // de "Bottom overflowed by X pixels". O ListView deixa dar scroll!
        child: ListView(
          physics: const BouncingScrollPhysics(), // Aquele efeitinho gostoso de borracha no iOS.
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consulte seus dados pessoais e configure a segurança da conta.',
              style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 28),

            // O cartão de visita do topo
            _buildProfileHeader(),

            const SizedBox(height: 24),

            // O cabeçalho da seção com o botão de "lápis" que alterna o estado de edição
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('DADOS PESSOAIS'),
                IconButton(
                  onPressed: () {
                    // Quando o dev clica, a gente muda a flag e avisa a tela pra se reconstruir!
                    setState(() {
                      isEditing = !isEditing;
                    });
                  },
                  icon: Icon(
                    isEditing ? Icons.close : Icons.edit_outlined,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // A caixa preta que engloba os campos
            _buildInfoCard(
              children: [
                // Nome e sobrenome o usuário pode alterar.
                _buildEditableInfoField(
                  label: 'Nome',
                  controller: firstNameController,
                  icon: Icons.person_outline,
                ),
                _buildEditableInfoField(
                  label: 'Sobrenome',
                  controller: lastNameController,
                  icon: Icons.badge_outlined,
                ),
                // Tem coisa que é sagrada: CPF, telefone e email. 
                // A gente trava o readOnly pra evitar fraude ou bagunçar a auth.
                _buildEditableInfoField(
                  label: 'CPF',
                  controller: cpfController,
                  icon: Icons.credit_card_outlined,
                  readOnly: true,
                ),
                _buildEditableInfoField(
                  label: 'Telefone',
                  controller: telefoneController,
                  icon: Icons.phone_outlined,
                  readOnly: true,
                ),
                _buildEditableInfoField(
                  label: 'E-mail',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  readOnly: true,
                ),
                _buildEditableInfoField(
                  label: 'Data de nascimento',
                  controller: dataNascimentoController,
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                ),

                // Se o modo de edição tá ligado, o botão de salvar aparece num passe de mágica.
                if (isEditing) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saveProfileChanges,
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Salvar alterações',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('SEGURANÇA'),

            const SizedBox(height: 12),

            // Card da verificação em 2 etapas
            _buildTwoFactorCard(),

            const SizedBox(height: 24),

            // O botão do pânico: Logout!
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFE74C3C), size: 20),
                label: const Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      // A barra inferior que todo mundo conhece e ama.
      bottomNavigationBar: CustomNavBar(
        userModel: widget.userModel,
        currentIndex: 4, // O perfil é a última aba!
      ),
    );
  }

  /// Cria o bloco do topo com aquela "fotinha" falsa feita das iniciais do cara.
  Widget _buildProfileHeader() {
    final initials = _getInitials();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: primaryGreen.withOpacity(0.18),
            child: Text(
              initials,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userModel.fullName.isEmpty ? 'Usuário' : widget.userModel.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userModel.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 10),
                // Aquela pill bonitinha dizendo a 'role' do usuário.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.userModel.role.name.toUpperCase(),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: primaryGreen,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  /// Cartão especial só pro Switch de 2FA. Fica girando um loading ali no cantinho 
  /// enquanto não confirma com o Firebase.
  Widget _buildTwoFactorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        // A borda brilha verde se o cara ativou! Recompensas visuais são massa.
        border: Border.all(
          color: isTwoFactorEnabled ? primaryGreen.withOpacity(0.7) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.security_outlined, color: primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Autenticação em duas etapas',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isTwoFactorEnabled
                      ? '2FA ativado para sua conta.'
                      : 'Ative para aumentar a segurança da sua conta.',
                  style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
          // Mostra a cobrinha rodando se tá chamando o Firestore.
          _savingTwoFactor
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                )
              : Switch(
                  value: isTwoFactorEnabled,
                  activeThumbColor: primaryGreen,
                  onChanged: _toggleTwoFactor,
                ),
        ],
      ),
    );
  }

  /// Método forte que manda a bronca pro Firestore e salva os novos dados.
  Future<void> _saveProfileChanges() async {
    // Pega o que o cara digitou nos controllers
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final cpf = cpfController.text.trim();
    final telefone = telefoneController.text.trim();
    final email = emailController.text.trim();
    final dataNascimento = dataNascimentoController.text.trim();

    // Fecha o teclado e os campos
    setState(() => isEditing = false);

    try {
      // Dispara o Update lá no banco
      await FirebaseFirestore.instance.collection('users').doc(widget.userModel.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'cpf': cpf,
        'telefone': telefone,
        'email': email,
        'dataNascimento': dataNascimento,
      });

      // Já arrumou lá? Arruma cá também, pra não ter que dar refresh na tela.
      widget.userModel.firstName = firstName;
      widget.userModel.lastName = lastName;
      widget.userModel.cpf = cpf;
      widget.userModel.telefone = telefone;
      widget.userModel.email = email;
      widget.userModel.dataNascimento = dataNascimento;

      // O 'mounted' é o "Seguro de vida" do Flutter. Se o cara mudou de tela enquanto
      // a internet demorou pra responder, o Flutter não vai tentar mostrar o Snackbar e quebrar.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dados atualizados com sucesso!', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao salvar. Tente novamente.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Tira o cara da conta e mata os serviços de fundo.
  Future<void> _logout() async {
    // Para o cronômetro da bolsa, senão ele continua sugando bateria!
    PriceSimulatorService.stop();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    
    // O pushAndRemoveUntil é tipo uma vassoura: varre TODA a pilha de telas,
    // e deixa só a tela de SignIn. Assim, se o cara der um 'Voltar', o app fecha (o que é o certo).
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  /// Controla a chamadinha pro Firestore do Switch de segurança.
  Future<void> _toggleTwoFactor(bool value) async {
    setState(() => _savingTwoFactor = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userModel.uid).update({'twoFactorEnabled': value});

      setState(() {
        isTwoFactorEnabled = value;
        widget.userModel.twoFactorEnabled = value;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao atualizar autenticação em duas etapas.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingTwoFactor = false);
    }
  }

  /// O widget que cuida de mostrar tanto o textinho quanto o input! Muito versátil.
  Widget _buildEditableInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    // Regrinha rápida: a gente só mostra o input de texto se o botão de edição tá ligado
    // E se a linha não estiver marcada como apenas leitura.
    final bool showAsEditable = isEditing && !readOnly;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showAsEditable ? primaryGreen.withOpacity(0.35) : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: showAsEditable ? primaryGreen : Colors.white54, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: showAsEditable
                  ? TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: label,
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          controller.text.isEmpty ? 'Não informado' : controller.text,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nosso extrator de letrinhas (ex: Felipe Batista -> FB).
  String _getInitials() {
    final first = widget.userModel.firstName.trim();
    final last = widget.userModel.lastName.trim();

    if (first.isEmpty && last.isEmpty) return 'U';

    final firstInitial = first.isNotEmpty ? first[0] : '';
    final lastInitial = last.isNotEmpty ? last[0] : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }
}
