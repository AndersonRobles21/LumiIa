import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'app_language.dart';

class OlvidarContrasena extends StatefulWidget {
  const OlvidarContrasena({super.key});

  @override
  State<OlvidarContrasena> createState() => _OlvidarContrasenaState();
}

class _OlvidarContrasenaState extends State<OlvidarContrasena>
    with AppLanguageListenerMixin<OlvidarContrasena> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationCode;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
  final LocalAuthentication localAuth = LocalAuthentication();

  try {
    final canCheck = await localAuth.canCheckBiometrics;
    final isSupported = await localAuth.isDeviceSupported();
    final biometrics = await localAuth.getAvailableBiometrics();

    print('canCheckBiometrics: $canCheck');
    print('isDeviceSupported: $isSupported');
    print('Biometrics: $biometrics');

    setState(() {
      _biometricAvailable =
          (canCheck || isSupported) && biometrics.isNotEmpty;
    });
  } catch (e) {
    print(e);
  }
}

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();

    setState(() => _errorMessage = null);

    if (email.isEmpty) {
      setState(() => _errorMessage = tr('Ingresa tu email.', 'Enter your email.'));
      return;
    }

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = tr('Ingresa un email válido.', 'Enter a valid email.'));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    _verificationCode = '123456';
    setState(() {
      _isLoading = false;
      _currentStep = 2;
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    setState(() => _errorMessage = null);

    if (code.isEmpty) {
      setState(() => _errorMessage = tr('Ingresa el código recibido.', 'Enter the code you received.'));
      return;
    }

    if (code != _verificationCode) {
      setState(() => _errorMessage = tr('Código incorrecto.', 'Incorrect code.'));
      return;
    }

    setState(() => _currentStep = 3);
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() => _errorMessage = null);
    final LocalAuthentication localAuth = LocalAuthentication();
    try {
      final isAuthenticated = await localAuth.authenticate(
        localizedReason: tr(
          'Usa tu huella dactilar para recuperar contraseña',
          'Use your fingerprint to recover your password',
        ),
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (isAuthenticated) {
        setState(() => _currentStep = 3);
      } else {
        setState(() => _errorMessage = tr('Autenticación biométrica rechazada.', 'Biometric authentication was rejected.'));
      }
    } catch (e) {
      setState(() => _errorMessage = '${tr('Error en autenticación', 'Authentication error')}: $e');
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    setState(() => _errorMessage = null);

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = tr('Completa todos los campos.', 'Fill in all fields.'));
      return;
    }

    if (newPass.length < 6) {
      setState(
        () => _errorMessage = tr(
          'La contraseña debe tener al menos 6 caracteres.',
          'The password must be at least 6 characters long.',
        ),
      );
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = tr('Las contraseñas no coinciden.', 'Passwords do not match.'));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
      _currentStep = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMethodChoiceStep();
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildCodeVerificationStep();
      case 3:
        return _buildNewPasswordStep();
      case 4:
        return _buildSuccessStep();
      default:
        return _buildMethodChoiceStep();
    }
  }

  Widget _buildMethodChoiceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              tr('Elige un Método', 'Choose a Method'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              tr(
                'Elige cómo quieres recuperar el acceso: con código o con huella dactilar.',
                'Choose how you want to recover access: with a code or with your fingerprint.',
              ),
              style: const TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          _buildMethodCard(
            icon: Icons.security,
            title: tr('Código de Email', 'Email Code'),
            description: tr(
              'Recibe un código en tu email y verifica tu identidad.',
              'Receive a code in your email and verify your identity.',
            ),
            onTap: () => setState(() => _currentStep = 1),
          ),
          const SizedBox(height: 16),
          _buildMethodCard(
            icon: Icons.fingerprint,
            title: tr('Huella Dactilar', 'Fingerprint'),
            description: _biometricAvailable
                ? tr('Usa tu huella para recuperar la contraseña.', 'Use your fingerprint to recover your password.')
                : tr('Huella no disponible en este dispositivo.', 'Fingerprint not available on this device.'),
            enabled: _biometricAvailable,
            onTap: _biometricAvailable ? _authenticateWithBiometric : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
         const SizedBox(height: 40),
          _buildPrimaryButton(
            label: tr('Volver al Inicio de Sesión', 'Back to Sign In'),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'logo/Lumi.png',
              width: 350,
              height: 205,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              tr('Recuperar Contraseña', 'Recover Password'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              tr(
                'Ingresa tu email para recibir un código de recuperación.',
                'Enter your email to receive a recovery code.',
              ),
              style: const TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            tr('Email', 'Email'),
            style: const TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: tr('ingresa tu email@', 'enter your email@'),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: tr('Enviar Código', 'Send Code'),
            onPressed: _isLoading ? null : _sendEmailCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: Text(
                tr('Volver', 'Back'),
                style: const TextStyle(
                  color: Color(0xFFB0AEC4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCodeVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              tr('Verifica tu Código', 'Verify your Code'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              tr(
                'Ingresa el código que recibiste en tu email.',
                'Enter the code you received in your email.',
              ),
              style: const TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            tr('Código', 'Code'),
            style: const TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _codeController,
            hint: tr('Ej: 123456', 'e.g. 123456'),
            keyboardType: TextInputType.number,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: tr('Verificar Código', 'Verify Code'),
            onPressed: _isLoading ? null : _verifyCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: Text(
                tr('Volver', 'Back'),
                style: const TextStyle(
                  color: Color(0xFFB0AEC4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'logo/Lumi.png',
              width: 280,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              tr('Nueva Contraseña', 'New Password'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              tr('Crea una contraseña segura y diferente.', 'Create a secure, different password.'),
              style: const TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            tr('Nueva Contraseña', 'New Password'),
            style: const TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _newPasswordController,
            hint: tr('Mínimo 6 caracteres', 'Minimum 6 characters'),
            obscureText: _obscureNew,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9A96B6),
                size: 22,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('Confirmar Contraseña', 'Confirm Password'),
            style: const TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: tr('Repite tu nueva contraseña', 'Repeat your new password'),
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9A96B6),
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: tr('Cambiar Contraseña', 'Change Password'),
            onPressed: _isLoading ? null : _resetPassword,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A2A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 50,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            tr('¡Contraseña Cambiada!', 'Password Changed!'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tr(
              'Tu contraseña ha sido actualizada exitosamente.',
              'Your password has been successfully updated.',
            ),
            style: const TextStyle(
              color: Color(0xFFB0AEC4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: tr('Volver al Inicio de Sesión', 'Back to Sign In'),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(height: 16),
        ],
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B6885), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF191632),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
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
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA41CF9), Color(0xFFF716DC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(128, 204, 51, 85)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFCC3355), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFCC3355), fontSize: 13),
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
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF191632),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(77, 154, 150, 182)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(51, 156, 39, 176),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF9C27B0), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFB0AEC4),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9C27B0),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}


