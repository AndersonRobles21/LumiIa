import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'app_language.dart';
import 'biometric_service.dart';
import 'login_screen.dart';
import 'info_screen.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../services/theme_controller.dart';
import '../services/task_notification_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesTareas = true;
  bool _recordatoriosDiarios = true;
  String _horaNotificacion = '18:00';
  bool _cargandoNotificaciones = false;
  bool _autenticacionBiometrica = false;
  bool _verificandoBiometria = false;
  bool _cerrandoSesion = false;
  bool _isEnglish = false;
  bool _isAdmin = false;
  bool _sonidosActivados = true;

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
    ThemeController.instance.addListener(_onThemeChanged);
    _isEnglish = AppLanguage.instance.isEnglish;
    _initializeAdminStatus();
    _initializeNotificationSettings();
    _initializeSoundSettings();
    // Solo inicializar biometría en plataformas nativas (no web)
    if (!kIsWeb) {
      _initializeBiometrics();
    }
  }

  Future<void> _initializeAdminStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isAdmin = false);
      return;
    }

    try {
      final profile = await ApiService.getProfile(userId);
      if (!mounted) return;
      setState(() => _isAdmin = (profile?['es_admin'] ?? false) == true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAdmin = false);
    }
  }

  Future<void> _initializeBiometrics() async {
    await BiometricService.initialize();
    if (!mounted) return;
    setState(() => _autenticacionBiometrica = BiometricService.isEnabled);
  }

  Future<void> _initializeNotificationSettings() async {
    final service = TaskNotificationService.instance;
    final enabled = await service.isEnabled();
    final time = await service.getReminderTime();
    if (!mounted) return;
    setState(() {
      _notificacionesTareas = enabled;
      _horaNotificacion = time;
    });
  }

  Future<void> _initializeSoundSettings() async {
    final enabled = await SoundService.instance.isEnabled();
    if (!mounted) return;
    setState(() => _sonidosActivados = enabled);
  }

  Future<void> _onSoundChanged(bool value) async {
    final enabled = await SoundService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() => _sonidosActivados = enabled);
  }

  Future<void> _onTaskNotificationsChanged(bool value) async {
    setState(() => _cargandoNotificaciones = true);
    final enabled = await TaskNotificationService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _notificacionesTareas = enabled;
      _cargandoNotificaciones = false;
    });
    if (value && !enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Las notificaciones del sistema están desactivadas.',
              'System notifications are disabled.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _seleccionarHoraNotificacion() async {
    final partes = _horaNotificacion.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(partes.first) ?? 18,
      minute: int.tryParse(partes.length > 1 ? partes[1] : '') ?? 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selected == null) return;

    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    await TaskNotificationService.instance.setReminderTime(
      selected.hour,
      selected.minute,
    );
    if (!mounted) return;
    setState(() => _horaNotificacion = value);
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_onLanguageChanged);
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() => _isEnglish = AppLanguage.instance.isEnglish);
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
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

    // Pedimos una verificación antes de activar la autorización biométrica.
    final exito = await BiometricService.authenticate(
      reason: _text(
        'Confirma tu identidad para activar la verificación biométrica',
        'Confirm your identity to enable biometric verification',
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
              'Biometric verification turned on.',
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
                    Color.fromARGB(255, 5, 8, 36),
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
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.esEscritorio(context)
                    ? 900
                    : Responsive.anchoMaximoContenido(context),
              ),
              child: Column(
                children: [
                  _buildHeader(context, lang),
                  Expanded(
                    child: Container(
                      margin: Responsive.esEscritorio(context)
                          ? const EdgeInsets.fromLTRB(18, 8, 18, 20)
                          : EdgeInsets.zero,
                      decoration: Responsive.esEscritorio(context)
                          ? BoxDecoration(
                              color: LumiAppTheme.surface(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: LumiAppTheme.outline(context),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 22,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            )
                          : null,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.paddingHorizontalRecomendado(
                            context,
                          ),
                          vertical: Responsive.espacio(context),
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isAdmin) ...[
                            _buildSectionTitle(
                              _text('Notificaciones', 'Notifications'),
                            ),
                            _buildSwitchTile(
                              icon: Icons.notifications_active_outlined,
                              title: _text(
                                'Notificaciones de tareas',
                                'Task notifications',
                              ),
                              subtitle: _text(
                                'Avisos locales de tareas pendientes',
                                'Local alerts for pending tasks',
                              ),
                              value: _notificacionesTareas,
                              loading: _cargandoNotificaciones,
                              onChanged: _onTaskNotificationsChanged,
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
                            _buildNavTile(
                              icon: Icons.schedule_outlined,
                              title: _text(
                                'Hora de recordatorio',
                                'Reminder time',
                              ),
                              trailingText: _horaNotificacion,
                              onTap: _seleccionarHoraNotificacion,
                            ),
                          ],

                          const SizedBox(height: 12),
                          _buildSectionTitle(_text('Seguridad', 'Security')),
                          if (!kIsWeb) ...[
                            _buildSwitchTile(
                              icon: Icons.fingerprint,
                              title: _text(
                                'Verificación biométrica',
                                'Biometric verification',
                              ),
                              subtitle: _text(
                                'Confirma cambios sensibles con huella o Face ID',
                                'Confirm sensitive changes with fingerprint or Face ID',
                              ),
                              value: _autenticacionBiometrica,
                              loading: _verificandoBiometria,
                              onChanged: _onBiometricChanged,
                            ),
                          ],
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
                            icon: ThemeController.instance.isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            title: _text('Tema', 'Theme'),
                            trailingText: ThemeController.instance.isDark
                                ? _text('Oscuro', 'Dark')
                                : _text('Claro', 'Light'),
                            onTap: () => _mostrarSelectorTema(context),
                          ),
                          _buildSwitchTile(
                            icon: Icons.volume_up_outlined,
                            title: _text('Sonidos', 'Sounds'),
                            subtitle: _text(
                              'Reproduce sonidos discretos en eventos importantes',
                              'Play discreet sounds for important events',
                            ),
                            value: _sonidosActivados,
                            onChanged: _onSoundChanged,
                          ),
                          if (!_isAdmin)
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

                          if (_isAdmin) ...[
                            const SizedBox(height: 12),
                            _buildSectionTitle(
                              _text('Administración', 'Administration'),
                            ),
                            _buildAdminDescription(),
                          ],

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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarSelectorTema(BuildContext context) async {
    final selectedMode = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_text('Tema', 'Theme')),
              subtitle: Text(
                _text(
                  'Elige la apariencia de LUMI',
                  'Choose LUMI\'s appearance',
                ),
              ),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: ThemeController.instance.themeMode,
              title: Text(_text('Tema oscuro', 'Dark theme')),
              secondary: const Icon(Icons.dark_mode_outlined),
              onChanged: (mode) => Navigator.pop(sheetContext, mode),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: ThemeController.instance.themeMode,
              title: Text(_text('Tema claro', 'Light theme')),
              secondary: const Icon(Icons.light_mode_outlined),
              onChanged: (mode) => Navigator.pop(sheetContext, mode),
            ),
          ],
        ),
      ),
    );

    if (selectedMode != null) {
      await ThemeController.instance.setThemeMode(selectedMode);
    }
  }

  // --- Header con flecha de volver ---
  Widget _buildHeader(BuildContext context, AppLanguage lang) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: LumiAppTheme.primaryText(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _text('Configuración', 'Settings'),
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.primaryText(context),
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
          color: LumiAppTheme.secondaryText(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildAdminDescription() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiAppTheme.outline(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: accentPink.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _text(
                'Desde el panel administrativo puedes gestionar usuarios y aprendices, gestionar administradores, consultar estadísticas generales y revisar la información y el progreso de los usuarios, junto con las demás funciones administrativas disponibles en LUMI.',
                'From the admin panel you can manage users and learners, manage administrators, view general statistics, and review user information and progress, along with the other administrative features available in LUMI.',
              ),
              style: GoogleFonts.orbitron(
                color: LumiAppTheme.secondaryText(context),
                fontSize: Responsive.tamanioTexto(context),
                height: 1.45,
              ),
            ),
          ),
        ],
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
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.paddingHorizontalRecomendado(context) / 2,
        vertical: Responsive.espacio(context) * 0.75,
      ),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiAppTheme.outline(context), width: 1),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: loading
            ? SizedBox(
                width: Responsive.tamanioSubtitulo(context),
                height: Responsive.tamanioSubtitulo(context),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentPink,
                ),
              )
            : Icon(icon, color: accentPink.withOpacity(0.9)),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: LumiAppTheme.primaryText(context),
            fontSize: Responsive.tamanioSubtitulo(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.orbitron(
                  color: LumiAppTheme.secondaryText(context),
                  fontSize: Responsive.tamanioTexto(context) - 2,
                ),
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
        color: LumiAppTheme.surface(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiAppTheme.outline(context), width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentPink.withOpacity(0.9)),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: LumiAppTheme.primaryText(context),
            fontSize: Responsive.tamanioSubtitulo(context),
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
                  style: GoogleFonts.orbitron(
                    color: textGrey,
                    fontSize: Responsive.tamanioTexto(context) - 2,
                  ),
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
      height: Responsive.altoBoton(context),
      child: OutlinedButton.icon(
        onPressed: _cerrandoSesion
            ? null
            : () => _confirmarCerrarSesion(context, lang),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: dangerColor, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radioBorde(context)),
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
            fontSize: Responsive.tamanioTexto(context),
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

  // --- Cambio de contraseña autorizado por biometría y sesión Supabase. ---
  Future<void> _cambiarContrasena(
    BuildContext context,
    AppLanguage lang,
  ) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'La autenticación biométrica no está disponible en Web.',
              'Biometric authentication is not available on Web.',
            ),
          ),
        ),
      );
      return;
    }

    final autorizado = await _autorizarCambioConBiometria(context);
    if (!autorizado || !mounted) return;

    final actualizado = await _mostrarFormularioNuevaContrasena(context);
    if (actualizado != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Contraseña actualizada correctamente.',
            'Password updated successfully.',
          ),
        ),
      ),
    );
  }

  Future<bool> _autorizarCambioConBiometria(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              _text(
                'Cambio de contraseña por biometría',
                'Password change by biometric authentication',
              ),
              style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
            ),
            content: Text(
              _text(
                'Autoriza este cambio con la biometría configurada en tu dispositivo.',
                'Authorize this change with the biometrics configured on your device.',
              ),
              style: GoogleFonts.orbitron(color: textGrey, fontSize: 12.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  _text('Cancelar', 'Cancel'),
                  style: GoogleFonts.orbitron(color: textGrey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final soportado = await BiometricService.isDeviceSupported();
                  if (!soportado) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, false);
                    }
                    return;
                  }

                  final autenticado = await BiometricService.authenticate(
                    reason: _text(
                      'Autoriza el cambio de contraseña en LUMI',
                      'Authorize the password change in LUMI',
                    ),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, autenticado);
                  }
                },
                child: Text(
                  _text('Verificar biometría', 'Verify biometrics'),
                  style: GoogleFonts.orbitron(
                    color: accentPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool?> _mostrarFormularioNuevaContrasena(BuildContext context) async {
    final nuevaController = TextEditingController();
    final confirmacionController = TextEditingController();

    try {
      return await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          var obscureNueva = true;
          var obscureConfirmacion = true;
          var guardando = false;
          String? error;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                _text('Nueva contraseña', 'New password'),
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nuevaController,
                      obscureText: obscureNueva,
                      enabled: !guardando,
                      decoration: InputDecoration(
                        labelText: _text('Nueva contraseña', 'New password'),
                        suffixIcon: IconButton(
                          onPressed: guardando
                              ? null
                              : () => setDialogState(
                                  () => obscureNueva = !obscureNueva,
                                ),
                          icon: Icon(
                            obscureNueva
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmacionController,
                      obscureText: obscureConfirmacion,
                      enabled: !guardando,
                      decoration: InputDecoration(
                        labelText: _text(
                          'Confirmar nueva contraseña',
                          'Confirm new password',
                        ),
                        suffixIcon: IconButton(
                          onPressed: guardando
                              ? null
                              : () => setDialogState(
                                  () => obscureConfirmacion =
                                      !obscureConfirmacion,
                                ),
                          icon: Icon(
                            obscureConfirmacion
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(_text('Cancelar', 'Cancel')),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          final nueva = nuevaController.text;
                          final confirmacion = confirmacionController.text;
                          final passwordRegex = RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
                          );

                          String? validationError;
                          if (nueva.isEmpty || confirmacion.isEmpty) {
                            validationError = _text(
                              'Completa ambos campos.',
                              'Complete both fields.',
                            );
                          } else if (!passwordRegex.hasMatch(nueva)) {
                            validationError = _text(
                              'Mín. 8 caracteres, incluir mayúscula, minúscula y número.',
                              'At least 8 characters with uppercase, lowercase, and number.',
                            );
                          } else if (nueva != confirmacion) {
                            validationError = _text(
                              'Las contraseñas no coinciden.',
                              'Passwords do not match.',
                            );
                          }

                          if (validationError != null) {
                            setDialogState(() => error = validationError);
                            return;
                          }

                          setDialogState(() {
                            error = null;
                            guardando = true;
                          });

                          try {
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(password: nueva),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } on AuthException catch (exception) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                guardando = false;
                                error = exception.message;
                              });
                            }
                          } catch (_) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                guardando = false;
                                error = _text(
                                  'No se pudo actualizar la contraseña.',
                                  'The password could not be updated.',
                                );
                              });
                            }
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_text('Guardar', 'Save')),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      nuevaController.dispose();
      confirmacionController.dispose();
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
