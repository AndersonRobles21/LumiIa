import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '/services/api_service.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'historial_ia_screen.dart';
import 'recompensas_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _buildEventsFromList(widget.tasks);
    _cargarTareas();
  }

  void _buildEventsFromList(List<dynamic> tasks) {
    final events = <DateTime, List<dynamic>>{};

    for (final task in tasks) {
      final fechaEntrega = task['fecha_entrega'] ?? task['fechaEntrega'];
      if (fechaEntrega == null || fechaEntrega.toString().isEmpty) continue;

      DateTime? date;
      try {
        date = DateTime.parse(fechaEntrega.toString());
      } catch (_) {
        continue;
      }

      final key = DateTime(date.year, date.month, date.day);
      events.putIfAbsent(key, () => []).add(task);
    }

    _eventsByDay = events;
  }

  Future<void> _cargarTareas() async {
    final tareas = await ApiService.getPlanesEstudio(widget.userId);
    if (!mounted) return;

    setState(() {
      final source = tareas ?? widget.tasks;
      _buildEventsFromList(source);
    });
  }

  List<dynamic> _getTasksForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDay[key] ?? [];
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Sin fecha';
    try {
      final parsed = DateTime.parse(value);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay == null ? const <dynamic>[] : _getTasksForDay(_selectedDay!);

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 86),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calendario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1A3A).withOpacity(0.45),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TableCalendar<dynamic>(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2035, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          eventLoader: _getTasksForDay,
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: const TextStyle(color: Colors.white70),
                            defaultTextStyle: const TextStyle(color: Colors.white),
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFFFF44AA),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFFCC00CC).withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Color(0xFF5BE7FF),
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                            markerSize: 7,
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: Colors.white70),
                            weekendStyle: TextStyle(color: Colors.white54),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return null;
                              return Positioned(
                                right: 6,
                                bottom: 7,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5BE7FF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tareas para ${_selectedDay == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1A3A).withOpacity(0.35),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              'No hay tareas programadas para este día.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedTasks.length,
                          itemBuilder: (context, index) {
                            final task = selectedTasks[index];
                            final title = task['nombre'] ?? task['titulo'] ?? 'Tarea';
                            final description = task['descripcion'] ?? 'Sin descripción';
                            final date = _formatDate(task['fecha_entrega'] ?? task['fechaEntrega']);
                            final estado = task['estado'] ?? 'PENDIENTE';

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1040),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Fecha de entrega: $date',
                                            style: const TextStyle(color: Colors.cyanAccent),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            description,
                                            style: const TextStyle(color: Colors.white70, height: 1.4),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Estado: $estado',
                                            style: const TextStyle(color: Colors.white60),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1A3A),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFFF44AA).withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event_note_outlined, color: Color(0xFFFF44AA), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: estado.toUpperCase() == 'COMPLETADA'
                                                ? Colors.green.withOpacity(0.2)
                                                : const Color(0xFFFF44AA).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            estado,
                                            style: TextStyle(
                                              color: estado.toUpperCase() == 'COMPLETADA'
                                                  ? Colors.greenAccent
                                                  : const Color(0xFFFF44AA),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                    const Icon(Icons.calendar_month, color: Color(0xFFFF44AA), size: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HistorialIAScreen(userId: widget.userId)),
                        );
                      },
                      child: const Icon(Icons.psychology_outlined, color: Colors.white38, size: 24),
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
