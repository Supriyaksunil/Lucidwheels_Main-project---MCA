import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _carProgress;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _carLift;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _carProgress = Tween<double>(begin: -0.24, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.48, curve: Curves.easeOut),
    );

    _carLift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(_navigateToHome);
  }

  Future<void> _navigateToHome() async {
    if (!mounted) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initializationFuture;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color.fromARGB(255, 3, 4, 104);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackY = constraints.maxHeight * 0.62;
            const carWidth = 156.0;
            const carHeight = 92.0;
            final travelWidth = constraints.maxWidth + (carWidth * 2);

            return Stack(
              children: [
                Positioned(
                  top: constraints.maxHeight * 0.19,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: const Column(
                      children: [
                        Text(
                          'LucidWheels',
                          style: TextStyle(
                            color: brandBlue,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Smarter driving starts here',
                          style: TextStyle(
                            color: Color(0xFF5362A8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  top: trackY,
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: brandBlue.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(
                          10,
                          (index) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 3,
                              decoration: BoxDecoration(
                                color: brandBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final left = (_carProgress.value * travelWidth) - carWidth;
                    return Positioned(
                      left: left,
                      top: trackY - carHeight - 6 + _carLift.value,
                      child: child!,
                    );
                  },
                  child: const SizedBox(
                    width: carWidth,
                    height: carHeight,
                    child: CustomPaint(
                      painter: _SideCarPainter(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SideCarPainter extends CustomPainter {
  const _SideCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bodyColor = Paint()..color = const Color.fromARGB(255, 17, 3, 148);
    final bodyOutline = Paint()
      ..color = const Color.fromARGB(255, 51, 3, 161)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final windowPaint = Paint()..color = const Color(0xFFA9DEF7);
    final trimPaint = Paint()
      ..color = const Color(0xFF215A82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final handlePaint = Paint()..color = const Color(0xFF215A82);
    final wheelOuter = Paint()..color = const Color.fromARGB(255, 42, 37, 67);
    final wheelRim = Paint()..color = const Color(0xFFE7EDF4);
    final wheelHub = Paint()..color = const Color(0xFFA7B7C9);
    final lampPaint = Paint()..color = const Color(0xFFBFE9FF);
    final tailLampPaint = Paint()..color = const Color(0xFFD54A5C);
    final shadowPaint = Paint()
      ..color = const Color(0x16030468)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.84),
        width: w * 0.76,
        height: h * 0.10,
      ),
      shadowPaint,
    );

    final body = Path()
      ..moveTo(w * 0.08, h * 0.68)
      ..quadraticBezierTo(w * 0.08, h * 0.59, w * 0.15, h * 0.56)
      ..quadraticBezierTo(w * 0.28, h * 0.34, w * 0.43, h * 0.24)
      ..quadraticBezierTo(w * 0.52, h * 0.18, w * 0.61, h * 0.24)
      ..quadraticBezierTo(w * 0.76, h * 0.32, w * 0.89, h * 0.56)
      ..quadraticBezierTo(w * 0.96, h * 0.59, w * 0.96, h * 0.68)
      ..quadraticBezierTo(w * 0.95, h * 0.73, w * 0.88, h * 0.73)
      ..lineTo(w * 0.81, h * 0.73)
      ..quadraticBezierTo(w * 0.79, h * 0.62, w * 0.71, h * 0.61)
      ..lineTo(w * 0.33, h * 0.61)
      ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.23, h * 0.73)
      ..lineTo(w * 0.16, h * 0.73)
      ..quadraticBezierTo(w * 0.09, h * 0.73, w * 0.08, h * 0.68)
      ..close();

    canvas.drawShadow(body, const Color(0x22000000), 10, false);
    canvas.drawPath(body, bodyColor);
    canvas.drawPath(body, bodyOutline);

    final rearWindow = Path()
      ..moveTo(w * 0.30, h * 0.56)
      ..quadraticBezierTo(w * 0.34, h * 0.39, w * 0.46, h * 0.32)
      ..lineTo(w * 0.53, h * 0.32)
      ..lineTo(w * 0.53, h * 0.56)
      ..close();

    final frontWindow = Path()
      ..moveTo(w * 0.56, h * 0.32)
      ..lineTo(w * 0.63, h * 0.32)
      ..quadraticBezierTo(w * 0.75, h * 0.39, w * 0.79, h * 0.56)
      ..lineTo(w * 0.56, h * 0.56)
      ..close();

    canvas.drawPath(rearWindow, windowPaint);
    canvas.drawPath(frontWindow, windowPaint);

    canvas.drawLine(
      Offset(w * 0.545, h * 0.32),
      Offset(w * 0.545, h * 0.61),
      trimPaint,
    );
    canvas.drawLine(
      Offset(w * 0.18, h * 0.57),
      Offset(w * 0.87, h * 0.57),
      trimPaint,
    );
    canvas.drawLine(
      Offset(w * 0.24, h * 0.55),
      Offset(w * 0.32, h * 0.42),
      trimPaint,
    );
    canvas.drawLine(
      Offset(w * 0.80, h * 0.55),
      Offset(w * 0.72, h * 0.42),
      trimPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.39, h * 0.49, w * 0.06, h * 0.02),
        const Radius.circular(3),
      ),
      handlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.60, h * 0.49, w * 0.06, h * 0.02),
        const Radius.circular(3),
      ),
      handlePaint,
    );

    final rearWheelCenter = Offset(w * 0.29, h * 0.73);
    final frontWheelCenter = Offset(w * 0.75, h * 0.73);
    final wheelR = h * 0.15;

    canvas.drawCircle(rearWheelCenter, wheelR, wheelOuter);
    canvas.drawCircle(frontWheelCenter, wheelR, wheelOuter);
    canvas.drawCircle(rearWheelCenter, wheelR * 0.65, wheelRim);
    canvas.drawCircle(frontWheelCenter, wheelR * 0.65, wheelRim);
    canvas.drawCircle(rearWheelCenter, wheelR * 0.18, wheelHub);
    canvas.drawCircle(frontWheelCenter, wheelR * 0.18, wheelHub);

    final spoke = Paint()
      ..color = const Color(0xFF7B8897)
      ..strokeWidth = 1.6;
    for (int i = 0; i < 6; i++) {
      final angle = i * 60.0 * (math.pi / 180.0);
      final dx = (wheelR * 0.50) * math.cos(angle);
      final dy = (wheelR * 0.50) * math.sin(angle);
      canvas.drawLine(
        rearWheelCenter,
        Offset(rearWheelCenter.dx + dx, rearWheelCenter.dy + dy),
        spoke,
      );
      canvas.drawLine(
        frontWheelCenter,
        Offset(frontWheelCenter.dx + dx, frontWheelCenter.dy + dy),
        spoke,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.915, h * 0.51, w * 0.03, h * 0.03),
        const Radius.circular(4),
      ),
      lampPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.095, h * 0.51, w * 0.03, h * 0.03),
        const Radius.circular(4),
      ),
      tailLampPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SideCarPainter oldDelegate) => false;
}
