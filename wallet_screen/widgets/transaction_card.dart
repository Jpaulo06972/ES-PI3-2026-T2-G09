import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class TransactionCard extends StatelessWidget {
  final Color iconColor;
  final String title;
  final String date;
  final String value;
  final bool isCredit;

  const TransactionCard({
    Key? key,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.value,
    required this.isCredit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
