import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class MarketSummaryWidget extends StatelessWidget {
  final double totalValue;
  final double dailyChange;
  final double weeklyChange;
  final bool isTablet;

  const MarketSummaryWidget({
    super.key,
    required this.totalValue,
    required this.dailyChange,
    required this.weeklyChange,
    required this.isTablet, required double monthlyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryColor, AppColors.primaryColorLight],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 32 : 20,
        isTablet ? 24 : 20,
        isTablet ? 32 : 20,
        isTablet ? 28 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Overview',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_formatValue(totalValue)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 36 : 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChangeIndicator(
                  label: 'Today',
                  value: dailyChange,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 24 : 20),
              Expanded(
                child: _ChangeIndicator(
                  label: 'This Week',
                  value: weeklyChange,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _ChangeIndicator extends StatelessWidget {
  final String label;
  final double value;
  final bool isTablet;

  const _ChangeIndicator({
    required this.label,
    required this.value,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.white : Colors.red.shade300,
                size: isTablet ? 20 : 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive
                      ? Colors.white
                      : Colors.red.shade300,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
