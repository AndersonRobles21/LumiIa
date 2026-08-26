import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '/services/api_service.dart';
import 'gamification_screen.dart';
import 'app_bottom_navbar.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarScreen extends StatefulWidget {
  final String userId;
  final List<dynamic> tasks;

  const CalendarScreen({super.key, required this.userId, required this.tasks});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _eventsByDay = {};
  bool _isLoading = false;
  bool _localeReady = false;

  static const Map<String, Color> _tipoColores = {
    'Examen': Color(0xFFFF4D94),
    'Proyecto': Color(0xFFFF9E00),
    'Trabajos': Color(0xFF9D4EDD),
  };

  @override
  void initState() {
    super.initState();
    // NOTA: normalizamos a UTC para que coincida con firstDay/lastDay
    // (DateTime.utc) y con las claves de _eventsByDay. Mezclar UTC y
    // hora local es lo que causaba el desplazamiento de días.
    final hoy = DateTime.now();
    _selectedDay = DateTime.utc(hoy.year, hoy.month, hoy.day);
    _focusedDay = DateTime.utc(hoy.year, hoy.month, hoy.day);
    _buildEventsFromList(widget.tasks);
    _initLocaleAndData();
  }

  Future<void> _initLocaleAndData() async {
    try {
      await initializeDateFormatting('es_ES', null);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _localeReady = true);
    await _cargarTareas();
  }

  // Devuelve siempre una fecha "solo día" en UTC (medianoche UTC),
  // usada como clave única para eventos y comparaciones del calendario.
  DateTime? _parsearFecha(dynamic fechaRaw) {
    if (fechaRaw == null) return null;
    final str = fechaRaw.toString().trim();
    if (str.isEmpty) return null;

    // Caso más común: fechas tipo "YYYY-MM-DD..." (ISO). Extraemos
    // año/mes/día directamente del string para evitar que DateTime.parse
    // interprete zona horaria y desplace el día.
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(str);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return DateTime.utc(year, month, day);
    }

    try {
      final parsed = DateTime.parse(str).toLocal();
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  void _buildEventsFromList(List<dynamic> tasks) {
    final events = <DateTime, List<dynamic>>{};
    final hoy = DateTime.now();
    final hoyNormalizado = DateTime.utc(hoy.year, hoy.month, hoy.day);

    for (final task in tasks) {
      final fechaEntregaRaw = task['fecha_entrega'] ?? task['fechaEntrega'];
      final fechaLimite = _parsearFecha(fechaEntregaRaw);
      if (fechaLimite == null) continue;

      final fechaCreacionRaw = task['created_at'] ?? task['fecha_creacion'] ?? task['fechaCreacion'];
      DateTime fechaInicio = _parsearFecha(fechaCreacionRaw) ?? hoyNormalizado;

      if (fechaInicio.isAfter(fechaLimite)) {
        fechaInicio = fechaLimite;
      }

      DateTime cursor = fechaInicio;
      while (!cursor.isAfter(fechaLimite)) {
        final key = DateTime.utc(cursor.year, cursor.month, cursor.day);
        events.putIfAbsent(key, () => []).add(task);
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    setState(() => _eventsByDay = events);
  }

  Future<void> _cargarTareas() async {
    setState(() => _isLoading = true);

    final tareasManuales = await ApiService.getPlanesEstudio(widget.userId) ?? [];
    final historialIA = await ApiService.obtenerHistorial(widget.userId) ?? [];
    final historialConFecha = await _completarFechasHistorial(historialIA);

    if (!mounted) return;

    final todasLasTareas = <dynamic>[...tareasManuales, ...historialConFecha];

    setState(() {
      _isLoading = false;
      _buildEventsFromList(
        todasLasTareas.isNotEmpty ? todasLasTareas : widget.tasks,
      );
    });

    _seleccionarDiaInicial();
  }

  Future<List<dynamic>> _completarFechasHistorial(List<dynamic> historial) async {
    final resultado = <dynamic>[];

    for (final item in historial) {
      if (item is! Map) continue;

      final fechaActual = item['fecha_entrega'] ?? item['fechaEntrega'];
      final tieneFecha = fechaActual != null && fechaActual.toString().isNotEmpty;

      if (tieneFecha) {
        resultado.add(item);
        continue;
      }

      final id = item['id']?.toString();
      if (id == null) {
        resultado.add(item);
        continue;
      }

      final planCompleto = await ApiService.obtenerPlan(id);
      if (planCompleto != null) {
        final combinado = Map<String, dynamic>.from(item)..addAll(planCompleto);
        resultado.add(combinado);
      } else {
        resultado.add(item);
      }
    }

    return resultado;
  }

  void _seleccionarDiaInicial() {
    final hoy = DateTime.now();
    final hoyKey = DateTime.utc(hoy.year, hoy.month, hoy.day);
    _fijarDiaSeleccionado(hoyKey);
  }

  void _fijarDiaSeleccionado(DateTime dia) {
    if (!mounted) return;
    setState(() {
      _selectedDay = dia;
      _focusedDay = dia;
    });
  }

  List<dynamic> _getTasksForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _eventsByDay[key] ?? [];
  }

  String _formatDateHeader(DateTime day) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${day.day} de ${meses[day.month - 1]} ${day.year}';
  }

  Color _colorParaTarea(Map task) {
    final tipo = _tipoNombreTarea(task);
    return _tipoColores[tipo]!;
  }

  String _tipoNombreTarea(Map task) {
    final nombre = (task['nombre'] ?? task['titulo'] ?? '').toString().toLowerCase();
    final tipo = (task['tipo'] ?? '').toString();

    if (tipo == 'Examen' || tipo == 'Proyecto' || tipo == 'Trabajos') {
      return tipo;
    }

    if (nombre.contains('examen') || nombre.contains('parcial') || nombre.contains('quiz')) {
      return 'Examen';
    } else if (nombre.contains('proyecto')) {
      return 'Proyecto';
    }
    
    return 'Trabajos';
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF03020A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9D4EDD),
          ),
        ),
      );
    }

    final selectedTasks = _selectedDay == null
        ? const <dynamic>[]
        : _getTasksForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: const Color(0xFF03020A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D061A), Color(0xFF03020A)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                color: const Color(0xFF9D4EDD),
                backgroundColor: const Color(0xFF13092A),
                onRefresh: _cargarTareas,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ENCABEZADO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Calendario',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Organiza tu tiempo y alcanza tus metas',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF160B33),
                              border: Border.all(
                                color: const Color(0xFF3B1E6D),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // CALENDARIO COMPLETO + LEYENDA
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C071E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF261247),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            TableCalendar<dynamic>(
                              locale: 'es_ES',
                              firstDay: DateTime.utc(2024, 1, 1),
                              lastDay: DateTime.utc(2035, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              eventLoader: _getTasksForDay,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: true,
                                outsideTextStyle: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                                weekendTextStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                defaultTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: const Color(0xFF8A2BE2),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF8A2BE2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                todayDecoration: BoxDecoration(
                                  color: const Color(0xFF3B1E6D).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                todayTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                headerPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              daysOfWeekStyle: const DaysOfWeekStyle(
                                weekdayStyle: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                weekendStyle: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  if (events.isEmpty) return null;
                                  return Positioned(
                                    bottom: 4,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: events.take(4).map((e) {
                                        final color = e is Map
                                            ? _colorParaTarea(e)
                                            : const Color(0xFF9D4EDD);
                                        return Container(
                                          width: 5,
                                          height: 5,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFF1E1038), height: 1),
                            const SizedBox(height: 12),
                            // LEYENDA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _tipoColores.entries.map((entry) {
                                return Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: entry.value,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TAREAS DEL DÍA SELECCIONADO
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C071E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF261247),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Trabajos para hoy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF160B33),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF3B1E6D),
                                    ),
                                  ),
                                  child: Text(
                                    '${selectedTasks.length} ${selectedTasks.length == 1 ? 'tarea' : 'tareas'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDay == null
                                  ? ''
                                  : _formatDateHeader(_selectedDay!),
                              style: const TextStyle(
                                color: Color(0xFF8A2BE2),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF9D4EDD),
                                  strokeWidth: 2,
                                ),
                              )
                            else if (selectedTasks.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No hay trabajos para este día.',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...selectedTasks.map((task) {
                                final t = task is Map
                                    ? Map<String, dynamic>.from(task)
                                    : <String, dynamic>{};
                                final title =
                                    t['nombre'] ?? t['titulo'] ?? 'Tarea';
                                final color = _colorParaTarea(t);
                                final tipoNombre = _tipoNombreTarea(t);
                                final completada = t['completada'] == true ||
                                    (t['estado'] ?? '')
                                            .toString()
                                            .toUpperCase() ==
                                        'COMPLETADA';

                                // Validación de si es el día exacto de la entrega
                                final fechaEntregaRaw =
                                    t['fecha_entrega'] ?? t['fechaEntrega'];
                                final fechaLimite = _parsearFecha(fechaEntregaRaw);
                                final esDiaEntrega = _selectedDay != null &&
                                    fechaLimite != null &&
                                    _selectedDay!.year == fechaLimite.year &&
                                    _selectedDay!.month == fechaLimite.month &&
                                    _selectedDay!.day == fechaLimite.day;

                                // Tono morado suave e iluminado
                                const moradoSuave = Color(0xFFB388FF);

                                return GestureDetector(
                                  onTap: () => _mostrarDetalleTarea(t),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF120826),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: esDiaEntrega
                                            ? moradoSuave.withOpacity(0.8)
                                            : const Color(0xFF261247),
                                        width: esDiaEntrega ? 1.4 : 1.0,
                                      ),
                                      boxShadow: esDiaEntrega
                                          ? [
                                              BoxShadow(
                                                color: moradoSuave.withOpacity(0.15),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: esDiaEntrega
                                                ? moradoSuave.withOpacity(0.18)
                                                : const Color(0xFF6A1B9A),
                                            borderRadius: BorderRadius.circular(12),
                                            border: esDiaEntrega
                                                ? Border.all(
                                                    color: moradoSuave.withOpacity(0.6))
                                                : null,
                                          ),
                                          child: Icon(
                                            Icons.code,
                                            color: esDiaEntrega
                                                ? moradoSuave
                                                : Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  color: completada
                                                      ? Colors.white38
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  decoration: completada
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    tipoNombre,
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (esDiaEntrega)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: moradoSuave.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: moradoSuave.withOpacity(0.5),
                                              ),
                                            ),
                                            child: const Text(
                                              '¡Entrega Hoy!',
                                              style: TextStyle(
                                                color: moradoSuave,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TARJETA DE GAMIFICACIÓN
                      _buildGamificacionCard(context),
                    ],
                  ),
                ),
              ),
            ),
            AppBottomNavbar(userId: widget.userId, currentIndex: 2),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleTarea(Map<String, dynamic> task) {
    final title = task['nombre'] ?? task['titulo'] ?? 'Tarea';
    final description = task['descripcion'] ?? 'Sin descripción';
    final estado = task['estado'] ?? 'PENDIENTE';
    final fechaRaw = task['fecha_entrega'] ?? task['fechaEntrega'];
    String fecha = 'Sin fecha';
    final fechaParsed = _parsearFecha(fechaRaw);
    if (fechaParsed != null) {
      fecha = DateFormat('dd/MM/yyyy').format(fechaParsed);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF120826),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fecha de entrega: $fecha',
              style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: estado.toUpperCase() == 'COMPLETADA'
                    ? Colors.green.withOpacity(0.2)
                    : const Color(0xFFFF4D94).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                estado,
                style: TextStyle(
                  color: estado.toUpperCase() == 'COMPLETADA'
                      ? Colors.greenAccent
                      : const Color(0xFFFF4D94),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificacionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C071E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF261247),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 120,
            child: Image.asset(
              'logo/lumi_gamificacion.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.smart_toy,
                color: Color(0xFF9D4EDD),
                size: 80,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC77DFF).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF4D94),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.star_border_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Gamificación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Accede aquí para explorar tu progreso en forma de logros, insignias y más.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GamificationScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0077B6), Color(0xFF8A2BE2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8A2BE2).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Ver mis logros',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}