import 'package:codegamma_sih/presentation/view/alerts/alertspage.dart';
import 'package:codegamma_sih/presentation/view/analytics/analytics.dart';
import 'package:codegamma_sih/presentation/view/home/home_page.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/animal_manage/animal_manage.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/disease/disease_track.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/market/marketpage.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/owner_management.dart';
import 'package:codegamma_sih/presentation/view/home/widgets/risk_predic.dart';
import 'package:codegamma_sih/presentation/view/profile/profilepage.dart';
import 'package:codegamma_sih/presentation/view/scanner/centre_button.dart';
import 'package:codegamma_sih/presentation/view/scanner/cow_details.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  static const String analytics = '/analytics';
  static const String alerts = '/alerts';
  static const String profile = '/profile';
  static const String scanner = '/scanner';
  static const String cowDetails = '/cow-details';
  static const String diseaseTracking = '/disease-tracking';
  static const String marketPrices = '/market-prices';
  static const String ownerManagement = '/owner-management';
  static const String animalManagement = '/animal-management';
  static const String riskPrediction = '/risk-prediction';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsPage());
      case alerts:
        return MaterialPageRoute(builder: (_) => const AlertsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case scanner:
        return MaterialPageRoute(builder: (_) => const AddPage());
      case ownerManagement:
        return MaterialPageRoute(builder: (_) => const OwnerManagementScreen());
      case animalManagement:
        return MaterialPageRoute(builder: (_) => const AnimalManagementScreen());
      case riskPrediction:
        return MaterialPageRoute(builder: (_) => const RiskPredictionScreen());
      case cowDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final tagId = args?['tagId'] ?? 'UNKNOWN-TAG';
        return MaterialPageRoute(builder: (_) => CowDetailsPage(tagId: tagId));
      case diseaseTracking:
        return MaterialPageRoute(builder: (_) => const DiseaseTrackingPage());
      case marketPrices:
        return MaterialPageRoute(builder: (_) => const MarketPricesPage());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
