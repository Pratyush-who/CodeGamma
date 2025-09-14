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
  late AnimationController _pulseController;
  String _selectedPeriod = '7D';
  String _selectedCategory = 'Livestock';
  bool _isLoading = false;
  bool _isRefreshing = false;

  final List<String> _categories = ['Livestock', 'Feed', 'Dairy', 'Equipment', 'Meat', 'Medicines'];

  final List<CommodityData> _commodities = [
    // Livestock
    CommodityData(
      name: 'Buffalo (Murrah)',
      currentPrice: 65000,
      change: 2.8,
      unit: 'per animal',
      category: 'Livestock',
      icon: Icons.pets,
      priceHistory: [62000, 63500, 64200, 65800, 64900, 66200, 65000],
      volume: '234 animals',
      marketCap: '15.2M',
      trend: 'Bullish',
    ),
    CommodityData(
      name: 'Cow (Holstein Friesian)',
      currentPrice: 45000,
      change: -1.5,
      unit: 'per animal',
      category: 'Livestock',
      icon: Icons.pets,
      priceHistory: [47000, 46200, 45800, 45100, 44800, 45300, 45000],
      volume: '189 animals',
      marketCap: '8.5M',
      trend: 'Bearish',
    ),
    CommodityData(
      name: 'Jersey Cow',
      currentPrice: 38000,
      change: 1.2,
      unit: 'per animal',
      category: 'Livestock',
      icon: Icons.pets,
      priceHistory: [37200, 37800, 38200, 37900, 38400, 38100, 38000],
      volume: '156 animals',
      marketCap: '5.9M',
      trend: 'Stable',
    ),
    CommodityData(
      name: 'Goat (Boer)',
      currentPrice: 12000,
      change: 4.2,
      unit: 'per animal',
      category: 'Livestock',
      icon: Icons.pets,
      priceHistory: [11200, 11600, 11800, 12200, 11900, 12300, 12000],
      volume: '445 animals',
      marketCap: '5.3M',
      trend: 'Bullish',
    ),

    // Dairy
    CommodityData(
      name: 'Buffalo Milk (A2)',
      currentPrice: 75,
      change: 3.1,
      unit: 'per liter',
      category: 'Dairy',
      icon: Icons.local_drink,
      priceHistory: [72, 73, 74, 76, 75, 76, 75],
      volume: '12.5K liters',
      marketCap: '937.5K',
      trend: 'Bullish',
    ),
    CommodityData(
      name: 'Cow Milk (Organic)',
      currentPrice: 58,
      change: 2.3,
      unit: 'per liter',
      category: 'Dairy',
      icon: Icons.local_drink,
      priceHistory: [56, 57, 58, 57, 59, 58, 58],
      volume: '18.7K liters',
      marketCap: '1.08M',
      trend: 'Bullish',
    ),
    CommodityData(
      name: 'Fresh Paneer',
      currentPrice: 420,
      change: 1.8,
      unit: 'per kg',
      category: 'Dairy',
      icon: Icons.cake,
      priceHistory: [408, 412, 418, 425, 420, 422, 420],
      volume: '890 kg',
      marketCap: '373.8K',
      trend: 'Stable',
    ),
    CommodityData(
      name: 'Ghee (Pure)',
      currentPrice: 650,
      change: -0.8,
      unit: 'per kg',
      category: 'Dairy',
      icon: Icons.opacity,
      priceHistory: [658, 654, 652, 648, 651, 649, 650],
      volume: '567 kg',
      marketCap: '368.6K',
      trend: 'Bearish',
    ),

    // Feed
    CommodityData(
      name: 'Cattle Feed (Premium)',
      currentPrice: 38,
      change: 2.1,
      unit: 'per kg',
      category: 'Feed',
      icon: Icons.grass,
      priceHistory: [37, 37.5, 38.2, 37.8, 38.5, 38.1, 38],
      volume: '45.2K kg',
      marketCap: '1.72M',
      trend: 'Stable',
    ),
    CommodityData(
      name: 'Green Fodder (Maize)',
      currentPrice: 12,
      change: -1.8,
      unit: 'per kg',
      category: 'Feed',
      icon: Icons.eco,
      priceHistory: [12.4, 12.2, 12.0, 11.8, 12.1, 11.9, 12.0],
      volume: '67.8K kg',
      marketCap: '813.6K',
      trend: 'Bearish',
    ),
    CommodityData(
      name: 'Wheat Straw',
      currentPrice: 8.5,
      change: 0.6,
      unit: 'per kg',
      category: 'Feed',
      icon: Icons.grass,
      priceHistory: [8.4, 8.5, 8.6, 8.4, 8.7, 8.5, 8.5],
      volume: '123K kg',
      marketCap: '1.05M',
      trend: 'Stable',
    ),
    CommodityData(
      name: 'Mineral Mix',
      currentPrice: 85,
      change: 3.4,
      unit: 'per kg',
      category: 'Feed',
      icon: Icons.science,
      priceHistory: [82, 83, 84, 86, 85, 87, 85],
      volume: '8.9K kg',
      marketCap: '756.5K',
      trend: 'Bullish',
    ),

    // Equipment
    CommodityData(
      name: 'Milking Machine (Auto)',
      currentPrice: 125000,
      change: 1.2,
      unit: 'per unit',
      category: 'Equipment',
      icon: Icons.precision_manufacturing,
      priceHistory: [123000, 124000, 125500, 124800, 126000, 125200, 125000],
      volume: '23 units',
      marketCap: '2.88M',
      trend: 'Stable',
    ),
    CommodityData(
      name: 'Chaff Cutter',
      currentPrice: 15000,
      change: 2.8,
      unit: 'per unit',
      category: 'Equipment',
      icon: Icons.content_cut,
      priceHistory: [14500, 14700, 15100, 14900, 15300, 15000, 15000],
      volume: '67 units',
      marketCap: '1.01M',
      trend: 'Bullish',
    ),
    CommodityData(
      name: 'Water Tank (500L)',
      currentPrice: 8500,
      change: -0.5,
      unit: 'per unit',
      category: 'Equipment',
      icon: Icons.water_drop,
      priceHistory: [8550, 8520, 8480, 8460, 8500, 8490, 8500],
      volume: '89 units',
      marketCap: '756.5K',
      trend: 'Stable',
    ),

    CommodityData(
      name: 'Mutton (Fresh)',
      currentPrice: 850,
      change: 4.1,
      unit: 'per kg',
      category: 'Meat',
      icon: Icons.dining,
      priceHistory: [815, 825, 835, 860, 845, 865, 850],
      volume: '1.2K kg',
      marketCap: '1.02M',
      trend: 'Bullish',
    ),
    CommodityData(
      name: 'Chicken (Broiler)',
      currentPrice: 180,
      change: -2.1,
      unit: 'per kg',
      category: 'Meat',
      icon: Icons.egg,
      priceHistory: [185, 182, 178, 176, 179, 178, 180],
      volume: '5.6K kg',
      marketCap: '1.01M',
      trend: 'Bearish',
    ),
    CommodityData(
      name: 'Beef (Premium)',
      currentPrice: 420,
      change: 1.8,
      unit: 'per kg',
      category: 'Meat',
      icon: Icons.restaurant,
      priceHistory: [412, 415, 418, 425, 420, 422, 420],
      volume: '890 kg',
      marketCap: '373.8K',
      trend: 'Stable',
    ),

    // Medicines
    CommodityData(
      name: 'Deworming Medicine',
      currentPrice: 450,
      change: 2.3,
      unit: 'per 100ml',
      category: 'Medicines',
      icon: Icons.medication,
      priceHistory: [440, 445, 450, 448, 452, 450, 450],
      volume: '234 bottles',
      marketCap: '105.3K',
      trend: 'Stable',
    ),
    CommodityData(
      name: 'Antibiotics (Pen-Strep)',
      currentPrice: 280,
      change: -1.2,
      unit: 'per vial',
      category: 'Medicines',
      icon: Icons.healing,
      priceHistory: [285, 282, 278, 276, 279, 278, 280],
      volume: '156 vials',
      marketCap: '43.7K',
      trend: 'Bearish',
    ),
    CommodityData(
      name: 'Vitamin Complex',
      currentPrice: 320,
      change: 3.8,
      unit: 'per bottle',
      category: 'Medicines',
      icon: Icons.health_and_safety,
      priceHistory: [308, 312, 318, 325, 320, 324, 320],
      volume: '89 bottles',
      marketCap: '28.5K',
      trend: 'Bullish',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartController.forward();
    _pulseController.repeat();
    _simulateInitialLoading();
  }

  void _simulateInitialLoading() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartController.dispose();
    _pulseController.dispose();
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
        title: Row(
          children: [
            const Text(
              'Market Prices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (_isRefreshing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                ),
              )
            else
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3 + 0.7 * _pulseController.value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _refreshData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(isTablet)
          : Column(
              children: [
                MarketSummaryWidget(
                  totalValue: 4567000,
                  dailyChange: 2.4,
                  weeklyChange: 5.7,
                  monthlyChange: 12.3,
                  isTablet: isTablet,
                ),

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

  Widget _buildLoadingState(bool isTablet) {
    return Column(
      children: [
        // Loading Market Summary
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryColor.withOpacity(0.3), AppColors.primaryColorLight.withOpacity(0.3)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Market Data...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Loading Commodities
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            itemCount: 6,
            separatorBuilder: (context, index) => SizedBox(height: isTablet ? 16 : 12),
            itemBuilder: (context, index) => _buildLoadingSkeleton(isTablet),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: isTablet ? 18 : 16,
                      width: double.infinity * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: isTablet ? 12 : 11,
                      width: double.infinity * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: isTablet ? 22 : 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              Container(
                width: isTablet ? 100 : 80,
                height: isTablet ? 50 : 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityList(List<CommodityData> commodities, bool isTablet) {
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshData();
      },
      child: ListView.separated(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        itemCount: commodities.length,
        separatorBuilder: (context, index) => SizedBox(height: isTablet ? 16 : 12),
        itemBuilder: (context, index) {
          final commodity = commodities[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, _isLoading ? 50 : 0, 0),
            child: CommodityCard(
              commodity: commodity,
              isTablet: isTablet,
              onTap: () => _showCommodityDetails(commodity, isTablet),
            ),
          );
        },
      ),
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
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryColorLight],
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
                            '${commodity.category} • ${commodity.trend}',
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
              
              // Enhanced Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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

                      // Market Stats Grid
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          children: [
                            // Price Row
                            _buildDetailRow(
                              'Current Price',
                              '₹${commodity.currentPrice.toStringAsFixed(commodity.currentPrice >= 1000 ? 0 : 2)} ${commodity.unit}',
                              AppColors.primaryTextColor,
                              FontWeight.w700,
                              18,
                            ),
                            const SizedBox(height: 12),
                            
                            // Change Row
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
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: commodity.change >= 0
                                          ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                                          : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
                                    ),
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
                                        '${commodity.change >= 0 ? '+' : ''}${commodity.change.toStringAsFixed(1)}%',
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
                            
                            const SizedBox(height: 16),
                            const Divider(color: Colors.grey, thickness: 0.3),
                            const SizedBox(height: 16),
                            
                            // Additional Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('Volume', commodity.volume, Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard('Market Cap', commodity.marketCap, Colors.purple),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('Trend', commodity.trend, 
                                    commodity.trend == 'Bullish' ? Colors.green :
                                    commodity.trend == 'Bearish' ? Colors.red : Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard('Category', commodity.category, AppColors.primaryColor),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Set price alert
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Price alert set for ${commodity.name}'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.notification_add, size: 16),
                                    label: const Text('Set Alert'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Share price info
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Price info shared!'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('Share'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, FontWeight fontWeight, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.filter_list, color: AppColors.primaryColor),
              title: const Text('Filter Markets'),
              onTap: () {
                Navigator.pop(context);
                _showFilterOptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.sort, color: AppColors.primaryColor),
              title: const Text('Sort Options'),
              onTap: () {
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: AppColors.primaryColor),
              title: const Text('Market Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showMarketAnalytics();
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: AppColors.primaryColor),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Market data exported successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    // Filter implementation
  }

  void _showSortOptions() {
    // Sort implementation
  }

  void _showMarketAnalytics() {
    // Analytics implementation
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 2000));
    
    setState(() {
      _isRefreshing = false;
    });
    
    _chartController.reset();
    _chartController.forward();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Market data refreshed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Enhanced Data Model
class CommodityData {
  final String name;
  final double currentPrice;
  final double change;
  final String unit;
  final String category;
  final IconData icon;
  final List<double> priceHistory;
  final String volume;
  final String marketCap;
  final String trend;

  CommodityData({
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.unit,
    required this.category,
    required this.icon,
    required this.priceHistory,
    required this.volume,
    required this.marketCap,
    required this.trend,
  });
}