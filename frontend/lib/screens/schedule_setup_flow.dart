import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class ScheduleSlot {
  final String dayKey;
  final int startMinutes;
  final int endMinutes;

  const ScheduleSlot({
    required this.dayKey,
    required this.startMinutes,
    required this.endMinutes,
  });

  ScheduleSlot copyWith({String? dayKey, int? startMinutes, int? endMinutes}) {
    return ScheduleSlot(
      dayKey: dayKey ?? this.dayKey,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }
}

class ScheduleDayMapper {
  static const keys = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];
  static const serverNames = [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];
  static const labels = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static int indexForKey(String key) => keys.indexOf(key);

  static int indexForServerDay(String value) {
    final normalized = value.trim().toLowerCase();
    final directIndex = serverNames.indexOf(normalized);
    if (directIndex != -1) return directIndex;
    return keys.indexOf(normalized.length >= 3 ? normalized.substring(0, 3) : normalized);
  }

  static String serverNameForKey(String key) {
    final index = keys.indexOf(key);
    return index >= 0 ? serverNames[index] : '';
  }

  static String labelForKey(String key) {
    final index = keys.indexOf(key);
    return index >= 0 ? labels[index] : key;
  }
}

class ScheduleSetupFlow extends StatefulWidget {
  final List<ScheduleSlot> initialSlots;
  final Future<void> Function(List<ScheduleSlot> slots) onSave;

  const ScheduleSetupFlow({
    super.key,
    required this.initialSlots,
    required this.onSave,
  });

  @override
  State<ScheduleSetupFlow> createState() => _ScheduleSetupFlowState();
}

class _ScheduleSetupFlowState extends State<ScheduleSetupFlow> {
  static const _timeBlocks = [
    (360, 480),
    (480, 600),
    (600, 720),
    (720, 840),
    (840, 960),
    (960, 1080),
    (1080, 1200),
    (1200, 1320),
  ];

