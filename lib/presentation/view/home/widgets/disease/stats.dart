import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class DiseaseStatsWidget extends StatelessWidget {
  final int totalOutbreaks;
  final int criticalAlerts;
  final int totalAffected;
  final bool isTablet;

  const DiseaseStatsWidget({
    super.key,
    required this.totalOutbreaks,
    required this.criticalAlerts,
    required this.totalAffected,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : 16),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.coronavirus_outlined,
              label: 'Active\nOutbreaks',
              value: totalOutbreaks.toString(),
              color: Colors.orange,
              isTablet: isTablet,
            ),
          ),
          Container(
            width: 1,
            height: isTablet ? 50 : 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.dangerous_outlined,
              label: 'Critical\nAlerts',
              value: criticalAlerts.toString(),
              color: Colors.red,
              isTablet: isTablet,
            ),
          ),
          Container(
            width: 1,
            height: isTablet ? 50 : 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.pets_outlined,
              label: 'Animals\nAffected',
              value: totalAffected.toString(),
              color: AppColors.primaryColor,
              isTablet: isTablet,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isTablet;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 12 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: isTablet ? 24 : 20),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 12 : 10,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
