import 'package:codegamma_sih/presentation/view/scanner/amu.dart';
import 'package:codegamma_sih/presentation/view/scanner/data.dart';
import 'package:codegamma_sih/presentation/view/scanner/mrl.dart';
import 'package:codegamma_sih/presentation/view/scanner/prescription.dart';
import 'package:codegamma_sih/presentation/view/voice_chat/voice_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class AfterScanPage extends StatefulWidget {
  final String tagId;

  const AfterScanPage({super.key, required this.tagId});

  @override
  State<AfterScanPage> createState() => _AfterScanPageState();
}

class _AfterScanPageState extends State<AfterScanPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  // Add your Gemini API key here
  static const String _geminiApiKey = 'AIzaSyA1IJ3ICYjRPZGdQheZCrbZeoVN_SoOtbs';
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(
      5, // Changed from 4 to 5 for the new voice chat card
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            0.4 + index * 0.1,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToAnalysis(String analysisType) {
    HapticFeedback.lightImpact();
    
    Widget destinationScreen;
    switch (analysisType) {
      case 'MRL':
        destinationScreen = MrlAnalysisScreen(tagId: widget.tagId);
        break;
      case 'AMU':
        destinationScreen = AmuAnalysisScreen(tagId: widget.tagId);
        break;
      case 'PRESCRIPTION':
        destinationScreen = PrescriptionAnalysisScreen(tagId: widget.tagId);
        break;
      case 'ANIMAL_DATA':
        destinationScreen = AnimalDataScreen(tagId: widget.tagId);
        break;
      case 'ASK_QUERIES':
        // Navigate to Voice Chat Page
        destinationScreen = VoiceChatPage(
          tagId: widget.tagId,
          geminiApiKey: _geminiApiKey,
          cowDetails: null, // You can pass actual cow details if available
        );
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String analysisType,
    required Color gradientStart,
    required Color gradientEnd,
    required int animationIndex,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimations[animationIndex],
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimations[animationIndex].value,
          child: Opacity(
            opacity: _cardAnimations[animationIndex].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                shadowColor: gradientStart.withOpacity(0.3),
                child: InkWell(
                  onTap: () => _navigateToAnalysis(analysisType),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [gradientStart, gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icon,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analysis Options',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.accentGreen.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.pets,
                          color: AppColors.accentGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scanned Successfully',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tag ID: ${widget.tagId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryTextColor,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose an analysis option below to get detailed insights about this animal.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Analysis Cards
            const SizedBox(height: 20),
            
            _buildAnalysisCard(
              title: 'MRL Analysis',
              subtitle: 'Maximum Residue Limit compliance check',
              icon: Icons.science,
              analysisType: 'MRL',
              gradientStart: AppColors.primaryColor,
              gradientEnd: AppColors.accentGreen,
              animationIndex: 0,
            ),

            _buildAnalysisCard(
              title: 'AMU Analysis',
              subtitle: 'Antimicrobial Usage monitoring',
              icon: Icons.medication,
              analysisType: 'AMU',
              gradientStart: AppColors.primaryColor,
              gradientEnd: AppColors.accentGreen,
              animationIndex: 1,
            ),

            _buildAnalysisCard(
              title: 'Prescription Analysis',
              subtitle: 'Treatment history and prescriptions',
              icon: Icons.receipt_long,
              analysisType: 'PRESCRIPTION',
              gradientStart: AppColors.primaryColor,
              gradientEnd: AppColors.accentGreen,
              animationIndex: 2,
            ),

            _buildAnalysisCard(
              title: 'Animal Data',
              subtitle: 'Complete animal overview and health status',
              icon: Icons.pets,
              analysisType: 'ANIMAL_DATA',
              gradientStart: AppColors.primaryColor,
              gradientEnd: AppColors.accentGreen,
              animationIndex: 3,
            ),

            _buildAnalysisCard(
              title: 'Ask Queries',
              subtitle: 'Voice-based AI assistant for animal data',
              icon: Icons.mic,
              analysisType: 'ASK_QUERIES',
              gradientStart: Colors.deepPurple,
              gradientEnd: Colors.purple,
              animationIndex: 4,
            ),

            const SizedBox(height: 40),

            // Footer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All analyses are based on real-time data and regulatory compliance standards.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryTextColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}