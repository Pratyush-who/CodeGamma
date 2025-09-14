import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OwnerManagementScreen extends StatelessWidget {
  const OwnerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Static owner data
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
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
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                        backgroundColor: AppColors.primaryColor.withOpacity(0.1),
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
                            SizedBox(height: 4),
                            Text(
                              'Owner ID: ${owner.ownerId}',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, 
                                    size: 16, color: AppColors.secondaryTextColor),
                                SizedBox(width: 4),
                                Text(
                                  'Registered: ${_formatDate(owner.registrationDate)}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
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
                  SizedBox(height: 20),
                  // Owner Details Grid
                  GridView.count(
                    crossAxisCount: isTablet ? 3 : 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isTablet ? 3 : 2.5,
                    children: [
                      _DetailItem(
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        value: owner.location,
                        color: Colors.blue,
                      ),
                      _DetailItem(
                        icon: Icons.phone_rounded,
                        title: 'Contact',
                        value: owner.phoneNumber,
                        color: Colors.green,
                      ),
                      _DetailItem(
                        icon: Icons.email_rounded,
                        title: 'Email',
                        value: owner.email,
                        color: Colors.orange,
                      ),
                      _DetailItem(
                        icon: Icons.agriculture_rounded,
                        title: 'Farm Size',
                        value: owner.farmSize,
                        color: Colors.purple,
                      ),
                      _DetailItem(
                        icon: Icons.work_history_rounded,
                        title: 'Experience',
                        value: owner.experience,
                        color: Colors.teal,
                      ),
                      _DetailItem(
                        icon: Icons.pets_rounded,
                        title: 'Total Livestock',
                        value: owner.livestockCount.toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Livestock Section
            Text(
              'Livestock Details',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextColor,
              ),
            ),
            SizedBox(height: 16),
            // Flocks List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: owner.flocks.length,
              itemBuilder: (context, index) {
                final flock = owner.flocks[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getFlockColor(flock.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getFlockIcon(flock.type),
                          color: _getFlockColor(flock.type),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flock.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${flock.animalCount} ${flock.type}s • ${flock.breed}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        backgroundColor: _getFlockColor(flock.type).withOpacity(0.1),
                        label: Text(
                          flock.type,
                          style: TextStyle(
                            color: _getFlockColor(flock.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            // Farm Statistics
            Text(
              'Farm Statistics',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextColor,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: isTablet ? 4 : 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Animals',
                  value: owner.totalAnimals.toString(),
                  icon: Icons.pets_rounded,
                  color: AppColors.primaryColor,
                ),
                _StatCard(
                  title: 'Livestock Value',
                  value: '₹4.2L',
                  icon: Icons.attach_money_rounded,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Monthly Production',
                  value: '320L',
                  icon: Icons.local_drink_rounded,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Vaccination Due',
                  value: '12 Animals',
                  icon: Icons.medical_services_rounded,
                  color: Colors.orange,
                ),
              ],
            ),
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
      case 'cattle': return Colors.brown;
      case 'goat': return Colors.orange;
      case 'chicken': return Colors.red;
      default: return AppColors.primaryColor;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTextColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
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