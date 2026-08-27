import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '/services/api_service.dart';
import 'gamification_screen.dart';
import 'app_bottom_navbar.dart';
import 'package:intl/date_symbol_data_local.dart';

const String kLumiBannerAsset = 'logo/lumi_gamificacion.png';

class CalendarScreen extends StatefulWidget {
  final String userId;
  final List<dynamic> tasks;

  const CalendarScreen({
    super.key,
    required this.userId,
    required this.tasks,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _eventsByDay = {};
  bool _isLoading = false;
  bool _localeReady = false;

  static const Color kColorEntrega = Color(0xFFFF2A55);

  static const Map<String, Color> _tipoColores = {
    'Trabajos': Color(0xFF9D4EDD),
    'Proyecto': Color(0xFFFFB800),
    'Examen': Color(0xFFFF4D94),
    'Entrega': kColorEntrega,
  };

  @override
  void initState() {
    super.initState();
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

  DateTime? _parsearFecha(dynamic fechaRaw) {
    if (fechaRaw == null) return null;

    if (fechaRaw is DateTime) {
      return DateTime.utc(fechaRaw.year, fechaRaw.month, fechaRaw.day);
    }

    final str = fechaRaw.toString().trim();
    if (str.isEmpty) return null;

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

  Map<DateTime, List<dynamic>> _crearMapaEventos(List<dynamic> tasks) {
    final events = <DateTime, List<dynamic>>{};
    final hoy = DateTime.now();
    final hoyNormalizado = DateTime.utc(hoy.year, hoy.month, hoy.day);

    for (final task in tasks) {
      if (task is! Map) continue;

      final rawEntrega =
          task['fecha_entrega'] ?? task['fechaEntrega'] ?? task['fecha'];
      final fechaLimite = _parsearFecha(rawEntrega);

      final rawCreacion =
          task['created_at'] ?? task['fecha_creacion'] ?? task['fechaCreacion'];
      final fechaInicio = _parsearFecha(rawCreacion) ?? hoyNormalizado;

      if (fechaLimite == null) {
        events.putIfAbsent(fechaInicio, () => []).add(task);
        continue;
      }

      DateTime cursor =
          fechaInicio.isAfter(fechaLimite) ? fechaLimite : fechaInicio;

      while (!cursor.isAfter(fechaLimite)) {
        final key = DateTime.utc(cursor.year, cursor.month, cursor.day);
        events.putIfAbsent(key, () => []).add(task);
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    return events;
  }

  void _buildEventsFromList(List<dynamic> tasks) {
    final events = _crearMapaEventos(tasks);

    if (!mounted) return;

    setState(() {
      _eventsByDay = events;
    });
  }

  Future<void> _cargarTareas() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final tareasManuales =
        await ApiService.getPlanesEstudio(widget.userId) ?? [];
    final historialIA = await ApiService.obtenerHistorial(widget.userId) ?? [];
    final historialConFecha = await _completarFechasHistorial(historialIA);

    if (!mounted) return;

    final todasLasTareas = <dynamic>[
      ...tareasManuales,
      ...historialConFecha,
    ];

    final eventos = _crearMapaEventos(
      todasLasTareas.isNotEmpty ? todasLasTareas : widget.tasks,
    );

    setState(() {
      _eventsByDay = eventos;
      _isLoading = false;
    });

    _seleccionarDiaInicial();
  }

  Future<List<dynamic>> _completarFechasHistorial(
    List<dynamic> historial,
  ) async {
    final resultado = <dynamic>[];

    for (final item in historial) {
      if (item is! Map) continue;

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

    return '${day.day} de ${meses[day.month - 1]} ${day.year}';
  }

  String _formatearFechaCorta(DateTime day) {
    final mesesCortos = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${day.day} de ${mesesCortos[day.month - 1]}';
  }

  Color _colorParaTarea(Map task) {
    final tipo = _tipoNombreTarea(task);
    return _tipoColores[tipo] ?? const Color(0xFF9D4EDD);
  }

  String _tipoNombreTarea(Map task) {
    final nombre =
        (task['nombre'] ?? task['titulo'] ?? '').toString().toLowerCase();
    final tipo = (task['tipo'] ?? '').toString();

    if (tipo == 'Examen' || tipo == 'Proyecto' || tipo == 'Trabajos') {
      return tipo;
    }

    if (nombre.contains('examen') ||
        nombre.contains('parcial') ||
        nombre.contains('quiz')) {
      return 'Examen';
    }

    if (nombre.contains('proyecto')) {
      return 'Proyecto';
    }

    return 'Trabajos';
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0B1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF261D45),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            kLumiBannerAsset,
            width: 90,
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy_rounded,
              size: 60,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1033),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEC4899),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                Text(
                  'Accede aquí para explorar tu progreso en forma de logros, insignias y más.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GamificationScreen(
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0088CC), Color(0xFF8B5CF6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ver mis logros',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildEventMarkers(DateTime date, List<dynamic> events) {
    if (events.isEmpty) return const SizedBox.shrink();

    final visibles = events.take(4).toList();

    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: visibles.map((event) {
          Color dotColor = const Color(0xFF9D4EDD);

          if (event is Map) {
            final rawEntrega =
                event['fecha_entrega'] ?? event['fechaEntrega'] ?? event['fecha'];
            final fechaEntrega = _parsearFecha(rawEntrega);

            final esEntregaExacta = fechaEntrega != null &&
                date.year == fechaEntrega.year &&
                date.month == fechaEntrega.month &&
                date.day == fechaEntrega.day;

            dotColor = esEntregaExacta ? kColorEntrega : _colorParaTarea(event);
          }

          return Container(
            width: 5.5,
            height: 5.5,
            margin: const EdgeInsets.symmetric(horizontal: 1.4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF03020A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF9D4EDD)),
        ),
      );
    }

    final selectedTasks =
        _selectedDay == null ? const <dynamic>[] : _getTasksForDay(_selectedDay!);

    final esHoy =
        _selectedDay != null && isSameDay(_selectedDay, DateTime.now());

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                      const SizedBox(height: 20),
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
                                  _selectedDay = DateTime.utc(
                                    selectedDay.year,
                                    selectedDay.month,
                                    selectedDay.day,
                                  );
                                  _focusedDay = focusedDay;
                                });
                              },
                              eventLoader: _getTasksForDay,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              rowHeight: 58,
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
selectedDecoration: const BoxDecoration(
  color: Color(0xFF8A2BE2),
  shape: BoxShape.circle,
  boxShadow: [
    BoxShadow(
      color: Color(0xFF8A2BE2),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ],
),
todayDecoration: BoxDecoration(
  color: const Color(0xFF3B1E6D).withOpacity(0.5),
  shape: BoxShape.circle,
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
                                  return Positioned(
                                    bottom: 6,
                                    left: 0,
                                    right: 0,
                                    child: _buildEventMarkers(date, events),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFF1E1038), height: 1),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              spacing: 14,
                              runSpacing: 8,
                              children: _tipoColores.entries.map((entry) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
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
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                Text(
                                  esHoy
                                      ? 'Trabajos para hoy'
                                      : (_selectedDay != null
                                          ? _formatDateHeader(_selectedDay!)
                                          : 'Trabajos asignados'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
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
                                    '${selectedTasks.length} ${selectedTasks.length == 1 ? 'trabajo' : 'trabajos'}',
                                    style: const TextStyle(
                                      color: Color(0xFF9D4EDD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF9D4EDD),
                                  ),
                                ),
                              )
                            else if (selectedTasks.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_available_outlined,
                                        color: Colors.white.withOpacity(0.3),
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No hay trabajos programados para este día',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedTasks.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final t = selectedTasks[index];
                                  final map = t is Map ? t : {};
                                  final titulo =
                                      map['nombre'] ?? map['titulo'] ?? 'Sin título';
                                  final desc = map['descripcion'] ?? '';
                                  final completada = map['completada'] == true ||
                                      (map['estado'] ?? '')
                                              .toString()
                                              .toUpperCase() ==
                                          'COMPLETADA';
                                  final color = _colorParaTarea(map);

                                  final rawEntrega = map['fecha_entrega'] ??
                                      map['fechaEntrega'] ??
                                      map['fecha'];
                                  final fechaEntrega = _parsearFecha(rawEntrega);

                                  final esDiaDeEntrega = fechaEntrega != null &&
                                      _selectedDay != null &&
                                      _selectedDay!.year == fechaEntrega.year &&
                                      _selectedDay!.month == fechaEntrega.month &&
                                      _selectedDay!.day == fechaEntrega.day;

                                  final diasRestantes =
                                      (fechaEntrega != null && _selectedDay != null)
                                          ? fechaEntrega
                                              .difference(_selectedDay!)
                                              .inDays
                                          : 0;

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF150A2E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: esDiaDeEntrega
                                            ? kColorEntrega.withOpacity(0.85)
                                            : color.withOpacity(0.3),
                                        width: esDiaDeEntrega ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: esDiaDeEntrega
                                                    ? kColorEntrega
                                                    : color,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    titulo.toString(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      decoration: completada
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                  if (desc.toString().isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      desc.toString(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.6),
                                                        fontSize: 11.5,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (completada)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF3DDC84),
                                                size: 22,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (completada)
                                              _buildStatusBadge(
                                                'Completada',
                                                const Color(0xFF3DDC84),
                                                Icons.check_circle,
                                              )
                                            else if (esDiaDeEntrega)
                                              _buildStatusBadge(
                                                'Fecha de entrega hoy',
                                                kColorEntrega,
                                                Icons.alarm,
                                              )
                                            else if (diasRestantes > 0 &&
                                                fechaEntrega != null)
                                              _buildStatusBadge(
                                                'Pendiente: ${_formatearFechaCorta(fechaEntrega)}',
                                                color,
                                                Icons.schedule,
                                              )
                                            else
                                              _buildStatusBadge(
                                                'Pendiente',
                                                color,
                                                Icons.circle,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildGamificationCard(context),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: AppBottomNavbar(
                  userId: widget.userId,
                  currentIndex: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}