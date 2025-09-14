import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

class UrgentAlertScreen extends StatefulWidget {
  const UrgentAlertScreen({super.key});

  @override
  State<UrgentAlertScreen> createState() => _UrgentAlertScreenState();
}

class _UrgentAlertScreenState extends State<UrgentAlertScreen>
    with TickerProviderStateMixin {
  Timer? _vibrationTimer;
  bool _canVibrate = false;
  late AnimationController _pulseController;
  late AnimationController _bellController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bellAnimation;
  bool _isLongPressing = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bellController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bellAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.elasticInOut),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _bellController.repeat(reverse: true);

    // Check vibration availability then start
    _initVibration();
  }

  Future<void> _initVibration() async {
    try {
      _canVibrate = await Vibration.hasVibrator();
      if (_canVibrate) {
        // Pattern: vibrate 600ms, pause 200ms, vibrate 400ms, pause 200ms (repeats)
        _startVibrationPattern();
      } else {
        // fallback to haptics
        _startFallbackHaptics();
      }
    } catch (_) {
      _startFallbackHaptics();
    }
  }

  void _startVibrationPattern() {
    if (_canVibrate) {
      // Kick off a long vibration (most Android devices allow up to 10s per call)
      Vibration.vibrate(duration: 10000, amplitude: 255);
      // Refresh before it ends to appear continuous
      _vibrationTimer = Timer.periodic(const Duration(seconds: 9), (timer) {
        if (_canVibrate) {
          Vibration.vibrate(duration: 10000, amplitude: 255);
        }
      });
    } else {
      _startFallbackHaptics();
    }
  }

  void _startFallbackHaptics() {
    // Faster cadence to simulate continuous alert when real vibration not available
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 250), (
      timer,
    ) {
      HapticFeedback.mediumImpact();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    if (_canVibrate) {
      Vibration.cancel();
    }
  }
  void _handleLongPress() {
    if (!_isLongPressing) {
      _isLongPressing = true;
      _holdProgress = 0.0;
      if (_canVibrate) {  
        Vibration.vibrate(duration: 120, amplitude: 255);
      } else {
        HapticFeedback.heavyImpact();
      }

      _holdTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        setState(() {
          _holdProgress += 0.01;
          if (_holdProgress >= 1.0) {
            _holdProgress = 1.0;
            timer.cancel();
            if (_isLongPressing && mounted) {
              _dismissAlert();
            }
          }
        });
      });
    }
  }

  void _handleLongPressEnd() {
    _isLongPressing = false;
    _holdTimer?.cancel();
    setState(() {
      _holdProgress = 0.0;
    });
  }

  void _dismissAlert() {
    _stopVibration();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stopVibration();
    _pulseController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDC2626), // Red-600
              Color(0xFFB91C1C), // Red-700
              Color(0xFF991B1B), // Red-800
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Alert Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'URGENT ALERT',
                  style: TextStyle(
                    fontSize: size.width > 600 ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Animated Bell Icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _bellAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _bellAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              size: size.width > 600 ? 80 : 64,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Alert Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    Text(
                      'MISSED A DOSAGE AT 12 AM',
                      style: TextStyle(
                        fontSize: size.width > 600 ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please provide the animal with proper doses on time.',
                      style: TextStyle(
                        fontSize: size.width > 600 ? 18 : 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Enlarged circular dismiss control
              GestureDetector(
                onLongPress: _handleLongPress,
                onLongPressEnd: (_) => _handleLongPressEnd(),
                child: SizedBox(
                  width: size.width * 0.65,
                  height: size.width * 0.65,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer progress ring
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: _isLongPressing ? _holdProgress : 0,
                        ),
                        duration: const Duration(milliseconds: 80),
                        builder: (_, value, __) => CircularProgressIndicator(
                          value: value,
                          strokeWidth: 24,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      // Inner content
                      Container(
                        width: size.width * 0.65 - 90,
                        height: size.width * 0.65 - 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.white.withOpacity(0.95),
                              size: size.width > 600 ? 72 : 56,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isLongPressing
                                  ? 'Keep Holding...'
                                  : 'Hold to Dismiss',
                              style: TextStyle(
                                fontSize: size.width > 600 ? 24 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.95),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            AnimatedOpacity(
                              opacity: _isLongPressing ? 1 : 0.7,
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                '2s secure hold',
                                style: TextStyle(
                                  fontSize: size.width > 600 ? 16 : 14,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Press & hold inside the circle to acknowledge',
                style: TextStyle(
                  fontSize: size.width > 600 ? 16 : 13,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),

              const Spacer(),

              // Time indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  DateTime.now().toString().substring(11, 19),
                  style: TextStyle(
                    fontSize: size.width > 600 ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
