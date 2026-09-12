import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/olvidar_contraseña.dart';
import 'register_screen.dart';
import '/screens/dashboard_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';

void main() {
  runApp(const IniciarSesion());
}

class IniciarSesion extends StatelessWidget {
  const IniciarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iniciar Sesión',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorMessage = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor, llena todos los campos.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un email válido.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('No se pudo recuperar la sesión del usuario.');
      }

      final String userId = user.id;

      try {
        await ApiService.login(userId: userId);
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido a Lumi!', style: GoogleFonts.orbitron(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF102CE4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      final perfil = await ApiService.getProfile(userId);
      if (!mounted) return;

      final bool esAdmin = (perfil?['es_admin'] ?? false) == true;
      final nombre = (perfil?['nombre'] ?? '').toString().trim();
      final objetivo = (perfil?['perfil_estudio']?['objetivo'] ?? '').toString().trim();
      final horarios = perfil?['horarios'] as List?;
      final perfilListo = nombre.isNotEmpty && (objetivo.isNotEmpty || (horarios != null && horarios.isNotEmpty));

      if (!context.mounted) return;
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
          builder: (context) => perfilListo
              ? DashboardScreen(userId: userId)
              : ProfileScreen(userId: userId),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1D8A), Color(0xFF16003A), Color(0xFF080010)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.anchoMaximoContenido(context)),
              child: Builder(
                builder: (context) {
                  final isDesktop = Responsive.esEscritorio(context);
                  
                  if (isDesktop) {
                    return SizedBox(
                      height: Responsive.altoPantalla(context) * 0.85,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context)),
                              child: SingleChildScrollView(
                                child: _buildFormContent(context),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context)),
                              child: Center(
                                child: _buildHeroLogo(
                                  width: Responsive.anchoPantalla(context) * 0.4,
                                  height: Responsive.altoPantalla(context) * 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.paddingHorizontalRecomendado(context), 
                      vertical: Responsive.espacio(context) * 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: _buildHeroLogo(
                            width: Responsive.anchoPantalla(context) * 0.45,
                            height: Responsive.altoPantalla(context) * 0.18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormContent(context),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Componente visual reutilizable para el logotipo con efecto glow sutil
  Widget _buildHeroLogo({required double width, required double height}) {
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
      ),
    );
  }

  // Contenido unificado del formulario para evitar duplicación de código
  Widget _buildFormContent(BuildContext context) {
    final isDesktop = Responsive.esEscritorio(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDesktop) ...[
          Text(
            'Iniciar Sesión',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido de nuevo a tu espacio',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFB0AEC4),
              fontSize: 14,
            ),
          ),
          SizedBox(height: Responsive.espacio(context) * 3),
        ] else ...[
          Center(
            child: Text(
              'Iniciar Sesión',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Bienvenido de nuevo a tu espacio',
              style: GoogleFonts.orbitron(
                color: const Color(0xFFB0AEC4),
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(height: Responsive.espacio(context) * 3),
        ],

        Text(
          'Email',
          style: GoogleFonts.orbitron(
            color: const Color(0xFFE2E0EE),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'tucorreo@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFFB0AEC4), size: 20),
        ),
        SizedBox(height: Responsive.espacio(context) * 2),

        Text(
          'Contraseña',
          style: GoogleFonts.orbitron(
            color: const Color(0xFFE2E0EE),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: '••••••••••••',
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFB0AEC4), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFFB0AEC4),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorContainer(_errorMessage!),
        ],

        SizedBox(height: Responsive.espacio(context) * 3.5),

        // Botón principal con degradado y sombra neón
        SizedBox(
          width: isDesktop ? Responsive.anchoBoton(context) : double.infinity,
          height: Responsive.altoBoton(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: Responsive.tamanioTexto(context),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ),

        SizedBox(height: Responsive.espacio(context) * 2.5),

        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OlvidarContrasena()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB0AEC4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: GoogleFonts.orbitron(
                fontSize: Responsive.tamanioTexto(context) - 1,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFB0AEC4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes una cuenta? ',
              style: GoogleFonts.orbitron(
                color: Colors.grey[400], 
                fontSize: Responsive.tamanioTexto(context) - 2,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: Text(
                'Regístrate',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF1E142C).withValues(alpha: 0.6),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFF4A2A68).withValues(alpha: 0.5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF716DC), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1B2A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCC3355).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCC3355).withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D79), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.orbitron(color: const Color(0xFFFF99B3), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}