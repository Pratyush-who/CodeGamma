import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';

class CowDetailsPage extends StatefulWidget {
  final String tagId;

  const CowDetailsPage({super.key, required this.tagId});

  @override
  State<CowDetailsPage> createState() => _CowDetailsPageState();
}

class _CowDetailsPageState extends State<CowDetailsPage> {
  Map<String, dynamic>? animalData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAnimalData();
  }

  Future<void> _fetchAnimalData() async {
    try {
      final response = await http.get(
        Uri.parse('https://bfc211a032dc.ngrok-free.app/animal/${widget.tagId}'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          animalData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load animal data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToMRLAnalyzer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MRLAnalyzerPage(tagId: widget.tagId),
      ),
    );
  }

  void _navigateToAmuAnalyzer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmuAnalyzerPage(tagId: widget.tagId),
      ),
    );
  }

  void _navigateToPrescriptionChecker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionCheckerPage(tagId: widget.tagId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Animal Details - ${widget.tagId}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        error = null;
                      });
                      _fetchAnimalData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimalDataCard(),
                  const SizedBox(height: 16),
                  _buildAnalysisOptionsGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildAnimalDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pets,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Animal Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    Text(
                      'Tag: ${widget.tagId}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (animalData != null) ...[
            _buildInfoRow('Breed', animalData!['basicInfo']['breed']),
            _buildInfoRow('Gender', animalData!['basicInfo']['gender']),
            _buildInfoRow('Farm ID', animalData!['basicInfo']['farmId']),
            _buildInfoRow(
              'Date of Admission',
              animalData!['basicInfo']['dateOfAdmission'],
            ),
            const SizedBox(height: 16),
            _buildComplianceStatus(),
            const SizedBox(height: 16),
            _buildHealthStatus(),
            const SizedBox(height: 16),
            _buildRecordCounts(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceStatus() {
    final complianceStatus = animalData!['basicInfo']['complianceStatus'];
    final isCompliant = complianceStatus['status'] == 'OK';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompliant
            ? AppColors.accentGreen.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompliant ? AppColors.accentGreen : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompliant ? Icons.check_circle : Icons.warning,
            color: isCompliant ? AppColors.accentGreen : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Compliance: ${complianceStatus['status']}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCompliant ? AppColors.accentGreen : Colors.red,
            ),
          ),
          const Spacer(),
          Text(
            'Updated: ${complianceStatus['lastUpdated']}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatus() {
    final healthStatus = animalData!['healthStatus'];
    final lastVisit = healthStatus['lastVisit'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildHealthIndicator('Vaccination', healthStatus['vaccination']),
            const SizedBox(width: 16),
            _buildHealthIndicator('Insurance', healthStatus['insurance']),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last Visit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dr. ${lastVisit['doctorName']} - ${lastVisit['date']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              Text(
                'Purpose: ${lastVisit['purpose']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, bool status) {
    return Row(
      children: [
        Icon(
          status ? Icons.check_circle : Icons.cancel,
          color: status ? AppColors.accentGreen : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCounts() {
    final recordCounts = animalData!['recordCounts'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medical Records',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildRecordCountItem(
              'Prescriptions',
              recordCounts['prescriptions'],
            ),
            _buildRecordCountItem('Treatments', recordCounts['treatments']),
            _buildRecordCountItem(
              'Doctor Visits',
              recordCounts['doctorVisits'],
            ),
            _buildRecordCountItem('History', recordCounts['historyEntries']),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordCountItem(String label, int count) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalysisOptionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analysis Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildAnalysisCard(
              'MRL Analyzer',
              'Maximum Residue Limits analysis for food safety compliance',
              Icons.science,
              AppColors.accentGreen,
              _navigateToMRLAnalyzer,
            ),
            _buildAnalysisCard(
              'AMU Analyzer',
              'Antimicrobial Usage analysis and monitoring',
              Icons.medication,
              AppColors.secondaryGreen,
              _navigateToAmuAnalyzer,
            ),
            _buildAnalysisCard(
              'Prescription Checker',
              'Verify prescriptions and drug interactions',
              Icons.assignment,
              AppColors.darkGreen,
              _navigateToPrescriptionChecker,
            ),
            _buildAnalysisCard(
              'Health Reports',
              'Generate comprehensive health and compliance reports',
              Icons.assessment,
              AppColors.primaryColor,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Health Reports feature coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MRL Analyzer Page
class MRLAnalyzerPage extends StatefulWidget {
  final String tagId;

  const MRLAnalyzerPage({super.key, required this.tagId});

  @override
  State<MRLAnalyzerPage> createState() => _MRLAnalyzerPageState();
}

class _MRLAnalyzerPageState extends State<MRLAnalyzerPage> {
  String selectedTissue = 'muscle';
  int daysSinceTreatment = 0;
  Map<String, dynamic>? analysisResult;
  bool isLoading = false;
  String? error;

  final List<String> tissueOptions = [
    'muscle',
    'milk',
    'eggs',
    'liver',
    'kidney',
  ];

  Future<void> _analyzeMRL() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://bfc211a032dc.ngrok-free.app/api/v1/mrl/analyze/${widget.tagId}?target_tissue=$selectedTissue&days_since_treatment=$daysSinceTreatment',
        ),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          analysisResult = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to analyze MRL data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.accentGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MRL Analyzer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParameterCard(),
            const SizedBox(height: 16),
            _buildAnalyzeButton(),
            if (analysisResult != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
            ],
            if (error != null) ...[
              const SizedBox(height: 24),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science,
                  color: AppColors.accentGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MRL Analysis Parameters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  Text(
                    'Tag: ${widget.tagId}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Target Tissue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.mutedTextColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTissue,
                items: tissueOptions.map((tissue) {
                  return DropdownMenuItem<String>(
                    value: tissue,
                    child: Text(tissue.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTissue = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Days Since Treatment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: daysSinceTreatment.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              daysSinceTreatment = int.tryParse(value) ?? 0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _analyzeMRL,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Analyze MRL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.accentGreen, size: 24),
              SizedBox(width: 8),
              Text(
                'Analysis Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              jsonEncode(analysisResult),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            error!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// AMU Analyzer Page (Placeholder)
class AmuAnalyzerPage extends StatelessWidget {
  final String tagId;

  const AmuAnalyzerPage({super.key, required this.tagId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AMU Analyzer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medication, color: AppColors.secondaryGreen, size: 64),
              const SizedBox(height: 16),
              const Text(
                'AMU Analyzer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tag: $tagId',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Antimicrobial Usage analysis and monitoring feature will be available soon.',
                style: TextStyle(fontSize: 16, color: AppColors.mutedTextColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Prescription Checker Page (Placeholder)
class PrescriptionCheckerPage extends StatelessWidget {
  final String tagId;

  const PrescriptionCheckerPage({super.key, required this.tagId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prescription Checker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment, color: AppColors.darkGreen, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Prescription Checker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tag: $tagId',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Prescription verification and drug interaction checking feature will be available soon.',
                style: TextStyle(fontSize: 16, color: AppColors.mutedTextColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
