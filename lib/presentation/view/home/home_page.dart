import 'package:codegamma_sih/presentation/view/alerts/alertspage.dart';
import 'package:codegamma_sih/presentation/view/analytics/analytics.dart';
import 'package:codegamma_sih/presentation/view/scanner/centre_button.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/home_content.dart';
import 'package:codegamma_sih/presentation/view/profile/profilepage.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const AnalyticsPage(),
    const HomeContent(),
    const AlertsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildSimpleAppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryColor, AppColors.primaryColorLight],
          ),
        ),
      ),
      elevation: 0,
      title: const Text(
        'PashuSeva',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.whiteColor,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications clicked'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side buttons
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          index: 0,
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildNavItem(
                          icon: Icons.bar_chart_outlined,
                          activeIcon: Icons.bar_chart_rounded,
                          index: 1,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: isSmallScreen ? 50 : 60),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications_rounded,
                          index: 3,
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildNavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          index: 4,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: -12,
            left: screenWidth / 2 - (isSmallScreen ? 25 : 28),
            child: GestureDetector(
              onTap: () => _onNavItemTapped(2),
              child: Container(
                width: isSmallScreen ? 50 : 56,
                height: isSmallScreen ? 50 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.document_scanner,
                  color: Colors.white,
                  size: isSmallScreen ? 24 : 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required bool isSmallScreen,
  }) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primaryColor : Colors.grey[500],
          size: isSmallScreen ? 26 : 28,
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      // Navigate to scanner as full screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddPage()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }
}
