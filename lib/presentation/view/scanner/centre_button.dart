import 'dart:io';
import 'package:camera/camera.dart';
import 'package:codegamma_sih/presentation/view/scanner/after_scan.dart';
import 'package:codegamma_sih/presentation/view/scanner/cow_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      // Read image as bytes and convert to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Use the correct Gemini Vision API endpoint
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
      );

      // Create the request payload with improved prompt
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    """Look at this cattle ear tag image carefully. I can see there are numbers printed on the yellow ear tag.

Please extract ALL the numbers you can see on this ear tag. The ear tag might have:
- A longer number (like 5-6 digits) 
- A shorter number (like 4-5 digits)
- Numbers arranged vertically or horizontally
- Numbers in different sections of the tag

Please return ALL the numbers you can see, separated by commas. For example: "105319,72122" or just "105319" if you only see one number.

If you cannot see any numbers clearly, return "NOT_FOUND".

Focus on the printed black numbers on the yellow ear tag. Don't include any barcodes or other markings, just the actual numeric digits.""",
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
          "maxOutputTokens": 100,
        },
      };

      // Make the API request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Gemini API Response Status: ${response.statusCode}');
      debugPrint('Gemini API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          final extractedText =
              responseData['candidates'][0]['content']['parts'][0]['text']
                  .trim();
          debugPrint('Extracted text from Gemini: $extractedText');

          // If the response is "NOT_FOUND", return null
          if (extractedText.toUpperCase().contains('NOT_FOUND')) {
            return null;
          }

          // Try to extract the 12-digit number from the response
          final RegExp numberRegex = RegExp(r'\d+');
          final Iterable<Match> matches = numberRegex.allMatches(extractedText);
          final List<String> foundNumbers = matches
              .map((match) => match.group(0)!)
              .toList();

          debugPrint('Found numbers: $foundNumbers');

          if (foundNumbers.isNotEmpty) {
            // First check if we got a single 12-digit number directly
            for (String number in foundNumbers) {
              if (number.length == 12) {
                debugPrint('Found complete 12-digit number: $number');
                return number;
              }
            }

            // If we have exactly 2 numbers, combine them (top + bottom)
            if (foundNumbers.length == 2) {
              String topNumber = foundNumbers[0];
              String bottomNumber = foundNumbers[1];

              // Pad bottom number with leading zeros if needed to make it 6 digits
              if (bottomNumber.length < 6) {
                bottomNumber = bottomNumber.padLeft(6, '0');
              }

              String combined = topNumber + bottomNumber;
              debugPrint(
                'Combined top ($topNumber) + bottom ($bottomNumber) = $combined',
              );

              // Validate that we got 12 digits
              if (combined.length == 12) {
                return combined;
              } else if (combined.length > 12) {
                // If combined is longer than 12, try to extract 12 consecutive digits
                final RegExp twelveDigitRegex = RegExp(r'\d{12}');
                final Match? match = twelveDigitRegex.firstMatch(combined);
                if (match != null) {
                  return match.group(0);
                }
              }
            }

            // If we have more than 2 numbers, try to find the best combination
            if (foundNumbers.length > 2) {
              // Look for pairs that could form 12 digits
              for (int i = 0; i < foundNumbers.length - 1; i++) {
                for (int j = i + 1; j < foundNumbers.length; j++) {
                  String combined = foundNumbers[i] + foundNumbers[j];
                  if (combined.length == 12) {
                    debugPrint(
                      'Found 12-digit combination: ${foundNumbers[i]} + ${foundNumbers[j]} = $combined',
                    );
                    return combined;
                  }
                }
              }
            }

            // Last resort: try to extract any 12-digit sequence from concatenated numbers
            String allNumbers = foundNumbers.join('');
            final RegExp twelveDigitRegex = RegExp(r'\d{12}');
            final Match? match = twelveDigitRegex.firstMatch(allNumbers);
            if (match != null) {
              debugPrint('Extracted 12-digit sequence: ${match.group(0)}');
              return match.group(0);
            }

            debugPrint(
              'Could not form a valid 12-digit number from found numbers',
            );
            return null;
          } else {
            debugPrint('No numbers found in response');
            return null;
          }
        } else {
          debugPrint('Unexpected response structure from Gemini');
          return null;
        }
      } else {
        debugPrint(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );

        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            debugPrint('Gemini API error details: ${errorData['error']}');
          }
        } catch (e) {
          debugPrint('Could not parse error response');
        }

        return null;
      }
    } catch (e) {
      debugPrint('Error analyzing image with Gemini: $e');
      return null;
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

      if (tagId != null && tagId.isNotEmpty) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully detected ear tag: $tagId'),
            backgroundColor: AppColors.accentGreen,
          ),
        );

        // Wait a moment before navigating
        await Future.delayed(const Duration(seconds: 1));

        // Navigate to the next screen with the extracted tag ID
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AfterScanPage(tagId: tagId)),
          );
        }
      } else {
        // Show error message with more helpful text
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not detect ear tag numbers clearly. Please ensure the tag is well-lit and try again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing or processing image: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
