import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/services/api_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

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
      _mostrarError(
        'La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.',
      );
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
        throw Exception(
          'No se pudo crear el usuario en el servicio de autenticación.',
        );
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
            content: Text(
              '✓ ¡Cuenta registrada exitosamente en LUMI!',
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context); // Regresa al Login
      } else {
        throw Exception(
          'Autenticación creada, pero el servidor Node.js rechazó el perfil.',
        );
      }
    } on AuthException catch (e) {
      final message = e.message;
      if (!mounted) return;
      _mostrarError(
        message.contains('already')
            ? 'Este correo ya está registrado.'
            : message.isNotEmpty
            ? message
            : 'No se pudo crear la cuenta. Revisa el correo y la contraseña.',
      );
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
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
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
              color: LumiAppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LumiAppTheme.outline(context).withValues(alpha: 0.5),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: LumiAppTheme.primaryText(context),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Text(
              'Registra tu cuenta',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.primaryText(context),
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
          child: Builder(
            builder: (context) {
              final registrationContent = Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.anchoMaximoContenido(context),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.paddingHorizontalRecomendado(
                          context,
                        ),
                        vertical: Responsive.espacio(context),
                      ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel(context, 'Nombre'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _nombreController,
                                        style: GoogleFonts.orbitron(
                                          color: LumiAppTheme.primaryText(
                                            context,
                                          ),
                                          fontSize: 13,
                                        ),
                                        decoration: _buildInputDecoration(
                                          context,
                                          'Tu nombre',
                                          Icons.person_outline_rounded,
                                        ),
                                        validator: (value) =>
                                            value == null ||
                                                value.trim().isEmpty
                                            ? 'Nombre obligatorio'
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: Responsive.espacio(context)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInputLabel(context, 'Apellido'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _apellidoController,
                                        style: GoogleFonts.orbitron(
                                          color: LumiAppTheme.primaryText(
                                            context,
                                          ),
                                          fontSize: 13,
                                        ),
                                        decoration: _buildInputDecoration(
                                          context,
                                          'Tu apellido',
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // --- EMAIL VÁLIDO ---
                            _buildInputLabel(context, 'Correo Electrónico'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.orbitron(
                                color: LumiAppTheme.primaryText(context),
                                fontSize: 13,
                              ),
                              decoration: _buildInputDecoration(
                                context,
                                'ejemplo@gmail.com',
                                Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Correo obligatorio';
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Ingresa un correo real y válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // --- CONTRASEÑA SEGURA ---
                            _buildInputLabel(context, 'Contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.orbitron(
                                color: LumiAppTheme.primaryText(context),
                                fontSize: 13,
                              ),
                              decoration:
                                  _buildInputDecoration(
                                    context,
                                    'Mín. 8 carac., Mayús y Núm',
                                    Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(
                                          0xFFF716DC,
                                        ).withValues(alpha: 0.8),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Contraseña obligatoria';
                                }
                                final passwordRegex = RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
                                );
                                if (!passwordRegex.hasMatch(value)) {
                                  return 'Mín. 8 carac., incluir mayús, minús y número';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // --- CONFIRMAR CONTRASEÑA ---
                            _buildInputLabel(context, 'Confirma tu contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: GoogleFonts.orbitron(
                                color: LumiAppTheme.primaryText(context),
                                fontSize: 13,
                              ),
                              decoration:
                                  _buildInputDecoration(
                                    context,
                                    'Repite la contraseña',
                                    Icons.lock_reset_outlined,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(
                                          0xFFF716DC,
                                        ).withValues(alpha: 0.8),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
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
                                    colors: [
                                      Color(0xFFF716DC),
                                      Color(0xFFA41CF9),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFF716DC,
                                      ).withValues(alpha: 0.3),
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
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Crear cuenta',
                                          style: GoogleFonts.orbitron(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
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
              );

              if (!Responsive.esEscritorio(context)) {
                return registrationContent;
              }

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.anchoMaximoContenido(context),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: Responsive.altoPantalla(context) * 0.88,
                    margin: const EdgeInsets.all(24),
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
                          child: _buildDesktopWelcomePanel(context),
                        ),
                        Expanded(flex: 6, child: registrationContent),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopWelcomePanel(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF211638), Color(0xFF151024)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'logo/Lumi.png',
            width: 210,
            height: 210,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.auto_awesome,
              color: Color(0xFFF716DC),
              size: 100,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'ESTUDIA MEJOR.\nLOGRA MÁS.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE6DDF7),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(BuildContext context, String labelText) {
    return Text(
      labelText,
      style: GoogleFonts.orbitron(
        color: LumiAppTheme.secondaryText(context),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context,
    String hintText,
    IconData prefixIcon,
  ) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.orbitron(
        color: LumiAppTheme.secondaryText(
          context,
        ).withValues(alpha: hintText.contains('@') ? 0.58 : 0.78),
        fontSize: 12,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: LumiAppTheme.accent(context),
        size: 20,
      ),
      filled: true,
      fillColor: LumiAppTheme.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: LumiAppTheme.outline(context),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: LumiAppTheme.accent(context), width: 1.5),
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
