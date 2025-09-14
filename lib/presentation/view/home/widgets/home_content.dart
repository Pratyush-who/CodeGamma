import 'package:codegamma_sih/presentation/view/alerts/moderate_alert.dart';
import 'package:codegamma_sih/presentation/view/alerts/urgent_alert.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _secretButtonController;
  bool _showSecretFeatures = false;
  int _secretTapCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _secretButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _secretButtonController.dispose();
    super.dispose();
  }

  void _handleAlertButtonPress(BuildContext context, String alertType) {
    HapticFeedback.heavyImpact();
    Widget alertScreen;
    switch (alertType) {
      case 'urgent':
        alertScreen = const UrgentAlertScreen();
        break;
      case 'moderate':
        alertScreen = const ModerateAlertScreen();
        break;
      default:
        return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => alertScreen,
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  void _activateSecretMode() {
    setState(() {
      _showSecretFeatures = !_showSecretFeatures;
    });
    _secretButtonController.forward().then((_) {
      _secretButtonController.reverse();
    });
    HapticFeedback.mediumImpact();
  }

  void _handleSecretTap() {
    _secretTapCount++;
    if (_secretTapCount >= 5) {
      _activateSecretMode();
      _secretTapCount = 0;
    }
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final statItems = [
      _StatData('Total Animals', '2,345', Icons.pets),
      _StatData('Vaccinations Done', '4,128', Icons.vaccines),
      _StatData('Health Checkups', '1,230', Icons.medical_services),
      _StatData('Next Appointment', '11 Sept', Icons.schedule),
    ];

    const monthlyGrowth = '38%';

    final services = [
      _ServiceData('Owner\nManagement', Icons.person),
      _ServiceData('Animal\nManagement', Icons.pets_outlined),
      _ServiceData('Risk\nPrediction', Icons.groups_outlined),
      _ServiceData('Disease\nTracking', Icons.coronavirus_outlined),
      _ServiceData('Market\nPrices', Icons.trending_up_outlined),
      _ServiceData('Reports\nAnalysis', Icons.assessment_outlined),
    ];

    // Sample upcoming events based on calendar
    final upcomingEvents = _getUpcomingEvents();

    return CustomScrollView(
      slivers: [
        // Enhanced Gradient Header
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColorLight,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              isTablet ? 32 : 20,
              isTablet ? 36 : 26,
              isTablet ? 32 : 20,
              isTablet ? 30 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Growth Card
                GestureDetector(
                  onTap: _handleSecretTap,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.1),
                                child: Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 24 : 20,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Growth',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Health metrics improved',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: isTablet ? 13 : 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          monthlyGrowth,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 18),
                _StatsSummaryCard(items: statItems, isTablet: isTablet),
              ],
            ),
          ),
        ),

        // Enhanced Quick Services (moved to appear after hero section)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 30 : 26,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(label: 'Quick Services', isTablet: isTablet),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 14 : 12,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3; // 3x2 grid (3 columns, 2 rows)
              final spacing = isTablet ? 16.0 : 15.0;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: isTablet ? 1.3 : 1.2,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final service = services[index];
                  return _EnhancedServiceCard(
                    data: service,
                    isTablet: isTablet,
                    showSecret: _showSecretFeatures,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // Handle service tap
                      if (service.title == 'Disease\nTracking') {
                        Navigator.pushNamed(context, '/disease-tracking');
                      } else if (service.title == 'Market\nPrices') {
                        Navigator.pushNamed(context, '/market-prices');
                      } else if (service.title == 'Owner\nManagement') {
                        Navigator.pushNamed(context, '/owner-management');
                      } else if (service.title == 'Animal\nManagement') {
                        Navigator.pushNamed(context, '/animal-management');
                      } else if (service.title == 'Risk\nPrediction') {
                        Navigator.pushNamed(context, '/risk-prediction');
                      }
                    },
                    onLongPress: () {
                      if (service.title == 'Animal\nManagement') {
                        _handleAlertButtonPress(context, 'urgent');
                      } else if (service.title == 'Disease\nTracking') {
                        _handleAlertButtonPress(context, 'moderate');
                      }
                    },
                    onDoubleTap: () {
                      if (service.title == 'Reports') {
                        _activateSecretMode();
                      }
                    },
                  );
                }, childCount: services.length),
              );
            },
          ),
        ),

        // Calendar Section (moved to appear after Quick Services)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 30 : 26,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(label: 'Health Calendar', isTablet: isTablet),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 14 : 12,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: CustomCalendar(
              isTablet: isTablet,
              onDateTapped: (date, event) {
                _showEventDetails(
                  context,
                  date,
                  event as List<Map<String, dynamic>>?,
                );
              },
            ),
          ),
        ),

        // Upcoming Events (previously Recent Activity)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 40 : 34,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(label: 'Upcoming Events', isTablet: isTablet),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 18 : 14,
            isTablet ? 32 : 20,
            isTablet ? 40 : 32,
          ),
          sliver: SliverToBoxAdapter(
            child: _ActivityTimeline(
              activities: upcomingEvents,
              isTablet: isTablet,
            ),
          ),
        ),

        // Secret Features Panel
        if (_showSecretFeatures)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 32 : 20,
              0,
              isTablet ? 32 : 20,
              isTablet ? 40 : 32,
            ),
            sliver: SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _secretButtonController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_secretButtonController.value * 0.05),
                    child: _SecretPanel(isTablet: isTablet),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  List<_ActivityData> _getUpcomingEvents() {
    final now = DateTime.now();
    return [
      _ActivityData(
        'Vaccination Schedule',
        'Cattle ID: C001-C015 - FMD vaccine due today',
        Icons.vaccines_outlined,
        Colors.blue,
        true,
        now,
      ),
      _ActivityData(
        'Health Checkup',
        'Monthly health assessment for Farm F089',
        Icons.health_and_safety_outlined,
        Colors.green,
        false,
        now.add(const Duration(days: 1)),
      ),
      _ActivityData(
        'Deworming Treatment',
        'Scheduled for 25 cattle in Block A',
        Icons.medical_services_outlined,
        Colors.orange,
        false,
        now.add(const Duration(days: 2)),
      ),
      _ActivityData(
        'Feed Quality Check',
        'Nutritional analysis and feed inspection',
        Icons.restaurant_outlined,
        AppColors.primaryColor,
        false,
        now.add(const Duration(days: 3)),
      ),
    ];
  }

  void _showEventDetails(
    BuildContext context,
    DateTime date,
    List<Map<String, dynamic>>? events,
  ) {
    if (events == null || events.isEmpty) return;

    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColorLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${events.length} event${events.length > 1 ? 's' : ''} scheduled',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Events List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: events.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (event['color'] as Color).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (event['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (event['color'] as Color).withOpacity(
                                0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              event['icon'],
                              color: event['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event['title'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: event['color'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        event['time'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event['description'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryTextColor,
                                    height: 1.4,
                                  ),
                                ),
                                if (event['type'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (event['color'] as Color)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      event['type'].toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: event['color'],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primaryColor,
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

// Enhanced Service Card
class _EnhancedServiceCard extends StatefulWidget {
  final _ServiceData data;
  final bool isTablet;
  final bool showSecret;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  const _EnhancedServiceCard({
    required this.data,
    required this.isTablet,
    required this.showSecret,
    required this.onTap,
    required this.onLongPress,
    required this.onDoubleTap,
  });

  @override
  State<_EnhancedServiceCard> createState() => _EnhancedServiceCardState();
}

class _EnhancedServiceCardState extends State<_EnhancedServiceCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.showSecret) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(_EnhancedServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSecret != oldWidget.showSecret) {
      if (widget.showSecret) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: widget.onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: widget.showSecret
                ? AppColors.primaryColor.withOpacity(0.6)
                : Colors.grey.withOpacity(0.15),
            width: widget.showSecret ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.08 : 0.04),
              blurRadius: _pressed ? 4 : 6,
              offset: Offset(0, _pressed ? 1 : 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(widget.isTablet ? 4 : 3),
        child: Stack(
          children: [
            if (widget.showSecret)
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment(-1.0, -0.3),
                        end: Alignment(1.0, 0.3),
                        colors: [
                          Colors.transparent,
                          AppColors.primaryColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: [
                          _shimmerController.value - 0.3,
                          _shimmerController.value,
                          _shimmerController.value + 0.3,
                        ],
                      ),
                    ),
                  );
                },
              ),
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Simplified icon container
                  Container(
                    height: widget.isTablet ? 40 : 36,
                    width: widget.isTablet ? 40 : 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.data.icon,
                        color: Colors.white,
                        size: widget.isTablet ? 20 : 20,
                      ),
                    ),
                  ),
                  SizedBox(height: widget.isTablet ? 6 : 4),
                  // Simplified text layout
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        widget.data.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.isTablet ? 11 : 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showSecret)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Secret Features Panel
class _SecretPanel extends StatelessWidget {
  final bool isTablet;
  const _SecretPanel({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.red,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Admin Panel Activated',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Secret features unlocked! Long press Animal Management for urgent alerts, double tap Reports for admin mode.',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Data Models
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  _StatData(this.label, this.value, this.icon);
}

class _ServiceData {
  final String title;
  final IconData icon;
  final String subtitle;
  _ServiceData(this.title, this.icon, {this.subtitle = ''});
}

class _ActivityData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool urgent;
  final DateTime scheduledDate;

  _ActivityData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.urgent,
    this.scheduledDate,
  );
}

