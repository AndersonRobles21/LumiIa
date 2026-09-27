import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/screens/olvidar_contraseña.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '/screens/dashboard_screen.dart';
import 'app_language.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AppLanguageListenerMixin<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorMessage = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = tr(
          'Por favor, llena todos los campos.',
          'Please fill in all fields.',
        );
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = tr(
          'Ingresa un correo electrónico válido.',
          'Enter a valid email address.',
        );
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          tr(
            'No se pudo recuperar la sesión del usuario.',
            'Could not retrieve the user session.',
          ),
        );
      }

      try {
        await ApiService.login(userId: user.id);
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              '✓ ¡Bienvenido de nuevo a LUMI!',
              '✓ Welcome back to LUMI!',
            ),
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _openAuthenticatedArea(user);
    } on AuthException catch (error) {
      if (!mounted) return;

      final message = error.message.toLowerCase();

      setState(() {
        _isLoading = false;
        _errorMessage =
            message.contains('invalid login credentials') ||
                message.contains('invalid grant') ||
                message.contains('unauthorized')
            ? tr(
                'Correo o contraseña incorrectos. Verifica tus datos.',
                'Incorrect email or password. Please check your credentials.',
              )
            : tr(
                'No se pudo iniciar sesión. Inténtalo de nuevo.',
                'Could not sign in. Please try again.',
              );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '');
      });
    }
  }

  Future<void> _openAuthenticatedArea(User user) async {
    final userId = user.id;
    final perfil = await ApiService.getProfile(userId);

    if (!mounted) return;

    final esAdmin = (perfil?['es_admin'] ?? false) == true;
    final nombre = (perfil?['nombre'] ?? '').toString().trim();
    final objetivo = (perfil?['perfil_estudio']?['objetivo'] ?? '')
        .toString()
        .trim();
    final horarios = perfil?['horarios'] as List?;

    final perfilListo =
        nombre.isNotEmpty &&
        (objetivo.isNotEmpty || (horarios != null && horarios.isNotEmpty));

    if (esAdmin) {
      Navigator.pushReplacementNamed(
        context,
        '/admin-panel',
        arguments: {'userId': userId},
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => perfilListo
            ? DashboardScreen(userId: userId)
            : ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.esEscritorio(context);

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color(0xFF0F1D8A),
                    Color(0xFF16003A),
                    Color(0xFF080010),
                  ]
                : const [
                    Color(0xFFF8F5FC),
                    Color(0xFFF0E4F8),
                    Color(0xFFF8F5FC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.anchoMaximoContenido(context),
              ),
              child: isDesktop
                  ? _buildDesktopLayout(context)
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.paddingHorizontalRecomendado(
                          context,
                        ),
                        vertical: Responsive.espacio(context) * 2,
                      ),
                      child: Column(
                        children: [
                          _buildHeroLogo(
                            width: Responsive.anchoPantalla(context) * 0.45,
                            height: Responsive.altoPantalla(context) * 0.18,
                          ),
                          const SizedBox(height: 16),
                          _buildFormContent(context),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SizedBox(
      height: Responsive.altoPantalla(context) * 0.85,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: LumiAppTheme.surface(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: LumiAppTheme.outline(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildDesktopWelcomePanel(),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      child: _buildFormContent(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroLogo({
    required double width,
    required double height,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF716DC).withValues(alpha: 0.15),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Image.asset(
        'logo/Lumi.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.auto_awesome,
          color: Color(0xFFF716DC),
          size: 70,
        ),
      ),
    );
  }

  Widget _buildDesktopWelcomePanel() {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF211638),
            Color(0xFF151024),
          ],
        ),
      ),
      child: Center(
        child: _buildHeroLogo(width: 190, height: 190),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final isDesktop = Responsive.esEscritorio(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            tr('Iniciar sesión', 'Sign in'),
            style: GoogleFonts.orbitron(
              color: LumiAppTheme.primaryText(context),
              fontSize: isDesktop ? 34 : 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            tr(
              'Bienvenido de nuevo a tu espacio',
              'Welcome back to your space',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: LumiAppTheme.secondaryText(context),
              fontSize: isDesktop ? 14 : 13,
            ),
          ),
        ),
        SizedBox(height: Responsive.espacio(context) * 3),

        _label(tr('Correo electrónico', 'Email')),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: tr('tucorreo@gmail.com', 'your@email.com'),
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(
            Icons.mail_outline_rounded,
            color: Color(0xFF7C3AED),
            size: 20,
          ),
        ),

        SizedBox(height: Responsive.espacio(context) * 2),

        _label(tr('Contraseña', 'Password')),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: '••••••••••••',
          obscureText: _obscurePassword,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF7C3AED),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFFF716DC),
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorContainer(_errorMessage!),
        ],

        SizedBox(height: Responsive.espacio(context) * 3),

        SizedBox(
          width: double.infinity,
          height: Responsive.altoBoton(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF716DC),
                  Color(0xFFA41CF9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF716DC).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      tr('Iniciar sesión', 'Sign in'),
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: Responsive.tamanioTexto(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        SizedBox(height: Responsive.espacio(context) * 1.5),

        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OlvidarContrasena(),
                ),
              );
            },
            child: Text(
              tr('¿Olvidaste tu contraseña?', 'Forgot your password?'),
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.secondaryText(context),
                fontSize: Responsive.tamanioTexto(context) - 1,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr('¿No tienes una cuenta? ', "Don't have an account? "),
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.secondaryText(context),
                fontSize: Responsive.tamanioTexto(context) - 2,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: Text(
                tr('Regístrate', 'Sign up'),
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFF716DC),
                  fontSize: Responsive.tamanioTexto(context) - 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: LumiAppTheme.secondaryText(context),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.orbitron(
        color: LumiAppTheme.primaryText(context),
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.orbitron(
          color: LumiAppTheme.secondaryText(context),
          fontSize: 12,
        ),
        filled: true,
        fillColor: LumiAppTheme.surface(context),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: LumiAppTheme.outline(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFF716DC),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.orbitron(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}