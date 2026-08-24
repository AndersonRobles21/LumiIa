import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:frontend/services/api_service.dart'; 

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

    if (!email.contains('@') || !email.contains('.')) {
      _mostrarError('El correo no tiene un formato válido.');
      return;
    }

    if (password.length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      _mostrarError('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PASO 1: Registro real en Supabase Auth para poblar auth.users y generar el UUID real
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
        "id": user.id, // El UUID oficial que ya existe en auth.users y cumple la FK
        "nombre": _nombreController.text.trim(),
        "apellido": _apellidoController.text.trim().isEmpty
            ? null
            : _apellidoController.text.trim(),
        "rol_id": null,
      };

      // PASO 3: Mandamos el perfil público a tu Node.js con tu pg Pool
      bool success = await ApiService.register(publicProfileData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Cuenta registrada exitosamente en LUMI!', style: GoogleFonts.orbitron()),
            backgroundColor: const Color(0xFF102CE4),
          ),
        );
        Navigator.pop(context); // Regresa al Login limpiamente
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
          'Error: $message',
          style: GoogleFonts.orbitron(fontSize: 12),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813), // Diseño Cyberpunk LUMI
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
                padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Registra tu cuenta',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

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
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                                  decoration: _buildInputDecoration('Tu nombre'),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Nombre obligatorio' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Apellido'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _apellidoController,
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                                  decoration: _buildInputDecoration('Tu apellido'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // --- EMAIL ---
                      _buildInputLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration('Ingresa tu email@'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Correo obligatorio' : null,
                      ),
                      const SizedBox(height: 18),

                      // --- CONTRASEÑA ---
                      _buildInputLabel('Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration('Ingresa una contraseña').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.lock_outline : Icons.lock_open,
                              color: const Color(0xFF102CE4).withOpacity(0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Contraseña obligatoria' : null,
                      ),
                      const SizedBox(height: 18),

                      // --- CONFIRMAR CONTRASEÑA ---
                      _buildInputLabel('Confirma tu contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: _buildInputDecoration('Repite la contraseña').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.lock_outline : Icons.lock_open,
                              color: const Color(0xFF102CE4).withOpacity(0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 35),

                      // --- BOTÓN CREAR CUENTA ---
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF716DC), Color(0xFFA41CF9)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _crearCuenta, 
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
                                    'Crear cuenta',
                                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
    return Text(labelText, style: GoogleFonts.orbitron(color: const Color(0xFFE2E0EE), fontSize: 13, fontWeight: FontWeight.w500));
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF301642).withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF321438), width: 1.2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF102CE4), width: 1.5)),
    );
  }
}