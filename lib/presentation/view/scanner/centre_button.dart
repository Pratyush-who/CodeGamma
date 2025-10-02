import 'dart:io';
import 'package:camera/camera.dart';
import 'package:codegamma_sih/presentation/view/scanner/after_scan.dart';
import 'package:codegamma_sih/presentation/view/scanner/cow_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/constants/app_colors.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  bool _isScanning = false;
  bool _isCameraInitialized = false;
  bool _isImageCaptured = false;
  bool _isProcessing = false;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  XFile? _capturedImage;
  String? _extractedTagId;
  final String _geminiApiKey = "AIzaSyA1IJ3ICYjRPZGdQheZCrbZeoVN_SoOtbs";
  // Dynamically resolved working Gemini model (vision capable)
  String? _workingGeminiModel; // e.g. gemini-1.5-pro, gemini-1.5-flash
  bool _modelResolutionAttempted = false;
  bool _geminiUnavailable = false; // If true we skip further Gemini attempts

  // Candidate multimodal models to try (ordered by quality preference)
  static const List<String> _candidateGeminiModels = [
    'gemini-1.5-pro',
    'gemini-1.5-flash',
    'gemini-1.5-pro-latest',
    'gemini-1.5-flash-latest',
    'gemini-pro-vision', // legacy
    'gemini-pro', // (text only, last resort – still can sometimes parse digits if model accepts image but usually not)
  ];

  Future<void> _resolveGeminiModel() async {
    if (_modelResolutionAttempted) return;
    _modelResolutionAttempted = true;
    debugPrint('Resolving available Gemini model...');

    // Try ListModels endpoint first
    try {
      final listUri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_geminiApiKey',
      );
      final listResp = await http
          .get(listUri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (listResp.statusCode == 200) {
        final data = jsonDecode(listResp.body);
        final models =
            (data['models'] as List?)
                ?.map((e) => e['name'] as String)
                .toList() ??
            [];
        debugPrint('ListModels returned ${models.length} models');
        for (final cand in _candidateGeminiModels) {
          if (models.contains('models/$cand')) {
            _workingGeminiModel = cand;
            debugPrint(
              'Selected Gemini model via ListModels: $_workingGeminiModel',
            );
            return;
          }
        }
      } else {
        debugPrint(
          'ListModels failed: ${listResp.statusCode} ${listResp.body}',
        );
      }
    } catch (e) {
      debugPrint('ListModels exception: $e');
    }

    // Fallback: try generateContent ping per candidate until one succeeds (text only)
    for (final cand in _candidateGeminiModels) {
      try {
        final pingUri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$cand:generateContent?key=$_geminiApiKey',
        );
        final body = {
          'contents': [
            {
              'parts': [
                {'text': 'PING: Return OK if you received this.'},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 1},
        };
        final resp = await http
            .post(
              pingUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 12));
        if (resp.statusCode == 200) {
          _workingGeminiModel = cand;
          debugPrint('Selected Gemini model via ping: $_workingGeminiModel');
          return;
        } else {
          debugPrint('Model $cand ping failed (${resp.statusCode})');
        }
      } catch (e) {
        debugPrint('Model $cand ping exception: $e');
      }
    }

    // If none works mark unavailable
    _geminiUnavailable = true;
    debugPrint(
      'No Gemini model available. Will use on-device OCR fallback only.',
    );
  }

  Future<String?> _fallbackOcr(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final result = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      final buffer = StringBuffer();
      for (final block in result.blocks) {
        for (final line in block.lines) {
          buffer.write(line.text);
          buffer.write(' ');
        }
      }
      final raw = buffer.toString();
      debugPrint('MLKit raw text: $raw');
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return null;
      if (digits.length >= 12) return digits.substring(0, 12);
      if (digits.length >= 8) return digits; // partial but acceptable
      return null;
    } catch (e) {
      debugPrint('Fallback OCR error: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan ear tags'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Use the back camera (usually index 0)
        _cameraController = CameraController(
          _cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _retakePhoto() {
    setState(() {
      _isImageCaptured = false;
      _capturedImage = null;
      _extractedTagId = null;
    });
  }

  Future<String?> _analyzeImageWithGemini(File imageFile) async {
    try {
      debugPrint('Starting Gemini analysis for image: ${imageFile.path}');
      await _resolveGeminiModel();
      if (_geminiUnavailable || _workingGeminiModel == null) {
        debugPrint('Skipping Gemini – unavailable, using fallback OCR');
        return await _fallbackOcr(imageFile);
      }

      // Check if file exists
      if (!await imageFile.exists()) {
        debugPrint('ERROR: Image file does not exist!');
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();
      debugPrint('Image size: ${imageBytes.length} bytes');

      final base64Image = base64Encode(imageBytes);
      debugPrint('Image encoded to base64 (length: ${base64Image.length})');

      final model = _workingGeminiModel!;
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
      );
      debugPrint('Making request to Gemini API with model: $model');

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    """Analyze this cattle ear tag image. Extract ONLY the numeric digits visible on the tag.

The ear tag typically has:
- One or more numbers printed on it
- Numbers might be arranged vertically or horizontally
- Focus on the clearly printed digits

Rules:
1. Return ONLY the numbers you see, nothing else
2. If you see multiple numbers, combine them into one 12-digit number if possible
3. If you see numbers like "105319" and "72122", combine to "10531972122"
4. Remove any spaces, letters, or special characters
5. If no clear numbers visible, return "NOT_FOUND"

Respond with just the number(s), for example: "105319072122" or "NOT_FOUND""",
              },
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.1,
          "topK": 1,
          "topP": 1,
          "maxOutputTokens": 150,
        },
      };

      // Make the API request with timeout
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('ERROR: Gemini API request timed out');
              throw Exception('Request timeout');
            },
          );

      debugPrint('Gemini API Response Status: ${response.statusCode}');
      debugPrint('Gemini API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];
          debugPrint('Candidate data: $candidate');

          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            final extractedText = candidate['content']['parts'][0]['text']
                .toString()
                .trim();
            debugPrint('✓ Extracted text from Gemini: $extractedText');

            // If the response is "NOT_FOUND", return null
            if (extractedText.toUpperCase().contains('NOT_FOUND') ||
                extractedText.toUpperCase().contains('NO NUMBER') ||
                extractedText.toUpperCase().contains('CANNOT')) {
              debugPrint('✗ No numbers found in image');
              return null;
            }

            // Clean the text - remove all non-digit characters
            String cleanedText = extractedText.replaceAll(RegExp(r'\D'), '');
            debugPrint('Cleaned numeric text: $cleanedText');

            if (cleanedText.isEmpty) {
              debugPrint('✗ No digits found after cleaning');
              return null;
            }

            // Strategy 1: Check if we have exactly 12 digits
            if (cleanedText.length == 12) {
              debugPrint('✓ Found exact 12-digit number: $cleanedText');
              return cleanedText;
            }

            // Strategy 2: Look for 12 consecutive digits in the text
            final RegExp twelveDigitRegex = RegExp(r'\d{12}');
            final Match? match = twelveDigitRegex.firstMatch(cleanedText);
            if (match != null) {
              final foundNumber = match.group(0)!;
              debugPrint('✓ Extracted 12-digit sequence: $foundNumber');
              return foundNumber;
            }

            // Strategy 3: If we have more or less than 12 digits, try to parse
            if (cleanedText.length > 12) {
              // Take first 12 digits
              final result = cleanedText.substring(0, 12);
              debugPrint(
                '⚠ Taking first 12 digits from longer string: $result',
              );
              return result;
            } else if (cleanedText.length >= 8) {
              // If we have at least 8 digits, return what we have
              debugPrint('⚠ Found ${cleanedText.length} digits: $cleanedText');
              return cleanedText;
            }

            debugPrint(
              '✗ Could not extract valid tag number (found ${cleanedText.length} digits)',
            );
            return null;
          } else {
            debugPrint(
              '✗ Unexpected response structure - missing content/parts',
            );
            debugPrint('Full response: $responseData');
            return null;
          }
        } else {
          debugPrint('✗ No candidates in response');
          debugPrint('Full response: $responseData');
          return null;
        }
      } else {
        debugPrint('✗ Gemini API error: HTTP ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        bool notFound = false;
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            final message = error['message']?.toString() ?? '';
            debugPrint('API Error: $message');
            if (message.contains('not found') ||
                message.contains('is not found')) {
              notFound = true;
            }
            if (message.contains('API_KEY')) {
              debugPrint('✗ ERROR: Invalid or missing API key');
            } else if (message.contains('QUOTA')) {
              debugPrint('✗ ERROR: API quota exceeded');
            }
          }
        } catch (e) {
          debugPrint('Could not parse error response: $e');
        }

        if (notFound) {
          // Mark model invalid and retry with next candidate once
          debugPrint('Model $model not found – trying next candidate');
          _workingGeminiModel = null;
          _modelResolutionAttempted = false; // allow re-resolution
          await _resolveGeminiModel();
          if (!_geminiUnavailable && _workingGeminiModel != null) {
            return await _analyzeImageWithGemini(imageFile); // retry
          } else {
            debugPrint('No other Gemini models available, falling back to OCR');
            return await _fallbackOcr(imageFile);
          }
        }

        // Other error: fallback OCR
        final ocrResult = await _fallbackOcr(imageFile);
        return ocrResult;
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Exception in Gemini analysis: $e');
      debugPrint('Stack trace: $stackTrace');
      // Last resort fallback
      return await _fallbackOcr(imageFile);
    }
  }

  void _startScanning() async {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not ready. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    try {
      setState(() {
        _isScanning = true;
        _isImageCaptured = true;
        _isProcessing = true;
      });

      _scanAnimationController.repeat();

      // Capture the image
      _capturedImage = await _cameraController!.takePicture();

      // Add a small delay to show the captured image
      await Future.delayed(const Duration(milliseconds: 500));

      // Analyze the image with Gemini AI
      final File imageFile = File(_capturedImage!.path);
      final String? tagId = await _analyzeImageWithGemini(imageFile);

      if (!mounted) return;

      _scanAnimationController.stop();
      _scanAnimationController.reset();

      setState(() {
        _isScanning = false;
        _isProcessing = false;
        _extractedTagId = tagId;
      });

      debugPrint('Scan completed. Extracted Tag ID: ${tagId ?? "NULL"}');

      if (tagId != null && tagId.isNotEmpty) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Successfully detected ear tag: $tagId'),
                  ),
                ],
              ),
              backgroundColor: AppColors.accentGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Wait a moment before navigating
        await Future.delayed(const Duration(milliseconds: 800));

        // Navigate to the next screen with the extracted tag ID
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AfterScanPage(tagId: tagId),
            ),
          );
        }
      } else {
        // Show error message with more helpful text
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Could not detect ear tag',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tips: Ensure good lighting, clean tag, and hold camera steady',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Error capturing or processing image: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isProcessing = false;
          _isImageCaptured = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Scanning Failed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Check your internet connection and try again',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanBoxSize = screenSize.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Ear Tag',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isImageCaptured && _capturedImage != null)
            Positioned.fill(
              child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
            )
          else if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentGreen,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Dark overlay with cutout for scanning area
          if (_isCameraInitialized)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: ScanOverlayPainter(
                  scanAreaSize: Size(scanBoxSize, scanBoxSize * 0.8),
                  screenSize: MediaQuery.of(context).size,
                ),
              ),
            ),

          // Scanning frame and corners
          if (_isCameraInitialized)
            Center(
              child: Container(
                width: scanBoxSize,
                height: scanBoxSize * 0.8,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? AppColors.accentGreen : Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          // Scanning animation line
          if (_isScanning)
            Center(
              child: SizedBox(
                width: scanBoxSize,
                height: scanBoxSize * 0.8,
                child: AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: (scanBoxSize * 0.8 - 4) * _scanAnimation.value,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.accentGreen,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Corner indicators
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize * 0.8,
              child: Stack(
                children: [
                  // Top left corner
                  Positioned(
                    top: -3,
                    left: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                          left: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Top right corner
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom left corner
                  Positioned(
                    bottom: -3,
                    left: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                          left: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom right corner
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: AppColors.accentGreen,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions and scan button
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isScanning
                      ? 'Scanning ear tag...'
                      : _isImageCaptured
                      ? _isProcessing
                            ? 'Processing image...'
                            : _extractedTagId != null
                            ? 'Tag ID: $_extractedTagId'
                            : 'Photo captured! Choose an option below'
                      : 'Position ear tag within the frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!_isScanning && !_isImageCaptured)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _startScanning();
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor,
                            AppColors.accentGreen,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                if (_isImageCaptured && !_isScanning && !_isProcessing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _retakePhoto();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Retake',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _startScanning();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryColor,
                                AppColors.accentGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Scan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_isScanning || _isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.accentGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isProcessing ? 'Analyzing...' : 'Processing...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to create overlay with cutout
class ScanOverlayPainter extends CustomPainter {
  final Size scanAreaSize;
  final Size screenSize;

  ScanOverlayPainter({required this.scanAreaSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create the cutout rectangle (扫描区域)
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize.width,
      height: scanAreaSize.height,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
