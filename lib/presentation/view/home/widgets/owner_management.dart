import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class OwnerManagementScreen extends StatelessWidget {
  const OwnerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final Owner owner = Owner(
      ownerId: "OWN001",
      name: "Rajesh Kumar",
      age: 42,
      location: "Sonipat, Haryana",
      phoneNumber: "+91 9876543210",
      email: "rajesh.kumar@example.com",
      farmSize: "12 acres",
      experience: "15 years",
      livestockCount: 197,
      flocks: [
        Flock(
          flockId: "FL001",
          name: "Dairy Cattle",
          type: "Cattle",
          animalCount: 32,
          breed: "Holstein Friesian",
        ),
        Flock(
          flockId: "FL002",
          name: "Goat Herd",
          type: "Goat",
          animalCount: 45,
          breed: "Sirohi",
        ),
        Flock(
          flockId: "FL003",
          name: "Poultry",
          type: "Chicken",
          animalCount: 120,
          breed: "Kadaknath",
        ),
      ],
      totalAnimals: 197,
      registrationDate: DateTime(2018, 5, 12),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.whiteColor,
        title: const Text(
          'Owner Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner Profile Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 40 : 32,
                        backgroundColor: AppColors.lightGreen,
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryColor,
                          size: isTablet ? 36 : 28,
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              owner.name,
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Owner ID: ${owner.ownerId}',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, 
                                    size: 16, color: AppColors.secondaryTextColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Registered: ${_formatDate(owner.registrationDate)}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DetailItem(
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        value: owner.location,
                        color: AppColors.accentGreen,
                        width: isTablet ? (size.width - 96) / 3 - 12 : (size.width - 64) / 2 - 12,
                      ),
                      _DetailItem(
                        icon: Icons.phone_rounded,
                        title: 'Contact',
                        value: owner.phoneNumber,
                        color: AppColors.secondaryGreen,
                        width: isTablet ? (size.width - 96) / 3 - 12 : (size.width - 64) / 2 - 12,
                      ),
                      _DetailItem(
                        icon: Icons.email_rounded,
                        title: 'Email',
                        value: owner.email,
                        color: AppColors.primaryColorLight,
                        width: isTablet ? (size.width - 96) / 3 - 12 : (size.width - 64) / 1 - 12,
                      ),
                      _DetailItem(
                        icon: Icons.agriculture_rounded,
                        title: 'Farm Size',
                        value: owner.farmSize,
                        color: AppColors.darkGreen,
                        width: isTablet ? (size.width - 96) / 3 - 12 : (size.width - 64) / 2 - 12,
                      ),
                      _DetailItem(
                        icon: Icons.pets_rounded,
                        title: 'Total Livestock',
                        value: owner.livestockCount.toString(),
                        color: AppColors.primaryColorDark,
                        width: isTablet ? (size.width - 96) / 3 - 12 : (size.width - 64) / 2 - 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Livestock Section
            Text(
              'Livestock Details',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            // Flocks List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: owner.flocks.length,
              itemBuilder: (context, index) {
                final flock = owner.flocks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getFlockColor(flock.type).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getFlockIcon(flock.type),
                          color: _getFlockColor(flock.type),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flock.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${flock.animalCount} ${flock.type}s • ${flock.breed}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        backgroundColor: _getFlockColor(flock.type).withOpacity(0.15),
                        side: BorderSide.none,
                        label: Text(
                          flock.type,
                          style: TextStyle(
                            color: _getFlockColor(flock.type),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Farm Statistics
            Text(
              'Farm Statistics',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            // Statistics - Using Wrap instead of GridView
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  title: 'Total Animals',
                  value: owner.totalAnimals.toString(),
                  icon: Icons.pets_rounded,
                  color: AppColors.primaryColor,
                  width: isTablet ? (size.width - 72) / 4 - 12 : (size.width - 44) / 2 - 12,
                ),
                _StatCard(
                  title: 'Livestock Value',
                  value: '₹4.2L',
                  icon: Icons.attach_money_rounded,
                  color: AppColors.accentGreen,
                  width: isTablet ? (size.width - 72) / 4 - 12 : (size.width - 44) / 2 - 12,
                ),
                _StatCard(
                  title: 'Monthly Production',
                  value: '320L',
                  icon: Icons.local_drink_rounded,
                  color: AppColors.secondaryGreen,
                  width: isTablet ? (size.width - 72) / 4 - 12 : (size.width - 44) / 2 - 12,
                ),
                _StatCard(
                  title: 'Vaccination Due',
                  value: '12 Animals',
                  icon: Icons.medical_services_rounded,
                  color: AppColors.primaryColorLight,
                  width: isTablet ? (size.width - 72) / 4 - 12 : (size.width - 44) / 2 - 12,
                ),
              ],
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getFlockIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cattle': return Icons.agriculture_rounded;
      case 'goat': return Icons.pets_rounded;
      case 'chicken': return Icons.egg_rounded;
      default: return Icons.pets_rounded;
    }
  }

  Color _getFlockColor(String type) {
    switch (type.toLowerCase()) {
      case 'cattle': return AppColors.darkGreen;
      case 'goat': return AppColors.accentGreen;
      case 'chicken': return AppColors.primaryColorDark;
      default: return AppColors.primaryColor;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final double width;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTextColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// Models
class Owner {
  final String ownerId;
  final String name;
  final int age;
  final String location;
  final String phoneNumber;
  final String email;
  final String farmSize;
  final String experience;
  final int livestockCount;
  final List<Flock> flocks;
  final int totalAnimals;
  final DateTime registrationDate;

  Owner({
    required this.ownerId,
    required this.name,
    required this.age,
    required this.location,
    required this.phoneNumber,
    required this.email,
    required this.farmSize,
    required this.experience,
    required this.livestockCount,
    required this.flocks,
    required this.totalAnimals,
    required this.registrationDate,
  });
}

class Flock {
  final String flockId;
  final String name;
  final String type;
  final int animalCount;
  final String breed;

  Flock({
    required this.flockId,
    required this.name,
    required this.type,
    required this.animalCount,
    required this.breed,
  });
}