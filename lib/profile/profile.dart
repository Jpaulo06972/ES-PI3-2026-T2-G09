import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:mesclainvest_f/components/appBar.dart';
import 'package:mesclainvest_f/components/navBar.dart';
import 'package:mesclainvest_f/model/userModel.dart';

class ProfilePage extends StatefulWidget {
  final UserModel userModel;

  const ProfilePage({super.key, required this.userModel});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool isTwoFactorEnabled;
  bool isEditing = false;
  bool _savingTwoFactor = false;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController cpfController;
  late TextEditingController telefoneController;
  late TextEditingController emailController;
  late TextEditingController dataNascimentoController;

  static const Color primaryGreen = Color(0xFF1A9B5F);
  static const Color backgroundColor = Color(0xFF0B0F0D);
  static const Color cardColor = Color(0xFF161A18);
  static const Color inputColor = Color(0xFF222624);

  @override
  void initState() {
    super.initState();

    isTwoFactorEnabled = widget.userModel.twoFactorEnabled;

    firstNameController = TextEditingController(
      text: widget.userModel.firstName,
    );
    lastNameController = TextEditingController(text: widget.userModel.lastName);
    cpfController = TextEditingController(text: widget.userModel.cpf);
    telefoneController = TextEditingController(text: widget.userModel.telefone);
    emailController = TextEditingController(text: widget.userModel.email);
    dataNascimentoController = TextEditingController(
      text: widget.userModel.dataNascimento,
    );
  }

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
      appBar: CustomHeader(userModel: widget.userModel),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
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
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 28),

            _buildProfileHeader(),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('DADOS PESSOAIS'),
                IconButton(
                  onPressed: () {
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

            _buildInfoCard(
              children: [
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
                _buildEditableInfoField(
                  label: 'CPF',
                  controller: cpfController,
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                ),
                _buildEditableInfoField(
                  label: 'Telefone',
                  controller: telefoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _buildEditableInfoField(
                  label: 'E-mail',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildEditableInfoField(
                  label: 'Data de nascimento',
                  controller: dataNascimentoController,
                  icon: Icons.calendar_today_outlined,
                ),

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

            _buildTwoFactorCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        userModel: widget.userModel,
        currentIndex: 4,
      ),
    );
  }

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
                  widget.userModel.fullName.isEmpty
                      ? 'Usuário'
                      : widget.userModel.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.userModel.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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

  Widget _buildTwoFactorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isTwoFactorEnabled
              ? primaryGreen.withOpacity(0.7)
              : Colors.white.withOpacity(0.08),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isTwoFactorEnabled
                      ? '2FA ativado para sua conta.'
                      : 'Ative para aumentar a segurança da sua conta.',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          _savingTwoFactor
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryGreen,
                  ),
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

  void _saveProfileChanges() {
    setState(() {
      widget.userModel.firstName = firstNameController.text.trim();
      widget.userModel.lastName = lastNameController.text.trim();
      widget.userModel.cpf = cpfController.text.trim();
      widget.userModel.telefone = telefoneController.text.trim();
      widget.userModel.email = emailController.text.trim();
      widget.userModel.dataNascimento = dataNascimentoController.text.trim();

      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Dados atualizados com sucesso!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _toggleTwoFactor(bool value) async {
    setState(() => _savingTwoFactor = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userModel.uid)
          .update({'twoFactorEnabled': value});

      setState(() {
        isTwoFactorEnabled = value;
        widget.userModel.twoFactorEnabled = value;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Erro ao atualizar autenticação em duas etapas.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingTwoFactor = false);
    }
  }

  Widget _buildEditableInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEditing
                ? primaryGreen.withOpacity(0.35)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEditing ? primaryGreen : Colors.white54,
              size: 21,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: isEditing
                  ? TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: label,
                        labelStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.text.isEmpty
                              ? 'Não informado'
                              : controller.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final first = widget.userModel.firstName.trim();
    final last = widget.userModel.lastName.trim();

    if (first.isEmpty && last.isEmpty) return 'U';

    final firstInitial = first.isNotEmpty ? first[0] : '';
    final lastInitial = last.isNotEmpty ? last[0] : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }
}
