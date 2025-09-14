import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../../../../core/constants/app_colors.dart';

class DiseaseTrackingPage extends StatefulWidget {
  const DiseaseTrackingPage({super.key});
  @override
  State<DiseaseTrackingPage> createState() => _DiseaseTrackingPageState();
}

class _DiseaseTrackingPageState extends State<DiseaseTrackingPage>
    with TickerProviderStateMixin {
  MapController _mapController = MapController();
  Position? _currentPosition;
  late AnimationController _pulseController;
  List<Marker> _markers = [];
  List<CircleMarker> _riskZones = [];
  bool _isLoading = true;
  bool _isMapView = true;
  String _currentAddress = 'Locating...';

  // Delhi NCR region outbreaks data - converted from your EnhancedDiseaseMapView
  final List<DiseaseOutbreak> _outbreaks = [
    DiseaseOutbreak(
      id: 'FMD_001',
      disease: 'Foot & Mouth Disease',
      location: 'Ghaziabad District',
      farmName: 'Green Valley Dairy Farm',
      coordinates: const LatLng(28.6692, 77.4538),
      severity: AlertSeverity.critical,
      affectedAnimals: 156,
      reportedTime: DateTime.now().subtract(const Duration(hours: 2)),
      status: OutbreakStatus.spreading,
      riskRadius: 2000,
      distance: 15.2,
    ),
    DiseaseOutbreak(
      id: 'BT_002',
      disease: 'Bovine Tuberculosis',
      location: 'Faridabad District',
      farmName: 'Sunrise Cattle Ranch',
      coordinates: const LatLng(28.4089, 77.3178),
      severity: AlertSeverity.high,
      affectedAnimals: 43,
      reportedTime: DateTime.now().subtract(const Duration(hours: 6)),
      status: OutbreakStatus.contained,
      riskRadius: 1500,
      distance: 22.8,
    ),
    DiseaseOutbreak(
      id: 'LSD_003',
      disease: 'Lumpy Skin Disease',
      location: 'Gurugram District',
      farmName: 'Heritage Livestock Farm',
      coordinates: const LatLng(28.4595, 77.0266),
      severity: AlertSeverity.medium,
      affectedAnimals: 28,
      reportedTime: DateTime.now().subtract(const Duration(hours: 18)),
      status: OutbreakStatus.monitoring,
      riskRadius: 1200,
      distance: 31.5,
    ),
    DiseaseOutbreak(
      id: 'BR_004',
      disease: 'Brucellosis',
      location: 'Noida District',
      farmName: 'Modern Dairy Complex',
      coordinates: const LatLng(28.5355, 77.3910),
      severity: AlertSeverity.low,
      affectedAnimals: 12,
      reportedTime: DateTime.now().subtract(const Duration(days: 1)),
      status: OutbreakStatus.resolved,
      riskRadius: 800,
      distance: 18.7,
    ),
    DiseaseOutbreak(
      id: 'PPR_005',
      disease: 'Peste des Petits Ruminants',
      location: 'Meerut District',
      farmName: 'Rural Goat Farm',
      coordinates: const LatLng(28.9845, 77.7064),
      severity: AlertSeverity.high,
      affectedAnimals: 67,
      reportedTime: DateTime.now().subtract(const Duration(hours: 4)),
      status: OutbreakStatus.spreading,
      riskRadius: 1800,
      distance: 45.3,
    ),
    DiseaseOutbreak(
      id: 'AI_006',
      disease: 'Avian Influenza',
      location: 'Sonipat District',
      farmName: 'Delhi Poultry Farm',
      coordinates: const LatLng(28.9931, 77.0151),
      severity: AlertSeverity.critical,
      affectedAnimals: 234,
      reportedTime: DateTime.now().subtract(const Duration(hours: 1)),
      status: OutbreakStatus.spreading,
      riskRadius: 2500,
      distance: 52.1,
    ),
  ];

  static const LatLng _delhiCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _getCurrentLocation();
    _createMarkersAndZones();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services disabled - Delhi NCR';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permission denied - Delhi NCR';
            _isLoading = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _currentAddress = '${place.locality}, ${place.administrativeArea}';
        }
        _isLoading = false;
      });

      _createMarkersAndZones();
    } catch (e) {
      setState(() {
        _currentAddress = 'Delhi NCR, India';
        _isLoading = false;
      });
    }
  }

  void _createMarkersAndZones() {
    List<Marker> markers = [];
    List<CircleMarker> riskZones = [];

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    for (final outbreak in _outbreaks) {
      markers.add(
        Marker(
          point: outbreak.coordinates,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showOutbreakDetails(outbreak),
            child: Icon(
              Icons.location_on,
              color: _getSeverityColor(outbreak.severity),
              size: 40,
            ),
          ),
        ),
      );

      riskZones.add(
        CircleMarker(
          point: outbreak.coordinates,
          radius:
              outbreak.riskRadius / 100, // Convert meters to appropriate scale
          color: _getSeverityColor(outbreak.severity).withOpacity(0.15),
          borderColor: _getSeverityColor(outbreak.severity).withOpacity(0.5),
          borderStrokeWidth: 2,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _riskZones = riskZones;
    });
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
          'Disease Tracking - Delhi NCR',
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
          if (_isMapView)
            IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: _goToCurrentLocation,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _getCurrentLocation();
              HapticFeedback.mediumImpact();
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
                  ? _buildEnhancedMapView(isTablet)
                  : _buildAlertsList(isTablet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(bool isTablet) {
    final criticalOutbreaks = _outbreaks
        .where((o) => o.severity == AlertSeverity.critical)
        .toList();

    if (criticalOutbreaks.isEmpty) return const SizedBox();

    final nearestCritical = criticalOutbreaks.first;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(
              color: Colors.red.withOpacity(
                0.3 + (_pulseController.value * 0.2),
              ),
              width: 2,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 20,
            vertical: isTablet ? 12 : 10,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(
                    0.1 + (_pulseController.value * 0.1),
                  ),
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
                  'CRITICAL: ${nearestCritical.disease} outbreak in ${nearestCritical.location} - ${nearestCritical.distance.toStringAsFixed(1)}km away',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showOutbreakDetails(nearestCritical),
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
      },
    );
  }

  Widget _buildEnhancedMapView(bool isTablet) {
    return Container(
      key: const ValueKey('enhanced_map'),
      margin: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location Info Bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isLoading ? 'Getting location...' : _currentAddress,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                ),
                if (_isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Flutter Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        )
                      : _delhiCenter,
                  initialZoom: 10.0,
                  maxZoom: 18.0,
                  minZoom: 3.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.codegamma_sih',
                  ),
                  CircleLayer(circles: _riskZones),
                  MarkerLayer(markers: _markers),
                ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Outbreaks',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_outbreaks.length} active',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
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
                  pulseController: _pulseController,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        12.0,
      );
      HapticFeedback.lightImpact();
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
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Header
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(outbreak.severity),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: outbreak.severity == AlertSeverity.critical
                          ? [
                              BoxShadow(
                                color: _getSeverityColor(outbreak.severity)
                                    .withOpacity(
                                      0.3 + (_pulseController.value * 0.2),
                                    ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
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
                  );
                },
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
                    _DetailRow(
                      'Risk Radius',
                      '${outbreak.riskRadius / 1000} km',
                    ),
                    _DetailRow('Reported', _getTimeAgo(outbreak.reportedTime)),
                    _DetailRow(
                      'Severity',
                      outbreak.severity.name.toUpperCase(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _mapController.move(outbreak.coordinates, 14.0);
                              setState(() {
                                _isMapView = true;
                              });
                            },
                            icon: const Icon(
                              Icons.center_focus_strong,
                              size: 16,
                            ),
                            label: const Text('Center on Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share Alert'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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

// Enhanced Stats Widget
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
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.lightGreen.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
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

// Enhanced Disease Alert Card
class DiseaseAlertCard extends StatelessWidget {
  final DiseaseOutbreak outbreak;
  final bool isTablet;
  final VoidCallback onTap;
  final AnimationController pulseController;

  const DiseaseAlertCard({
    super.key,
    required this.outbreak,
    required this.isTablet,
    required this.onTap,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: outbreak.severity == AlertSeverity.critical
                  ? Border.all(
                      color: Colors.red.withOpacity(
                        0.3 + (pulseController.value * 0.2),
                      ),
                      width: 2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (outbreak.severity == AlertSeverity.critical)
                  BoxShadow(
                    color: Colors.red.withOpacity(
                      0.1 + (pulseController.value * 0.05),
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(
                      outbreak.severity,
                    ).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(outbreak.severity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSeverityIcon(outbreak.severity),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outbreak.disease,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              outbreak.farmName,
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 10,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(outbreak.severity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              outbreak.severity.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: isTablet ? 10 : 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${outbreak.distance.toStringAsFixed(1)}km',
                            style: TextStyle(
                              fontSize: isTablet ? 11 : 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              outbreak.location,
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 11,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.pets_outlined,
                            size: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${outbreak.affectedAnimals} affected',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(outbreak.status),
                                size: 14,
                                color: _getStatusColor(outbreak.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                outbreak.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isTablet ? 10 : 9,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(outbreak.status),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _getTimeAgo(outbreak.reportedTime),
                            style: TextStyle(
                              fontSize: isTablet ? 10 : 9,
                              color: AppColors.secondaryTextColor,
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
        );
      },
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

  Color _getStatusColor(OutbreakStatus status) {
    switch (status) {
      case OutbreakStatus.spreading:
        return Colors.red;
      case OutbreakStatus.contained:
        return Colors.orange;
      case OutbreakStatus.monitoring:
        return Colors.blue;
      case OutbreakStatus.resolved:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(OutbreakStatus status) {
    switch (status) {
      case OutbreakStatus.spreading:
        return Icons.trending_up;
      case OutbreakStatus.contained:
        return Icons.shield;
      case OutbreakStatus.monitoring:
        return Icons.visibility;
      case OutbreakStatus.resolved:
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models - Updated to match your existing structure
enum AlertSeverity { critical, high, medium, low }

enum OutbreakStatus { spreading, contained, monitoring, resolved }

class DiseaseOutbreak {
  final String id;
  final String disease;
  final String location;
  final String farmName;
  final LatLng coordinates;
  final AlertSeverity severity;
  final int affectedAnimals;
  final DateTime reportedTime;
  final OutbreakStatus status;
  final int riskRadius; // in meters
  final double distance; // in km

  DiseaseOutbreak({
    required this.id,
    required this.disease,
    required this.location,
    required this.farmName,
    required this.coordinates,
    required this.severity,
    required this.affectedAnimals,
    required this.reportedTime,
    required this.status,
    required this.riskRadius,
    required this.distance,
  });
}
