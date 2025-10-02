import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class RiskPredictionScreen extends StatefulWidget {
  const RiskPredictionScreen({Key? key}) : super(key: key);

  @override
  State<RiskPredictionScreen> createState() => _RiskPredictionScreenState();
}

class _RiskPredictionScreenState extends State<RiskPredictionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Connection test state
  bool _isTestingConnection = false;
  String? _connectionStatus;
  bool _showDebugInfo = false;

  // Make ngrok URL configurable and add fallback
  static const String baseUrl = 'https://bfc211a032dc.ngrok-free.app';
  static const String fallbackUrl = 'http://localhost:8000'; // Add fallback URL

  final _sessionIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _previousInfectionsController = TextEditingController();
  final _treatmentDurationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _timeSinceLastTreatmentController = TextEditingController();
  final _previousTreatmentsController = TextEditingController();

  String? _animalType;
  String? _farmType;
  String? _vaccinationStatus;
  String? _feedType;
  String? _housingCondition;
  String? _region;
  String? _season;
  String? _antibioticClassUsed;
  String? _resistancePattern;

  // Loading and result states
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  // Dropdown options
  final List<String> _animalTypes = [
    'Dairy Cow',
    'Beef Cattle',
    'Goat',
    'Sheep',
    'Buffalo',
    'Pig',
    'Chicken',
    'Duck',
  ];

  final List<String> _farmTypes = [
    'Commercial',
    'Small-scale',
    'Organic',
    'Intensive',
    'Extensive',
  ];

  final List<String> _vaccinationStatuses = [
    'Up-to-date',
    'Partially vaccinated',
    'Not vaccinated',
    'Overdue',
  ];

  final List<String> _feedTypes = [
    'Mixed ration (silage + concentrate)',
    'Pasture only',
    'Concentrate only',
    'Silage only',
    'Organic feed',
    'Commercial feed',
  ];

  final List<String> _housingConditions = [
    'Semi-intensive',
    'Intensive',
    'Free-range',
    'Confined',
    'Pasture-based',
  ];

  final List<String> _regions = [
    'Uttar Pradesh, India',
    'Maharashtra, India',
    'Punjab, India',
    'Karnataka, India',
    'Tamil Nadu, India',
    'Gujarat, India',
  ];

  final List<String> _seasons = ['Monsoon', 'Winter', 'Summer', 'Post-monsoon'];

  final List<String> _antibioticClasses = [
    'Tetracyclines',
    'Penicillins',
    'Macrolides',
    'Fluoroquinolones',
    'Aminoglycosides',
    'Sulfonamides',
    'Chloramphenicol',
  ];

  final List<String> _resistancePatterns = [
    'Moderate resistance to penicillin',
    'High resistance to tetracycline',
    'Multi-drug resistance',
    'Low resistance',
    'No known resistance',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation - this was missing!
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sessionIdController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _farmSizeController.dispose();
    _previousInfectionsController.dispose();
    _treatmentDurationController.dispose();
    _dosageController.dispose();
    _timeSinceLastTreatmentController.dispose();
    _previousTreatmentsController.dispose();
    super.dispose();
  }

  // Improved connection test with better error handling
  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    // List of URLs to test
    final urlsToTest = [baseUrl, fallbackUrl];

    for (String url in urlsToTest) {
      try {
        print('Testing connection to: $url');

        final response = await http
            .get(
              Uri.parse('$url/health'), // Try health endpoint first
              headers: {
                'Accept': 'application/json',
                'ngrok-skip-browser-warning':
                    'true', // Skip ngrok browser warning
              },
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Connection timeout after 10 seconds');
              },
            );

        print('Response from $url: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 500) {
          setState(() {
            _connectionStatus =
                '✅ Server reachable at $url\nStatus: ${response.statusCode}';
          });
          return; // Success, exit the loop
        }
      } catch (e) {
        print('Failed to connect to $url: $e');
        // Try root endpoint as fallback
        try {
          final response = await http
              .get(
                Uri.parse('$url/'),
                headers: {
                  'Accept': 'application/json',
                  'ngrok-skip-browser-warning': 'true',
                },
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode >= 200 && response.statusCode < 500) {
            setState(() {
              _connectionStatus =
                  '✅ Server reachable at $url\nStatus: ${response.statusCode}';
            });
            return;
          }
        } catch (e2) {
          print('Root endpoint also failed for $url: $e2');
        }
      }
    }

    // If all URLs failed
    setState(() {
      _connectionStatus =
          '''
❌ All connection attempts failed

Tested URLs:
${urlsToTest.map((url) => '• $url').join('\n')}

Troubleshooting:
• Check if server is running
• Verify ngrok tunnel is active
• Check network connection
• Try VPN if behind firewall
• Check server logs
      ''';
    });

    setState(() {
      _isTestingConnection = false;
    });
  }

  void _fillDummyData() {
    setState(() {
      _sessionIdController.text =
          'SESSION-${DateTime.now().millisecondsSinceEpoch}'; // Make unique
      _ageController.text = '4';
      _weightController.text = '620';
      _farmSizeController.text = '75';
      _previousInfectionsController.text = '2';
      _treatmentDurationController.text = '7';
      _dosageController.text = '15';
      _timeSinceLastTreatmentController.text = '90';
      _previousTreatmentsController.text = '3';
      _animalType = 'Dairy Cow';
      _farmType = 'Commercial';
      _vaccinationStatus = 'Up-to-date';
      _feedType = 'Mixed ration (silage + concentrate)';
      _housingCondition = 'Semi-intensive';
      _region = 'Uttar Pradesh, India';
      _season = 'Monsoon';
      _antibioticClassUsed = 'Tetracyclines';
      _resistancePattern = 'Moderate resistance to penicillin';
    });
  }

  void _clearForm() {
    setState(() {
      _sessionIdController.clear();
      _ageController.clear();
      _weightController.clear();
      _farmSizeController.clear();
      _previousInfectionsController.clear();
      _treatmentDurationController.clear();
      _dosageController.clear();
      _timeSinceLastTreatmentController.clear();
      _previousTreatmentsController.clear();
      _animalType = null;
      _farmType = null;
      _vaccinationStatus = null;
      _feedType = null;
      _housingCondition = null;
      _region = null;
      _season = null;
      _antibioticClassUsed = null;
      _resistancePattern = null;
      _predictionResult = null;
      _errorMessage = null;
      _connectionStatus = null;
    });
  }

  // Improved prediction function with better error handling and validation
  Future<void> _predictRisk() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    try {
      // Validate numeric inputs
      final age = int.tryParse(_ageController.text);
      final weight = int.tryParse(_weightController.text);
      final farmSize = int.tryParse(_farmSizeController.text);
      final previousInfections = int.tryParse(
        _previousInfectionsController.text,
      );
      final treatmentDuration = int.tryParse(_treatmentDurationController.text);
      final dosage = int.tryParse(_dosageController.text);
      final timeSinceLastTreatment = int.tryParse(
        _timeSinceLastTreatmentController.text,
      );
      final previousTreatments = int.tryParse(
        _previousTreatmentsController.text,
      );

      if (age == null ||
          weight == null ||
          farmSize == null ||
          previousInfections == null ||
          treatmentDuration == null ||
          dosage == null ||
          timeSinceLastTreatment == null ||
          previousTreatments == null) {
        throw Exception('Invalid numeric input values');
      }

      final requestBody = {
        "session_id": _sessionIdController.text,
        "metadata": {
          "note": "Risk prediction request",
          "timestamp": DateTime.now().toIso8601String(),
          "app_version": "1.0.0", // Add app version
        },
        "age": age,
        "weight": weight,
        "farm_size": farmSize,
        "previous_infections": previousInfections,
        "treatment_duration": treatmentDuration,
        "dosage": dosage,
        "time_since_last_treatment": timeSinceLastTreatment,
        "previous_treatments": previousTreatments,
        "animal_type": _animalType,
        "farm_type": _farmType,
        "vaccination_status": _vaccinationStatus,
        "feed_type": _feedType,
        "housing_condition": _housingCondition,
        "region": _region,
        "season": _season,
        "antibiotic_class_used": _antibioticClassUsed,
        "resistance_pattern": _resistancePattern,
      };

      // Try multiple URLs
      final urlsToTry = [
        '$baseUrl/api/v1/risk/predict',
        '$fallbackUrl/api/v1/risk/predict',
        '$baseUrl/predict', // Alternative endpoint
        '$fallbackUrl/predict',
      ];

      http.Response? successResponse;
      String? lastError;

      for (String url in urlsToTry) {
        try {
          print('Trying API request to: $url');

          final response = await http
              .post(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'ngrok-skip-browser-warning': 'true', // Skip ngrok warning
                },
                body: json.encode(requestBody),
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw Exception('Request timeout after 30 seconds');
                },
              );

          print('Response from $url - Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            successResponse = response;
            break;
          } else {
            lastError =
                'HTTP ${response.statusCode} from $url: ${response.body}';
          }
        } catch (e) {
          lastError = 'Failed to connect to $url: $e';
          print(lastError);
        }
      }

      if (successResponse != null) {
        try {
          final responseData = json.decode(successResponse.body);
          setState(() {
            _predictionResult = responseData;
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Risk prediction completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (parseError) {
          print('JSON parse error: $parseError');
          setState(() {
            _errorMessage =
                'Response parsing failed: $parseError\nRaw response: ${successResponse?.body}';
          });
        }
      } else {
        setState(() {
          _errorMessage = lastError ?? 'All API endpoints failed';
        });
      }
    } catch (e) {
      print('Exception in _predictRisk: $e');
      setState(() {
        _errorMessage =
            'Request failed: $e\n\nPlease check:\n• Network connection\n• Server availability\n• Input data format';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.mutedTextColor),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(color: AppColors.primaryTextColor),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_predictionResult == null && _errorMessage == null) return Container();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                colors: _errorMessage != null
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [AppColors.primaryColor, AppColors.primaryColorLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _errorMessage != null
                        ? Icons.error_outline
                        : Icons.analytics,
                    color: AppColors.whiteColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage != null
                            ? 'Prediction Failed'
                            : 'Risk Analysis Complete',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.whiteColor,
                        ),
                      ),
                      Text(
                        _errorMessage != null
                            ? 'Unable to process request'
                            : 'AMR resistance prediction results',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.whiteColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: _errorMessage != null
                ? _buildErrorContent()
                : _buildSuccessContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Error Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Troubleshooting Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '• Check your internet connection\n'
                '• Verify all form fields are filled correctly\n'
                '• Try the "Test Connection" button\n'
                '• Contact support if the issue persists',
                style: TextStyle(color: Colors.blue, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    final result = _predictionResult!;

    // Extract key information from the API response
    final riskScore = result['risk_score'] ?? result['prediction'] ?? 'N/A';
    final riskLevel = _getRiskLevel(riskScore);
    final confidence = result['confidence'] ?? result['probability'] ?? 'N/A';
    final recommendations = result['recommendations'] ?? [];
    final factors = result['risk_factors'] ?? result['factors'] ?? [];
    final sessionId = result['session_id'] ?? 'N/A';
    final timestamp = result['timestamp'] ?? DateTime.now().toIso8601String();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risk Score Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getRiskGradientColors(riskLevel),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Risk Assessment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      riskLevel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Risk Score',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          riskScore.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (confidence != 'N/A')
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confidence',
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(double.tryParse(confidence.toString()) ?? 0.0) * 100}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Risk Factors Section
        if (factors.isNotEmpty) ...[
          const Text(
            'Key Risk Factors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...factors
              .take(5)
              .map<Widget>(
                (factor) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          factor.toString(),
                          style: const TextStyle(
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
          const SizedBox(height: 20),
        ],

        // Recommendations Section
        if (recommendations.isNotEmpty) ...[
          const Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations
              .take(5)
              .map<Widget>(
                (recommendation) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.accentGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation.toString(),
                          style: const TextStyle(
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
          const SizedBox(height: 20),
        ],

        // Session Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Session Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Session ID: $sessionId',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedTextColor,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Generated: ${_formatTimestamp(timestamp)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRiskLevel(dynamic riskScore) {
    if (riskScore == 'N/A') return 'Unknown';

    final score = double.tryParse(riskScore.toString()) ?? 0.0;

    if (score >= 0.8) return 'High';
    if (score >= 0.6) return 'Moderate';
    if (score >= 0.4) return 'Low';
    return 'Very Low';
  }

  List<Color> _getRiskGradientColors(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return [Colors.red.shade400, Colors.red.shade600];
      case 'moderate':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'low':
        return [Colors.yellow.shade400, Colors.yellow.shade600];
      case 'very low':
        return [Colors.green.shade400, Colors.green.shade600];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'AMR Risk Prediction',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.whiteColor,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColorLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.biotech,
                        size: 32,
                        color: AppColors.whiteColor,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Antimicrobial Resistance Prediction',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.whiteColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Predict resistance risk for livestock',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fillDummyData,
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Fill Dummy Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: AppColors.whiteColor,
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
                        onPressed: _clearForm,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear Form'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTestingConnection
                            ? null
                            : _testConnection,
                        icon: _isTestingConnection
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.whiteColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.wifi_find, size: 18),
                        label: Text(
                          _isTestingConnection
                              ? 'Testing...'
                              : 'Test Connection',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryGreen,
                          foregroundColor: AppColors.whiteColor,
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
                        onPressed: () =>
                            setState(() => _showDebugInfo = !_showDebugInfo),
                        icon: Icon(
                          _showDebugInfo
                              ? Icons.bug_report
                              : Icons.info_outline,
                          size: 18,
                        ),
                        label: Text(
                          _showDebugInfo ? 'Hide Debug' : 'Show Debug',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkGreen,
                          side: const BorderSide(color: AppColors.darkGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Debug Info Panel
                if (_showDebugInfo) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.developer_mode,
                              color: AppColors.darkGreen,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Debug Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Base URL: $baseUrl',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Endpoint: /api/v1/risk/predict',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Method: POST',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Content-Type: application/json',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check console output for detailed logs',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Connection Status
                if (_connectionStatus != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _connectionStatus!.contains('failed')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _connectionStatus!.contains('failed')
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _connectionStatus!.contains('failed')
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: _connectionStatus!.contains('failed')
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Connection Test Result',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _connectionStatus!.contains('failed')
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _connectionStatus!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _connectionStatus!.contains('failed')
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Form Fields
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Session ID',
                  controller: _sessionIdController,
                  hintText: 'Enter session identifier',
                  validator: (value) =>
                      value?.isEmpty == true ? 'Session ID is required' : null,
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Age (years)',
                        controller: _ageController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Age is required';
                          if (int.tryParse(value!) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Weight (kg)',
                        controller: _weightController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true)
                            return 'Weight is required';
                          if (int.tryParse(value!) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                _buildTextField(
                  label: 'Farm Size (hectares)',
                  controller: _farmSizeController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Farm size is required';
                    if (int.tryParse(value!) == null)
                      return 'Enter valid number';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Medical History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Previous Infections',
                        controller: _previousInfectionsController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (int.tryParse(value!) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Treatment Duration (days)',
                        controller: _treatmentDurationController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (int.tryParse(value!) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Dosage (mg)',
                        controller: _dosageController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (int.tryParse(value!) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Days Since Last Treatment',
                        controller: _timeSinceLastTreatmentController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (int.tryParse(value!) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                _buildTextField(
                  label: 'Previous Treatments Count',
                  controller: _previousTreatmentsController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Required';
                    if (int.tryParse(value!) == null)
                      return 'Enter valid number';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Farm Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'Animal Type',
                  value: _animalType,
                  items: _animalTypes,
                  onChanged: (value) => setState(() => _animalType = value),
                  validator: (value) =>
                      value == null ? 'Please select animal type' : null,
                ),

                _buildDropdown(
                  label: 'Farm Type',
                  value: _farmType,
                  items: _farmTypes,
                  onChanged: (value) => setState(() => _farmType = value),
                  validator: (value) =>
                      value == null ? 'Please select farm type' : null,
                ),

                _buildDropdown(
                  label: 'Vaccination Status',
                  value: _vaccinationStatus,
                  items: _vaccinationStatuses,
                  onChanged: (value) =>
                      setState(() => _vaccinationStatus = value),
                  validator: (value) =>
                      value == null ? 'Please select vaccination status' : null,
                ),

                _buildDropdown(
                  label: 'Feed Type',
                  value: _feedType,
                  items: _feedTypes,
                  onChanged: (value) => setState(() => _feedType = value),
                  validator: (value) =>
                      value == null ? 'Please select feed type' : null,
                ),

                _buildDropdown(
                  label: 'Housing Condition',
                  value: _housingCondition,
                  items: _housingConditions,
                  onChanged: (value) =>
                      setState(() => _housingCondition = value),
                  validator: (value) =>
                      value == null ? 'Please select housing condition' : null,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Environmental & Treatment Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'Region',
                  value: _region,
                  items: _regions,
                  onChanged: (value) => setState(() => _region = value),
                  validator: (value) =>
                      value == null ? 'Please select region' : null,
                ),

                _buildDropdown(
                  label: 'Season',
                  value: _season,
                  items: _seasons,
                  onChanged: (value) => setState(() => _season = value),
                  validator: (value) =>
                      value == null ? 'Please select season' : null,
                ),

                _buildDropdown(
                  label: 'Antibiotic Class Used',
                  value: _antibioticClassUsed,
                  items: _antibioticClasses,
                  onChanged: (value) =>
                      setState(() => _antibioticClassUsed = value),
                  validator: (value) =>
                      value == null ? 'Please select antibiotic class' : null,
                ),

                _buildDropdown(
                  label: 'Resistance Pattern',
                  value: _resistancePattern,
                  items: _resistancePatterns,
                  onChanged: (value) =>
                      setState(() => _resistancePattern = value),
                  validator: (value) =>
                      value == null ? 'Please select resistance pattern' : null,
                ),

                const SizedBox(height: 32),

                // Predict Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _predictRisk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.whiteColor,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Analyzing...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Predict AMR Risk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                _buildResultCard(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
