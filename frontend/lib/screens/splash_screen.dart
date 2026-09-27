import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import '../utils/responsive.dart';
import 'app_language.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

const Color kPurplePrimary = Color(0xFFB026FF);
const Color kPurpleSecondary = Color(0xFF7B2FF7);
const Color kPurpleAccent = Color(0xFFD87BFF);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, AppLanguageListenerMixin<SplashScreen> {
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
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
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
    final objective =
        (profile?['perfil_estudio']?['objetivo'] ?? '').toString().trim();
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

  Widget _logo(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'logo/lumisplash.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _slogan() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: tr('LA ', '')),
          TextSpan(
            text: tr(
              'PROCRASTINACIÓN ',
              'PROCRASTINATION ',
            ),
            style: const TextStyle(color: kPurpleAccent),
          ),
          TextSpan(text: tr('TERMINA ', 'ENDS ')),
          TextSpan(
            text: tr('AQUÍ', 'HERE'),
            style: const TextStyle(color: kPurpleAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final robotSize = math.min(width * 0.62, height * 0.34);

          if (Responsive.esEscritorio(context)) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF140D24).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: kPurpleSecondary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _bounceAnimation.value),
                              child: child,
                            );
                          },
                          child: _logo(190),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'LUMI',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _slogan(),
                        const SizedBox(height: 24),
                        const _InfoCard(),
                        const SizedBox(height: 28),
                        _LoadingBar(animation: _loadingAnimation),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'logo/Fondo_splash.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          Responsive.paddingHorizontalRecomendado(context),
                    ),
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
                          child: _logo(robotSize),
                        ),
                        SizedBox(height: height * 0.16),
                        const Text(
                          'LUMI',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _slogan(),
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
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.paddingHorizontalRecomendado(context) / 2,
            vertical: Responsive.espacio(context),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF140D24).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: kPurpleSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school,
                color: Colors.white70,
                size: 32,
              ),
              SizedBox(width: Responsive.espacio(context) * 2),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: appLanguageText(
                          'Tu compañero inteligente\npara aprender ',
                          'Your smart learning\ncompanion ',
                        ),
                      ),
                      TextSpan(
                        text: appLanguageText(
                          'sin límites',
                          'without limits',
                        ),
                        style: const TextStyle(
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
      },
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingBar({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) {
        return Column(
          children: [
            Text(
              appLanguageText('CARGANDO...', 'LOADING...'),
              style: const TextStyle(
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
      },
    );
  }
}