import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'admin_estadisticas_screen.dart';
import 'admin_usuario_detalle_screen.dart';
import 'admin_usuarios_list_v2.dart';
import 'configuracion_screen.dart';
import 'dart:async';

import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final String userId;

  const AdminPanelScreen({super.key, required this.userId});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _profileAlerts = [];
  List<dynamic> _usuarios = [];
  String? _errorMessage;
  late Timer _refreshTimer;
  DateTime _lastUpdate = DateTime.now();
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _loadData();
    _initializeRefreshTimer();
  }

  Future<void> _loadAdminName() async {
    try {
      final profile = await ApiService.getProfile(widget.userId);
      if (profile != null && mounted) {
        setState(() {
          _adminName =
              '${profile['nombre'] ?? 'Admin'} ${profile['apellido'] ?? ''}'
                  .trim();
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre del admin: $e');
    }
  }

  void _initializeRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Error cerrando sesión desde panel: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final summary = await ApiService.getAdminSummary(widget.userId);
      final profileAlerts = await ApiService.getProfileAlerts(widget.userId);

      if (!mounted) return;

      setState(() {
        _summary = summary ?? {};
        _profileAlerts = profileAlerts;
        _loading = false;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _getLabel(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toString();
    return value.toString();
  }

  String _getFormattedDate() {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[_lastUpdate.month - 1]} ${_lastUpdate.day}, ${_lastUpdate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1024;
        final crossCount = (width ~/ 260).clamp(2, 4);

        return Scaffold(
          backgroundColor: LumiAppTheme.pageBackground(context),
          appBar: AppBar(
            backgroundColor: LumiAppTheme.surface(context),
            elevation: 0,
            title: Text(
              'Panel de control • Administrador',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: LumiAppTheme.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF4A2A68).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Sincronizado: ${_lastUpdate.hour.toString().padLeft(2, '0')}:${_lastUpdate.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        color: LumiAppTheme.secondaryText(context),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Configuración',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfiguracionScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white70,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () async => await _cerrarSesion(context),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF4D79),
                ),
              ),
            ],
          ),
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF716DC),
                        strokeWidth: 3,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.paddingHorizontalRecomendado(
                          context,
                        ),
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF3A1B2A,
                                ).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFCC3355),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFFF4D79),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.orbitron(
                                        color: LumiAppTheme.primaryText(
                                          context,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Reintentar',
                                    onPressed: _loadData,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Banner de Bienvenida Estilo Cyberpunk
                          _buildHeaderCard(width),
                          const SizedBox(height: 24),
                          _buildProfileAlerts(),
                          if (_profileAlerts.isNotEmpty)
                            const SizedBox(height: 24),

                          // Cuadrícula de Estadísticas
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: isDesktop ? 144 : 142,
                                ),
                            itemCount: 4,
                            itemBuilder: (context, index) => [
                              _buildStatCard(
                                'Estudiantes totales',
                                _getLabel(_summary['totalUsuarios']),
                                Icons.school_outlined,
                                'Registrados',
                              ),
                              _buildStatCard(
                                'Estudiantes activos',
                                _getLabel(_summary['estudiantes']),
                                Icons.verified_user_outlined,
                                'En línea ahora',
                              ),
                              _buildStatCard(
                                'Planes generados',
                                _getLabel(_summary['totalPlanes']),
                                Icons.assignment_outlined,
                                'IA activa',
                              ),
                              _buildStatCard(
                                'Estado del sistema',
                                'Óptimo',
                                Icons.psychology_outlined,
                                'Latencia: 42ms',
                              ),
                            ][index],
                          ),
                          const SizedBox(height: 28),

                          // Botones de Acción Rápida (Estadísticas y Gestión)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminEstadisticasScreen(
                                        summary: _summary,
                                        adminUserId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E142C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFF716DC,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: Color(0xFFF716DC),
                                ),
                                label: Text(
                                  'Ver estadísticas completas',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Accesos a Listas de Usuarios
                          Text(
                            'Gestión de usuarios',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final estudiantes = _buildActionButton(
                                title: 'Estudiantes',
                                icon: Icons.group_rounded,
                                gradientColors: const [
                                  Color(0xFFF716DC),
                                  Color(0xFFA41CF9),
                                ],
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUsuariosListV2(
                                        adminUserId: widget.userId,
                                        onlyAdmins: false,
                                      ),
                                    ),
                                  );
                                },
                              );
                              final administradores = _buildActionButton(
                                title: 'Administradores',
                                icon: Icons.admin_panel_settings_rounded,
                                gradientColors: const [
                                  Color(0xFF0F1D8A),
                                  Color(0xFF102CE4),
                                ],
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUsuariosListV2(
                                        adminUserId: widget.userId,
                                        onlyAdmins: true,
                                      ),
                                    ),
                                  );
                                },
                              );

                              if (constraints.maxWidth < 560) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: estudiantes,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: administradores,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: estudiantes),
                                  const SizedBox(width: 16),
                                  Expanded(child: administradores),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(double width) {
    final isDesktop = width >= 1024;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4A2A68).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF716DC).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFormattedDate(),
                  style: GoogleFonts.orbitron(
                    color: LumiAppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Panel de control - Administrador',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFF716DC),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenido otra vez, $_adminName',
                  style: GoogleFonts.orbitron(
                    color: LumiAppTheme.primaryText(context),
                    fontSize: isDesktop ? 26 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitoreo del sistema de LUMI a tiempo real',
                  style: GoogleFonts.orbitron(
                    color: LumiAppTheme.secondaryText(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF716DC).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'logo/Lumi.png',
                width: isDesktop ? 110 : 80,
                height: isDesktop ? 110 : 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAlerts() {
    if (_profileAlerts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LumiAppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF44AA).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFFF8ACB),
              ),
              SizedBox(width: 8),
              Text(
                'Alertas de tu perfil',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._profileAlerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• ${(alert['mensaje'] ?? 'Se actualizó tu perfil.').toString()}',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String titulo,
    String valor,
    IconData icon,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4A2A68).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.orbitron(
                    color: LumiAppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFFF716DC), size: 20),
            ],
          ),
          Text(
            valor,
            style: GoogleFonts.orbitron(
              color: LumiAppTheme.primaryText(context),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.orbitron(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: gradientColors),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(icon, color: Colors.white, size: 19),
          label: Flexible(
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
