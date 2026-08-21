import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'historial_ia_screen.dart';
import 'profile_screen.dart';

class RecompensasScreen extends StatefulWidget {
  final String userId;

  const RecompensasScreen({super.key, required this.userId});

  @override
  State<RecompensasScreen> createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends State<RecompensasScreen> {
  bool _isLoading = true;
  int _totalTareas = 0;
  int _completadas = 0;
  int _pendientes = 0;
  int _puntos = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    final tareas = await ApiService.getPlanesEstudio(widget.userId) ?? const [];
    final stats = await ApiService.getEstadisticas(widget.userId);

    if (!mounted) return;

    final lista = tareas.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    final completadas = lista.where((item) {
      final estado = (item['estado'] ?? item['completada'] ?? '').toString().toUpperCase();
      return item['completada'] == true || estado == 'COMPLETADA';
    }).length;

    final total = lista.length;
    final puntos = completadas * 100;

    setState(() {
      _totalTareas = total;
      _completadas = completadas;
      _pendientes = total - completadas;
      _puntos = stats != null ? ((stats['tareas_completadas'] ?? 0) as int) * 100 : puntos;
      _isLoading = false;
    });
  }

  String get _nivelActual {
    if (_puntos >= 1000) return 'Legendario';
    if (_puntos >= 600) return 'Experto';
    if (_puntos >= 300) return 'Avanzado';
    if (_puntos >= 100) return 'Principiante';
    return 'Nuevo';
  }

  double get _progresoNivel {
    const niveles = [0, 100, 300, 600, 1000];
    for (int i = 0; i < niveles.length - 1; i++) {
      final actual = niveles[i];
      final siguiente = niveles[i + 1];
      if (_puntos >= actual && _puntos < siguiente) {
        final progreso = (_puntos - actual) / (siguiente - actual);
        return progreso.clamp(0.0, 1.0).toDouble();
      }
    }
    return 1.0;
  }

  String get _textoSiguienteNivel {
    const niveles = [
      {'nombre': 'Nuevo', 'puntos': 0},
      {'nombre': 'Principiante', 'puntos': 100},
      {'nombre': 'Avanzado', 'puntos': 300},
      {'nombre': 'Experto', 'puntos': 600},
      {'nombre': 'Legendario', 'puntos': 1000},
    ];

    for (int i = 0; i < niveles.length - 1; i++) {
      final actual = niveles[i]['puntos'] as int;
      final siguiente = niveles[i + 1]['puntos'] as int;
      final nombre = niveles[i + 1]['nombre'] as String;
      if (_puntos >= actual && _puntos < siguiente) {
        return 'Faltan ${siguiente - _puntos} pts para llegar a $nombre';
      }
    }

    return '¡Ya alcanzaste el máximo nivel!';
  }

  List<Map<String, dynamic>> get _logros {
    return [
      {'titulo': 'Primera', 'icon': Icons.emoji_events_outlined, 'activo': _puntos >= 100},
      {'titulo': 'Ritmo', 'icon': Icons.flash_on_rounded, 'activo': _puntos >= 300},
      {'titulo': 'Constancia', 'icon': Icons.verified_rounded, 'activo': _puntos >= 600},
      {'titulo': 'Leyenda', 'icon': Icons.stars_rounded, 'activo': _puntos >= 1000},
    ];
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
                backgroundColor: const Color(0xFF1F1A3A),
                onRefresh: _cargarDatos,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recompensas',
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
                          color: const Color(0xFF1F1A3A).withOpacity(0.45),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: Color(0xFFFF44AA)),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Nivel $_nivelActual',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
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
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2E1B4E), Color(0xFF1F1A3A)],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF44AA),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.emoji_events,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Progreso de nivel',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(999),
                                                child: LinearProgressIndicator(
                                                  minHeight: 10,
                                                  value: _progresoNivel,
                                                  backgroundColor: Colors.white12,
                                                  color: const Color(0xFF69E6FF),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _textoSiguienteNivel,
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _metricCard('Tareas', '$_totalTareas'),
                                      _metricCard('Hechas', '$_completadas'),
                                      _metricCard('Faltan', '$_pendientes'),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Logros',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _logros.map((logro) {
                                      final activo = logro['activo'] as bool;
                                      return Container(
                                        width: 95,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: activo
                                              ? const Color(0xFF2E1B4E).withValues(alpha: 0.9)
                                              : Colors.white.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: activo ? const Color(0xFFFF44AA) : Colors.white12,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              logro['icon'] as IconData,
                                              color: activo ? const Color(0xFFFF44AA) : Colors.white38,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              logro['titulo'] as String,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: activo ? Colors.white : Colors.white38,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
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
                      child: const Icon(Icons.psychology_outlined, color: Colors.white38, size: 24),
                    ),
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFFF44AA), size: 24),
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

  Widget _metricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
}