// Enhanced Section Header
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isTablet;
  const _SectionHeader({required this.label, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: isTablet ? 32 : 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.primaryColorLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// Enhanced Stats Summary Card
class _StatsSummaryCard extends StatelessWidget {
  final List<_StatData> items;
  final bool isTablet;
  const _StatsSummaryCard({required this.items, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 2;
          final spacing = isTablet ? 20.0 : 16.0;
          final itemWidth = (constraints.maxWidth - spacing) / crossAxisCount;
          return Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _SingleStat(data: items[0], isTablet: isTablet),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: _SingleStat(data: items[1], isTablet: isTablet),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _SingleStat(data: items[2], isTablet: isTablet),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: _SingleStat(data: items[3], isTablet: isTablet),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SingleStat extends StatelessWidget {
  final _StatData data;
  final bool isTablet;
  const _SingleStat({required this.data, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 26 : 19,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isTablet ? 13 : 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Activity Timeline
class _ActivityTimeline extends StatelessWidget {
  final List<_ActivityData> activities;
  final bool isTablet;
  const _ActivityTimeline({required this.activities, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 20,
        isTablet ? 20 : 16,
        isTablet ? 24 : 20,
        isTablet ? 12 : 10,
      ),
      child: Column(
        children: [
          for (int i = 0; i < activities.length; i++) ...[
            _ActivityTile(
              data: activities[i],
              isTablet: isTablet,
              isLast: i == activities.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityData data;
  final bool isTablet;
  final bool isLast;
  const _ActivityTile({
    required this.data,
    required this.isTablet,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntil = data.scheduledDate.difference(DateTime.now()).inDays;
    String timeText;
    if (daysUntil == 0) {
      timeText = 'Today';
    } else if (daysUntil == 1) {
      timeText = 'Tomorrow';
    } else {
      timeText = '${daysUntil}d';
    }

    return SizedBox(
      height: isTablet ? 88 : 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Timeline axis
          SizedBox(
            width: 38,
            child: Stack(
              children: [
                Positioned(
                  left: 17,
                  top: 0,
                  bottom: isLast ? 35 : 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          data.color.withOpacity(0.3),
                          Colors.grey.withOpacity(0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: isTablet ? 22 : 20,
                    height: isTablet ? 22 : 20,
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: data.color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: data.color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      data.icon,
                      size: isTablet ? 13 : 12,
                      color: data.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Enhanced Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        style: TextStyle(
                          fontSize: isTablet ? 16.5 : 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTextColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: data.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          color: data.color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: AppColors.secondaryTextColor,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.only(top: isTablet ? 16 : 12),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (data.urgent)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'URGENT',
                  style: TextStyle(
                    fontSize: isTablet ? 10.5 : 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
