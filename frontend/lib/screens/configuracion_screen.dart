import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'info_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesPush = true;
  bool _recordatoriosDiarios = true;
  bool _autenticacionBiometrica = false;
  bool _cerrandoSesion = false;

  static const Color bgDark = Color(0xFF0B0813);
  static const Color cardColor = Color(0xFF1F1A3A);
  static const Color accentPink = Color(0xFFFF44AA);
  static const Color textGrey = Color(0xFFB0AEC4);
  static const Color dangerColor = Color(0xFFE23E57);

  @override
  Widget build(BuildContext context) {
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
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── NOTIFICACIONES ──────────────────────────────
                          _buildSectionTitle('Notificaciones'),
                          _buildSwitchTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Notificaciones push',
                            subtitle: 'Avisos de actividades y tareas pendientes',
                            value: _notificacionesPush,
                            onChanged: (v) =>
                                setState(() => _notificacionesPush = v),
                          ),
                          _buildSwitchTile(
                            icon: Icons.alarm_outlined,
                            title: 'Recordatorios diarios',
                            subtitle:
                                'Recibe un recordatorio de tu horario de estudio',
                            value: _recordatoriosDiarios,
                            onChanged: (v) =>
                                setState(() => _recordatoriosDiarios = v),
                          ),

                          const SizedBox(height: 12),

                          // ── SEGURIDAD ────────────────────────────────────
                          _buildSectionTitle('Seguridad'),
                          _buildSwitchTile(
                            icon: Icons.fingerprint,
                            title: 'Inicio con biometría',
                            subtitle: 'Usa huella o Face ID para entrar a Lumi',
                            value: _autenticacionBiometrica,
                            onChanged: (v) =>
                                setState(() => _autenticacionBiometrica = v),
                          ),
                          _buildNavTile(
                            icon: Icons.lock_reset_outlined,
                            title: 'Cambiar contraseña',
                            onTap: () {
                              // TODO: pantalla de cambio de contraseña
                            },
                          ),
                          _buildNavTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacidad y datos',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => InfoScreen.privacidad()),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // ── PREFERENCIAS ─────────────────────────────────
                          _buildSectionTitle('Preferencias'),
                          _buildNavTile(
                            icon: Icons.language_outlined,
                            title: 'Idioma',
                            trailingText: 'Español',
                            onTap: () {
                              // TODO: selector de idioma
                            },
                          ),
                          _buildNavTile(
                            icon: Icons.school_outlined,
                            title: 'Métodos de estudio preferidos',
                            onTap: () {
                              // TODO: editar métodos vinculados a metodos_estudio
                            },
                          ),

                          const SizedBox(height: 12),

                          // ── SOPORTE ──────────────────────────────────────
                          _buildSectionTitle('Soporte'),
                          _buildNavTile(
                            icon: Icons.help_outline,
                            title: 'Centro de ayuda',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => InfoScreen.ayuda()),
                              );
                            },
                          ),
                          _buildNavTile(
                            icon: Icons.info_outline,
                            title: 'Acerca de Lumi',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => InfoScreen.acercaDe()),
                              );
                            },
                          ),

                          const SizedBox(height: 28),
                          _buildLogoutButton(context),
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

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
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
              'Configuración',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
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
        secondary: Icon(icon, color: accentPink.withOpacity(0.9)),
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
                style:
                    GoogleFonts.orbitron(color: textGrey, fontSize: 10.5),
              )
            : null,
        value: value,
        activeColor: accentPink,
        onChanged: onChanged,
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

  // ── BOTÓN CERRAR SESIÓN ───────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed:
            _cerrandoSesion ? null : () => _confirmarCerrarSesion(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: dangerColor, width: 1.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        icon: _cerrandoSesion
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: dangerColor, strokeWidth: 2),
              )
            : const Icon(Icons.logout, color: dangerColor),
        label: Text(
          'Cerrar sesión',
          style: GoogleFonts.orbitron(
            color: dangerColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          '¿Cerrar sesión?',
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Tendrás que volver a iniciar sesión para acceder a tu cuenta.',
          style: GoogleFonts.orbitron(color: textGrey, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.orbitron(color: textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Cerrar sesión',
              style: GoogleFonts.orbitron(
                  color: dangerColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _cerrarSesion(context);
    }
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
