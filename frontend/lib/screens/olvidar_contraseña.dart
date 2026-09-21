import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class OlvidarContrasena extends StatefulWidget {
  const OlvidarContrasena({super.key});

  @override
  State<OlvidarContrasena> createState() => _OlvidarContrasenaState();
}

class _OlvidarContrasenaState extends State<OlvidarContrasena> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Elegir método, 1: Ingresar email, 3: Nueva contraseña, 4: Éxito
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- 1. ENVIAR CORREO REAL DE RECUPERACIÓN CON SUPABASE ---
  Future<void> _sendSupabaseRecoveryEmail() async {
    final email = _emailController.text.trim();

    setState(() => _errorMessage = null);

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo electrónico.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un correo electrónico válido.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Supabase envía el enlace de recuperación al correo real
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        // Opcional: puedes configurar una URL de redirección si usas Web o Deep Links
        // redirectTo: 'tu-app://reset-password',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentStep = 4; // Pantalla de aviso de correo enviado con éxito
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ocurrió un error al enviar el correo. Inténtalo de nuevo.';
      });
    }
  }

  // --- 3. ACTUALIZAR CONTRASEÑA EN SUPABASE ---
  Future<void> _updatePasswordInSupabase() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    setState(() => _errorMessage = null);

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos obligatorios.');
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(newPass)) {
      setState(() => _errorMessage = 'Mín. 8 caracteres, incluir mayúscula, minúscula y número.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Actualiza la contraseña del usuario actualmente autenticado (vía biométrica o enlace)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentStep = 5; // Pantalla final de éxito total
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo actualizar la contraseña.';
      });
    }
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
              ? const [Color(0xFF0F1D8A), Color(0xFF16003A), Color(0xFF080010)]
              : const [Color(0xFFF8F5FC), Color(0xFFF0E4F8), Color(0xFFF8F5FC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Responsive.anchoMaximoContenido(context)),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: LumiAppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LumiAppTheme.outline(context).withValues(alpha: 0.5)),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: LumiAppTheme.primaryText(context), size: 18),
              onPressed: () {
                if (_currentStep > 0 && _currentStep < 4) {
                  setState(() => _currentStep = 0);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          Expanded(
            child: Text(
              'Recuperación de Cuenta',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.primaryText(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMethodChoiceStep();
      case 1:
        return _buildEmailStep();
      case 3:
        return _buildNewPasswordStep();
      case 4:
        return _buildEmailSentSuccessStep(); // Aviso de que se envió el correo real
      case 5:
        return _buildSuccessStep(); // Cambio completado con éxito
      default:
        return _buildMethodChoiceStep();
    }
  }

  Widget _buildMethodChoiceStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Elige un Método',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Selecciona cómo deseas recuperar el acceso a tu cuenta.',
              style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          _buildMethodCard(
            icon: Icons.mark_email_read_rounded,
            title: 'Correo Electrónico (Supabase)',
            description: 'Recibe un enlace oficial de recuperación en tu bandeja.',
            accentColor: const Color(0xFF00C2FF),
            onTap: () => setState(() {
              _errorMessage = null;
              _currentStep = 1;
            }),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 30),
          _buildPrimaryButton(
            label: 'Volver al Inicio de Sesión',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Icon(Icons.mark_email_unread_rounded, size: 70, color: const Color(0xFF00C2FF)),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Recuperar por Correo',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Te enviaremos un enlace seguro a tu correo registrado mediante Supabase.',
              style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Text('Correo Electrónico', style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'ejemplo@correo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: 'Enviar Enlace de Recuperación',
            onPressed: _isLoading ? null : _sendSupabaseRecoveryEmail,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // Pantalla cuando el correo de Supabase ya fue disparado con éxito
  Widget _buildEmailSentSuccessStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00C2FF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00C2FF), width: 2),
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF00C2FF), size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Correo Enviado!',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hemos enviado un enlace de recuperación a ${_emailController.text.trim()}. Revisa tu bandeja de entrada o spam para restablecer tu contraseña.',
            style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          _buildPrimaryButton(
            label: 'Volver al Inicio de Sesión',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Nueva Contraseña',
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Crea una contraseña segura (Mín. 8 caracteres, mayúscula y número).',
              style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text('Nueva Contraseña', style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _newPasswordController,
            hint: 'Mínimo 8 caracteres',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureNew,
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFF716DC), size: 20),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 16),
          Text('Confirmar Contraseña', style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Repite tu nueva contraseña',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFF716DC), size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: 'Actualizar Contraseña',
            onPressed: _isLoading ? null : _updatePasswordInSupabase,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: Responsive.paddingHorizontalRecomendado(context), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22C55E), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 45),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Contraseña Actualizada!',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tu contraseña ha sido modificada con éxito en Supabase. Ya puedes iniciar sesión con tus nuevas credenciales.',
            style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          _buildPrimaryButton(
            label: 'Ir al Inicio de Sesión',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.orbitron(color: Colors.grey[600], fontSize: 12),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF7C3AED), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: LumiAppTheme.surface(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A2A68), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF716DC), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
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
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
                      color: LumiAppTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF4A2A68).withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.orbitron(color: const Color(0xFFB0AEC4), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: accentColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}