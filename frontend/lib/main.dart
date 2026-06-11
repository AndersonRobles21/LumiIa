import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/olvidar_contraseña.dart';
import 'register_screen.dart';

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
    
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un email válido.');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor, llena todos los campos.');
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡Inicio de sesión simulado con éxito!',
          style: GoogleFonts.orbitron(),
        ),
        backgroundColor: const Color(0xFF102CE4),
      ),
    );
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
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36.0,
                  vertical: 24.0,
                ),
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
                        'Iniciar Sesión',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- ETIQUETA EMAIL ---
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
                      hint: 'Ingresa tu email@',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // --- ETIQUETA CONTRASEÑA ---
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
                      hint: 'Ingresa tu contraseña',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _buildErrorContainer(_errorMessage!),
                    ],

                    const SizedBox(height: 32),

                    // --- BOTÓN INICIAR SESIÓN ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Iniciar Sesión',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- LINKS DE NAVEGACIÓN ---
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OlvidarContrasena(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB0AEC4),
                        ),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    // Enlace hacia RegisterScreen de forma limpia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes una cuenta? ',
                          style: GoogleFonts.orbitron(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFF102CE4),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
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
        fillColor: const Color(0xFF301642).withValues(alpha: 0.5),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF321438), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF102CE4), width: 1.5),
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
              style: GoogleFonts.orbitron(
                color: const Color(0xFFCC3355),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
