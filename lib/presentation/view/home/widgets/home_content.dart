import 'package:codegamma_sih/presentation/view/alerts/moderate_alert.dart';
import 'package:codegamma_sih/presentation/view/alerts/urgent_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  // ----------------- Navigation (unchanged behavior) -----------------
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final statItems = [
      _StatData('Total Animal Currently', '2,345', Icons.pets),
      _StatData('Total Vaccinations This Month', '4,128', Icons.people),
      _StatData('Total Vaccination Left', '1,230', Icons.medical_services),
      _StatData('Next Vet Appointment', '11 Sept', Icons.science),
    ];

    // Fake monthly transaction count (current month)
    const monthlyTransactions = '38%';

    final services = [
      _ServiceData('Owner\nManagement', Icons.person_add_outlined),
      _ServiceData('Animal\nManagement', Icons.pets_outlined),
      _ServiceData('Flock\nManagement', Icons.groups_outlined),
      _ServiceData('Animal Health\nRecord', Icons.health_and_safety_outlined),
      _ServiceData('Animal\nBreeding', Icons.favorite_border_outlined),
      _ServiceData('PR', Icons.description_outlined),
      _ServiceData('Animal\nNutrition', Icons.restaurant_outlined),
      _ServiceData('Miscellaneous', Icons.more_horiz_outlined),
      _ServiceData('Disease\nTracking', Icons.coronavirus_outlined),
      _ServiceData('Feed\nInventory', Icons.inventory_2_outlined),
      _ServiceData('Market\nPrices', Icons.trending_up_outlined),
      _ServiceData('Reports', Icons.assessment_outlined),
    ];
    final activities = [
      _ActivityData(
        'Withdrawal Period Alert',
        'Farm ID: F001 - Expires in 2 days',
        Icons.warning_amber_outlined,
        Colors.red,
        true,
      ),
      _ActivityData(
        'MRL Compliance Check',
        'All levels within safe limits - Farm F089',
        Icons.verified_outlined,
        Colors.green,
        false,
      ),
      _ActivityData(
        'New AMU Record Added',
        'Antimicrobial usage logged successfully',
        Icons.add_circle_outline,
        AppColors.primaryColor,
        false,
      ),
      _ActivityData(
        'Vaccination Reminder',
        'Due for 15 animals in Farm F023',
        Icons.schedule_outlined,
        Colors.orange,
        false,
      ),
    ];

    return CustomScrollView(
      slivers: [
        // ----------------- Gradient Header with Horizontal Stats -----------------
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryColor, AppColors.primaryColorLight],
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
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: isTablet ? 20 : 18,
                        ),
                      ),
                      SizedBox(width: isTablet ? 14 : 10),
                      Expanded(
                        child: Text(
                          'This months sales increase',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isTablet ? 15 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        monthlyTransactions,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 18),
                _StatsSummaryCard(items: statItems, isTablet: isTablet),
              ],
            ),
          ),
        ),

        // ----------------- Quick Services -----------------
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 30 : 26,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(label: 'Quick Service', isTablet: isTablet),
          ),
        ),
        // Uniform grid for services (all cards equal size)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 14 : 12,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              // Responsive 3-column layout (3x4 grid) with overflow protection
              final width = constraints.crossAxisExtent;
              int crossAxisCount;
              if (width < 300) {
                crossAxisCount = 2; // Very small screens: 2 columns
              } else if (width < 480) {
                crossAxisCount = 3; // Default: 3 columns (3x4 layout)
              } else {
                crossAxisCount = 3; // Keep 3 columns for larger screens too
              }
              final spacing = isTablet ? 14.0 : 10.0;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  // Responsive aspect ratio for 3-column layout
                  childAspectRatio: crossAxisCount == 2 ? 1.6 : 1.2,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final s = services[index];
                  return _ServiceCard(
                    data: s,
                    isTablet: isTablet,
                    onLongPress: () {
                      if (s.title == 'Animal Health\nRecord') {
                        _handleAlertButtonPress(context, 'urgent');
                      } else if (s.title == 'Miscellaneous') {
                        _handleAlertButtonPress(context, 'moderate');
                      } else if (s.title == 'Disease\nTracking') {
                        _handleAlertButtonPress(context, 'urgent');
                      }
                      // Add more long press actions here for new cards if needed
                    },
                  );
                }, childCount: services.length),
              );
            },
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            isTablet ? 40 : 34,
            isTablet ? 32 : 20,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(label: 'Recent Activity', isTablet: isTablet),
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
              activities: activities,
              isTablet: isTablet,
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== Data Models (lightweight) =====================
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  _StatData(this.label, this.value, this.icon);
}

class _ServiceData {
  final String title;
  final IconData icon;
  _ServiceData(this.title, this.icon);
}

class _ActivityData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool urgent;
  _ActivityData(this.title, this.subtitle, this.icon, this.color, this.urgent);
}

// ===================== Reusable Section Header =====================
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
          height: isTablet ? 28 : 24,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ===================== Statistics Summary Card (no horizontal scroll) =====================
class _StatsSummaryCard extends StatelessWidget {
  final List<_StatData> items;
  final bool isTablet;
  const _StatsSummaryCard({required this.items, required this.isTablet});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fixed 2x2 layout
          final maxWidth = constraints.maxWidth;
          const crossAxisCount = 2;
          final spacing = isTablet ? 20.0 : 14.0;
          final itemWidth = (maxWidth - spacing) / crossAxisCount;
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
      padding: EdgeInsets.all(isTablet ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: isTablet ? 22 : 18,
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
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  data.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isTablet ? 12.5 : 11,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
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

// ===================== Service Card =====================
class _ServiceCard extends StatefulWidget {
  final _ServiceData data;
  final bool isTablet;
  final VoidCallback onLongPress;
  const _ServiceCard({
    required this.data,
    required this.isTablet,
    required this.onLongPress,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isTablet ? 8 : 5,
          vertical: widget.isTablet ? 8 : 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: widget.isTablet ? 40 : 36,
              width: widget.isTablet ? 40 : 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.data.icon,
                color: Colors.white,
                size: widget.isTablet ? 22 : 20,
              ),
            ),
            SizedBox(height: widget.isTablet ? 6 : 5),
            Text(
              widget.data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: widget.isTablet ? 11 : 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextColor,
                height: 1.1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Activity Timeline =====================
class _ActivityTimeline extends StatelessWidget {
  final List<_ActivityData> activities;
  final bool isTablet;
  const _ActivityTimeline({required this.activities, required this.isTablet});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 20 : 16,
        isTablet ? 18 : 14,
        isTablet ? 20 : 16,
        isTablet ? 10 : 8,
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
    return SizedBox(
      height: isTablet ? 82 : 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline axis
          SizedBox(
            width: 34,
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 0,
                  bottom: isLast ? 30 : 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: isTablet ? 20 : 18,
                    height: isTablet ? 20 : 18,
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: data.color.withOpacity(0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      data.icon,
                      size: isTablet ? 12 : 11,
                      color: data.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
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
                          fontSize: isTablet ? 15.5 : 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextColor,
                          height: 1.15,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      '2h ago',
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 9.5,
                        color: AppColors.mutedTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11.5,
                    color: AppColors.secondaryTextColor,
                    height: 1.2,
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: isTablet ? 22 : 18,
                    thickness: 0.6,
                    color: Colors.grey.withOpacity(0.35),
                  ),
              ],
            ),
          ),
          if (data.urgent)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Text(
                  'URGENT',
                  style: TextStyle(
                    fontSize: isTablet ? 10.5 : 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
