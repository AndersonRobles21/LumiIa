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
                          color: const Color(0xFF1F1A3A).withOpacity(0.4),
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
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _tareasPendientes.length,
                                    itemBuilder: (context, index) {
                                      final t = _tareasPendientes[index];
                                      final nombre = (t['nombre'] ?? '')
                                          .toString();
                                      final fecha = t['fecha_creacion'] != null
                                          ? _formatFecha(
                                              t['fecha_creacion'].toString(),
                                            )
                                          : '';
                                      return GestureDetector(
                                        onTap: () async {
                                          final planId =
                                              t['id'] ?? t['plan_id'];
                                          if (planId != null) {
                                            final Map<String, dynamic>
                                            datosSeguros = {
                                              'id': planId,
                                              'nombre':
                                                  t['nombre'] ??
                                                  t['titulo'] ??
                                                  'Sin título',
                                            };

                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    GuiaDetalleScreen(
                                                      guiaData: datosSeguros,
                                                    ),
                                              ),
                                            );
                                            _cargarPlanes();
                                          }
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
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
                                                        color: Color(
                                                          0xFFFF44AA,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        nombre.toUpperCase(),
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.arrow_forward_ios,
                                                    color: Colors.white24,
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
                                color: const Color(0xFF1F1A3A).withOpacity(0.4),
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
                              color: const Color(0xFF1F1A3A).withOpacity(0.4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  height:
                                      80 * (_racha > 0 ? (_racha % 7) / 7 : 0),
                                  color: const Color(
                                    0xFFFF44AA,
                                  ).withOpacity(0.7),
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
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1A3A).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
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
                                            fontSize: 11,
                                          ),
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
                                    child: const Icon(
                                      Icons.timer_outlined,
                                      color: Colors.orangeAccent,
                                      size: 26,
                                    ),
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
                              color: const Color(0xFF1F1A3A).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                          ),
                        ],
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

  String _formatFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr).toLocal();
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return '';
    }
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
            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white38,
              size: 24,
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
                    builder: (_) => ProfileScreen(userId: widget.userId),
                  ),
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