import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/screens/olvidar_contraseña.dart';
import 'register_screen.dart';
import '/screens/dashboard_screen.dart';
import 'admin_panel_screen.dart';
import '../services/api_service.dart';
import 'biometric_service.dart';
import 'app_language.dart';

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

  bool _verificandoBiometria = false;

  @override
  void initState() {
    super.initState();
    // Apenas se abre la pantalla, intentamos entrar con huella si el
    // usuario la activó en Configuración y ya tiene sesión de Supabase.
    _tryBiometricLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _tryBiometricLogin({bool manual = false}) async {
    final sesionExistente = Supabase.instance.client.auth.currentSession;

    if (!BiometricService.isEnabled || sesionExistente == null) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'No hay una sesión guardada en este dispositivo. Inicia sesión con tu contraseña una vez y luego la huella quedará activa.',
                'There\'s no saved session on this device. Sign in with your password once and then fingerprint login will be active.',
              ),
            ),
            backgroundColor: const Color(0xFF3A1B2A),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _verificandoBiometria = true);

    final exito = await BiometricService.authenticate(
      reason: tr('Confirma tu huella para entrar a Lumi', 'Confirm your fingerprint to sign in to Lumi'),
    );

    if (!mounted) return;

    if (!exito) {
      // Falló o cancelo la huella, se pasa es a la contraseña
      setState(() => _verificandoBiometria = false);
      return;
    }

    final String userId = sesionExistente.user.id;
    try {
      await ApiService.login(userId: userId);
    } catch (_) {
      // El backend Node es opcional para navegar; Supabase Auth manda.
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen(userId: userId)),
    );
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorMessage = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = tr('Por favor, llena todos los campos.', 'Please fill in all fields.'));
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = tr('Ingresa un email válido.', 'Enter a valid email.'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      //  Autenticación real con Supabase Auth
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception(tr('No se pudo recuperar la sesión del usuario.', 'Could not retrieve the user session.'));
      }

      // PASO 2: El userId viene directamente de Supabase Auth (UUID real)
      // Intentamos sincronizar con el backend Node, pero no bloqueamos el login si falla
      final String userId = user.id;
      bool isAdmin = false;
      try {
        await ApiService.login(userId: userId);
      } catch (_) {
        // El backend es opcional para navegar; Supabase Auth es la fuente de verdad
      }

      try {
        isAdmin = await ApiService.adminCheck(userId);
      } catch (_) {
        isAdmin = false;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('¡Bienvenido a Lumi!', 'Welcome to Lumi!'), style: GoogleFonts.orbitron()),
          backgroundColor: const Color(0xFF102CE4),
        ),
      );

      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPanelScreen(userId: userId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(userId: userId),
          ),
        );
      }

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
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Image.asset(
                            'logo/Lumi.png',
                            width: 350,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Center(
                          child: Text(
                            tr('Iniciar Sesión', 'Sign in'),
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          tr('Email', 'Email'),
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFFE2E0EE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: tr('Ingresa tu email@', 'Enter your email@'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          tr('Contraseña', 'Password'),
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFFE2E0EE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: tr('Ingresa tu contraseña', 'Enter your password'),
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF102CE4).withOpacity(0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _buildErrorContainer(_errorMessage!),
                        ],

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      tr('Iniciar Sesión', 'Sign in'),
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),

// aac es para q si el usuario tiene biometría activada en Configuración, se muestra el botón de verificación en el login
                        if (BiometricService.isEnabled) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton.icon(
                              onPressed: _verificandoBiometria
                                  ? null
                                  : () => _tryBiometricLogin(manual: true),
                              icon: const Icon(Icons.fingerprint, color: Color(0xFFB0AEC4)),
                              label: Text(
                                tr('Usar huella', 'Use fingerprint'),
                                style: GoogleFonts.orbitron(
                                  color: const Color(0xFFB0AEC4),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const OlvidarContrasena()),
                              );
                            },
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB0AEC4)),
                            child: Text(
                              tr('¿Olvidaste tu contraseña?', 'Forgot your password?'),
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr('¿No tienes una cuenta? ', 'Don\'t have an account? '),
                              style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 12),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                              child: Text(
                                tr('Regístrate', 'Sign up'),
                                style: GoogleFonts.orbitron(
                                  color: const Color(0xFF102CE4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              if (_verificandoBiometria) _buildBiometricOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0B0813).withOpacity(0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1F1A3A),
                  border: Border.all(color: const Color(0xFFFF44AA), width: 1.5),
                ),
                child: const Icon(Icons.fingerprint, color: Color(0xFFFF44AA), size: 46),
              ),
              const SizedBox(height: 20),
              Text(
                tr('Verificando huella...', 'Verifying fingerprint...'),
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() => _verificandoBiometria = false),
                child: Text(
                  tr('Usar contraseña en su lugar', 'Use password instead'),
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFB0AEC4),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF301642).withOpacity(0.5),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF321438)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF102CE4)),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1B2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color.fromARGB(128, 204, 51, 85)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFCC3355), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.orbitron(color: const Color(0xFFCC3355), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}