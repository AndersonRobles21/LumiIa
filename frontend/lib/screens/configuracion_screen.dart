import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_language.dart';
import 'biometric_service.dart';
import 'login_screen.dart'; 
import 'info_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  //  Estado local de las preferencias (luego puedes persistirlas) ---
  bool _notificacionesPush = true;
  bool _recordatoriosDiarios = true;
  bool _autenticacionBiometrica = false;
  bool _verificandoBiometria = false;
  bool _cerrandoSesion = false;
  bool _isEnglish = false;

  // Colores reutilizados del resto de la app (mismo look que login/perfil)
  static const Color bgDark = Color(0xFF0B0813);
  static const Color cardColor = Color(0xFF1F1A3A);
  static const Color accentPink = Color(0xFFFF44AA);
  static const Color textGrey = Color(0xFFB0AEC4);
  static const Color dangerColor = Color(0xFFE23E57);

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_onLanguageChanged);
    _initializeBiometrics();
    _isEnglish = AppLanguage.instance.isEnglish;
  }

  Future<void> _initializeBiometrics() async {
    await BiometricService.initialize();
    if (!mounted) return;
    setState(() => _autenticacionBiometrica = BiometricService.isEnabled);
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() => _isEnglish = AppLanguage.instance.isEnglish);
    }
  }

  String _text(String spanish, String english) =>
      _isEnglish ? english : spanish;

  // --- Activar/desactivar biometría con verificación real del dispositivo ---
  Future<void> _onBiometricChanged(bool value) async {
    final lang = AppLanguage.instance;

    if (!value) {
      // Apagar siempre se permite sin pedir huella.
      setState(() => _autenticacionBiometrica = false);
      await BiometricService.setEnabled(false);
      return;
    }

    setState(() => _verificandoBiometria = true);

    final soportado = await BiometricService.isDeviceSupported();
    if (!soportado) {
      if (!mounted) return;
      setState(() => _verificandoBiometria = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Este dispositivo no tiene biometría configurada o no se pudo abrir el prompt.',
              'This device has no biometrics set up or the prompt could not be opened.',
            ),
          ),
        ),
      );
      return;
    }

    // Pedimos una huella de confirmación antes de activarla, para
    // asegurarnos de que el usuario realmente puede usarla luego en login.
    final exito = await BiometricService.authenticate(
      reason: _text(
        'Confirma tu huella para activar el inicio con biometría',
        'Confirm your fingerprint to enable biometric login',
      ),
    );

    if (!mounted) return;
    if (!exito) {
      setState(() {
        _verificandoBiometria = false;
        _autenticacionBiometrica = false;
      });
      await BiometricService.setEnabled(false);
    } else {
      setState(() {
        _verificandoBiometria = false;
        _autenticacionBiometrica = true;
      });
      await BiometricService.setEnabled(true);
    }

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Biometría activada correctamente.',
              'Biometric login turned on.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage.instance;

    return Scaffold(
      backgroundColor: bgDark,
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
              child: Column(
                children: [
                  _buildHeader(context, lang),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            _text('Notificaciones', 'Notifications'),
                          ),
                          _buildSwitchTile(
                            icon: Icons.notifications_active_outlined,
                            title: _text(
                              'Notificaciones push',
                              'Push notifications',
                            ),
                            subtitle: _text(
                              'Avisos de actividades y tareas pendientes',
                              'Alerts for activities and pending tasks',
                            ),
                            value: _notificacionesPush,
                            onChanged: (v) =>
                                setState(() => _notificacionesPush = v),
                          ),
                          _buildSwitchTile(
                            icon: Icons.alarm_outlined,
                            title: _text(
                              'Recordatorios diarios',
                              'Daily reminders',
                            ),
                            subtitle: _text(
                              'Recibe un recordatorio de tu horario de estudio',
                              'Get a reminder of your study schedule',
                            ),
                            value: _recordatoriosDiarios,
                            onChanged: (v) =>
                                setState(() => _recordatoriosDiarios = v),
                          ),

                          const SizedBox(height: 12),
                          _buildSectionTitle(_text('Seguridad', 'Security')),
                          _buildSwitchTile(
                            icon: Icons.fingerprint,
                            title: _text(
                              'Inicio con biometría',
                              'Biometric login',
                            ),
                            subtitle: _text(
                              'Usa huella o Face ID para entrar a Lumi',
                              'Use fingerprint or Face ID to sign in to Lumi',
                            ),
                            value: _autenticacionBiometrica,
                            loading: _verificandoBiometria,
                            onChanged: _onBiometricChanged,
                          ),
                          _buildNavTile(
                            icon: Icons.lock_reset_outlined,
                            title: _text(
                              'Cambiar contraseña',
                              'Change password',
                            ),
                            onTap: () => _cambiarContrasena(context, lang),
                          ),
                          _buildNavTile(
                            icon: Icons.privacy_tip_outlined,
                            title: _text(
                              'Privacidad y datos',
                              'Privacy & data',
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InfoScreen.privacidad(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          _buildSectionTitle(
                            _text('Preferencias', 'Preferences'),
                          ),
                          _buildNavTile(
                            icon: Icons.language_outlined,
                            title: _text('Idioma', 'Language'),
                            trailingText: _isEnglish ? 'English' : 'Español',
                            onTap: () => _mostrarSelectorIdioma(context, lang),
                          ),
                          _buildNavTile(
                            icon: Icons.school_outlined,
                            title: _text(
                              'Métodos de estudio preferidos',
                              'Preferred study methods',
                            ),
                            onTap: () => _mostrarProximamente(
                              context,
                              lang,
                              _text(
                                'Métodos de estudio preferidos',
                                'Preferred study methods',
                              ),
                              _text(
                                'Podrás elegir y guardar tus métodos de estudio favoritos (Pomodoro, mapas mentales, práctica activa, etc.) directamente desde aquí en una próxima actualización.',
                                'You\'ll be able to choose and save your favorite study methods (Pomodoro, mind maps, active recall, etc.) right from here in an upcoming update.',
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          _buildSectionTitle(_text('Soporte', 'Support')),
                          _buildNavTile(
                            icon: Icons.help_outline,
                            title: _text('Centro de ayuda', 'Help center'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InfoScreen.ayuda(),
                                ),
                              );
                            },
                          ),
                          _buildNavTile(
                            icon: Icons.info_outline,
                            title: _text('Acerca de Lumi', 'About Lumi'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InfoScreen.acercaDe(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 28),
                          _buildLogoutButton(context, lang),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Header con flecha de volver ---
  Widget _buildHeader(BuildContext context, AppLanguage lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _text('Configuración', 'Settings'),
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48), // balancea el icono de la izquierda
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.orbitron(
          color: textGrey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    bool loading = false,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF321438), width: 1),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentPink,
                ),
              )
            : Icon(icon, color: accentPink.withOpacity(0.9)),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.orbitron(color: textGrey, fontSize: 10.5),
              )
            : null,
        value: value,
        activeColor: accentPink,
        onChanged: loading ? null : onChanged,
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF321438), width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentPink.withOpacity(0.9)),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  trailingText,
                  style: GoogleFonts.orbitron(color: textGrey, fontSize: 12),
                ),
              ),
            const Icon(Icons.chevron_right, color: textGrey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // --- Botón Cerrar sesión ---
  Widget _buildLogoutButton(BuildContext context, AppLanguage lang) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cerrandoSesion
            ? null
            : () => _confirmarCerrarSesion(context, lang),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: dangerColor, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _cerrandoSesion
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: dangerColor,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.logout, color: dangerColor),
        label: Text(
          _text('Cerrar sesión', 'Log out'),
          style: GoogleFonts.orbitron(
            color: dangerColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCerrarSesion(
    BuildContext context,
    AppLanguage lang,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _text('¿Cerrar sesión?', 'Log out?'),
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          _text(
            'Tendrás que volver a iniciar sesión para acceder a tu cuenta.',
            'You\'ll need to sign in again to access your account.',
          ),
          style: GoogleFonts.orbitron(color: textGrey, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _text('Cancelar', 'Cancel'),
              style: GoogleFonts.orbitron(color: textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _text('Cerrar sesión', 'Log out'),
              style: GoogleFonts.orbitron(
                color: dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _cerrarSesion(context);
    }
  }

  // --- Cambiar contraseña: envía un correo real de restablecimiento
  // usando el usuario que ya inició sesión en Supabase. ---
  Future<void> _cambiarContrasena(
    BuildContext context,
    AppLanguage lang,
  ) async {
    final String? email = Supabase.instance.client.auth.currentUser?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'No se encontró un correo asociado a tu cuenta.',
              'No email associated with your account was found.',
            ),
          ),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _text('Cambiar contraseña', 'Change password'),
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          _text(
            'Te enviaremos un correo a $email con un enlace para restablecer tu contraseña. ¿Deseas continuar?',
            'We\'ll send an email to $email with a link to reset your password. Continue?',
          ),
          style: GoogleFonts.orbitron(color: textGrey, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _text('Cancelar', 'Cancel'),
              style: GoogleFonts.orbitron(color: textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _text('Enviar correo', 'Send email'),
              style: GoogleFonts.orbitron(
                color: accentPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Te enviamos un correo a $email para cambiar tu contraseña.',
              'We sent an email to $email to reset your password.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'No se pudo enviar el correo. Intenta de nuevo más tarde.',
              'Could not send the email. Please try again later.',
            ),
          ),
        ),
      );
    }
  }

  // --- Selector de idioma: Español / English, ambos activos ---
  void _mostrarSelectorIdioma(BuildContext context, AppLanguage lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          _text('Idioma', 'Language'),
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<AppLang>(
              value: AppLang.es,
              groupValue: _isEnglish ? AppLang.en : AppLang.es,
              activeColor: accentPink,
              title: Text(
                'Español',
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
              ),
              onChanged: (_) async {
                await AppLanguage.instance.setLanguage(AppLang.es);
                if (!mounted) return;
                setState(() => _isEnglish = false);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<AppLang>(
              value: AppLang.en,
              groupValue: _isEnglish ? AppLang.en : AppLang.es,
              activeColor: accentPink,
              title: Text(
                'English',
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
              ),
              onChanged: (_) async {
                await AppLanguage.instance.setLanguage(AppLang.en);
                if (!mounted) return;
                setState(() => _isEnglish = true);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _text('Cerrar', 'Close'),
              style: GoogleFonts.orbitron(color: textGrey),
            ),
          ),
        ],
      ),
    );
  }

  // --- Placeholder honesto para funciones aún no conectadas al backend ---
  void _mostrarProximamente(
    BuildContext context,
    AppLanguage lang,
    String titulo,
    String mensaje,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          titulo,
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          mensaje,
          style: GoogleFonts.orbitron(color: textGrey, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _text('Entendido', 'Got it'),
              style: GoogleFonts.orbitron(
                color: accentPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    setState(() => _cerrandoSesion = true);

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Error cerrando sesión: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
