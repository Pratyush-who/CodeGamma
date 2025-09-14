import 'package:codegamma_sih/presentation/view/home/widgets/disease/disease_track.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../../core/constants/app_colors.dart';

class OutbreakMapWidget extends StatefulWidget {
  final List<DiseaseOutbreak> outbreaks;
  final AnimationController pulseController;
  final bool isTablet;
  final Function(DiseaseOutbreak) onOutbreakTap;

  const OutbreakMapWidget({
    super.key,
    required this.outbreaks,
    required this.pulseController,
    required this.isTablet,
    required this.onOutbreakTap,
  });

  @override
  State<OutbreakMapWidget> createState() => _OutbreakMapWidgetState();
}

class _OutbreakMapWidgetState extends State<OutbreakMapWidget> {
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.all(widget.isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Agra, UP - Disease Outbreaks',
                          style: TextStyle(
                            fontSize: widget.isTablet ? 14 : 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _zoomLevel = math.min(_zoomLevel + 0.2, 2.0);
                          });
                        },
                        iconSize: 20,
                        color: AppColors.primaryColor,
                      ),
                      Container(
                        height: 1,
                        width: 20,
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            _zoomLevel = math.max(_zoomLevel - 0.2, 0.5);
                          });
                        },
                        iconSize: 20,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map Area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _panOffset += details.delta;
                  });
                },
                child: Transform.scale(
                  scale: _zoomLevel,
                  child: Transform.translate(
                    offset: _panOffset,
                    child: CustomPaint(
                      painter: OutbreakMapPainter(
                        outbreaks: widget.outbreaks,
                        pulseAnimation: widget.pulseController,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Stack(
                          children: [
                            // Current Location (Agra)
                            Positioned(
                              left: size.width * 0.5 - 25,
                              top: size.height * 0.4,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),

                            // Outbreak Markers
                            ...widget.outbreaks.asMap().entries.map((entry) {
                              final index = entry.key;
                              final outbreak = entry.value;
                              final positions = [
                                const Offset(0.7, 0.25), // Mathura
                                const Offset(0.2, 0.7),  // Firozabad
                                const Offset(0.8, 0.15), // Mainpuri
                                const Offset(0.3, 0.8),  // Etah
                              ];
                              
                              return Positioned(
                                left: size.width * positions[index].dx - 15,
                                top: size.height * positions[index].dy,
                                child: GestureDetector(
                                  onTap: () => widget.onOutbreakTap(outbreak),
                                  child: AnimatedBuilder(
                                    animation: widget.pulseController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: outbreak.severity == AlertSeverity.critical
                                            ? 1.0 + (widget.pulseController.value * 0.3)
                                            : 1.0,
                                        child: Container(
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            color: _getSeverityColor(outbreak.severity),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getSeverityColor(outbreak.severity)
                                                    .withOpacity(0.4),
                                                blurRadius: 12,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _getSeverityIcon(outbreak.severity),
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),

                            // Risk Zones
                            ...widget.outbreaks.where((o) => o.severity == AlertSeverity.critical).map((outbreak) {
                              final index = widget.outbreaks.indexOf(outbreak);
                              final positions = [
                                const Offset(0.7, 0.25),
                                const Offset(0.2, 0.7),
                                const Offset(0.8, 0.15),
                                const Offset(0.3, 0.8),
                              ];
                              
                              return Positioned(
                                left: size.width * positions[index].dx - 50,
                                top: size.height * positions[index].dy - 50,
                                child: AnimatedBuilder(
                                  animation: widget.pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red.withOpacity(
                                          0.1 + (widget.pulseController.value * 0.1),
                                        ),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Legend
          Container(
            padding: EdgeInsets.all(widget.isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Levels',
                  style: TextStyle(
                    fontSize: widget.isTablet ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(
                      color: Colors.red,
                      label: 'Critical',
                      count: widget.outbreaks.where((o) => o.severity == AlertSeverity.critical).length,
                      isTablet: widget.isTablet,
                    ),
                    _LegendItem(
                      color: Colors.orange,
                      label: 'High',
                      count: widget.outbreaks.where((o) => o.severity == AlertSeverity.high).length,
                      isTablet: widget.isTablet,
                    ),
                    _LegendItem(
                      color: Colors.yellow.shade700,
                      label: 'Medium',
                      count: widget.outbreaks.where((o) => o.severity == AlertSeverity.medium).length,
                      isTablet: widget.isTablet,
                    ),
                    _LegendItem(
                      color: Colors.green,
                      label: 'Low',
                      count: widget.outbreaks.where((o) => o.severity == AlertSeverity.low).length,
                      isTablet: widget.isTablet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.yellow.shade700;
      case AlertSeverity.low:
        return Colors.green;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.dangerous;
      case AlertSeverity.high:
        return Icons.warning;
      case AlertSeverity.medium:
        return Icons.info;
      case AlertSeverity.low:
        return Icons.check_circle;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool isTablet;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: isTablet ? 11 : 10,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryTextColor,
          ),
        ),
      ],
    );
  }
}

class OutbreakMapPainter extends CustomPainter {
  final List<DiseaseOutbreak> outbreaks;
  final Animation<double> pulseAnimation;

  OutbreakMapPainter({
    required this.outbreaks,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw map background
    paint.color = AppColors.lightGreen.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw district boundaries
    paint.color = AppColors.primaryColor.withOpacity(0.2);
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    // Draw roads/highways
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      paint,
    );

    // Draw farm areas
    paint.style = PaintingStyle.fill;
    paint.color = AppColors.accentGreen.withOpacity(0.1);
    
    final farmAreas = [
      Rect.fromLTWH(size.width * 0.6, size.height * 0.1, size.width * 0.25, size.height * 0.2),  // Mathura
      Rect.fromLTWH(size.width * 0.1, size.height * 0.55, size.width * 0.2, size.height * 0.25), // Firozabad
      Rect.fromLTWH(size.width * 0.75, size.height * 0.05, size.width * 0.2, size.height * 0.15), // Mainpuri
      Rect.fromLTWH(size.width * 0.2, size.height * 0.7, size.width * 0.2, size.height * 0.2),   // Etah
    ];

    for (final area in farmAreas) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(area, const Radius.circular(8)),
        paint,
      );
    }

    // Draw river (Yamuna)
    paint.color = Colors.blue.withOpacity(0.3);
    paint.strokeWidth = 8;
    paint.style = PaintingStyle.stroke;
    
    final river = Path();
    river.moveTo(size.width * 0.4, 0);
    river.quadraticBezierTo(
      size.width * 0.6, size.height * 0.3,
      size.width * 0.5, size.height * 0.6,
    );
    river.quadraticBezierTo(
      size.width * 0.4, size.height * 0.8,
      size.width * 0.3, size.height,
    );
    
    canvas.drawPath(river, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}