import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:frontend/services/api_service.dart'; 
import '../utils/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- CONTROLADORES DE TEXTO ---
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false; 

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN DE REGISTRO INTEGRADO CON SUPABASE AUTH REAL ---
  void _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validación estricta de correo real
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _mostrarError('Por favor, ingresa un correo electrónico real y válido.');
      return;
    }

    // Validación de contraseña segura (Mínimo 8 caracteres, 1 mayúscula, 1 minúscula y 1 número)
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _mostrarError('La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.');
      return;
    }

    if (password != confirmPassword) {
      _mostrarError('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PASO 1: Registro real en Supabase Auth
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario en el servicio de autenticación.');
      }

      // PASO 2: Estructura exacta con las columnas de tu tabla pública
      final Map<String, dynamic> publicProfileData = {
        "id": user.id, 
        "nombre": _nombreController.text.trim(),
        "apellido": _apellidoController.text.trim().isEmpty
            ? null
            : _apellidoController.text.trim(),
        "rol_id": null,
      };

      // PASO 3: Mandamos el perfil público a tu Node.js
      bool success = await ApiService.register(publicProfileData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ¡Cuenta registrada exitosamente en LUMI!', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context); // Regresa al Login
      } else {
        throw Exception('Autenticación creada, pero el servidor Node.js rechazó el perfil.');
      }
    } on AuthException catch (e) {
      final message = e.message;
      if (!mounted) return;
      _mostrarError(message.contains('already')
          ? 'Este correo ya está registrado.'
          : message.isNotEmpty
              ? message
              : 'No se pudo crear la cuenta. Revisa el correo y la contraseña.');
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ Error: $message',
          style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- HEADER CON FLECHA DE VOLVER ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E142C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A2A68).withValues(alpha: 0.5)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Text(
              'Registra tu cuenta',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48), 
        ],
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
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Responsive.anchoMaximoContenido(context)),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: Responsive.espacio(context)),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- NOMBRE Y APELLIDO ---
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Nombre'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _nombreController,
                                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
                                        decoration: _buildInputDecoration('Tu nombre', Icons.person_outline_rounded),
                                        validator: (value) => value == null || value.trim().isEmpty ? 'Nombre obligatorio' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: Responsive.espacio(context)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel('Apellido'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _apellidoController,
                                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
                                        decoration: _buildInputDecoration('Tu apellido', Icons.person_outline_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // --- EMAIL VÁLIDO ---
                            _buildInputLabel('Correo Electrónico'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('ejemplo@correo.com', Icons.email_outlined),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Correo obligatorio';
                                }
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Ingresa un correo real y válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // --- CONTRASEÑA SEGURA ---
                            _buildInputLabel('Contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('Mín. 8 carac., Mayús y Núm', Icons.lock_outline_rounded).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFFF716DC).withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Contraseña obligatoria';
                                }
                                final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
                                if (!passwordRegex.hasMatch(value)) {
                                  return 'Mín. 8 carac., incluir mayús, minús y número';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // --- CONFIRMAR CONTRASEÑA ---
                            _buildInputLabel('Confirma tu contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
                              decoration: _buildInputDecoration('Repite la contraseña', Icons.lock_reset_outlined).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFFF716DC).withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // --- BOTÓN CREAR CUENTA ---
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF716DC).withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _crearCuenta, 
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          'Crear cuenta',
                                          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String labelText) {
    return Text(
      labelText, 
      style: GoogleFonts.orbitron(
        color: const Color(0xFFB0AEC4), 
        fontSize: 12, 
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, IconData prefixIcon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 12),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF7C3AED), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E142C).withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Color(0xFF4A2A68), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Color(0xFFF716DC), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}