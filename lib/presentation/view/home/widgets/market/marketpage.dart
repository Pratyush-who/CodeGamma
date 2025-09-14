import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/market/comodity.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/market/market_summary.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/market/price.dart';

class MarketPricesPage extends StatefulWidget {
  const MarketPricesPage({super.key});

  @override
  State<MarketPricesPage> createState() => _MarketPricesPageState();
}

class _MarketPricesPageState extends State<MarketPricesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _chartController;
  String _selectedPeriod = '7D';
  String _selectedCategory = 'Livestock';

  final List<String> _periods = ['1D', '7D', '1M', '3M', '1Y'];
  final List<String> _categories = ['Livestock', 'Feed', 'Dairy', 'Equipment'];

  final List<CommodityData> _commodities = [
    CommodityData(
      name: 'Buffalo',
      currentPrice: 45000,
      change: 2.5,
      unit: 'per animal',
      category: 'Livestock',
      icon: Icons.pets,
      priceHistory: [42000, 43000, 44500, 45000, 44800, 45200, 45000],
    ),
    CommodityData(
      name: 'Cow (HF)',
      currentPrice: 38000,
      change: -1.2,
      unit: 'per animal',
      category: 'Livestock',
      icon: Icons.pets,
      priceHistory: [39000, 38500, 38200, 37800, 38100, 38300, 38000],
    ),
    CommodityData(
      name: 'Milk (Buffalo)',
      currentPrice: 68,
      change: 3.8,
      unit: 'per liter',
      category: 'Dairy',
      icon: Icons.local_drink,
      priceHistory: [65, 66, 67, 68, 67, 68, 68],
    ),
    CommodityData(
      name: 'Cattle Feed',
      currentPrice: 32,
      change: 1.5,
      unit: 'per kg',
      category: 'Feed',
      icon: Icons.grass,
      priceHistory: [31, 31.5, 32, 31.8, 32.2, 32.1, 32],
    ),
    CommodityData(
      name: 'Green Fodder',
      currentPrice: 8,
      change: -2.1,
      unit: 'per kg',
      category: 'Feed',
      icon: Icons.eco,
      priceHistory: [8.2, 8.1, 8.0, 7.9, 8.1, 8.0, 8.0],
    ),
    CommodityData(
      name: 'Milking Machine',
      currentPrice: 85000,
      change: 0.8,
      unit: 'per unit',
      category: 'Equipment',
      icon: Icons.precision_manufacturing,
      priceHistory: [84000, 84500, 85000, 84800, 85200, 85100, 85000],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  List<CommodityData> get _filteredCommodities {
    return _commodities.where((commodity) => commodity.category == _selectedCategory).toList();
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
          'Market Prices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              _showPriceAlerts(context, isTablet);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _refreshData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Market Summary Header
          MarketSummaryWidget(
            totalValue: 2345000,
            dailyChange: 1.8,
            weeklyChange: 3.2,
            isTablet: isTablet,
          ),

          // Period Selector
          Container(
            margin: EdgeInsets.fromLTRB(
              isTablet ? 24 : 16,
              isTablet ? 16 : 12,
              isTablet ? 24 : 16,
              0,
            ),
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final period = _periods[index];
                final isSelected = period == _selectedPeriod;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : [],
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.secondaryTextColor,
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Category Tabs
          Container(
            margin: EdgeInsets.fromLTRB(
              isTablet ? 24 : 16,
              isTablet ? 16 : 12,
              isTablet ? 24 : 16,
              0,
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.secondaryTextColor,
              labelStyle: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
              onTap: (index) {
                setState(() {
                  _selectedCategory = _categories[index];
                });
              },
              tabs: _categories.map((category) => Tab(text: category)).toList(),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final filteredCommodities = _commodities
                    .where((commodity) => commodity.category == category)
                    .toList();
                
                return _buildCommodityList(filteredCommodities, isTablet);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityList(List<CommodityData> commodities, bool isTablet) {
    return ListView.separated(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      itemCount: commodities.length,
      separatorBuilder: (context, index) => SizedBox(height: isTablet ? 16 : 12),
      itemBuilder: (context, index) {
        final commodity = commodities[index];
        return CommodityCard(
          commodity: commodity,
          isTablet: isTablet,
          onTap: () => _showCommodityDetails(commodity, isTablet),
        );
      },
    );
  }

  void _showCommodityDetails(CommodityData commodity, bool isTablet) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 500 : 350,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                  color: AppColors.primaryColor,
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
                        commodity.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commodity.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Current Market Price',
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
              
              // Price Chart
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                child: PriceChart(
                  data: commodity.priceHistory,
                  color: AppColors.primaryColor,
                  isTablet: isTablet,
                ),
              ),

              // Price Details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Price',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        Text(
                          '₹${commodity.currentPrice.toStringAsFixed(commodity.currentPrice >= 1000 ? 0 : 2)} ${commodity.unit}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change (24h)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: commodity.change >= 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                commodity.change >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 16,
                                color: commodity.change >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${commodity.change.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: commodity.change >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Set price alert
                            },
                            icon: const Icon(Icons.notification_add, size: 16),
                            label: const Text('Set Alert'),
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
                              // Share price info
                            },
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share'),
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

  void _showPriceAlerts(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 400 : 320,
          ),
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
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Price Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
                  children: [
                    _AlertItem(
                      'Buffalo price dropped below ₹44,000',
                      '2 hours ago',
                      Colors.red,
                      Icons.trending_down,
                    ),
                    const SizedBox(height: 12),
                    _AlertItem(
                      'Milk prices increased by 3.8%',
                      '4 hours ago',
                      Colors.green,
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 12),
                    _AlertItem(
                      'Feed prices volatile - monitor closely',
                      '1 day ago',
                      Colors.orange,
                      Icons.warning,
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

  void _refreshData() {
    _chartController.reset();
    _chartController.forward();
  }
}

class _AlertItem extends StatelessWidget {
  final String message;
  final String time;
  final Color color;
  final IconData icon;

  const _AlertItem(this.message, this.time, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data Model
class CommodityData {
  final String name;
  final double currentPrice;
  final double change;
  final String unit;
  final String category;
  final IconData icon;
  final List<double> priceHistory;

  CommodityData({
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.unit,
    required this.category,
    required this.icon,
    required this.priceHistory,
  });
}