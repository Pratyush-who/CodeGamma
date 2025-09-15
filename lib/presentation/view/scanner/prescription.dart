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
  State<PrescriptionAnalysisScreen> createState() => _PrescriptionAnalysisScreenState();
}

class _PrescriptionAnalysisScreenState extends State<PrescriptionAnalysisScreen> {
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
      bytes[7] == 0x0A) return true;
  
  // GIF: GIF87a or GIF89a
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
  
  // WebP: RIFF + WEBP
  if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;
  
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
      Uri.parse('https://8f2wld3k-8001.inc1.devtunnels.ms/prescription/upload'),
    );

    final file = File(_selectedImage!.path);
    final bytes = await file.readAsBytes();
    
    // Create multipart file with proper content type
    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: _selectedImage!.name,
      contentType: _getContentType(_selectedImage!.path),
    );

    request.files.add(multipartFile);

    request.fields['species'] = 'cattle';
    request.fields['additional_info'] = 'Prescription analysis for animal ${widget.tagId}';
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
        _errorMessage = jsonResponse['detail'] ?? 
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
List<Map<String, dynamic>> _extractMedicationsFromResponse(Map<String, dynamic> response) {
  final List<Map<String, dynamic>> medications = [];
  
  // Extract from prescriptions
  if (response['animal_data']?['prescriptions'] != null) {
    for (var prescription in response['animal_data']['prescriptions']) {
      if (prescription['medicines'] != null) {
        for (var medicine in prescription['medicines']) {
          medications.add({
            'drug_name': medicine['name'] ?? 'Unknown Drug',
            'dosage': medicine['dosage'] ?? 'Not specified',
            'frequency': medicine['frequency'] ?? 'Not specified',
            'duration': medicine['duration'] ?? 'Not specified',
          });
        }
      }
    }
  }
  
  return medications;
}

Map<String, dynamic> _extractAnalysisResults(Map<String, dynamic> response) {
  // Extract relevant analysis data from the response
  return {
    'status': response['status'],
    'animal_id': response['animal_id'],
    'compliance_status': response['animal_data']?['complianceStatus'],
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
  // Create a unified report based on the available data
  final animalData = response['animal_data'] ?? {};
  final complianceStatus = animalData['complianceStatus'] ?? {'status': 'unknown'};
  
  return {
    'overall_status': complianceStatus['status']?.toLowerCase() ?? 'unknown',
    'summary': animalData['summary'] ?? 'No summary available',
    'key_findings': _generateKeyFindings(response),
    'recommendations': _generateRecommendations(response),
  };
}

List<String> _generateKeyFindings(Map<String, dynamic> response) {
  final findings = <String>[];
  final animalData = response['animal_data'] ?? {};
  
  if (animalData['complianceStatus']?['status'] == 'OK') {
    findings.add('Animal compliance status is satisfactory');
  }
  
  if (animalData['prescriptions'] != null && animalData['prescriptions'].isNotEmpty) {
    findings.add('${animalData['prescriptions'].length} prescription(s) found in history');
  }
  
  if (animalData['treatments'] != null && animalData['treatments'].isNotEmpty) {
    findings.add('${animalData['treatments'].length} treatment(s) recorded');
  }
  
  return findings;
}

List<String> _generateRecommendations(Map<String, dynamic> response) {
  final recommendations = <String>[];
  final animalData = response['animal_data'] ?? {};
  
  // Add recommendations based on the data
  recommendations.add('Continue regular health monitoring as per current schedule');
  
  if (animalData['prescriptions'] != null) {
    for (var prescription in animalData['prescriptions']) {
      if (prescription['followUpRequired'] == true) {
        recommendations.add('Schedule follow-up visit as recommended');
        break;
      }
    }
  }
  
  return recommendations;
}

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox();

    final prescriptionData = _analysisResult!['prescription_data'];
    final analysis = _analysisResult!['analysis_results'];
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
                : Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unifiedReport['overall_status'] == 'compliant' 
                  ? AppColors.accentGreen 
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
                        : Icons.warning,
                    color: unifiedReport['overall_status'] == 'compliant' 
                        ? AppColors.darkGreen 
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unifiedReport['overall_status'] == 'compliant' 
                        ? 'Compliant' 
                        : 'Needs Review',
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
                unifiedReport['summary'] ?? 'No summary available',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 14,
                ),
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
                'Medications',
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(prescriptionData['medications'] as List).map((med) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.mutedTextColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['drug_name'] ?? 'Unknown Drug',
                        style: TextStyle(
                          color: AppColors.primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (med['dosage'] != null && med['dosage'] != 'Not specified')
                        Text('Dosage: ${med['dosage']}', style: TextStyle(color: AppColors.secondaryTextColor)),
                      if (med['frequency'] != null && med['frequency'] != 'Not specified')
                        Text('Frequency: ${med['frequency']}', style: TextStyle(color: AppColors.secondaryTextColor)),
                      if (med['duration'] != null && med['duration'] != 'Not specified')
                        Text('Duration: ${med['duration']}', style: TextStyle(color: AppColors.secondaryTextColor)),
                    ],
                  ),
                ),
              ).toList(),
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
              ...(unifiedReport['key_findings'] as List).map((finding) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.accentGreen),
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
              ).toList(),
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
              ...(unifiedReport['recommendations'] as List).map((recommendation) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accentGreen),
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
              ).toList(),
            ],
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
                  colors: [Color.fromARGB(255, 49, 118, 76), Color.fromARGB(255, 68, 140, 93)],
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
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
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
                border: Border.all(color: AppColors.mutedTextColor.withOpacity(0.3)),
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
                                valueColor: AlwaysStoppedAnimation(Colors.white),
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
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
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
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing prescription...',
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                      ),
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