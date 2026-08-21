import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'guia_detalle_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';
import 'recompensas_screen.dart';

class HistorialIAScreen extends StatefulWidget {
  final String userId;

  const HistorialIAScreen({super.key, required this.userId});

  @override
  State<HistorialIAScreen> createState() => _HistorialIAScreenState();
}

class _HistorialIAScreenState extends State<HistorialIAScreen> {
  bool _isLoading = true;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    final lista = await ApiService.obtenerHistorial(widget.userId);

    if (mounted) {
      setState(() {
        _historial = lista ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirPlan(String planId) async {
    setState(() => _isLoading = true);

    final plan = await ApiService.obtenerPlan(planId);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el plan seleccionado.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuiaDetalleScreen(
          guiaData: plan,
          userId: widget.userId,
        ),
      ),
    );
  }

  String _formatFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr).toLocal();
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (_) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                color: const Color(0xFFFF44AA),
                onRefresh: _cargarHistorial,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          children: const [
                            Text(
                              'Aquí verás tus planes de IA generados previamente.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Selecciona uno para revisarlo en detalle.',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFF44AA)),
                        )
                      else if (_historial.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No hay planes de IA guardados aún.',
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _historial.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final plan = _historial[index];
                            final fecha = plan['fecha_creacion'] != null
                                ? _formatFecha(plan['fecha_creacion'].toString())
                                : '';
                            final subtareas = plan['subtareas'] is List ? plan['subtareas'] as List : const [];
                            final totalTareas = subtareas.length;
                            final completadas = subtareas.whereType<Map>().where((item) {
                              final estado = (item['estado'] ?? item['completada'] ?? '').toString().toUpperCase();
                              return item['completada'] == true || estado == 'COMPLETADA';
                            }).length;
                            final pendientes = totalTareas - completadas;

                            return GestureDetector(
                              onTap: () {
                                final planId = plan['id']?.toString();
                                if (planId != null) {
                                  _abrirPlan(planId);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1A3A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['nombre'] ?? 'Plan de estudio',
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      plan['descripcion'] ?? '',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$completadas/$totalTareas completadas · $pendientes pendientes',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          plan['metodo_estudio'] ?? '',
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                                        ),
                                        Text(
                                          fecha,
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
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
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1437),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => DashboardScreen(userId: widget.userId)),
                        );
                      },
                      child: const Icon(Icons.home_outlined, color: Colors.white38, size: 24),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final tasks = await ApiService.getPlanesEstudio(widget.userId) ?? [];
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CalendarScreen(userId: widget.userId, tasks: tasks),
                          ),
                        );
                      },
                      child: const Icon(Icons.calendar_month_outlined, color: Colors.white38, size: 24),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HistorialIAScreen(userId: widget.userId)),
                        );
                      },
                      child: const Icon(Icons.psychology_outlined, color: Color(0xFFFF44AA), size: 24),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => RecompensasScreen(userId: widget.userId)),
                        );
                      },
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.white38, size: 24),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.userId)),
                        );
                      },
                      child: const Icon(Icons.person_outline, color: Colors.white38, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
