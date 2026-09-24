import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';

class ScheduleSlot {
  final String dayKey;
  final int startMinutes;
  final int endMinutes;

  const ScheduleSlot({
    required this.dayKey,
    required this.startMinutes,
    required this.endMinutes,
  });
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
    if (directIndex >= 0) return directIndex;
    return keys.indexOf(
      normalized.length >= 3 ? normalized.substring(0, 3) : normalized,
    );
  }

  static String serverNameForKey(String key) {
    final index = keys.indexOf(key);
    return index >= 0 ? serverNames[index] : '';
  }
}

class ScheduleSetupFlow extends StatefulWidget {
  final List<ScheduleSlot> initialSlots;
  final Future<bool> Function(List<ScheduleSlot> slots) onSave;

  const ScheduleSetupFlow({
    super.key,
    required this.initialSlots,
    required this.onSave,
  });

  @override
  State<ScheduleSetupFlow> createState() => _ScheduleSetupFlowState();
}

class _ScheduleSetupFlowState extends State<ScheduleSetupFlow>
    with AppLanguageListenerMixin<ScheduleSetupFlow> {
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
  bool _clearedAll = false;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _resetFromInitialSlots();
  }

  @override
  void didUpdateWidget(covariant ScheduleSetupFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlots != widget.initialSlots && !_isEditing) {
      _resetFromInitialSlots();
    }
  }

  void _resetFromInitialSlots() {
    _slotsByDay = {for (final key in ScheduleDayMapper.keys) key: []};
    for (final slot in widget.initialSlots) {
      if (!_slotsByDay.containsKey(slot.dayKey) ||
          slot.endMinutes <= slot.startMinutes) {
        continue;
      }
      final slots = _slotsByDay[slot.dayKey]!;
      if (!slots.any(
        (item) =>
            item.startMinutes == slot.startMinutes &&
            item.endMinutes == slot.endMinutes,
      )) {
        slots.add(slot);
      }
    }
    for (final slots in _slotsByDay.values) {
      slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    _selectedDays = ScheduleDayMapper.keys
        .where((key) => _slotsByDay[key]!.isNotEmpty)
        .toList();
    _step = 0;
    _clearedAll = false;
  }

  int get _totalMinutes => _slotsByDay.values
      .expand((slots) => slots)
      .fold(0, (total, slot) => total + slot.endMinutes - slot.startMinutes);

  List<ScheduleSlot> get _allSlots => [
    for (final dayKey in ScheduleDayMapper.keys) ..._slotsByDay[dayKey]!,
  ];

  String _dayLabel(String dayKey) {
    final index = ScheduleDayMapper.indexForKey(dayKey);
    const english = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return index >= 0
        ? tr(ScheduleDayMapper.labels[index], english[index])
        : dayKey;
  }

  String _formatMinutes(int minutes) {
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  String _formatDuration() {
    final hours = _totalMinutes ~/ 60;
    final minutes = _totalMinutes % 60;
    if (minutes == 0) {
      return '$hours ${hours == 1 ? tr('hora', 'hour') : tr('horas', 'hours')} ${tr('por semana', 'per week')}';
    }
    return '$hours h $minutes min ${tr('por semana', 'per week')}';
  }

  void _startEditing() {
    setState(() {
      _resetFromInitialSlots();
      _isEditing = true;
    });
  }

  Future<void> _toggleDay(String dayKey) async {
    final removing = _selectedDays.contains(dayKey);
    if (removing && _slotsByDay[dayKey]!.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: LumiAppTheme.surface(context),
          title: Text(
            tr('Eliminar día con horarios', 'Remove day with scheduled times'),
            style: TextStyle(color: LumiAppTheme.primaryText(context)),
          ),
          content: Text(
            tr(
              'Este día tiene horarios configurados. Si lo quitas, también se eliminarán sus bloques al guardar.',
              'This day has scheduled times. Removing it will also delete its blocks when you save.',
            ),
            style: TextStyle(color: LumiAppTheme.secondaryText(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Cancelar', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(tr('Quitar día', 'Remove day')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      if (removing) {
        _selectedDays.remove(dayKey);
        _slotsByDay[dayKey]!.clear();
      } else {
        _selectedDays.add(dayKey);
        _selectedDays.sort(
          (a, b) => ScheduleDayMapper.indexForKey(
            a,
          ).compareTo(ScheduleDayMapper.indexForKey(b)),
        );
      }
      _clearedAll = false;
    });
  }

  void _continueFromDays() {
    if (_selectedDays.isEmpty) {
      _showMessage(
        tr(
          'Selecciona al menos un día para continuar.',
          'Select at least one day to continue.',
        ),
      );
      return;
    }
    setState(() => _step = 1);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTimeBlock(String dayKey, {int? slotIndex}) async {
    final slots = _slotsByDay[dayKey]!;
    final current = slotIndex == null ? null : slots[slotIndex];
    final start = current == null
        ? (slots.isEmpty
              ? const TimeOfDay(hour: 9, minute: 0)
              : TimeOfDay(
                  hour: slots.last.endMinutes ~/ 60,
                  minute: slots.last.endMinutes % 60,
                ))
        : TimeOfDay(
            hour: current.startMinutes ~/ 60,
            minute: current.startMinutes % 60,
          );
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: start,
      helpText: tr('Hora de inicio', 'Start time'),
    );
    if (pickedStart == null || !mounted) return;
    var defaultEnd = pickedStart.hour * 60 + pickedStart.minute + 60;
    if (defaultEnd > 1439) defaultEnd = 1439;
    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay(hour: defaultEnd ~/ 60, minute: defaultEnd % 60)
          : TimeOfDay(
              hour: current.endMinutes ~/ 60,
              minute: current.endMinutes % 60,
            ),
      helpText: tr('Hora de fin', 'End time'),
    );
    if (pickedEnd == null || !mounted) return;
    final startMinutes = pickedStart.hour * 60 + pickedStart.minute;
    final endMinutes = pickedEnd.hour * 60 + pickedEnd.minute;
    if (endMinutes <= startMinutes) {
      _showMessage(
        tr(
          'La hora de fin debe ser mayor que la de inicio.',
          'End time must be after the start time.',
        ),
      );
      return;
    }
    if (slots.asMap().entries.any((entry) {
      if (entry.key == slotIndex) return false;
      final slot = entry.value;
      return startMinutes < slot.endMinutes && endMinutes > slot.startMinutes;
    })) {
      _showMessage(
        tr(
          'Ese horario se cruza con otro bloque.',
          'That time overlaps another block.',
        ),
      );
      return;
    }
    setState(() {
      final replacement = ScheduleSlot(
        dayKey: dayKey,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      );
      if (slotIndex == null) {
        slots.add(replacement);
      } else {
        slots[slotIndex] = replacement;
      }
      slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    });
  }

  void _togglePreset(String dayKey, int startMinutes, int endMinutes) {
    final slots = _slotsByDay[dayKey]!;
    final index = slots.indexWhere(
      (slot) =>
          slot.startMinutes == startMinutes && slot.endMinutes == endMinutes,
    );
    if (index >= 0) {
      setState(() => slots.removeAt(index));
      return;
    }
    if (slots.any(
      (slot) =>
          startMinutes < slot.endMinutes && endMinutes > slot.startMinutes,
    )) {
      _showMessage(
        tr(
          'Ese bloque se cruza con otro horario.',
          'That block overlaps another time.',
        ),
      );
      return;
    }
    setState(() {
      slots.add(
        ScheduleSlot(
          dayKey: dayKey,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
      );
      slots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LumiAppTheme.surface(context),
        title: Text(
          tr('Eliminar toda la disponibilidad', 'Remove all availability'),
          style: TextStyle(color: LumiAppTheme.primaryText(context)),
        ),
        content: Text(
          tr(
            'Se eliminarán todos tus días y bloques actuales. Esta acción solo se aplicará cuando guardes los cambios.',
            'All current days and blocks will be removed. This only applies when you save your changes.',
          ),
          style: TextStyle(color: LumiAppTheme.secondaryText(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancelar', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(tr('Eliminar todo', 'Remove all')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
      _showMessage(
        tr(
          'Selecciona días y horarios antes de guardar.',
          'Select days and times before saving.',
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (await widget.onSave(_allSlots) && mounted) {
        setState(() {
          _isEditing = false;
          _step = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) return _buildCurrentSchedule();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _step == 0
          ? _buildDaysStep()
          : _step == 1
          ? _buildTimesStep()
          : _buildSummaryStep(),
    );
  }

  Widget _buildShell({
    required Widget child,
    required String title,
    required String subtitle,
    bool showProgress = true,
  }) {
    final isDesktop = Responsive.esEscritorio(context);
    return Container(
      key: ValueKey('schedule-$_isEditing-$_step'),
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF44AA).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress) _buildProgress(),
          if (showProgress) const SizedBox(height: 22),
          Text(
            title,
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: isDesktop ? 22 : 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
            decoration: BoxDecoration(
              color: index <= _step
                  ? const Color(0xFFFF44AA)
                  : LumiAppTheme.secondaryText(context).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSchedule() {
    final isDesktop = Responsive.esEscritorio(context);
    final daysContent = isDesktop
        ? LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 880 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ScheduleDayMapper.keys.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (context, index) {
                  final dayKey = ScheduleDayMapper.keys[index];
                  return _buildReadOnlyDayCard(dayKey);
                },
              );
            },
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: ScheduleDayMapper.keys.map(_buildReadOnlyDay).toList(),
          );

    return _buildShell(
      title: tr('Mi horario actual', 'My current schedule'),
      subtitle: tr(
        'Aquí puedes consultar tus días y horas disponibles para estudiar.',
        'Here you can view your available study days and times.',
      ),
      showProgress: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          daysContent,
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _startEditing,
            icon: const Icon(Icons.tune_rounded),
            label: Text(tr('Personalizar horario', 'Customize schedule')),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF44AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDay(String dayKey) {
    final slots = _slotsByDay[dayKey]!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LumiAppTheme.pageBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LumiAppTheme.outline(context).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Responsive.esMovil(context) ? 82 : 112,
            child: Text(
              _dayLabel(dayKey),
              style: TextStyle(
                color: LumiAppTheme.primaryText(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: slots.isEmpty
                ? Text(
                    tr('Sin disponibilidad', 'No availability'),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: slots
                        .map(
                          (slot) => Text(
                            '${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}',
                            style: const TextStyle(
                              color: Color(0xFFFF44AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDayCard(String dayKey) {
    final slots = _slotsByDay[dayKey]!;
    final isEmpty = slots.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LumiAppTheme.pageBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LumiAppTheme.outline(context).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dayLabel(dayKey),
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isEmpty
                ? Text(
                    tr('Sin disponibilidad', 'No availability'),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: slots
                        .map(
                          (slot) => Text(
                            '${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}',
                            style: const TextStyle(
                              color: Color(0xFFFF44AA),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysStep() {
    return _buildShell(
      title: tr(
        '¿Qué días tienes disponibles para estudiar?',
        'Which days are you available to study?',
      ),
      subtitle: tr(
        'Elige uno o varios días. Después configuraremos sus horarios.',
        'Choose one or more days. Then we will set their times.',
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.esMovil(context) ? 2 : 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: Responsive.esMovil(context) ? 2.3 : 2.6,
            ),
            itemBuilder: (context, index) {
              final dayKey = ScheduleDayMapper.keys[index];
              return _selectableCard(
                selected: _selectedDays.contains(dayKey),
                icon: Icons.calendar_today_rounded,
                label: _dayLabel(dayKey),
                onTap: () => _toggleDay(dayKey),
              );
            },
          ),
          const SizedBox(height: 18),
          _buildActionRow(
            leading: _selectedDays.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    '${_selectedDays.length} ${_selectedDays.length == 1 ? tr('día seleccionado', 'day selected') : tr('días seleccionados', 'days selected')}',
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                    ),
                  ),
            primaryLabel: tr('Continuar', 'Continue'),
            onPrimary: _continueFromDays,
          ),
          if (_allSlots.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                tr(
                  'Eliminar toda mi disponibilidad',
                  'Remove all my availability',
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildTimesStep() {
    return _buildShell(
      title: tr('Horas de los días disponibles', 'Times for available days'),
      subtitle: tr(
        'Agrega, edita o elimina bloques en cada día.',
        'Add, edit, or remove blocks for each day.',
      ),
      child: Column(
        children: [
          ..._selectedDays.map(_buildDayEditor),
          _buildActionRow(
            leading: TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back),
              label: Text(tr('Atrás', 'Back')),
            ),
            primaryLabel: tr('Ver resumen', 'View summary'),
            onPrimary: () => setState(() => _step = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEditor(String dayKey) {
    final slots = _slotsByDay[dayKey]!;
    final options = [..._timeBlocks];
    for (final slot in slots) {
      if (!options.any(
        (option) =>
            option.$1 == slot.startMinutes && option.$2 == slot.endMinutes,
      )) {
        options.add((slot.startMinutes, slot.endMinutes));
      }
    }
    options.sort((a, b) => a.$1.compareTo(b.$1));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LumiAppTheme.pageBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dayLabel(dayKey),
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            Text(
              tr('Sin horarios configurados', 'No times configured'),
              style: TextStyle(color: LumiAppTheme.secondaryText(context)),
            )
          else
            ...slots.asMap().entries.map(
              (entry) => _editableSlot(dayKey, entry.key, entry.value),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = slots.any(
                (slot) =>
                    slot.startMinutes == option.$1 &&
                    slot.endMinutes == option.$2,
              );
              return FilterChip(
                selected: selected,
                label: Text(
                  '${_formatMinutes(option.$1)} - ${_formatMinutes(option.$2)}',
                ),
                onSelected: (_) => _togglePreset(dayKey, option.$1, option.$2),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickTimeBlock(dayKey),
            icon: const Icon(Icons.add, size: 18),
            label: Text(tr('Agregar horario', 'Add time')),
          ),
        ],
      ),
    );
  }

  Widget _editableSlot(String dayKey, int index, ScheduleSlot slot) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.schedule_rounded, color: Color(0xFFFF44AA)),
      title: Text(
        '${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}',
      ),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: tr('Editar horario', 'Edit time'),
            onPressed: () => _pickTimeBlock(dayKey, slotIndex: index),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: tr('Eliminar horario', 'Remove time'),
            onPressed: () =>
                setState(() => _slotsByDay[dayKey]!.removeAt(index)),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    final isDesktop = Responsive.esEscritorio(context);
    final daysWidget = isDesktop
        ? LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ScheduleDayMapper.keys.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final dayKey = ScheduleDayMapper.keys[index];
                  return _summaryDayCard(dayKey);
                },
              );
            },
          )
        : Column(
            children: ScheduleDayMapper.keys
                .map((dayKey) => _summaryDay(dayKey))
                .toList(),
          );

    return _buildShell(
      title: tr('Resumen de tu horario', 'Schedule summary'),
      subtitle: tr(
        'Revisa los siete días antes de guardar.',
        'Review all seven days before saving.',
      ),
      child: Column(
        children: [
          daysWidget,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF44AA).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: Color(0xFFFF44AA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${tr('Disponibilidad aproximada', 'Approximate availability')}: ${_formatDuration()}',
                    style: TextStyle(
                      color: LumiAppTheme.primaryText(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildActionRow(
            leading: TextButton.icon(
              onPressed: () => setState(() => _step = 1),
              icon: const Icon(Icons.arrow_back),
              label: Text(tr('Volver y editar', 'Back and edit')),
            ),
            primaryLabel: _isSaving
                ? tr('Guardando...', 'Saving...')
                : tr('Guardar horario', 'Save schedule'),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LumiAppTheme.pageBackground(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Responsive.esMovil(context) ? 82 : 112,
            child: Text(
              _dayLabel(dayKey),
              style: TextStyle(
                color: LumiAppTheme.primaryText(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: slots.isEmpty
                ? Text(
                    tr('Sin disponibilidad', 'No availability'),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: slots
                        .map(
                          (slot) => Text(
                            '${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}',
                            style: const TextStyle(
                              color: Color(0xFFFF44AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDayCard(String dayKey) {
    final slots = _slotsByDay[dayKey]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LumiAppTheme.pageBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dayLabel(dayKey),
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: slots.isEmpty
                ? Text(
                    tr('Sin disponibilidad', 'No availability'),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: slots
                        .map(
                          (slot) => Text(
                            '${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}',
                            style: const TextStyle(
                              color: Color(0xFFFF44AA),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _selectableCard({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
            color: selected
                ? const Color(0xFFFF44AA).withValues(alpha: 0.18)
                : LumiAppTheme.pageBackground(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFF44AA)
                  : LumiAppTheme.secondaryText(context).withValues(alpha: 0.18),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFFFF44AA)
                    : LumiAppTheme.secondaryText(context),
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: LumiAppTheme.primaryText(context),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: Color(0xFFFF44AA), size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required Widget leading,
    required String primaryLabel,
    required VoidCallback? onPrimary,
  }) {
    final button = FilledButton(
      onPressed: onPrimary,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFF44AA),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        primaryLabel,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    if (Responsive.esMovil(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: leading),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: button),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: leading),
        button,
      ],
    );
  }
}
