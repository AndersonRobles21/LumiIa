import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'historial_ia_screen.dart';
import 'profile_screen.dart';
import 'agregar_tarea_screen.dart';
import 'guia_detalle_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _tareasPendientes = [];
  int _racha = 0;
  int _tareasCompletadas = 0;
  String _nombreUsuario = '';
  int _currentNavIndex = 0;

  static const Color _pink = Color(0xFFFF44AA);
  static const Color _cardBg = Color(0xFF1F1A3A);

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _cargarPlanes(),
      _cargarEstadisticas(),
      _cargarPerfil(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarPerfil() async {
    final data = await ApiService.getProfile(widget.userId);
    if (mounted && data != null) {
      setState(() {
        _nombreUsuario = data['nombre'] ?? '';
      });
    }
  }

  Future<void> _cargarPlanes() async {
    final lista = await ApiService.getPlanesEstudio(widget.userId);
    if (mounted) {
      setState(() {
        _tareasPendientes = lista ?? [];
      });
    }
  }

  Future<void> _cargarEstadisticas() async {
    final stats = await ApiService.getEstadisticas(widget.userId);
    if (mounted && stats != null) {
      setState(() {
        _racha = (stats['racha'] ?? 0) as int;
        _tareasCompletadas = (stats['tareas_completadas'] ?? 0) as int;
      });
    }
  }

  Future<void> _registrarEstudioHoy() async {
    final ok = await ApiService.registrarRachaHoy(widget.userId);
    if (ok) {
      await _cargarEstadisticas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔥 ¡Racha actualizada!'),
            backgroundColor: Color(0xFF2E1B4E),
          ),
        );
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => HistorialIAScreen(userId: widget.userId)),
      );
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.userId)),
      ).then((_) => _cargarPerfil());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaSiguiente = _racha + 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14002A), Color(0xFF0B0813)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                color: _pink,
                backgroundColor: _cardBg,
                onRefresh: _cargarTodo,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── HEADER ────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_nombreUsuario.isNotEmpty)
                                  Text(
                                    'Hola, $_nombreUsuario 👋',
                                    style: const TextStyle(
                                      color: Color(0xFFB0AEC4),
                                      fontSize: 13,
                                    ),
                                  ),
                                const Text(
                                  'Tu plan de estudio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: Colors.white, size: 26),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── TRABAJOS PENDIENTES ───────────────────────────────
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Trabajos pendientes (${_tareasPendientes.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AgregarTareaScreen(
                                            userId: widget.userId),
                                      ),
                                    );
                                    _cargarPlanes();
                                  },
                                  child: const Icon(Icons.add_circle_outline,
                                      color: _pink, size: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isLoading)
                              const Center(
                                child: CircularProgressIndicator(color: _pink),
                              )
                            else if (_tareasPendientes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: Text(
                                    'No hay tareas agregadas.\nToca el "+" para crear una.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white30, fontSize: 12),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _tareasPendientes.length,
                                itemBuilder: (context, index) {
                                  final t = _tareasPendientes[index];
                                  final nombre =
                                      (t['nombre'] ?? '').toString();
                                  final fecha = t['fecha_creacion'] != null
                                      ? _formatFecha(
                                          t['fecha_creacion'].toString())
                                      : '';
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GuiaDetalleScreen(
                                            planId: t['id']?.toString() ?? '',
                                            userId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    color: _pink,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    nombre.toUpperCase(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                fecha,
                                                style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 11),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: Colors.white24,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── RACHA DE HOY ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LA RACHA DE HOY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: _registrarEstudioHoy,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _pink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: _pink.withOpacity(0.4)),
                              ),
                              child: const Text(
                                '+ MARCAR DÍA',
                                style: TextStyle(
                                  color: _pink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _racha == 0
                                            ? '¡EMPIEZA HOY!'
                                            : 'MAÑANA DÍA $diaSiguiente',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _racha == 0 ? 'DÍA 0' : 'DÍA $_racha',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _racha == 0
                                            ? 'Toca "+ MARCAR DÍA" para iniciar'
                                            : '$_tareasCompletadas tareas completadas',
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2E1B4E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _racha == 0 ? '⭐' : '🔥',
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                              color: _cardBg.withOpacity(0.4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  height: 80 *
                                      (_racha > 0 ? (_racha % 7) / 7 : 0),
                                  color: _pink.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── IA ESTADÍSTICAS ───────────────────────────────────
                      const Text(
                        'IA Estadísticas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TU PROGRESO EN TUS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Text(
                                          'TAREAS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$_tareasCompletadas tareas completadas • racha de $_racha días',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E1B4E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.timer_outlined,
                                        color: Colors.orangeAccent, size: 26),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                              color: _cardBg.withOpacity(0.4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  height: _tareasCompletadas > 0
                                      ? 110 *
                                          (_tareasCompletadas /
                                              (_tareasCompletadas + 1))
                                      : 0,
                                  color: Colors.orangeAccent.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── ACCESO RÁPIDO ─────────────────────────────────────
                      const Text(
                        'Acceso rápido',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAccess(
                              icon: Icons.add_task,
                              label: 'Nueva tarea',
                              color: _pink,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AgregarTareaScreen(
                                        userId: widget.userId),
                                  ),
                                );
                                _cargarPlanes();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAccess(
                              icon: Icons.psychology_outlined,
                              label: 'Historial IA',
                              color: Colors.purpleAccent,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HistorialIAScreen(userId: widget.userId),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── BOTTOM NAVBAR ─────────────────────────────────────────
              _buildBottomNavbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildQuickAccess({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr).toLocal();
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildBottomNavbar() {
    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Inicio'),
      _NavItem(icon: Icons.calendar_month_outlined, label: 'Calendario'),
      _NavItem(icon: Icons.psychology_outlined, label: 'IA'),
      _NavItem(icon: Icons.person_outline, label: 'Perfil'),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1437),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final active = index == _currentNavIndex;
            return GestureDetector(
              onTap: () => _onNavTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _pink.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      navItems[index].icon,
                      color: active ? _pink : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      navItems[index].label,
                      style: TextStyle(
                        color: active ? _pink : Colors.white38,
                        fontSize: 9,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
