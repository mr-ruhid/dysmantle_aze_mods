//Do not make any changes to this page!

import 'dart:math';
import 'package:flutter/material.dart';
import 'home_page.dart'; // Ana səhifəni import edirik

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  late Animation<double> _bgScaleAnimation;

  late AnimationController _snowAnimationController;

  late AnimationController _logoFadeController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToHome(); // Yükləmə bitdikdən sonra keçid üçün funksiyanı çağırırıq
  }

  // 5 saniyəlik gecikmədən sonra Ana Səhifəyə yönləndirmə funksiyası
  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      // pushReplacement istifadə edirik ki, istifadəçi geri qayıtmaq istəyəndə yenidən loading-ə düşməsin
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const InstallerHomePage()),
      );
    }
  }

  void _initializeAnimations() {
    // 1. Arxa fonun yavaş-yavaş böyüyüb kiçilməsi (Zoom effekti)
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _bgScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _bgAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 2. Qar animasiyası
    _snowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 3. Loqonun yavaş-yavaş görünməsi (Fade In) və Yuxarıdan düşməsi
    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 saniyəlik cəzbedici düşüş
    )..forward();

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoFadeController,
        curve: Curves.easeIn,
      ),
    );

    // Loqonun yuxarıdan aşağı düşüb hoppanması (Bounce) effekti
    _logoSlideAnimation = Tween<Offset>(begin: const Offset(0, -3.0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _logoFadeController,
        curve: Curves.bounceOut, // Fizikadan tanış olan sıçrama effekti
      ),
    );
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _snowAnimationController.dispose();
    _logoFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekranın ölçüsünü alırıq ki, elastiklik təmin edək
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black, // Şəkil yüklənənə qədər arxa fon
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Hərəkət edən Arxa Fon Şəkli
          AnimatedBuilder(
            animation: _bgScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bgScaleAnimation.value,
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/background.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF0F0B21));
              },
            ),
          ),

          // Şəklin üzərinə yüngül tündləşdirmə
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // 2. Qar Yağma Effekti
          AnimatedBuilder(
            animation: _snowAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: SnowPainter(
                  animationValue: _snowAnimationController.value,
                ),
              );
            },
          ),

          // 3. Loqo və Yükləmə İndikatorunun Elastik Yerləşimi
          Column(
            children: [
              const Spacer(flex: 2), // Yuxarıdan məsafə

              SlideTransition(
                position: _logoSlideAnimation,
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: screenWidth < 900 ? 250 : 300, // Ekrana görə loqonu bir az kiçildir
                    height: screenWidth < 900 ? 250 : 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'LOGONUZ BURA GƏLƏCƏK',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      );
                    },
                  ),
                ),
              ),

              const Spacer(flex: 6), // Loqo ilə Loading Bar arasındakı boşluq

              // 4. Loading Bar və Mətn (Elastik genişliklə)
              Container(
                width: screenWidth * 0.6, // Ekran genişliyinin 60%-i qədər yer tutacaq
                constraints: const BoxConstraints(maxWidth: 400), // Maksimum genişliyi 400-ü keçməyəcək
                child: Column(
                  children: [
                    const Text(
                      'Mod Paketi Hazırlanır...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      backgroundColor: const Color(0xFF1A153A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE412A5)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1), // Ən aşağıdan boşluq
            ],
          ),
        ],
      ),
    );
  }
}

class SnowPainter extends CustomPainter {
  final double animationValue;
  final Random random = Random(42);
  final int numberOfFlakes = 150;

  SnowPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numberOfFlakes; i++) {
      final double x = random.nextDouble() * size.width;
      final double startY = random.nextDouble() * size.height;
      final double speedMultiplier = 0.5 + random.nextDouble() * 1.5;

      double currentY = startY + (animationValue * size.height * speedMultiplier);
      currentY = currentY % size.height;

      final double xOffset = sin(animationValue * pi * 4 + i) * 15;
      final double radius = 1.0 + random.nextDouble() * 2.5;

      canvas.drawCircle(Offset(x + xOffset, currentY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SnowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
