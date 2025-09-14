import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class PriceChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool isTablet;

  const PriceChart({
    super.key,
    required this.data,
    required this.color,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Area
          Expanded(
            child: Container(
              width: double.infinity,
              child: CustomPaint(
                painter: SimpleChartPainter(
                  data: data,
                  color: color,
                ),
              ),
            ),
          ),
          
          // Bottom Labels
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              data.length < 5 ? data.length : 5,
              (index) {
                final actualIndex = index * (data.length - 1) ~/ (data.length < 5 ? data.length - 1 : 4);
                return Text(
                  'Day ${actualIndex + 1}',
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 9,
                    color: AppColors.secondaryTextColor,
                  ),
                );
              },
            ),
          ),
          
          // Price Range
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Low',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '₹${_formatPrice(data.reduce((a, b) => a < b ? a : b))}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'High',
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 10,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '₹${_formatPrice(data.reduce((a, b) => a > b ? a : b))}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
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

  String _formatPrice(double price) {
    if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return price.toStringAsFixed(price >= 10 ? 0 : 1);
    }
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SimpleChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) {
      // If all values are the same, draw a straight line
      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      return;
    }

    final path = Path();
    final fillPath = Path();
    
    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    // Create smooth curve path
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        
        // Simple curve using quadratic bezier
        if (i < points.length - 1) {
          final next = points[i + 1];
          final controlPoint = Offset(
            current.dx,
            current.dy,
          );
          path.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            (current.dx + next.dx) / 2,
            (current.dy + next.dy) / 2,
          );
          fillPath.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            (current.dx + next.dx) / 2,
            (current.dy + next.dy) / 2,
          );
        } else {
          path.lineTo(current.dx, current.dy);
          fillPath.lineTo(current.dx, current.dy);
        }
      }

      // Complete fill path
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Draw fill area
      canvas.drawPath(fillPath, fillPaint);

      // Draw line
      canvas.drawPath(path, paint);

      // Draw points
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final pointBorderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
        canvas.drawCircle(point, 4, pointBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}