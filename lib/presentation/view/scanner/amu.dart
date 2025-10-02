// analysis_screens/amu_analysis_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class AmuAnalysisScreen extends StatefulWidget {
  final String tagId;

  const AmuAnalysisScreen({super.key, required this.tagId});

  @override
  State<AmuAnalysisScreen> createState() => _AmuAnalysisScreenState();
}

class _AmuAnalysisScreenState extends State<AmuAnalysisScreen> {
  bool isLoading = true;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    fetchAmuAnalysis();
  }

  Future<void> fetchAmuAnalysis() async {
    final url =
        'https://bfc211a032dc.ngrok-free.app/animal/${widget.tagId}/amu';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching AMU data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AMU Analysis',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? Center(
              child: Text(
                'Failed to load data',
                style: TextStyle(color: AppColors.primaryTextColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerCard(),
                  const SizedBox(height: 20),
                  overallAssessment(),
                  const SizedBox(height: 20),
                  medicationAnalysis(),
                  const SizedBox(height: 20),
                  recommendations(),
                ],
              ),
            ),
    );
  }

  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColorLight, AppColors.primaryColorDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: AppColors.whiteColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal Tag: ${data!['tagNo']}',
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analysis Date: ${data!['amuAnalysis']['analysis_date']}',
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget overallAssessment() {
    final assessment = data!['amuAnalysis']['overall_assessment'];
    return Card(
      color: AppColors.lightGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Assessment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            infoRow('Compliant', assessment['compliant'].toString()),
            infoRow(
              'Total Medications',
              assessment['total_medications'].toString(),
            ),
            infoRow(
              'Total Anomalies',
              assessment['total_anomalies'].toString(),
            ),
            infoRow(
              'Critical Drugs Used',
              assessment['critical_drugs_used'].toString(),
            ),
            infoRow('Risk Level', assessment['risk_level'].toString()),
          ],
        ),
      ),
    );
  }

  Widget medicationAnalysis() {
    final meds = data!['amuAnalysis']['medication_analyses'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medication Analysis',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...meds.map(
          (med) => Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['medication'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  infoRow('Risk Level', med['risk_level']),
                  infoRow(
                    'Overall Compliance',
                    med['overall_compliance'].toString(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anomalies:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...((med['anomalies'] as List).map(
                    (anomaly) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: anomalyCard(anomaly),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget anomalyCard(Map<String, dynamic> anomaly) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            anomaly['anomaly_type'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(anomaly['description']),
          const SizedBox(height: 4),
          infoRow('Severity', anomaly['severity']),
          infoRow('Detected Value', anomaly['detected_value'].toString()),
          infoRow('Expected Range', anomaly['expected_range']),
          Text(
            'Recommendation: ${anomaly['recommendation']}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget recommendations() {
    final recs = data!['amuAnalysis']['recommendations'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...recs.map(
          (rec) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColorLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(rec)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
