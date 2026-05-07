import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class TokenCard extends StatelessWidget {
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String variation;
  final bool isPositive;

  const TokenCard({
    Key? key,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.variation,
    required this.isPositive,
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
                Text(subtitle, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.cardValue),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isPositive ? AppColors.primary : AppColors.error,
                    size: 20,
                  ),
                  Text(
                    variation,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
