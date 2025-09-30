import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MrlAnalysisScreen extends StatefulWidget {
  final String tagId;

  const MrlAnalysisScreen({super.key, required this.tagId});

  @override
  State<MrlAnalysisScreen> createState() => _MrlAnalysisScreenState();
}

class _MrlAnalysisScreenState extends State<MrlAnalysisScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? mrlAnalysisData;
  Map<String, dynamic>? complianceCheckData;
  Map<String, dynamic>? residuePredictionData;
  String? _error;
  String _targetTissue = 'muscle';
  int _daysSinceTreatment = 0;
  String _drugName = 'oxytetracycline';
  double _dosage = 15.0;
  int _treatmentDuration = 3;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _fetchMrlAnalysis(),
        _fetchComplianceCheck(),
        _fetchResiduePrediction(),
      ]);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMrlAnalysis() async {
    try {
      final response = await http.post(
        Uri.parse('https://6cd1f87533a9.ngrok-free.app/api/v1/mrl/analyze/${widget.tagId}?target_tissue=$_targetTissue&days_since_treatment=$_daysSinceTreatment'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          mrlAnalysisData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching MRL analysis: $e');
    }
  }

  Future<void> _fetchComplianceCheck() async {
    try {
      final response = await http.post(
        Uri.parse('https://6cd1f87533a9.ngrok-free.app/api/v1/mrl/check-compliance?tag_no=${widget.tagId}&drug_name=$_drugName&species=cattle&dosage=$_dosage&treatment_duration=$_treatmentDuration&days_since_treatment=$_daysSinceTreatment&target_tissue=$_targetTissue'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          complianceCheckData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching compliance check: $e');
    }
  }

  Future<void> _fetchResiduePrediction() async {
    try {
      final response = await http.post(
        Uri.parse('https://6cd1f87533a9.ngrok-free.app/api/v1/mrl/predict-residue?tag_no=${widget.tagId}&drug_name=$_drugName&days_since_treatment=$_daysSinceTreatment&dosage=$_dosage&treatment_duration=$_treatmentDuration'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          residuePredictionData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching residue prediction: $e');
    }
  }

  Widget _buildParameterControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor.withOpacity(0.8), AppColors.accentGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Analysis Parameters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildParameterField(
                    'Target Tissue',
                    DropdownButtonFormField<String>(
                      value: _targetTissue,
                      dropdownColor: Colors.white,
                      style: TextStyle(color: AppColors.primaryTextColor),
                      items: ['muscle', 'liver', 'kidney', 'milk', 'eggs'].map((tissue) {
                        return DropdownMenuItem(
                          value: tissue,
                          child: Text(tissue.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _targetTissue = value!);
                        _fetchAllData();
                      },
                      decoration: _inputDecoration(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildParameterField(
                    'Days Since Treatment',
                    TextFormField(
                      initialValue: _daysSinceTreatment.toString(),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.primaryTextColor),
                      decoration: _inputDecoration(),
                      onChanged: (value) {
                        setState(() {
                          _daysSinceTreatment = int.tryParse(value) ?? 0;
                        });
                        _fetchAllData();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildAnimalContextCard(Map<String, dynamic> animalContext) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Tag: ${animalContext['tagNo'] ?? widget.tagId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Basic Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Breed',
                    animalContext['breed'] ?? 'Unknown',
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    'Gender',
                    animalContext['gender'] ?? 'Unknown',
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Farm ID',
                    animalContext['farmId'] ?? 'Unknown',
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    'Admission Date',
                    animalContext['dateOfAdmission'] ?? 'Unknown',
                    Colors.teal,
                  ),
                ),
              ],
            ),

            // Status Indicators
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (animalContext['insurance'] == true)
                  _buildStatusChip('Insured', Colors.green),
                if (animalContext['vaccination'] == true)
                  _buildStatusChip('Vaccinated', Colors.blue),
                if (animalContext['artificialInsemination'] == true)
                  _buildStatusChip('AI', Colors.purple),
              ],
            ),

            // Summary
            if (animalContext['summary'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animalContext['summary'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Doctor Visits
            if (animalContext['doctorVisits'] != null && animalContext['doctorVisits'].isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSubsectionHeader('Recent Doctor Visits'),
              const SizedBox(height: 8),
              ...((animalContext['doctorVisits'] as List).take(2).map((visit) =>
                _buildDoctorVisitCard(visit)
              )),
            ],

            // Prescriptions Summary
            if (animalContext['prescriptions'] != null && animalContext['prescriptions'].isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSubsectionHeader('Active Prescriptions'),
              const SizedBox(height: 8),
              ...((animalContext['prescriptions'] as List).map((prescription) =>
                _buildPrescriptionCard(prescription)
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorVisitCard(Map<String, dynamic> visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.medical_services, color: AppColors.darkGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit['doctorName'] ?? 'Unknown Doctor',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                Text(
                  '${visit['purpose'] ?? 'Check-up'} • ${visit['date'] ?? 'Unknown date'}',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    final medicines = prescription['medicines'] as List? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.medication, color: AppColors.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${prescription['doctorName'] ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    Text(
                      '${prescription['diagnosis'] ?? 'General treatment'} • ${prescription['date'] ?? 'Unknown date'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (medicines.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...medicines.take(2).map((medicine) => 
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  '• ${medicine['name']} - ${medicine['dosage']} (${medicine['duration']})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSubsectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTextColor,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceMetrics(Map<String, dynamic> complianceResult) {
    final String status = complianceResult['compliance_status'] ?? 'unknown';
    final double predictedLevel = complianceResult['predicted_residue_level']?.toDouble() ?? 0.0;
    final double mrlLimit = complianceResult['mrl_limit']?.toDouble() ?? 0.0;
    final double safetyMargin = complianceResult['safety_margin']?.toDouble() ?? 0.0;
    final double confidence = complianceResult['confidence_score']?.toDouble() ?? 0.0;

    Color statusColor = status == 'violation' ? Colors.red : 
                       status == 'compliant' ? AppColors.accentGreen : Colors.orange;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                'Status',
                status.toUpperCase(),
                statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoTile(
                'Confidence',
                '${(confidence * 100).toStringAsFixed(0)}%',
                AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                'Predicted Level',
                '${predictedLevel.toStringAsFixed(2)} µg/kg',
                AppColors.darkGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoTile(
                'MRL Limit',
                '${mrlLimit.toStringAsFixed(2)} µg/kg',
                AppColors.secondaryTextColor,
              ),
            ),
          ],
        ),
        if (complianceResult['risk_factors'] != null && complianceResult['risk_factors'].isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Factors:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                ...(complianceResult['risk_factors'] as List).map((factor) =>
                  Text(
                    '• $factor',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWithdrawalInfo(Map<String, dynamic> withdrawal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWithdrawalMetric(
                '${withdrawal['standard_withdrawal_days'] ?? 0}',
                'Standard Days',
                AppColors.primaryColor,
              ),
              _buildWithdrawalMetric(
                '${withdrawal['recommended_days'] ?? 0}',
                'Recommended',
                AppColors.accentGreen,
              ),
              _buildWithdrawalMetric(
                '${withdrawal['safety_buffer_days'] ?? 0}',
                'Safety Buffer',
                AppColors.darkGreen,
              ),
            ],
          ),
          if (withdrawal['factors_considered'] != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Factors Considered:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            ...(withdrawal['factors_considered'] as List).map((factor) =>
              Text(
                '• $factor',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWithdrawalMetric(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResidueChart(Map<String, dynamic> residues) {
    final tissues = ['muscle', 'liver', 'kidney', 'milk'];
    final values = tissues.map((tissue) => residues[tissue]?.toDouble() ?? 0.0).toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: List.generate(tissues.length, (index) {
        final tissue = tissues[index];
        final value = values[index];
        final percentage = maxValue > 0 ? value / maxValue : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  tissue.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryColor, AppColors.accentGreen],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Text(
                  '${value.toStringAsFixed(4)} µg/kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final String level = alert['level'] ?? 'info';
    final Color alertColor = level == 'critical' ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: alertColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            level == 'critical' ? Icons.error : Icons.warning,
            color: alertColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] ?? 'Alert',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: alertColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert['message'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                if (alert['action'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Action: ${alert['action']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: alertColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = mrlAnalysisData?['recommendations'] as List? ?? [];
    
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionHeader('System Recommendations', Icons.lightbulb, Colors.amber),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations.asMap().entries.map((entry) {
                final index = entry.key;
                final recommendation = entry.value.toString();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallStatusCard() {
    if (mrlAnalysisData == null) return const SizedBox.shrink();
    
    final overallAssessment = mrlAnalysisData!['overall_assessment'] ?? {};
    final bool isCompliant = overallAssessment['compliant'] ?? false;
    final String safetyStatus = overallAssessment['safety_status'] ?? 'unknown';
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompliant 
            ? [AppColors.accentGreen, AppColors.secondaryGreen]
            : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCompliant ? AppColors.accentGreen : Colors.red).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompliant ? Icons.check_circle : Icons.warning,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompliant ? 'MRL COMPLIANT' : 'MRL VIOLATION DETECTED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Safety Status: ${safetyStatus.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusMetric(
                  '${overallAssessment['total_medications'] ?? 0}',
                  'Total Medications',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatusMetric(
                  '${overallAssessment['high_risk_medications'] ?? 0}',
                  'High Risk Medications',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMrlAnalysisSection() {
    if (mrlAnalysisData?['mrl_analysis'] == null) return const SizedBox.shrink();

    final mrlAnalysisList = mrlAnalysisData!['mrl_analysis'] as List;
    
    return Column(
      children: [
        _buildSectionHeader('MRL Analysis Results', Icons.analytics, Colors.blue),
        ...mrlAnalysisList.map((analysis) => _buildMedicationAnalysisCard(analysis)).toList(),
      ],
    );
  }

  Widget _buildComplianceCheckSection() {
    if (complianceCheckData == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionHeader('Compliance Check', Icons.verified, Colors.orange),
        _buildComplianceCard(complianceCheckData!),
      ],
    );
  }

  Widget _buildResiduePredictionSection() {
    if (residuePredictionData == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionHeader('Residue Predictions', Icons.science, Colors.purple),
        _buildResiduePredictionCard(residuePredictionData!),
      ],
    );
  }

  Widget _buildWithdrawalPeriodSection() {
    // Hardcoded data as requested
    return Column(
      children: [
        _buildSectionHeader('Withdrawal Period ', Icons.schedule, Colors.green),
        _buildWithdrawalPeriodCard(),
      ],
    );
  }

  Widget _buildAnimalContextSection() {
    final animalContext = mrlAnalysisData?['animal_context'] ?? 
                         complianceCheckData?['animal_context'];
    
    if (animalContext == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionHeader('Animal Information', Icons.pets, Colors.teal),
        _buildAnimalContextCard(animalContext),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationAnalysisCard(Map<String, dynamic> analysis) {
    final complianceResult = analysis['compliance_result'] ?? {};
    final predictedResidues = analysis['predicted_residues'] ?? {};
    final withdrawalRecommendation = analysis['withdrawal_recommendation'] ?? {};
    final safetyAlerts = analysis['safety_alerts'] ?? [];

    final String complianceStatus = complianceResult['compliance_status'] ?? 'unknown';
    final bool isViolation = complianceStatus == 'violation';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isViolation ? Colors.red.withOpacity(0.5) : AppColors.accentGreen.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isViolation ? Colors.red : AppColors.accentGreen).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isViolation
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [AppColors.primaryColor, AppColors.accentGreen],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isViolation ? Icons.warning : Icons.medication,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis['normalized_name'] ?? 'Unknown Medication',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prescribed: ${analysis['prescription_date'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compliance Results
                _buildSubsectionHeader('Compliance Results'),
                const SizedBox(height: 12),
                _buildComplianceMetrics(complianceResult),
                
                // Predicted Residues
                if (predictedResidues.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSubsectionHeader('Predicted Residue Levels'),
                  const SizedBox(height: 12),
                  _buildResidueChart(predictedResidues),
                ],

                // Withdrawal Recommendation
                if (withdrawalRecommendation.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSubsectionHeader('Withdrawal Recommendations'),
                  const SizedBox(height: 12),
                  _buildWithdrawalInfo(withdrawalRecommendation),
                ],

                // Safety Alerts
                if (safetyAlerts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSubsectionHeader('Safety Alerts'),
                  const SizedBox(height: 12),
                  ...safetyAlerts.map((alert) => _buildAlertCard(alert)).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(Map<String, dynamic> data) {
    final complianceResult = data['compliance_result'] ?? {};
    final predictedResidues = data['predicted_residues'] ?? {};
    final withdrawalRecommendation = data['withdrawal_recommendation'] ?? {};
    final safetyAlerts = data['safety_alerts'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Drug: ${data['drug_name']?.toString().toUpperCase() ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Compliance Results
            _buildSubsectionHeader('Compliance Status'),
            const SizedBox(height: 12),
            _buildComplianceMetrics(complianceResult),

            // Predicted Residues
            if (predictedResidues.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSubsectionHeader('Predicted Residues'),
              const SizedBox(height: 12),
              _buildResidueChart(predictedResidues),
            ],

            // Withdrawal Info
            if (withdrawalRecommendation.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSubsectionHeader('Withdrawal Recommendations'),
              const SizedBox(height: 12),
              _buildWithdrawalInfo(withdrawalRecommendation),
            ],

            // Safety Alerts
            if (safetyAlerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSubsectionHeader('Safety Alerts'),
              const SizedBox(height: 12),
              ...safetyAlerts.map((alert) => _buildAlertCard(alert)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResiduePredictionCard(Map<String, dynamic> data) {
    final predictedResidues = data['predicted_residues'] ?? {};
    final complianceCheck = data['compliance_check'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Drug: ${data['drug_name']?.toString().toUpperCase() ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Days Since Treatment: ${data['days_since_treatment'] ?? 0}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 20),

            // Residue Levels
            _buildSubsectionHeader('Predicted Residue Levels'),
            const SizedBox(height: 12),
            _buildResidueChart(predictedResidues),

            // Model Information
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Model: ${predictedResidues['model_used'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  Text(
                    'Confidence: ${((predictedResidues['prediction_confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryTextColor,
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

  Widget _buildWithdrawalPeriodCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Oxytetracycline Withdrawal :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWithdrawalMetric(
                  '7',
                  'Standard Days',
                  Colors.blue,
                ),
                _buildWithdrawalMetric(
                  '8',
                  'Recommended',
                  Colors.green,
                ),
                _buildWithdrawalMetric(
                  '1',
                  'Safety Buffer',
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _daysSinceTreatment >= 8 
                  ? AppColors.lightGreen 
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _daysSinceTreatment >= 8 ? Icons.check_circle : Icons.warning,
                    color: _daysSinceTreatment >= 8 ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _daysSinceTreatment >= 8
                        ? 'Safe for consumption (withdrawal period completed)'
                        : 'Not safe for consumption (${8 - _daysSinceTreatment} days remaining)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _daysSinceTreatment >= 8 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Factors Considered:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            ...([
              'Drug pharmacokinetics',
              'Dosage and treatment duration',
              'Animal weight',
              'Safety margins',
              'Regulatory guidelines'
            ]).map((factor) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        factor,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
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
        title: Text(
          'MRL Analysis - ${widget.tagId}',
          style: const TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
            onPressed: _fetchAllData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Parameter Controls
          _buildParameterControls(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Fetching MRL Analysis Data...',
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 64),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchAllData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Retry Analysis'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Overall Status
                            _buildOverallStatusCard(),
                            
                            // MRL Analysis
                            _buildMrlAnalysisSection(),
                            
                            // Compliance Check
                            _buildComplianceCheckSection(),
                            
                            // Residue Predictions
                            _buildResiduePredictionSection(),
                            
                            // Withdrawal Periods
                            _buildWithdrawalPeriodSection(),
                            
                            // Animal Context
                            _buildAnimalContextSection(),
                            
                            // Recommendations
                            _buildRecommendationsSection(),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}