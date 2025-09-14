import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class DiseaseMapView extends StatefulWidget {
  const DiseaseMapView({super.key});

  @override
  State<DiseaseMapView> createState() => _DiseaseMapViewState();
}

class _DiseaseMapViewState extends State<DiseaseMapView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  final List<DiseaseOutbreak> _outbreaks = [
    DiseaseOutbreak(
      location: 'Farm Valley - 2.3km NE',
      disease: 'Foot & Mouth Disease',
      severity: OutbreakSeverity.critical,
      position: const Offset(0.7, 0.3),
      affectedCount: 45,
      timeAgo: '2 hours ago',
    ),
    DiseaseOutbreak(
      location: 'Green Pastures - 4.1km SW',
      disease: 'Bovine Tuberculosis',
      severity: OutbreakSeverity.high,
      position: const Offset(0.2, 0.7),
      affectedCount: 12,
      timeAgo: '6 hours ago',
    ),
    DiseaseOutbreak(
      location: 'Riverside Ranch - 5.8km N',
      disease: 'Lumpy Skin Disease',
      severity: OutbreakSeverity.medium,
      position: const Offset(0.5, 0.1),
      affectedCount: 8,
      timeAgo: '1 day ago',
    ),
    DiseaseOutbreak(
      location: 'Meadow Farms - 3.2km SE',
      disease: 'Brucellosis',
      severity: OutbreakSeverity.low,
      position: const Offset(0.8, 0.8),
      affectedCount: 3,
      timeAgo: '3 days ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      color: AppColors.backgroundColor,
      child: Column(
        children: [
          // Map Controls
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
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
                          'Current Location: Agra, UP',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _zoomLevel = math.min(_zoomLevel + 0.2, 2.0);
                          });
                          HapticFeedback.lightImpact();
                        },
                        iconSize: 20,
                      ),
                      Container(
                        height: 1,
                        width: 20,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            _zoomLevel = math.max(_zoomLevel - 0.2, 0.5);
                          });
                          HapticFeedback.lightImpact();
                        },
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map Area
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                        painter: DiseaseMapPainter(
                          outbreaks: _outbreaks,
                          pulseAnimation: _pulseController,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              // Your Location (Center)
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
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
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

                              // Disease Outbreak Markers
                              ..._outbreaks.map((outbreak) {
                                return Positioned(
                                  left: size.width * outbreak.position.dx - 15,
                                  top: size.height * outbreak.position.dy,
                                  child: GestureDetector(
                                    onTap: () => _showOutbreakDetails(outbreak),
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale:
                                              outbreak.severity ==
                                                  OutbreakSeverity.critical
                                              ? 1.0 +
                                                    (_pulseController.value *
                                                        0.3)
                                              : 1.0,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _getSeverityColor(
                                                outbreak.severity,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _getSeverityColor(
                                                    outbreak.severity,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.warning,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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
          ),

          // Legend
          Container(
            margin: EdgeInsets.all(isTablet ? 16 : 12),
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alert Levels',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
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
                      count: 1,
                      isTablet: isTablet,
                    ),
                    _LegendItem(
                      color: Colors.orange,
                      label: 'High',
                      count: 1,
                      isTablet: isTablet,
                    ),
                    _LegendItem(
                      color: Colors.yellow.shade700,
                      label: 'Medium',
                      count: 1,
                      isTablet: isTablet,
                    ),
                    _LegendItem(
                      color: Colors.green,
                      label: 'Low',
                      count: 1,
                      isTablet: isTablet,
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

  Color _getSeverityColor(OutbreakSeverity severity) {
    switch (severity) {
      case OutbreakSeverity.critical:
        return Colors.red;
      case OutbreakSeverity.high:
        return Colors.orange;
      case OutbreakSeverity.medium:
        return Colors.yellow.shade700;
      case OutbreakSeverity.low:
        return Colors.green;
    }
  }

  void _showOutbreakDetails(DiseaseOutbreak outbreak) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getSeverityColor(outbreak.severity),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outbreak.disease,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            outbreak.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow('Animals Affected', '${outbreak.affectedCount}'),
                    _DetailRow('Reported', outbreak.timeAgo),
                    _DetailRow(
                      'Risk Level',
                      outbreak.severity.name.toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Recommended Actions:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Restrict animal movement\n• Contact veterinary services\n• Implement biosecurity measures\n• Monitor your livestock closely',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.secondaryTextColor, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: isTablet ? 11 : 10,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

class DiseaseMapPainter extends CustomPainter {
  final List<DiseaseOutbreak> outbreaks;
  final Animation<double> pulseAnimation;

  DiseaseMapPainter({required this.outbreaks, required this.pulseAnimation})
    : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw map background (simplified)
    paint.color = Colors.grey.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw roads/paths
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    // Horizontal roads
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

    // Vertical roads
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
    paint.color = Colors.green.shade50;

    final farmAreas = [
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.1,
        size.width * 0.3,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.05,
        size.width * 0.35,
        size.height * 0.2,
      ),
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.6,
        size.width * 0.25,
        size.height * 0.25,
      ),
      Rect.fromLTWH(
        size.width * 0.6,
        size.height * 0.65,
        size.width * 0.3,
        size.height * 0.2,
      ),
    ];

    for (final area in farmAreas) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(area, const Radius.circular(8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum OutbreakSeverity { critical, high, medium, low }

class DiseaseOutbreak {
  final String location;
  final String disease;
  final OutbreakSeverity severity;
  final Offset position;
  final int affectedCount;
  final String timeAgo;

  DiseaseOutbreak({
    required this.location,
    required this.disease,
    required this.severity,
    required this.position,
    required this.affectedCount,
    required this.timeAgo,
  });
}
