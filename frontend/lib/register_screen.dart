import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../servicios/auth_service.dart'; // ajusta la ruta si es diferente

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _cargando = false; // ← AÑADIDO

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ← MÉTODO DE REGISTRO AÑADIDO
  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final resultado = await AuthService.registrar(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (resultado['exito'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Cuenta creada exitosamente!',
              style: GoogleFonts.orbitron(),
            ),
            backgroundColor: const Color(0xFF102CE4),
          ),
        );
        // Navigator.pushReplacementNamed(context, '/home'); // descomenta cuando tengas la ruta
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${resultado['error']}',
              style: GoogleFonts.orbitron(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error de conexión',
            style: GoogleFonts.orbitron(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
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
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),

                      // --- TÍTULO PRINCIPAL ---
                      Center(
                        child: Text(
                          'Registra tu cuenta',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- CAMPO EMAIL ---
                      _buildInputLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 14),
                        decoration:
                            _buildInputDecoration('Ingresa tu email@'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingresa tu correo electrónico';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Introduce un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- CAMPO CONTRASEÑA ---
                      _buildInputLabel('Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 14),
                        decoration:
                            _buildInputDecoration('Ingresa una contraseña')
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.lock_outline
                                  : Icons.lock_open,
                              color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- CAMPO CONFIRMAR CONTRASEÑA ---
                      _buildInputLabel('Confirma tu contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 14),
                        decoration:
                            _buildInputDecoration('Ingresa una contraseña')
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.lock_outline
                                  : Icons.lock_open,
                              color: const Color(0xFF102CE4).withValues(alpha: 0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // --- BOTÓN CREAR CUENTA ---
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: _cargando
                                  ? [
                                      const Color(0xFF888888),
                                      const Color(0xFF555555),
                                    ]
                                  : [
                                      const Color(0xFFF716DC),
                                      const Color(0xFFA41CF9),
                                    ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _crearCuenta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Crear cuenta',
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

                      // --- TEXTO INFERIOR ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Listo para iniciar ',
                            style: GoogleFonts.orbitron(
                                color: Colors.grey, fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'continua',
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
      ),
    );
  }

  Widget _buildInputLabel(String labelText) {
    return Text(
      labelText,
      style: GoogleFonts.orbitron(
        color: const Color(0xFFE2E0EE),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF301642).withValues(alpha: 0.5),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: Color(0xFF321438), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: Color(0xFF102CE4), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      errorStyle:
          GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 11),
    );
  }
}