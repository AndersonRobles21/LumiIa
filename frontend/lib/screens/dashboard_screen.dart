import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'historial_ia_screen.dart';
import 'profile_screen.dart';
import 'agregar_tarea_screen.dart';
import 'guia_detalle_screen.dart';
import 'calendar_screen.dart';
import 'recompensas_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _tareasPendientes = [];
  List<dynamic> _todasLasTareas = [];
  int _racha = 0;
  int _tareasCompletadas = 0;
  int _puntos = 0;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _isLoading = true);
    await Future.wait([_cargarPlanes(), _cargarEstadisticas()]);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarPlanes() async {
    final lista = await ApiService.getPlanesEstudio(widget.userId);
    if (mounted) {
      final tareas = (lista ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final pendientes = tareas.where((item) {
        final estado = (item['estado'] ?? item['completada'] ?? '').toString().toUpperCase();
        final completada = item['completada'] == true || estado == 'COMPLETADA';
        return !completada;
      }).toList();

      pendientes.sort((a, b) {
        final fechaA = _fechaOrden(a);
        final fechaB = _fechaOrden(b);
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        _todasLasTareas = tareas;
        _tareasPendientes = pendientes.take(3).toList();
        _tareasCompletadas = tareas.where((item) {
          final estado = (item['estado'] ?? item['completada'] ?? '').toString().toUpperCase();
          return item['completada'] == true || estado == 'COMPLETADA';
        }).length;
        _puntos = _tareasCompletadas * 100;
      });
    }
  }

  Future<void> _cargarEstadisticas() async {
    final stats = await ApiService.getEstadisticas(widget.userId);
    if (mounted && stats != null) {
      final completadas = (stats['tareas_completadas'] ?? 0) as int;
      setState(() {
        _racha = (stats['racha'] ?? 0) as int;
        _tareasCompletadas = completadas;
        _puntos = completadas * 100;
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

  @override
  Widget build(BuildContext context) {
    final diaActual = _racha;
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
                color: const Color(0xFFFF44AA),
                backgroundColor: const Color(0xFF1F1A3A),
                onRefresh: _cargarTodo,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tu plan de estudio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // TRABAJOS PENDIENTES
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1A3A).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
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
                                          userId: widget.userId,
                                        ),
                                      ),
                                    );
                                    _cargarPlanes();
                                  },
                                  child: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFFFF44AA),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFF44AA),
                                    ),
                                  )
                                : _tareasPendientes.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No hay tareas agregadas.\nToca el "+" para crear una.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white30,
                                          fontSize: 12,
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _tareasPendientes.length,
                                        itemBuilder: (context, index) {
                                          final t = _tareasPendientes[index];
                                          final nombre = (t['nombre'] ?? t['titulo'] ?? 'Tarea').toString();

                                          return GestureDetector(
                                            onTap: () async {
                                              final planId = t['id'] ?? t['plan_id'];
                                              if (planId != null) {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => GuiaDetalleScreen(
                                                      guiaData: t,
                                                      userId: widget.userId,
                                                    ),
                                                  ),
                                                );
                                                _cargarPlanes();
                                              }
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.only(bottom: 10.0),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1F1A3A).withValues(alpha: 0.6),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: Colors.white12),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      nombre,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Color(0xFF69E6FF),
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.arrow_forward_ios,
                                                    color: Colors.white38,
                                                    size: 12,
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

                      // LA RACHA DE HOY
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
                            child: const Text(
                              '+ MARCAR DÍA',
                              style: TextStyle(
                                color: Color(0xFFFF44AA),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1A3A).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        diaActual == 0
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
                                        diaActual == 0
                                            ? 'DÍA 0'
                                            : 'DÍA $diaActual',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        diaActual == 0
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
                                      diaActual == 0 ? '⭐' : '🔥',
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
                              color: const Color(0xFF1F1A3A).withValues(alpha: 0.4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  height: 80 * (_racha > 0 ? (_racha % 7) / 7 : 0),
                                  color: const Color(0xFFFF44AA).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // IA ESTADISTICAS
                      const Text(
                        'IA Estadisticas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1A3A).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progreso total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$_puntos pts',
                                  style: const TextStyle(
                                    color: Color(0xFFFF44AA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _miniMetric('Creadas', '${_todasLasTareas.length}'),
                                _miniMetric('Completas', '$_tareasCompletadas'),
                                _miniMetric('Faltan', '${_todasLasTareas.length - _tareasCompletadas}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 10,
                                value: _todasLasTareas.isEmpty ? 0 : (_tareasCompletadas / _todasLasTareas.length),
                                backgroundColor: Colors.white12,
                                color: const Color(0xFFFF44AA),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$_tareasCompletadas de ${_todasLasTareas.length} tareas completadas',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E1B4E), Color(0xFF1F1A3A)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.emoji_events, color: Color(0xFFFF44AA)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Recompensas: cada tarea completada suma 100 puntos.',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              _buildBottomNavbar(),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _fechaOrden(Map<String, dynamic> item) {
    final raw = item['fecha_creacion'] ?? item['created_at'] ?? item['fecha_entrega'] ?? item['fechaEntrega'] ?? '';
    if (raw is String && raw.isNotEmpty) {
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _miniMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1437),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.home, color: Color(0xFFFF44AA), size: 24),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarScreen(userId: widget.userId, tasks: _tareasPendientes),
                  ),
                );
              },
              child: const Icon(Icons.calendar_month_outlined, color: Colors.white38, size: 24),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialIAScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white38,
                size: 24,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecompensasScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white38, size: 24),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.userId)),
                );
              },
              child: const Icon(
                Icons.person_outline,
                color: Colors.white38,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
