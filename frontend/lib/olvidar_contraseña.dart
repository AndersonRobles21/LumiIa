import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class OlvidarContrasena extends StatefulWidget {
  const OlvidarContrasena({super.key});

  @override
  State<OlvidarContrasena> createState() => _OlvidarContrasenaState();
}

class _OlvidarContrasenaState extends State<OlvidarContrasena> {
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
      final isDeviceSupported = await localAuth.canCheckBiometrics;
      final availableBiometrics = await localAuth.getAvailableBiometrics();
      setState(() {
        _biometricAvailable =
            isDeviceSupported && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();

    setState(() => _errorMessage = null);

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu email.');
      return;
    }

    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un email válido.');
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
      setState(() => _errorMessage = 'Ingresa el código recibido.');
      return;
    }

    if (code != _verificationCode) {
      setState(() => _errorMessage = 'Código incorrecto.');
      return;
    }

    setState(() => _currentStep = 3);
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() => _errorMessage = null);
    final LocalAuthentication localAuth = LocalAuthentication();
    try {
      final isAuthenticated = await localAuth.authenticate(
        localizedReason: 'Usa tu huella dactilar para recuperar contraseña',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (isAuthenticated) {
        setState(() => _currentStep = 3);
      } else {
        setState(() => _errorMessage = 'Autenticación biométrica rechazada.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error en autenticación: $e');
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    setState(() => _errorMessage = null);

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos.');
      return;
    }

    if (newPass.length < 6) {
      setState(
        () => _errorMessage = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
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
          const Center(
            child: Text(
              'Elige un Método',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Elige cómo quieres recuperar el acceso: con código o con huella dactilar.',
              style: TextStyle(
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
            title: 'Código de Email',
            description:
                'Recibe un código en tu email y verifica tu identidad.',
            onTap: () => setState(() => _currentStep = 1),
          ),
          const SizedBox(height: 16),
          _buildMethodCard(
            icon: Icons.fingerprint,
            title: 'Huella Dactilar',
            description: _biometricAvailable
                ? 'Usa tu huella para recuperar la contraseña.'
                : 'Huella no disponible en este dispositivo.',
            enabled: _biometricAvailable,
            onTap: _biometricAvailable ? _authenticateWithBiometric : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
         const SizedBox(height: 40),
          _buildPrimaryButton(
            label: 'Volver al Inicio de Sesión',
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
          const Center(
            child: Text(
              'Recuperar Contraseña',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Ingresa tu email para recibir un código de recuperación.',
              style: TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Email',
            style: TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'ingresa tu email@',
            keyboardType: TextInputType.emailAddress,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: 'Enviar Código',
            onPressed: _isLoading ? null : _sendEmailCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text(
                'Volver',
                style: TextStyle(
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
          const Center(
            child: Text(
              'Verifica tu Código',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Ingresa el código que recibiste en tu email.',
              style: TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Código',
            style: TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _codeController,
            hint: 'Ej: 123456',
            keyboardType: TextInputType.number,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorContainer(_errorMessage!),
          ],
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: 'Verificar Código',
            onPressed: _isLoading ? null : _verifyCode,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text(
                'Volver',
                style: TextStyle(
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
          const Center(
            child: Text(
              'Nueva Contraseña',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Crea una contraseña segura y diferente.',
              style: TextStyle(
                color: Color(0xFFB0AEC4),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Nueva Contraseña',
            style: TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _newPasswordController,
            hint: 'Mínimo 6 caracteres',
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
          const Text(
            'Confirmar Contraseña',
            style: TextStyle(
              color: Color(0xFFE2E0EE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Repite tu nueva contraseña',
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
            label: 'Cambiar Contraseña',
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
          const Text(
            '¡Contraseña Cambiada!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu contraseña ha sido actualizada exitosamente.',
            style: TextStyle(
              color: Color(0xFFB0AEC4),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: 'Volver al Inicio de Sesión',
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


