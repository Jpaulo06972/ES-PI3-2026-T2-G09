import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/action_button.dart';

class WalletView extends StatelessWidget {
  const WalletView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(),
              const SizedBox(height: 32),
              const Text('MEUS TOKENS', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              _buildEmptyStateCard('Nenhum token disponível'),
              const SizedBox(height: 24),
              const Text('EXTRATO RECENTE', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              _buildEmptyStateCard('Nenhuma movimentação disponível'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Olá',
          style: AppTextStyles.header,
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary, size: 28),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.balanceCardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SALDO DISPONÍVEL',
            style: AppTextStyles.balanceLabel,
          ),
          const SizedBox(height: 8),
          const Text(
            '--',
            style: AppTextStyles.balanceValue,
          ),
          const SizedBox(height: 8),
          const Text('Saldo disponível', style: AppTextStyles.caption),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  title: '+ Adicionar',
                  subtitle: 'adicionar saldo',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ActionButton(
                  title: 'Holdings',
                  subtitle: 'meus tokens',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption,
      ),
    );
  }
}
