import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';

class AnimalDataScreen extends StatefulWidget {
  final String tagId;

  const AnimalDataScreen({super.key, required this.tagId});

  @override
  State<AnimalDataScreen> createState() => _AnimalDataScreenState();
}

class _AnimalDataScreenState extends State<AnimalDataScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _animalData;
  String? _error;

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
          _animalData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch animal data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        title: const Text(
          'Animal Data',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _fetchAnimalData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.accentGreen],
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
                            Icons.pets,
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
                                'Animal Overview',
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

                  // Basic Information
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_animalData?['basicInfo'] != null) ...[
                    _buildInfoCard(
                      'Breed',
                      _animalData!['basicInfo']['breed'] ?? 'N/A',
                      Icons.pets,
                    ),
                    _buildInfoCard(
                      'Gender',
                      _animalData!['basicInfo']['gender'] ?? 'N/A',
                      Icons.male,
                    ),
                    _buildInfoCard(
                      'Farm ID',
                      _animalData!['basicInfo']['farmId'] ?? 'N/A',
                      Icons.home,
                    ),
                    _buildInfoCard(
                      'Date of Admission',
                      _animalData!['basicInfo']['dateOfAdmission'] ?? 'N/A',
                      Icons.calendar_today,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Health Status
                  const Text(
                    'Health Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_animalData?['healthStatus'] != null) ...[
                    _buildInfoCard(
                      'Vaccination Status',
                      _animalData!['healthStatus']['vaccination'] == true
                          ? 'Completed'
                          : 'Pending',
                      Icons.vaccines,
                    ),
                    _buildInfoCard(
                      'Insurance Status',
                      _animalData!['healthStatus']['insurance'] == true
                          ? 'Covered'
                          : 'Not Covered',
                      Icons.shield,
                    ),
                    if (_animalData!['healthStatus']['lastVisit'] != null) ...[
                      _buildInfoCard(
                        'Last Visit Date',
                        _animalData!['healthStatus']['lastVisit']['date'] ??
                            'N/A',
                        Icons.medical_services,
                      ),
                      _buildInfoCard(
                        'Doctor',
                        _animalData!['healthStatus']['lastVisit']['doctorName'] ??
                            'N/A',
                        Icons.person,
                      ),
                      _buildInfoCard(
                        'Purpose',
                        _animalData!['healthStatus']['lastVisit']['purpose'] ??
                            'N/A',
                        Icons.description,
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // Record Counts
                  const Text(
                    'Records Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_animalData?['recordCounts'] != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_animalData!['recordCounts']['prescriptions'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const Text(
                                  'Prescriptions',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.mintGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_animalData!['recordCounts']['doctorVisits'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const Text(
                                  'Doctor Visits',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_animalData!['recordCounts']['treatments'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const Text(
                                  'Treatments',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_animalData!['recordCounts']['historyEntries'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const Text(
                                  'History Entries',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
