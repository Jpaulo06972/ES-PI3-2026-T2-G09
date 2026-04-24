// Importa o pacote do Flutter com tudo que precisamos pra montar a interface
import 'package:flutter/material.dart';
import 'package:mesclainvest_f/model/userModel.dart';
import 'package:mesclainvest_f/dashboard/pages/notification.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final UserModel userModel;

  const CustomHeader({super.key, required this.userModel});

  Future<void> _onSendPressed(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top +
            16, // Espaço da barra de status do celular
        bottom: 16,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          const Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 52, // Tamanho equivalente a um raio de 26
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min, // Ocupa apenas o espaço necessário
              children: [
                Text(
                  'Olá, ${userModel.fullName.isNotEmpty ? userModel.fullName : 'Usuário'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 38,
            ),
            onPressed: () => _onSendPressed(context),
          ),
        ],
      ),
    );
  }

  // Definimos o tamanho fixo que esse header vai ocupar no topo da tela
  @override
  Size get preferredSize => const Size.fromHeight(100.0);
}
