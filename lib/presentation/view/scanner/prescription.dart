// analysis_screens/prescription_analysis_screen.dart
import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class PrescriptionAnalysisScreen extends StatefulWidget {
  final String tagId;

  const PrescriptionAnalysisScreen({super.key, required this.tagId});

  @override
  State<PrescriptionAnalysisScreen> createState() =>
      _PrescriptionAnalysisScreenState();
}

class _PrescriptionAnalysisScreenState
    extends State<PrescriptionAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90, // Increased quality
        maxWidth: 1920, // Limit size to avoid large files
        maxHeight: 1080,
      );

      if (image != null) {
        // Verify the file is actually an image
        final file = File(image.path);
        final bytes = await file.readAsBytes();

        // Simple check for image file signature
        if (_isValidImage(bytes)) {
          setState(() {
            _selectedImage = image;
            _analysisResult = null;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = 'Selected file is not a valid image';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  // Helper method to validate image file signature
  bool _isValidImage(List<int> bytes) {
    if (bytes.length < 8) return false;

    // Check for common image file signatures
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A)
      return true;

    // GIF: GIF87a or GIF89a
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;

    // WebP: RIFF + WEBP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50)
      return true;

    return false;
  }

  Future<void> _uploadPrescription() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://bfc211a032dc.ngrok-free.app/prescription/upload'),
      );

      final file = File(_selectedImage!.path);
      final bytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: _selectedImage!.name,
        contentType: _getContentType(_selectedImage!.path),
      );

      request.files.add(multipartFile);

      request.fields['species'] = 'cattle';
      request.fields['additional_info'] =
          'Prescription analysis for animal ${widget.tagId}';
      request.fields['tag_no'] = widget.tagId;

      request.headers['Accept'] = 'application/json';
      request.headers['User-Agent'] = 'PrescriptionAnalysisApp/1.0';

      print('Sending request with file: ${_selectedImage!.name}');
      print('File size: ${bytes.length} bytes');
      print('Fields: ${request.fields}');

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      print('Response status: ${response.statusCode}');
      print('Response data: $jsonResponse');

      if (response.statusCode == 200) {
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _analysisResult = {
              'prescription_data': {
                'medications': _extractMedicationsFromResponse(jsonResponse),
              },
              'analysis_results': _extractAnalysisResults(jsonResponse),
              'unified_report': _createUnifiedReport(jsonResponse),
            };
          });
        } else {
          setState(() {
            _errorMessage = jsonResponse['message'] ?? 'Analysis failed';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              jsonResponse['detail'] ??
              jsonResponse['message'] ??
              'Failed to analyze prescription. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error uploading prescription: $e');
      setState(() {
        _errorMessage = 'Error uploading prescription: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper methods to transform the response
  List<Map<String, dynamic>> _extractMedicationsFromResponse(
    Map<String, dynamic> response,
  ) {
    final List<Map<String, dynamic>> medications = [];

    // Extract current prescription medications
    if (response['prescription_data']?['medications'] != null) {
      for (var medication in response['prescription_data']['medications']) {
        medications.add({
          'drug_name': medication['name'] ?? 'Unknown Drug',
          'dosage': medication['dose'] ?? 'Not specified',
          'frequency': medication['frequency'] ?? 'Not specified',
          'duration': medication['duration'] ?? 'Not specified',
          'route': 'Not specified', // Not provided in current structure
          'confidence':
              response['prescription_data']['confidence_score'] ?? 0.0,
          'type': 'current',
          'veterinarian':
              response['prescription_data']['veterinarian'] ?? 'Unknown',
          'clinic': response['prescription_data']['clinic'] ?? 'Unknown',
          'date': response['prescription_data']['date'] ?? 'Unknown',
        });
      }
    }

    if (response['animal_context']?['existing_prescriptions'] != null) {
      for (var prescription
          in response['animal_context']['existing_prescriptions']) {
        if (prescription['medicines'] != null) {
          for (var medicine in prescription['medicines']) {
            medications.add({
              'drug_name':
                  medicine['name'] ?? medicine['genericName'] ?? 'Unknown Drug',
              'dosage': medicine['dosage'] ?? 'Not specified',
              'frequency': medicine['frequency'] ?? 'Not specified',
              'duration': medicine['duration'] ?? 'Not specified',
              'route': medicine['administrationRoute'] ?? 'Not specified',
              'confidence': 1.0, // Historical data is considered reliable
              'type': 'historical',
              'date': prescription['date'] ?? 'Unknown date',
              'doctor': prescription['doctorName'] ?? 'Unknown doctor',
            });
          }
        }
      }
    }

    return medications;
  }

  Map<String, dynamic> _extractAnalysisResults(Map<String, dynamic> response) {
    final analysisResults = response['analysis_results'] ?? {};
    final unifiedReport = response['unified_report'] ?? {};

    return {
      'status': response['status'],
      'message': response['message'],
      'animal_id':
          response['prescription_data']?['animal_id'] ??
          unifiedReport['animal_id'],
      'species':
          response['prescription_data']?['species'] ?? unifiedReport['species'],
      'confidence_score':
          response['prescription_data']?['confidence_score'] ?? 0.0,
      'ocr_confidence': analysisResults['ocr_confidence'] ?? 0.0,
      'raw_text': analysisResults['raw_text'] ?? '',
      'rag_analysis': analysisResults['rag_analysis'] ?? {},
      'amu_analysis': analysisResults['amu_analysis'] ?? {},
      'mrl_analysis': analysisResults['mrl_analysis'] ?? {},
      'overall_status': unifiedReport['overall_status'] ?? 'unknown',
      'compliance_status': unifiedReport['compliance_status'] ?? 'unknown',
      'risk_level': unifiedReport['risk_level'] ?? 'unknown',
      'medications_count': unifiedReport['medications_count'] ?? 0,
      'key_findings': unifiedReport['key_findings'] ?? [],
      'critical_alerts': unifiedReport['critical_alerts'] ?? [],
      'recommendations': unifiedReport['recommendations'] ?? [],
      'withdrawal_periods': unifiedReport['withdrawal_periods'] ?? {},
      'summary': unifiedReport['summary'] ?? 'No summary available',
      'animal_summary':
          response['animal_context']?['summary'] ??
          'No animal context available',
      'total_prescriptions':
          response['animal_context']?['total_prescriptions'] ?? 0,
      'total_treatments': response['animal_context']?['total_treatments'] ?? 0,
    };
  }

  MediaType _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg'); // default to jpeg
    }
  }

  Map<String, dynamic> _createUnifiedReport(Map<String, dynamic> response) {
    // Use the unified_report directly from the API response
    final unifiedReport = response['unified_report'] ?? {};
    final analysisResults = response['analysis_results'] ?? {};

    return {
      'overall_status': unifiedReport['overall_status'] ?? 'unknown',
      'compliance_status': unifiedReport['compliance_status'] ?? 'unknown',
      'risk_level': unifiedReport['risk_level'] ?? 'unknown',
      'summary': unifiedReport['summary'] ?? 'Prescription analysis completed',
      'key_findings': unifiedReport['key_findings'] ?? [],
      'recommendations': unifiedReport['recommendations'] ?? [],
      'critical_alerts': unifiedReport['critical_alerts'] ?? [],
      'animal_id':
          unifiedReport['animal_id'] ??
          response['prescription_data']?['animal_id'],
      'species':
          unifiedReport['species'] ?? response['prescription_data']?['species'],
      'medications_count': unifiedReport['medications_count'] ?? 0,
      'withdrawal_periods': unifiedReport['withdrawal_periods'] ?? {},
      'analysis_timestamp': unifiedReport['analysis_timestamp'] ?? '',
      'ocr_confidence': analysisResults['ocr_confidence'] ?? 0.0,
      'amu_analysis': analysisResults['amu_analysis'] ?? {},
      'mrl_analysis': analysisResults['mrl_analysis'] ?? {},
      'rag_analysis': analysisResults['rag_analysis'] ?? {},
      'animal_context': response['animal_context'] ?? {},
    };
  }

  String _getStatusDisplayText(String? status) {
    switch (status?.toLowerCase()) {
      case 'compliant':
        return 'Compliant';
      case 'non-compliant':
      case 'non_compliant':
        return 'Non-Compliant';
      case 'unknown':
        return 'Analysis Pending';
      default:
        return 'Unknown Status';
    }
  }

  Widget _buildComplianceBadge(
    String label,
    bool? isCompliant,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCompliant == true
              ? Colors.green[100]
              : isCompliant == false
              ? Colors.red[100]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompliant == true
                ? Colors.green
                : isCompliant == false
                ? Colors.red
                : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompliant == true
                  ? Icons.check_circle
                  : isCompliant == false
                  ? Icons.cancel
                  : Icons.help_outline,
              size: 12,
              color: isCompliant == true
                  ? Colors.green
                  : isCompliant == false
                  ? Colors.red
                  : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isCompliant == true
                    ? Colors.green[800]
                    : isCompliant == false
                    ? Colors.red[800]
                    : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String? riskLevel) {
    Color color;
    IconData icon;

    switch (riskLevel?.toLowerCase()) {
      case 'low':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.red;
        icon = Icons.dangerous;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        riskLevel = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            'Risk: ${riskLevel?.toUpperCase()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double? confidence) {
    if (confidence == null) return Colors.grey;

    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    if (confidence >= 0.4) return Colors.red;
    return Colors.grey;
  }

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox();

    final prescriptionData = _analysisResult!['prescription_data'];
    final unifiedReport = _analysisResult!['unified_report'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Analysis Results',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Overall Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unifiedReport['overall_status'] == 'compliant'
                ? AppColors.lightGreen
                : unifiedReport['overall_status'] == 'unknown'
                ? Colors.grey[100]
                : Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unifiedReport['overall_status'] == 'compliant'
                  ? AppColors.accentGreen
                  : unifiedReport['overall_status'] == 'unknown'
                  ? Colors.grey
                  : Colors.orange,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    unifiedReport['overall_status'] == 'compliant'
                        ? Icons.check_circle
                        : unifiedReport['overall_status'] == 'unknown'
                        ? Icons.help_outline
                        : Icons.warning,
                    color: unifiedReport['overall_status'] == 'compliant'
                        ? AppColors.darkGreen
                        : unifiedReport['overall_status'] == 'unknown'
                        ? Colors.grey
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusDisplayText(unifiedReport['overall_status']),
                    style: TextStyle(
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                unifiedReport['summary'] ?? 'Analysis completed successfully',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 14,
                ),
              ),

              // Compliance status badges
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (unifiedReport['mrl_analysis']?['overall_assessment']?['compliant'] !=
                      null)
                    _buildComplianceBadge(
                      'MRL',
                      unifiedReport['mrl_analysis']['overall_assessment']['compliant'],
                      'Maximum Residue Limits',
                    ),
                  if (unifiedReport['amu_analysis']?['status'] != null)
                    _buildComplianceBadge(
                      'AMU',
                      unifiedReport['amu_analysis']['status'] == 'success',
                      'Antimicrobial Use Analysis: ${unifiedReport['amu_analysis']['status']}',
                    ),
                  if (unifiedReport['risk_level'] != null)
                    _buildRiskBadge(unifiedReport['risk_level']),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Medications List
        if (prescriptionData['medications'] != null &&
            (prescriptionData['medications'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detected Medications',
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(prescriptionData['medications'] as List)
                  .map(
                    (med) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.mutedTextColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  med['drug_name'] ?? 'Unknown Drug',
                                  style: TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (med['confidence'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getConfidenceColor(
                                      med['confidence'],
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getConfidenceColor(
                                        med['confidence'],
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${(med['confidence'] * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getConfidenceColor(
                                        med['confidence'],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (med['dosage'] != null &&
                              med['dosage'] != 'Not specified')
                            Text(
                              'Dosage: ${med['dosage']}',
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          if (med['frequency'] != null &&
                              med['frequency'] != 'Not specified')
                            Text(
                              'Frequency: ${med['frequency']}',
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          if (med['duration'] != null &&
                              med['duration'] != 'Not specified')
                            Text(
                              'Duration: ${med['duration']}',
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          if (med['route'] != null &&
                              med['route'] != 'Not specified')
                            Text(
                              'Route: ${med['route']}',
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          if (med['type'] == 'historical')
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                'Historical - ${med['date']} by ${med['doctor']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),

        const SizedBox(height: 16),

        // Key Findings
        if (unifiedReport['key_findings'] != null &&
            (unifiedReport['key_findings'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Findings',
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(unifiedReport['key_findings'] as List)
                  .map(
                    (finding) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              finding,
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),

        const SizedBox(height: 16),

        // Recommendations
        if (unifiedReport['recommendations'] != null &&
            (unifiedReport['recommendations'] as List).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommendations',
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(unifiedReport['recommendations'] as List)
                  .map(
                    (recommendation) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: TextStyle(
                                color: AppColors.primaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),

        const SizedBox(height: 16),

        // Analysis Details Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.mutedTextColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Details',
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // OCR Confidence
              if (unifiedReport['ocr_confidence'] != null)
                Row(
                  children: [
                    Icon(
                      Icons.document_scanner,
                      size: 16,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OCR Confidence: ${(unifiedReport['ocr_confidence'] * 100).round()}%',
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

              if (unifiedReport['medications_count'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 16,
                        color: AppColors.accentGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Medications Found: ${unifiedReport['medications_count']}',
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Analysis timestamp
              if (unifiedReport['analysis_timestamp'] != null &&
                  unifiedReport['analysis_timestamp'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.accentGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzed: ${unifiedReport['analysis_timestamp']}',
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Animal Context Section
        if (unifiedReport['animal_context'] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal History',
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (unifiedReport['animal_context']['summary'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      unifiedReport['animal_context']['summary'],
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),

                if (unifiedReport['animal_context']['total_prescriptions'] !=
                    null)
                  Row(
                    children: [
                      Icon(Icons.history, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Previous Prescriptions: ${unifiedReport['animal_context']['total_prescriptions']}',
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                if (unifiedReport['animal_context']['total_treatments'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Treatments: ${unifiedReport['animal_context']['total_treatments']}',
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // Critical Alerts Section
        if (unifiedReport['critical_alerts'] != null &&
            (unifiedReport['critical_alerts'] as List).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Critical Alerts',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(unifiedReport['critical_alerts'] as List)
                      .map(
                        (alert) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error,
                                size: 12,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
      ],
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
          'Prescription Analysis',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 49, 118, 76),
                    Color.fromARGB(255, 68, 140, 93),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prescription Analysis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Tag: ${widget.tagId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Image Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.mutedTextColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Prescription',
                    style: TextStyle(
                      color: AppColors.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedImage != null)
                    Column(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImage!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 20),
                        SizedBox(width: 8),
                        Text('Select Prescription Image'),
                      ],
                    ),
                  ),

                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _uploadPrescription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics, size: 20),
                                SizedBox(width: 8),
                                Text('Analyze Prescription'),
                              ],
                            ),
                    ),
                  ],
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Analysis Results
            if (_analysisResult != null) _buildAnalysisResult(),

            // Loading Indicator
            if (_isLoading) ...[
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing prescription...',
                      style: TextStyle(color: AppColors.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
