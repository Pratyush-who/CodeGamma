import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/disease/alertcard.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/disease/outbreak.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/disease/stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:maps_launcher/maps_launcher.dart';

class DiseaseTrackingPage extends StatefulWidget {
  const DiseaseTrackingPage({super.key});

  @override
  State<DiseaseTrackingPage> createState() => _DiseaseTrackingPageState();
}

class _DiseaseTrackingPageState extends State<DiseaseTrackingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMapView = true;
  late AnimationController _pulseController;

  final List<DiseaseOutbreak> _outbreaks = [
    DiseaseOutbreak(
      id: 'FMD_001',
      disease: 'Foot & Mouth Disease',
      location: 'Mathura District',
      distance: 12.3,
      severity: AlertSeverity.critical,
      affectedAnimals: 156,
      reportedTime: DateTime.now().subtract(const Duration(hours: 2)),
      coordinates: const LatLng(27.4924, 77.6737),
      farmName: 'Green Valley Dairy',
      status: OutbreakStatus.spreading,
    ),
    DiseaseOutbreak(
      id: 'BT_002',
      disease: 'Bovine Tuberculosis',
      location: 'Firozabad District',
      distance: 18.7,
      severity: AlertSeverity.high,
      affectedAnimals: 43,
      reportedTime: DateTime.now().subtract(const Duration(hours: 8)),
      coordinates: const LatLng(27.1592, 78.3957),
      farmName: 'Sunrise Cattle Farm',
      status: OutbreakStatus.contained,
    ),
    DiseaseOutbreak(
      id: 'LSD_003',
      disease: 'Lumpy Skin Disease',
      location: 'Mainpuri District',
      distance: 25.4,
      severity: AlertSeverity.medium,
      affectedAnimals: 28,
      reportedTime: DateTime.now().subtract(const Duration(days: 1)),
      coordinates: const LatLng(27.2379, 79.0177),
      farmName: 'Riverside Ranch',
      status: OutbreakStatus.monitoring,
    ),
    DiseaseOutbreak(
      id: 'BR_004',
      disease: 'Brucellosis',
      location: 'Etah District',
      distance: 31.2,
      severity: AlertSeverity.low,
      affectedAnimals: 12,
      reportedTime: DateTime.now().subtract(const Duration(days: 3)),
      coordinates: const LatLng(27.6300, 78.6644),
      farmName: 'Heritage Livestock',
      status: OutbreakStatus.resolved,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Disease Tracking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMapView ? Icons.list_alt_outlined : Icons.map_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
              HapticFeedback.lightImpact();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Refresh data
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Critical Alert Banner
          _buildAlertBanner(isTablet),

          // Disease Stats Overview
          DiseaseStatsWidget(
            totalOutbreaks: _outbreaks.length,
            criticalAlerts: _outbreaks
                .where((o) => o.severity == AlertSeverity.critical)
                .length,
            totalAffected: _outbreaks.fold(
              0,
              (sum, outbreak) => sum + outbreak.affectedAnimals,
            ),
            isTablet: isTablet,
          ),

          // Main Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isMapView
                  ? OutbreakMapWidget(
                      key: const ValueKey('map'),
                      outbreaks: _outbreaks,
                      pulseController: _pulseController,
                      isTablet: isTablet,
                      onOutbreakTap: _showOutbreakDetails,
                    )
                  : _buildAlertsList(isTablet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(bool isTablet) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: isTablet ? 12 : 10,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'High Alert: FMD outbreak spreading in Mathura region - 12km away',
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showOutbreakDetails(_outbreaks[0]),
            child: Text(
              'Details',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(bool isTablet) {
    return Container(
      key: const ValueKey('list'),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Outbreaks',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _outbreaks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final outbreak = _outbreaks[index];
                return DiseaseAlertCard(
                  outbreak: outbreak,
                  isTablet: isTablet,
                  onTap: () => _showOutbreakDetails(outbreak),
                  onNavigate: () => _navigateToLocation(outbreak.coordinates),
                );
              },
            ),
          ),
        ],
      ),
    );
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
              // Header
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
                    Icon(
                      _getSeverityIcon(outbreak.severity),
                      color: Colors.white,
                      size: 24,
                    ),
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
                            '${outbreak.farmName} • ${outbreak.distance.toStringAsFixed(1)}km away',
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
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow('Location', outbreak.location),
                    _DetailRow(
                      'Animals Affected',
                      '${outbreak.affectedAnimals}',
                    ),
                    _DetailRow('Status', outbreak.status.name.toUpperCase()),
                    _DetailRow('Reported', _getTimeAgo(outbreak.reportedTime)),
                    _DetailRow(
                      'Risk Level',
                      outbreak.severity.name.toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _navigateToLocation(outbreak.coordinates),
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Share outbreak info
                            },
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
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

  void _navigateToLocation(LatLng coordinates) async {
    try {
      await MapsLauncher.launchCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
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

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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

// Data Models
enum AlertSeverity { critical, high, medium, low }

enum OutbreakStatus { spreading, contained, monitoring, resolved }

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class DiseaseOutbreak {
  final String id;
  final String disease;
  final String location;
  final double distance;
  final AlertSeverity severity;
  final int affectedAnimals;
  final DateTime reportedTime;
  final LatLng coordinates;
  final String farmName;
  final OutbreakStatus status;

  DiseaseOutbreak({
    required this.id,
    required this.disease,
    required this.location,
    required this.distance,
    required this.severity,
    required this.affectedAnimals,
    required this.reportedTime,
    required this.coordinates,
    required this.farmName,
    required this.status,
  });
}
