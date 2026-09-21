import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import '../utils/responsive.dart';

const Color kPurplePrimary = Color(0xFFB026FF);
const Color kPurpleSecondary = Color(0xFF7B2FF7);
const Color kPurpleAccent = Color(0xFFD87BFF);
const Color kBackgroundDark = Color(0xFF03010A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _loadingController;
  late final AnimationController _fadeController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _loadingAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
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

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _loadingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ),
    );

    _loadingController.forward();

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _restoreSession();
      }
    });
  }

  Future<void> _restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final profile = await ApiService.getProfile(session.user.id);
    if (!mounted) return;

    final isAdmin = (profile?['es_admin'] ?? false) == true;
    if (isAdmin) {
      Navigator.of(context).pushReplacementNamed(
        '/admin-panel',
        arguments: {'userId': session.user.id},
      );
      return;
    }

    final name = (profile?['nombre'] ?? '').toString().trim();
    final objective = (profile?['perfil_estudio']?['objetivo'] ?? '').toString().trim();
    final schedules = profile?['horarios'] as List?;
    final profileReady = name.isNotEmpty &&
        (objective.isNotEmpty || (schedules != null && schedules.isNotEmpty));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => profileReady
            ? DashboardScreen(userId: session.user.id)
            : ProfileScreen(userId: session.user.id),
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El Splash es una excepción visual intencional: conserva el fondo negro
    // diseñado para sus imágenes, independientemente del tema seleccionado.
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final robotSize = math.min(width * 0.62, height * 0.34);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'logo/Fondo_splash.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context)),
                    child: Column(
                      children: [
                        SizedBox(height: height * 0.10),

                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _bounceAnimation.value),
                              child: child,
                            );
                          },
                          child: SizedBox(
                            width: robotSize,
                            height: robotSize,
                            child: Image.asset(
                              'logo/lumisplash.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: height * 0.16),

                        Text(
                          'LUMI',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),

                        const SizedBox(height: 6),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: 'LA ',
                                style: const TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'PROCRASTINACIÓN ',
                                style: TextStyle(color: kPurpleAccent),
                              ),
                              TextSpan(
                                text: 'TERMINA ',
                                style: const TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'AQUÍ',
                                style: TextStyle(color: kPurpleAccent),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: height * 0.045),

                        const _InfoCard(),

                        const Spacer(),

                        Padding(
                          padding: EdgeInsets.only(bottom: height * 0.08),
                          child: _LoadingBar(animation: _loadingAnimation),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.paddingHorizontalRecomendado(context) / 2,
        vertical: Responsive.espacio(context),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF140D24).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: kPurpleSecondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            color: Colors.white70,
            size: 32,
          ),
          SizedBox(width: Responsive.espacio(context) * 2),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: 'Tu compañero inteligente\npara aprender '),
                  TextSpan(
                    text: 'sin límites',
                    style: TextStyle(
                      color: kPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'CARGANDO...',
          style: TextStyle(
            fontSize: 10,
            color: kPurpleAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF120826),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: animation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          kPurpleSecondary,
                          kPurplePrimary,
                          kPurpleAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}