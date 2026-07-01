import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _loadingController;
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _pulseController; 
  late AnimationController _ringController; 

  late Animation<double> _bounceAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -18.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _bounceController.repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowController.repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _ringAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_ringController);

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _loadingController.forward();

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _loadingController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final robotSize =
        (screenWidth < 600 ? screenWidth * 0.55 : screenWidth * 0.28).clamp(
          180.0,
          320.0,
        );
    final titleSize = screenWidth < 400
        ? 48.0
        : screenWidth < 700
        ? 56.0
        : 72.0;
    final subtitleSize = screenWidth < 400 ? 11.0 : 13.0;
    final loadingBarWidth = screenWidth < 600 ? screenWidth * 0.8 : 320.0;
    final spacing = screenHeight < 700 ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFF080D2B),
      body: Stack(
        children: [
          const _BackgroundParticles(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth > 600 ? 520 : screenWidth * 0.92,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _bounceAnimation.value),
                              child: child,
                            );
                          },
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _glowAnimation,
                              _pulseAnimation,
                              _ringAnimation,
                            ]),
                            builder: (context, child) {
                              return SizedBox(
                                width: robotSize,
                                height: robotSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: _ringAnimation.value,
                                      child: CustomPaint(
                                        size: Size(
                                          robotSize * 0.95,
                                          robotSize * 0.95,
                                        ),
                                        painter: _EnergyRingPainter(
                                          _glowAnimation.value,
                                        ),
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        width: robotSize * 0.85,
                                        height: robotSize * 0.85,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00D4FF)
                                                  .withOpacity(
                                                    0.25 * _glowAnimation.value,
                                                  ),
                                              blurRadius: 100,
                                              spreadRadius: 40,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF0066FF)
                                                  .withOpacity(
                                                    0.18 * _glowAnimation.value,
                                                  ),
                                              blurRadius: 150,
                                              spreadRadius: 60,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'logo/robot_IA.png',
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const _RobotFallback();
                                              },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: spacing),

                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Text(
                              'LUMI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: screenWidth < 400 ? 3 : 4,
                                shadows: [
                                  Shadow(
                                    color: const Color(
                                      0xFF00D4FF,
                                    ).withOpacity(_glowAnimation.value),
                                    blurRadius: 20,
                                  ),
                                  Shadow(
                                    color: const Color(
                                      0xFF00D4FF,
                                    ).withOpacity(_glowAnimation.value * 0.6),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        SizedBox(height: screenHeight < 700 ? 10 : 16),

                        Text(
                          'BIENVENIDO AL FUTURO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: const Color(0xFFB0C4DE),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'LA PROCASTINACIÓN TERMINA AQUÍ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: const Color(0xFFB0C4DE),
                            letterSpacing: 3,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: screenHeight < 700 ? 24 : 36),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 600 ? 16 : 40,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'LOADING...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00D4FF),
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedBuilder(
                                animation: _loadingAnimation,
                                builder: (context, child) {
                                  return SizedBox(
                                    width: loadingBarWidth,
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 4,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A2550),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: _loadingAnimation.value,
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF0066FF),
                                                  Color(0xFF00D4FF),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF00D4FF,
                                                  ).withOpacity(0.8),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyRingPainter extends CustomPainter {
  final double glowValue;
  _EnergyRingPainter(this.glowValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF00D4FF).withOpacity(0.0),
          const Color(0xFF00D4FF).withOpacity(0.7 * glowValue),
          const Color(0xFF0066FF).withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) =>
      oldDelegate.glowValue != glowValue;
}

class _BackgroundParticles extends StatelessWidget {
  const _BackgroundParticles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CircuitPainter(), size: Size.infinite);
  }
}

class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final lines = [
      [0.1, 0.15, 0.35, 0.15],
      [0.35, 0.15, 0.35, 0.25],
      [0.35, 0.25, 0.5, 0.25],
      [0.7, 0.1, 0.7, 0.3],
      [0.7, 0.3, 0.85, 0.3],
      [0.05, 0.55, 0.2, 0.55],
      [0.2, 0.55, 0.2, 0.65],
      [0.8, 0.6, 0.95, 0.6],
      [0.8, 0.45, 0.8, 0.6],
    ];

    for (final line in lines) {
      canvas.drawLine(
        Offset(size.width * line[0], size.height * line[1]),
        Offset(size.width * line[2], size.height * line[3]),
        paint,
      );
    }

    final dots = [
      [0.35, 0.15],
      [0.35, 0.25],
      [0.7, 0.3],
      [0.2, 0.55],
      [0.8, 0.6],
    ];

    for (final dot in dots) {
      canvas.drawCircle(
        Offset(size.width * dot[0], size.height * dot[1]),
        2.5,
        dotPaint,
      );
    }

    final random = Random(42);
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      final opacity = random.nextDouble() * 0.5 + 0.1;
      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RobotFallback extends StatelessWidget {
  const _RobotFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.3),
            const Color(0xFF080D2B).withOpacity(0.0),
          ],
        ),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        size: 120,
        color: Color(0xFF00D4FF),
      ),
    );
  }
}