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
      // PASO 1: Autenticación real con Supabase Auth
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('No se pudo recuperar la sesión del usuario.');
      }

      // PASO 2: El userId viene directamente de Supabase Auth (UUID real)
      // Intentamos sincronizar con el backend Node, pero no bloqueamos el login si falla
      final String userId = user.id;

      try {
        await ApiService.login(userId: userId);
      } catch (_) {
        // El backend es opcional para navegar; Supabase Auth es la fuente de verdad
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido a Lumi!', style: GoogleFonts.orbitron()),
          backgroundColor: const Color(0xFF102CE4),
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
                  // Modo escritorio: fila con formulario a la izquierda e imagen grande a la derecha
                  if (isDesktop) {
                    return SizedBox(
                      height: Responsive.altoPantalla(context) * 0.8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context)),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      'Iniciar Sesión',
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: Responsive.espacio(context) * 4),

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
                                    SizedBox(height: Responsive.espacio(context) * 2.5),

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
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),

                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 14),
                                      _buildErrorContainer(_errorMessage!),
                                    ],

                                    SizedBox(height: Responsive.espacio(context) * 4),

                                    SizedBox(
                                      width: Responsive.anchoBoton(context),
                                      height: Responsive.altoBoton(context),
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
                                              ? SizedBox(
                                                  width: Responsive.tamanioSubtitulo(context),
                                                  height: Responsive.tamanioSubtitulo(context),
                                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                )
                                              : Text(
                                                  'Iniciar Sesión',
                                                  style: GoogleFonts.orbitron(
                                                    color: Colors.white,
                                                    fontSize: Responsive.tamanioTexto(context),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: Responsive.espacio(context) * 3),

                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const OlvidarContrasena()),
                                        );
                                      },
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFB0AEC4)),
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: GoogleFonts.orbitron(
                                          fontSize: Responsive.tamanioTexto(context),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),

                                    Row(
                                      children: [
                                        Text(
                                          '¿No tienes una cuenta? ',
                                          style: GoogleFonts.orbitron(color: Colors.grey, fontSize: Responsive.tamanioTexto(context) - 2),
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
                                              color: const Color(0xFF102CE4),
                                              fontSize: Responsive.tamanioTexto(context) - 2,
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
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context)),
                              child: Center(
                                child: Image.asset(
                                  'logo/Lumi.png',
                                  width: Responsive.anchoPantalla(context) * 0.45,
                                  height: Responsive.altoPantalla(context) * 0.7,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Modo móvil/tablet: diseño original en columna y scroll
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: Responsive.espacio(context) * 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Image.asset(
                            'logo/Lumi.png',
                            width: Responsive.anchoPantalla(context) * 0.6,
                            height: Responsive.altoPantalla(context) * 0.2,
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
                        SizedBox(height: Responsive.espacio(context) * 4),

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
                        SizedBox(height: Responsive.espacio(context) * 2.5),

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
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _buildErrorContainer(_errorMessage!),
                        ],

                        SizedBox(height: Responsive.espacio(context) * 4),

                        SizedBox(
                          width: double.infinity,
                          height: Responsive.altoBoton(context),
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
                                  ? SizedBox(
                                      width: Responsive.tamanioSubtitulo(context),
                                      height: Responsive.tamanioSubtitulo(context),
                                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Iniciar Sesión',
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: Responsive.tamanioTexto(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.espacio(context) * 3),

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
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.orbitron(
                                  fontSize: Responsive.tamanioTexto(context),
                                  decoration: TextDecoration.underline,
                                ),
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes una cuenta? ',
                              style: GoogleFonts.orbitron(color: Colors.grey, fontSize: Responsive.tamanioTexto(context) - 2),
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
                                  color: const Color(0xFF102CE4),
                                  fontSize: Responsive.tamanioTexto(context) - 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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