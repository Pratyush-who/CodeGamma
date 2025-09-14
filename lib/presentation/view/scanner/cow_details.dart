// Updated Cow Details Page with Voice Chat Navigation
import 'package:codegamma_sih/presentation/view/voice_chat/voice_chat.dart';
import 'package:codegamma_sih/core/models/cow_details.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CowDetailsPage extends StatefulWidget {
  final String tagId;

  const CowDetailsPage({super.key, required this.tagId});

  @override
  State<CowDetailsPage> createState() => _CowDetailsPageState();
}

class _CowDetailsPageState extends State<CowDetailsPage> {
  // Add your Gemini API key here
  static const String GEMINI_API_KEY =
      'AIzaSyA1IJ3ICYjRPZGdQheZCrbZeoVN_SoOtbs'; // Replace with your actual API key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to home page and remove all previous routes
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
          },
        ),
        title: Text(
          '${widget.tagId}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cow Image Section
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColorLight.withOpacity(0.1),
                    AppColors.backgroundColor,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://www.dial4trade.com/uploaded_files/product_images/thumbs/red-sindhi-cow-1839559468280.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.lightGreen,
                          child: const Icon(
                            Icons.pets,
                            size: 64,
                            color: AppColors.primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Details Sections
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailCard('Basic Information', Icons.info_outline, [
                    _buildDetailRow('Tag ID', widget.tagId),
                    _buildDetailRow('Breed', 'Red Sindhi'),
                    _buildDetailRow('Age', '3 years 2 months'),
                    _buildDetailRow('Weight', '650 kg'),
                    _buildDetailRow('Gender', 'Female'),
                    _buildDetailRow('Status', 'Healthy', isStatus: true),
                  ]),

                  const SizedBox(height: 16),

                  _buildDetailCard(
                    'Antimicrobial Usage & Safety',
                    Icons.medication_outlined,
                    [
                      _buildDetailRow('Last Treatment', '15 days ago'),
                      _buildDetailRow('Medication', 'Penicillin G'),
                      _buildDetailRow('Dosage', '20 ml intramuscular'),
                      _buildDetailRow(
                        'Withdrawal Period',
                        '7 days (Completed)',
                      ),
                      _buildDetailRow(
                        'Next Treatment Due',
                        'No active treatment',
                      ),
                      _buildDetailRow(
                        'Milk Usage',
                        'Safe for consumption',
                        isStatus: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildDetailCard(
                    'Health Monitoring',
                    Icons.favorite_outline,
                    [
                      _buildDetailRow('Last Checkup', '2 days ago'),
                      _buildDetailRow('Temperature', '101.2°F (Normal)'),
                      _buildDetailRow('Heart Rate', '78 bpm'),
                      _buildDetailRow('Respiration Rate', '22 breaths/min'),
                      _buildDetailRow('Milk Production', '25 L/day'),
                      _buildDetailRow('Nutrition Level', 'Adequate'),
                      _buildDetailRow('Body Condition Score', '3.5/5 (Good)'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildDetailCard(
                    'Compliance & Records',
                    Icons.assignment_outlined,
                    [
                      _buildDetailRow('Owner', 'Rajesh Kumar'),
                      _buildDetailRow('Farm Location', 'Village Rampur, UP'),
                      _buildDetailRow(
                        'Compliance Status',
                        'Compliant',
                        isStatus: true,
                      ),
                      _buildDetailRow('Last Inspection', '1 month ago'),
                      _buildDetailRow('Registration ID', 'UP-2024-001234'),
                      _buildDetailRow(
                        'Blockchain Verified',
                        'Yes',
                        isStatus: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildDetailCard(
                    'Usage Advisory',
                    Icons.warning_amber_outlined,
                    [
                      _buildDetailRow(
                        'Milk Usage',
                        'Fit for daily consumption',
                      ),
                      _buildDetailRow(
                        'Medication Note',
                        'No antibiotics within last 7 days',
                      ),
                      _buildDetailRow('Recommended Checkup', 'Every 30 days'),
                      _buildDetailRow('Vaccination Status', 'Up to date'),
                      _buildDetailRow(
                        'Heat Stress Risk',
                        'Low – Good ventilation',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Generate Report',
                          Icons.description_outlined,
                          AppColors.primaryColor,
                          () {
                            _showSnackBar('Generating compliance report...');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Ask Queries',
                          Icons.question_answer,
                          AppColors.accentGreen,
                          () {
                            _navigateToVoiceChat();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      'View Past Records',
                      Icons.history,
                      AppColors.darkGreen,
                      () {
                        _showSnackBar('Opening detailed history...');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToVoiceChat() {
    if (GEMINI_API_KEY == 'YOUR_GEMINI_API_KEY_HERE' ||
        GEMINI_API_KEY.isEmpty) {
      _showSnackBar('Please set your Gemini API key in the code');
      return;
    }
    // Build the cow details context object
    final details = CowDetails(
      tagId: widget.tagId,
      breed: 'Red Sindhi',
      age: '3 years 2 months',
      weight: '650 kg',
      gender: 'Female',
      status: 'Healthy',
      lastTreatment: '15 days ago',
      medication: 'Penicillin G',
      dosage: '20 ml intramuscular',
      withdrawalPeriod: '7 days (Completed)',
      nextTreatmentDue: 'No active treatment',
      milkUsage: 'Safe for consumption',
      lastCheckup: '2 days ago',
      temperature: '101.2°F (Normal)',
      heartRate: '78 bpm',
      respirationRate: '22 breaths/min',
      milkProduction: '25 L/day',
      nutritionLevel: 'Adequate',
      bodyConditionScore: '3.5/5 (Good)',
      owner: 'Rajesh Kumar',
      farmLocation: 'Village Rampur, UP',
      complianceStatus: 'Compliant',
      lastInspection: '1 month ago',
      registrationId: 'UP-2024-001234',
      blockchainVerified: 'Yes',
      usageMilkStatus: 'Fit for daily consumption',
      medicationNote: 'No antibiotics within last 7 days',
      recommendedCheckup: 'Every 30 days',
      vaccinationStatus: 'Up to date',
      heatStressRisk: 'Low – Good ventilation',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceChatPage(
          tagId: widget.tagId,
          geminiApiKey: GEMINI_API_KEY,
          cowDetails: details,
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.primaryColorLight.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    Color valueColor = AppColors.primaryTextColor;
    if (isStatus) {
      if (value.toLowerCase().contains('healthy') ||
          value.toLowerCase().contains('compliant') ||
          value.toLowerCase().contains('yes') ||
          value.toLowerCase().contains('up to date') ||
          value.toLowerCase().contains('safe')) {
        valueColor = AppColors.accentGreen;
      } else if (value.toLowerCase().contains('warning')) {
        valueColor = Colors.orange;
      } else if (value.toLowerCase().contains('critical')) {
        valueColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: AppColors.secondaryTextColor),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
