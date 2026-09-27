import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with AppLanguageListenerMixin<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

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

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      _mostrarError(
        tr(
          'Por favor, ingresa un correo electrónico real y válido.',
          'Please enter a valid email address.',
        ),
      );
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

    if (!passwordRegex.hasMatch(password)) {
      _mostrarError(
        tr(
          'La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.',
          'The password must have at least 8 characters, an uppercase letter, a lowercase letter, and a number.',
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      _mostrarError(
        tr(
          'Las contraseñas no coinciden.',
          'Passwords do not match.',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response =
          await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          tr(
            'No se pudo crear el usuario en el servicio de autenticación.',
            'Could not create the user in the authentication service.',
          ),
        );
      }

      final publicProfileData = <String, dynamic>{
        'id': user.id,
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim().isEmpty
            ? null
            : _apellidoController.text.trim(),
        'rol_id': null,
      };

      final success = await ApiService.register(publicProfileData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                '✓ ¡Cuenta registrada exitosamente en LUMI!',
                '✓ LUMI account registered successfully!',
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

        Navigator.pop(context);
      } else {
        throw Exception(
          tr(
            'Autenticación creada, pero el servidor Node.js rechazó el perfil.',
            'Authentication was created, but the Node.js server rejected the profile.',
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      final message = e.message.toLowerCase();

      if (message.contains('already')) {
        _mostrarError(
          tr(
            'Este correo ya está registrado.',
            'This email is already registered.',
          ),
        );
      } else {
        _mostrarError(
          tr(
            'No se pudo crear la cuenta. Revisa el correo y la contraseña.',
            'Could not create the account. Check your email and password.',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarError(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ ${tr('Error', 'Error')}: $message',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

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
              tr('Registra tu cuenta', 'Create your account'),
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

  Widget _buildInputLabel(BuildContext context, String text) {
    return Text(
      text,
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
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.orbitron(
        color: LumiAppTheme.secondaryText(context).withValues(alpha: 0.7),
        fontSize: 12,
      ),
      prefixIcon: Icon(
        icon,
        color: LumiAppTheme.accent(context),
        size: 20,
      ),
      filled: true,
      fillColor: LumiAppTheme.surface(context),
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
        borderSide: BorderSide(
          color: LumiAppTheme.accent(context),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
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
          colors: [
            Color(0xFF211638),
            Color(0xFF151024),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          Text(
            tr(
              'ESTUDIA MEJOR.\nLOGRA MÁS.',
              'STUDY BETTER.\nACHIEVE MORE.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
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

  Widget _field({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(context, label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: icon == Icons.email_outlined
              ? TextInputType.emailAddress
              : TextInputType.text,
          style: GoogleFonts.orbitron(
            color: LumiAppTheme.primaryText(context),
            fontSize: 13,
          ),
          decoration: _buildInputDecoration(context, hint, icon).copyWith(
            suffixIcon: onToggleVisibility == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFF716DC).withValues(alpha: 0.8),
                    ),
                    onPressed: onToggleVisibility,
                  ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
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
                  horizontal: Responsive.paddingHorizontalRecomendado(context),
                  vertical: Responsive.espacio(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              context: context,
                              label: tr('Nombre', 'First name'),
                              controller: _nombreController,
                              hint: tr('Tu nombre', 'Your first name'),
                              icon: Icons.person_outline_rounded,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? tr(
                                          'Nombre obligatorio',
                                          'First name is required',
                                        )
                                      : null,
                            ),
                          ),
                          SizedBox(width: Responsive.espacio(context)),
                          Expanded(
                            child: _field(
                              context: context,
                              label: tr('Apellido', 'Last name'),
                              controller: _apellidoController,
                              hint: tr('Tu apellido', 'Your last name'),
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context: context,
                        label: tr('Correo electrónico', 'Email'),
                        controller: _emailController,
                        hint: tr('ejemplo@gmail.com', 'example@gmail.com'),
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr('Correo obligatorio', 'Email is required');
                          }

                          final regex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          return regex.hasMatch(value.trim())
                              ? null
                              : tr(
                                  'Ingresa un correo real y válido',
                                  'Enter a valid email address',
                                );
                        },
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context: context,
                        label: tr('Contraseña', 'Password'),
                        controller: _passwordController,
                        hint: tr(
                          'Mín. 8 carac., Mayús y Núm',
                          'Min. 8 chars, uppercase and number',
                        ),
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(
                            () => _obscurePassword = !_obscurePassword,
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr(
                              'Contraseña obligatoria',
                              'Password is required',
                            );
                          }

                          final regex = RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
                          );

                          return regex.hasMatch(value)
                              ? null
                              : tr(
                                  'Mín. 8 carac., incluir mayús, minús y número',
                                  'Min. 8 chars, include uppercase, lowercase, and number',
                                );
                        },
                      ),
                      const SizedBox(height: 18),
                      _field(
                        context: context,
                        label: tr(
                          'Confirma tu contraseña',
                          'Confirm your password',
                        ),
                        controller: _confirmPasswordController,
                        hint: tr(
                          'Repite la contraseña',
                          'Re-enter your password',
                        ),
                        icon: Icons.lock_reset_outlined,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                        validator: (value) {
                          return value == _passwordController.text
                              ? null
                              : tr(
                                  'Las contraseñas no coinciden',
                                  'Passwords do not match',
                                );
                        },
                      ),
                      const SizedBox(height: 28),
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
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    tr('Crear cuenta', 'Create account'),
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

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: Container(
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
          child: !Responsive.esEscritorio(context)
              ? content
              : Center(
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
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildDesktopWelcomePanel(context),
                          ),
                          Expanded(
                            flex: 6,
                            child: content,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}