import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import 'admin_estadisticas_screen.dart';
import 'admin_usuario_detalle_screen.dart';
import 'admin_usuarios_list_v2.dart';
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
          _adminName = '${profile['nombre'] ?? 'Admin'} ${profile['apellido'] ?? ''}'.trim();
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre del admin: $e');
    }
  }

  void _initializeRefreshTimer() {
    // Actualizar datos cada 10 segundos en tiempo real
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

      if (!mounted) return;

      setState(() {
        _summary = summary ?? {};
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final isDesktop = width >= 1024;

      final crossCount = (width ~/ 240).clamp(2, 6);

      return Scaffold(
      backgroundColor: const Color(0xFF080D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111C4A),
        foregroundColor: Colors.white,
        title: Text(
          'Panel Admin • $_adminName',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Actualizado: ${_lastUpdate.hour.toString().padLeft(2, '0')}:${_lastUpdate.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async => await _cerrarSesion(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA)))
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.paddingHorizontalRecomendado(context),
                  vertical: 20,
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C1832),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white70),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Reintentar',
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      _buildHeaderCard(width),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isDesktop ? 2.2 : 1.5,
                          children: [
                            _buildStatCard('Usuarios', _getLabel(_summary['totalUsuarios'])),
                            _buildStatCard('Estudiantes', _getLabel(_summary['estudiantes'])),
                            _buildStatCard('Admins', _getLabel(_summary['administradores'])),
                            _buildStatCard('Planes', _getLabel(_summary['totalPlanes'])),
                            _buildStatCard('Tareas', _getLabel(_summary['totalTareas'])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminEstadisticasScreen(summary: _summary, adminUserId: widget.userId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Ver estadísticas'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
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
                              child: const Text('Estudiantes'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonal(
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
                              child: const Text('Administradores'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ),
      ),
      );
    });
  }

  Widget _buildHeaderCard([double? width]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18275E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D5AFE).withValues(alpha: 0.4)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isDesktop = (width ?? constraints.maxWidth) >= 1024;

        if (isDesktop) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LUMI Admin',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Resumen operativo y gestión de usuarios del sistema.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'logo/lumii.png',
                  width: Responsive.esEscritorio(context) ? 120 : 96,
                  height: Responsive.esEscritorio(context) ? 120 : 96,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'logo/lumii.png',
                width: 84,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LUMI Admin',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Resumen operativo y gestión de usuarios del sistema.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatCard(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usuarios registrados',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: _loadData,
                child: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_usuarios.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No hay usuarios disponibles para mostrar.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _usuarios.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFF2A2F5A)),
              itemBuilder: (context, index) {
                final usuario = _usuarios[index] as Map<String, dynamic>;
                final nombre = (usuario['nombre'] ?? 'Usuario').toString();
                final apellido = (usuario['apellido'] ?? '').toString();
                final fecha = usuario['fecha_registro']?.toString() ?? 'Sin fecha';
                final tareas = usuario['tareas_completadas'] ?? 0;
                final racha = usuario['racha'] ?? 0;

                final userId = (usuario['id'] ?? '').toString();

                return ListTile(
                  onTap: userId.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUsuarioDetalleScreen(
                                adminUserId: widget.userId,
                                targetUserId: userId,
                              ),
                            ),
                          );
                        },
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF44AA),
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    '$nombre $apellido'.trim(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Registrado: $fecha\nTareas completadas: $tareas • Racha: $racha',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