  late Map<String, List<ScheduleSlot>> _slotsByDay;
  late List<String> _selectedDays;
  int _step = 0;
  int _dayIndex = 0;
  bool _clearedAll = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _resetFromInitialSlots();
  }

  @override
  void didUpdateWidget(covariant ScheduleSetupFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlots != widget.initialSlots) {
      _resetFromInitialSlots();
    }
  }

  void _resetFromInitialSlots() {
    _slotsByDay = {for (final key in ScheduleDayMapper.keys) key: []};
    for (final slot in widget.initialSlots) {
      if (!_slotsByDay.containsKey(slot.dayKey) || slot.endMinutes <= slot.startMinutes) continue;
      final daySlots = _slotsByDay[slot.dayKey]!;
      if (!daySlots.any((item) => item.startMinutes == slot.startMinutes && item.endMinutes == slot.endMinutes)) {
        daySlots.add(slot);
      }
    }
    for (final slots in _slotsByDay.values) {
      slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    _selectedDays = ScheduleDayMapper.keys.where((key) => _slotsByDay[key]!.isNotEmpty).toList();
    _step = 0;
    _dayIndex = 0;
    _clearedAll = false;
  }

  int get _totalMinutes => _slotsByDay.values
      .expand((slots) => slots)
      .fold(0, (total, slot) => total + slot.endMinutes - slot.startMinutes);

  List<ScheduleSlot> get _allSlots => [
        for (final dayKey in ScheduleDayMapper.keys) ..._slotsByDay[dayKey]!,
      ];

  String _formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration() {
    final hours = _totalMinutes ~/ 60;
    final minutes = _totalMinutes % 60;
    if (minutes == 0) return '$hours ${hours == 1 ? 'hora' : 'horas'} por semana';
    return '$hours h $minutes min por semana';
  }

  void _toggleDay(String dayKey) {
    setState(() {
      if (_selectedDays.contains(dayKey)) {
        _selectedDays.remove(dayKey);
        _slotsByDay[dayKey]!.clear();
      } else {
        _selectedDays.add(dayKey);
        _selectedDays.sort((a, b) => ScheduleDayMapper.indexForKey(a).compareTo(ScheduleDayMapper.indexForKey(b)));
      }
      _clearedAll = false;
    });
  }

  void _continueFromDays() {
    if (_selectedDays.isEmpty) {
      _showMessage('Selecciona al menos un día para continuar.');
      return;
    }
    setState(() {
      _step = 1;
      _dayIndex = 0;
    });
  }

  void _continueFromDay() {
    final dayKey = _selectedDays[_dayIndex];
    if (_slotsByDay[dayKey]!.isEmpty) {
      _showMessage('Selecciona al menos un bloque para ${ScheduleDayMapper.labelForKey(dayKey).toLowerCase()}.');
      return;
    }
    setState(() {
      if (_dayIndex < _selectedDays.length - 1) {
        _dayIndex++;
      } else {
        _step = 2;
      }
    });
  }

  void _toggleTimeBlock(int startMinutes, int endMinutes) {
    final dayKey = _selectedDays[_dayIndex];
    final daySlots = _slotsByDay[dayKey]!;
    final existingIndex = daySlots.indexWhere(
      (slot) => slot.startMinutes == startMinutes && slot.endMinutes == endMinutes,
    );
    setState(() {
      if (existingIndex >= 0) {
        daySlots.removeAt(existingIndex);
        return;
      }
      if (daySlots.any(
        (slot) => startMinutes < slot.endMinutes && endMinutes > slot.startMinutes,
      )) {
        _showMessage('Ese bloque se cruza con otro bloque seleccionado.');
        return;
      }
      daySlots.add(ScheduleSlot(
        dayKey: dayKey,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ));
      daySlots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    });
  }

  Future<void> _clearAll() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LumiAppTheme.surface(context),
        title: Text('Eliminar toda la disponibilidad', style: TextStyle(color: LumiAppTheme.primaryText(context))),
        content: Text(
          'Se eliminarán todos tus días y bloques actuales. Esta acción solo se aplicará cuando guardes los cambios.',
          style: TextStyle(color: LumiAppTheme.secondaryText(context)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
    if (shouldClear != true || !mounted) return;
    setState(() {
      for (final slots in _slotsByDay.values) {
        slots.clear();
      }
      _selectedDays.clear();
      _clearedAll = true;
      _step = 2;
    });
  }

  Future<void> _save() async {
    if (_allSlots.isEmpty && !_clearedAll) {
      _showMessage('Selecciona días y horarios antes de guardar.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_allSlots);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _step == 0
          ? _buildDaysStep()
          : _step == 1
              ? _buildDayStep()
              : _buildSummaryStep(),
    );
  }

  Widget _buildShell({required Widget child, required String title, required String subtitle}) {
    final isDesktop = Responsive.esEscritorio(context);
    return Container(
      key: ValueKey('step-$_step'),
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF44AA).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 22),
          Text(title, style: TextStyle(color: LumiAppTheme.primaryText(context), fontSize: isDesktop ? 22 : 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: LumiAppTheme.secondaryText(context), fontSize: 14, height: 1.35)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= _step;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF44AA) : LumiAppTheme.secondaryText(context).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDaysStep() {
    return _buildShell(
      title: '¿Qué días tienes disponibles para estudiar?',
      subtitle: 'Elige uno o varios días. Después veremos los horarios de cada uno.',
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ScheduleDayMapper.keys.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.esMovil(context) ? 2 : 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: Responsive.esMovil(context) ? 2.3 : 2.6,
            ),
            itemBuilder: (context, index) {
              final key = ScheduleDayMapper.keys[index];
              final selected = _selectedDays.contains(key);
              return _selectableCard(
                selected: selected,
                icon: Icons.calendar_today_rounded,
                label: ScheduleDayMapper.labels[index],
                onTap: () => _toggleDay(key),
              );
            },
          ),
          const SizedBox(height: 18),
          _buildActionRow(
            leading: _selectedDays.isNotEmpty
                ? Text('${_selectedDays.length} ${_selectedDays.length == 1 ? 'día seleccionado' : 'días seleccionados'}', style: TextStyle(color: LumiAppTheme.secondaryText(context)))
                : const SizedBox.shrink(),
            primaryLabel: 'Continuar',
            onPrimary: _continueFromDays,
          ),
          if (_allSlots.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar toda mi disponibilidad'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayStep() {
    final dayKey = _selectedDays[_dayIndex];
    final selectedSlots = _slotsByDay[dayKey]!;
    final options = [..._timeBlocks];
    for (final slot in selectedSlots) {
      if (!options.any((item) => item.$1 == slot.startMinutes && item.$2 == slot.endMinutes)) {
        options.add((slot.startMinutes, slot.endMinutes));
      }
    }
    options.sort((a, b) => a.$1.compareTo(b.$1));

    return _buildShell(
      title: '¿Qué horas tienes disponibles el ${ScheduleDayMapper.labelForKey(dayKey).toLowerCase()}?',
      subtitle: 'Toca todos los bloques en los que podrías estudiar.',
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.esMovil(context) ? 1 : 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: Responsive.esMovil(context) ? 4.4 : 3.8,
            ),
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = selectedSlots.any((slot) => slot.startMinutes == option.$1 && slot.endMinutes == option.$2);
              return _selectableCard(
                selected: selected,
                icon: selected ? Icons.check_circle_rounded : Icons.schedule_rounded,
                label: '${_formatMinutes(option.$1)} - ${_formatMinutes(option.$2)}',
                onTap: () => _toggleTimeBlock(option.$1, option.$2),
              );
            },
          ),
          const SizedBox(height: 18),
          _buildActionRow(
            leading: TextButton.icon(
              onPressed: () => setState(() {
                if (_dayIndex > 0) {
                  _dayIndex--;
                } else {
                  _step = 0;
                }
              }),
              icon: const Icon(Icons.arrow_back),
              label: Text(_dayIndex > 0 ? 'Día anterior' : 'Atrás'),
            ),
            primaryLabel: _dayIndex == _selectedDays.length - 1 ? 'Ver resumen' : 'Siguiente día',
            onPrimary: _continueFromDay,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return _buildShell(
      title: 'Así quedará tu horario',
      subtitle: _allSlots.isEmpty ? 'No tendrás bloques de estudio guardados.' : 'Esta es tu disponibilidad aproximada para la semana.',
      child: Column(
        children: [
          if (_allSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text('Toda tu disponibilidad será eliminada.', style: TextStyle(color: LumiAppTheme.secondaryText(context))),
            )
          else
            ..._selectedDays.map((dayKey) => _summaryDay(dayKey)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF44AA).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: Color(0xFFFF44AA)),
                const SizedBox(width: 10),
                Text('Disponibilidad aproximada: ${_formatDuration()}', style: TextStyle(color: LumiAppTheme.primaryText(context), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActionRow(
            leading: TextButton.icon(
              onPressed: () => setState(() => _step = _allSlots.isEmpty ? 0 : 1),
              icon: const Icon(Icons.arrow_back),
              label: Text(_allSlots.isEmpty ? 'Volver' : 'Volver y editar'),
            ),
            primaryLabel: _isSaving ? 'Guardando...' : (_allSlots.isEmpty ? 'Guardar eliminación' : 'Guardar horario'),
            onPrimary: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _summaryDay(String dayKey) {
    final slots = _slotsByDay[dayKey]!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LumiAppTheme.pageBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ScheduleDayMapper.labelForKey(dayKey), style: TextStyle(color: LumiAppTheme.primaryText(context), fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: slots.map((slot) => Text('${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}', style: const TextStyle(color: Color(0xFFFF44AA), fontWeight: FontWeight.w600))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _selectableCard({required bool selected, required IconData icon, required String label, required VoidCallback onTap}) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF44AA).withValues(alpha: 0.18) : LumiAppTheme.pageBackground(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: selected ? const Color(0xFFFF44AA) : LumiAppTheme.secondaryText(context).withValues(alpha: 0.18), width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? const Color(0xFFFF44AA) : LumiAppTheme.secondaryText(context), size: 20),
              const SizedBox(width: 9),
              Expanded(child: Text(label, style: TextStyle(color: LumiAppTheme.primaryText(context), fontWeight: selected ? FontWeight.bold : FontWeight.w500))),
              if (selected) const Icon(Icons.check, color: Color(0xFFFF44AA), size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({required Widget leading, required String primaryLabel, required VoidCallback? onPrimary}) {
    return Row(
      children: [
        Expanded(child: leading),
        FilledButton(
          onPressed: onPrimary,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF44AA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
