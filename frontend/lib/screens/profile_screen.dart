import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'configuracion_screen.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';
import 'edit_profile_screen.dart';
import '../utils/responsive.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AppLanguageListenerMixin<ProfileScreen> {
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _objetivoController = TextEditingController();

  int _nivelProcrastinacion = 1;
  bool _isLoading = true;
  String get _userId => widget.userId;

  // Claves intactas para indexar _scheduleData y mapear con el backend
  final List<String> _days = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];

  // Etiqueta traducida de cada día para mostrar en la UI.
  String _dayLabel(int index) {
    const es = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    const en = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return AppLanguage.instance.isEnglish ? en[index] : es[index];
  }

  late List<List<String>> _scheduleData;

  File? _imageFile;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scheduleData = List.generate(_days.length, (_) => []);
    _cargarDatosDeBaseDeDatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  String _formatHoraAmPm(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour % 12;
    if (hour12 == 0) hour12 = 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  String _horaA24h(String horaAmPm) {
    final minutosTotales = _convertTimeToMinutes(horaAmPm, context);
    final hour = minutosTotales ~/ 60;
    final minute = minutosTotales % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _horaServerA12h(String horaServer) {
    if (horaServer.trim().isEmpty) return '';
    try {
      final partes = horaServer.trim().split(':');
      final int hour = int.parse(partes[0]);
      final int minute = int.parse(partes[1]);
      return _formatHoraAmPm(hour, minute);
    } catch (_) {
      return '';
    }
  }

  int _convertTimeToMinutes(String timeStr, BuildContext context) {
    try {
      final timeOfDay = TimeOfDay.fromDateTime(
        DateTime.parse("2026-01-01 $timeStr"),
      );
      return (timeOfDay.hour * 60) + timeOfDay.minute;
    } catch (_) {
      final cleanStr = timeStr.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = cleanStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (timeStr.toLowerCase().contains('pm') && hour < 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;
      return (hour * 60) + minute;
    }
  }

  bool _verificarChoqueHorario(
    int dayIndex,
    int nuevoInicioMin,
    int nuevoFinMin, {
    int? excluirIndex,
  }) {
    for (int i = 0; i < _scheduleData[dayIndex].length; i++) {
      if (excluirIndex != null && i == excluirIndex) continue;
      final rangoExistente = _scheduleData[dayIndex][i];
      final partes = rangoExistente.split(' - ');
      if (partes.length != 2) continue;
      int extInicioMin = _convertTimeToMinutes(partes[0], context);
      int extFinMin = _convertTimeToMinutes(partes[1], context);
      if (nuevoInicioMin < extFinMin && nuevoFinMin > extInicioMin) {
        return true;
      }
    }
    return false;
  }

  int _minutosDisponiblesSemanales() {
    var minutosTotales = 0;
    for (final horariosDelDia in _scheduleData) {
      for (final rango in horariosDelDia) {
        final partes = rango.split(' - ');
        if (partes.length != 2) continue;
        final inicio = _convertTimeToMinutes(partes[0].trim(), context);
        final fin = _convertTimeToMinutes(partes[1].trim(), context);
        if (fin > inicio) minutosTotales += fin - inicio;
      }
    }
    return minutosTotales;
  }

  Widget _buildWeeklyAvailabilitySummary() {
    final minutosTotales = _minutosDisponiblesSemanales();
    final horas = minutosTotales ~/ 60;
    final minutos = minutosTotales % 60;
    final detalle = minutosTotales == 0
        ? tr('Aún no has agregado bloques de estudio.', 'No study blocks added yet.')
        : minutos == 0
            ? tr('$horas h disponibles aproximadamente esta semana', '$horas h available approximately this week')
            : tr('$horas h $minutos min disponibles aproximadamente esta semana', '$horas h $minutos min available approximately this week');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF211A42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6D43D9).withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color(0xFFFF44AA), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Tu disponibilidad semanal', 'Your weekly availability'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  detalle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _configurarTiemposMultiples(int dayIndex) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1040),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tr('HORARIOS', 'SCHEDULE')}: ${_dayLabel(dayIndex)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFFFF44AA),
                      size: 28,
                    ),
                    onPressed: () =>
                        _abrirSelectorReloj(dayIndex, null, setDialogState),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _scheduleData[dayIndex].isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          tr(
                            'No hay tiempos agregados.\nToca el "+" arriba para añadir varios.',
                            'No time blocks added yet.\nTap "+" above to add some.',
                          ),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _scheduleData[dayIndex].length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1F5A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.access_time_filled,
                                color: Color(0xFFFF44AA),
                                size: 18,
                              ),
                              title: Text(
                                _scheduleData[dayIndex][index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.cyanAccent,
                                      size: 18,
                                    ),
                                    onPressed: () => _abrirSelectorReloj(
                                      dayIndex,
                                      index,
                                      setDialogState,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            backgroundColor: const Color(
                                              0xFF1A1040,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            title: Text(
                                              tr(
                                                '¿Eliminar bloque?',
                                                'Delete block?',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              tr(
                                                'Este horario se borrará por completo de la lista actual.',
                                                'This time block will be completely removed from the current list.',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                                child: Text(
                                                  tr('CANCELAR', 'CANCEL'),
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(dialogContext);
                                                  setDialogState(() {
                                                    _scheduleData[dayIndex]
                                                        .removeAt(index);
                                                  });
                                                },
                                                child: Text(
                                                  tr('ELIMINAR', 'DELETE'),
                                                  style: const TextStyle(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC00CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Text(
                    tr('LISTO', 'DONE'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _abrirSelectorReloj(
    int dayIndex,
    int? editarIndex,
    StateSetter setDialogState,
  ) async {
    TimeOfDay horaInicio = TimeOfDay.now();

    if (editarIndex != null) {
      try {
        final partes = _scheduleData[dayIndex][editarIndex].split(' - ');
        final inicioPartes = partes[0].split(':');
        int h = int.parse(inicioPartes[0]);
        int m = int.parse(inicioPartes[1].replaceAll(RegExp(r'[^\d]'), ''));
        if (partes[0].toLowerCase().contains('pm') && h < 12) h += 12;
        horaInicio = TimeOfDay(hour: h, minute: m);
      } catch (_) {}
    }

    final TimeOfDay? pickedInicio = await showTimePicker(
      context: context,
      initialTime: horaInicio,
      helpText: editarIndex == null
          ? tr('HORA INICIO', 'START TIME')
          : tr('EDITAR INICIO', 'EDIT START TIME'),
      builder: (context, child) => _timePickerTheme(child),
    );
    if (pickedInicio == null) return;

    TimeOfDay horaFin = TimeOfDay(
      hour: (pickedInicio.hour + 2) % 24,
      minute: pickedInicio.minute,
    );

    if (editarIndex != null) {
      try {
        final partes = _scheduleData[dayIndex][editarIndex].split(' - ');
        final finPartes = partes[1].split(':');
        int h = int.parse(finPartes[0]);
        int m = int.parse(finPartes[1].replaceAll(RegExp(r'[^\d]'), ''));
        if (partes[1].toLowerCase().contains('pm') && h < 12) h += 12;
        horaFin = TimeOfDay(hour: h, minute: m);
      } catch (_) {}
    }

    final TimeOfDay? pickedFin = await showTimePicker(
      context: context,
      initialTime: horaFin,
      helpText: editarIndex == null
          ? tr('HORA FIN', 'END TIME')
          : tr('EDITAR FIN', 'EDIT END TIME'),
      builder: (context, child) => _timePickerTheme(child),
    );
    if (pickedFin == null) return;

    final int nuevoInicioMin = (pickedInicio.hour * 60) + pickedInicio.minute;
    final int nuevoFinMin = (pickedFin.hour * 60) + pickedFin.minute;

    if (nuevoInicioMin >= nuevoFinMin) {
      _showSnackBar(
        tr(
          'La hora de fin debe ser mayor a la de inicio.',
          'End time must be after start time.',
        ),
      );
      return;
    }
    if (_verificarChoqueHorario(
      dayIndex,
      nuevoInicioMin,
      nuevoFinMin,
      excluirIndex: editarIndex,
    )) {
      _showSnackBar(
        tr(
          'Ya tienes un horario que se cruza o coincide en este mismo día.',
          'You already have an overlapping time block on this day.',
        ),
      );
      return;
    }

    final String nuevoRango =
        '${_formatHoraAmPm(pickedInicio.hour, pickedInicio.minute)} - '
        '${_formatHoraAmPm(pickedFin.hour, pickedFin.minute)}';
    setDialogState(() {
      if (editarIndex == null) {
        _scheduleData[dayIndex].add(nuevoRango);
      } else {
        _scheduleData[dayIndex][editarIndex] = nuevoRango;
      }
    });
  }

  Widget _timePickerTheme(Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF44AA),
            onPrimary: Colors.white,
            surface: Color(0xFF1A1040),
            onSurface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCC00CC),
            ),
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _seleccionarNuevaImagen() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 250, // Reducido para que la resolución sea ligera
        maxHeight: 250, // Reducido para que la resolución sea ligera
        imageQuality:
            40, // Alta compresión para que pese muy pocos KB y no dé error 413
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        String base64String = base64Encode(bytes);

        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }

        setState(() {
          _imageFile = null;
          _base64Image = base64String;
        });
      }
    } catch (e) {
      _showSnackBar(
        tr('No se pudo acceder a la galería.', 'Could not access gallery.'),
      );
    }
  }

  Future<void> _cargarDatosDeBaseDeDatos() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProfile(_userId);

    if (data != null) {
      final scheduleFromServer = List<List<String>>.generate(
        _days.length,
        (_) => [],
      );

      if (data['perfil_estudio'] != null) {
        var fotoServidor = data['perfil_estudio']['foto_perfil'];

        // Limpiamos el Base64 por si en la BD se guardó con el header data:image/...
        if (fotoServidor != null && fotoServidor.toString().contains(',')) {
          fotoServidor = fotoServidor.toString().split(',').last;
        }

        _base64Image = fotoServidor;
        _objetivoController.text = data['perfil_estudio']['objetivo'] ?? '';
        _nivelProcrastinacion =
            data['perfil_estudio']['nivel_procrastinacion'] ?? 1;
      }

      if (data['horarios'] != null && data['horarios'] is List) {
        final List<dynamic> horarioServer = data['horarios'];
        for (final item in horarioServer) {
          if (item is Map<String, dynamic>) {
            final String dia = item['dia']?.toString() ?? '';
            String horaInicio = item['hora_inicio']?.toString() ?? '';
            String horaFin = item['hora_fin']?.toString() ?? '';

            if (horaInicio.length > 5) horaInicio = horaInicio.substring(0, 5);
            if (horaFin.length > 5) horaFin = horaFin.substring(0, 5);

            final String horaInicio12h = _horaServerA12h(horaInicio);
            final String horaFin12h = _horaServerA12h(horaFin);

            final int dayIndex = _days.indexOf(
              dia.toLowerCase().trim().substring(0, 3),
            );
            if (dayIndex != -1 &&
                horaInicio12h.isNotEmpty &&
                horaFin12h.isNotEmpty) {
              scheduleFromServer[dayIndex].add('$horaInicio12h - $horaFin12h');
            }
          }
        }
      }

      setState(() {
        _nameController.text = data['nombre'] ?? '';
        _apellidoController.text = data['apellido'] ?? '';
        _scheduleData = scheduleFromServer;
      });
    }
    setState(() => _isLoading = false);
  }

  Widget _buildAvatar() {
    Widget avatarChild = const Icon(
      Icons.person,
      size: 50,
      color: Colors.white30,
    );

    if (_imageFile != null) {
      // Prioridad 1: Imagen recién seleccionada desde el dispositivo (Archivo local)
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.file(
          _imageFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null && _base64Image!.startsWith('asset:')) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          _base64Image!.substring(6),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null && _base64Image!.trim().isNotEmpty) {
      // Prioridad 2: Imagen convertida en Base64 proveniente de Supabase / Backend
      try {
        String cleanBase64 = _base64Image!.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.memory(
            base64Decode(cleanBase64),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.white54,
              );
            },
          ),
        );
      } catch (e) {
        avatarChild = const Icon(Icons.person, size: 50, color: Colors.white30);
      }
    }

    final isDesktop = Responsive.esEscritorio(context);
    final avatarRadius = isDesktop ? 80.0 : 50.0;
    final imageSize = isDesktop ? 160.0 : 100.0;

    // Adjust inner avatar child sizes if image widgets are used
    if (_imageFile != null) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(avatarRadius),
        child: Image.file(
          _imageFile!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        ),
      );
    } else if (_base64Image != null && _base64Image!.trim().isNotEmpty) {
      try {
        String cleanBase64 = _base64Image!.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(avatarRadius),
          child: Image.memory(
            base64Decode(cleanBase64),
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.broken_image, size: imageSize * 0.5, color: Colors.white54);
            },
          ),
        );
      } catch (e) {
        avatarChild = Icon(Icons.person, size: avatarRadius * 0.6, color: Colors.white30);
      }
    }

    return GestureDetector(
      onTap: _seleccionarNuevaImagen,
      child: Stack(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: const Color(0xFF2A1F5A),
            child: avatarChild,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF44AA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: isDesktop ? 18 : 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(
        tr('Por favor, ingresa tu nombre.', 'Please enter your name.'),
      );
      return;
    }
    setState(() => _isLoading = true);
    final horarioParaBackend = <Map<String, String>>[];
    final minutosDisponibles = _minutosDisponiblesSemanales();
    const nombresDias = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    for (int i = 0; i < _scheduleData.length; i++) {
      final String diaCompleto = i < nombresDias.length
          ? nombresDias[i]
          : 'lunes';

      for (final rango in _scheduleData[i]) {
        final partes = rango.split(' - ');
        if (partes.length == 2) {
          horarioParaBackend.add({
            'dia':
                diaCompleto, // Se mantiene intacto en español para Backend/DB
            'hora_inicio': _horaA24h(partes[0].trim()),
            'hora_fin': _horaA24h(partes[1].trim()),
          });
        }
      }
    }
    final resultado = await ApiService.updateProfile(
      userId: _userId,
      nombre: _nameController.text.trim(),
      apellido: _apellidoController.text.trim(),
      horasDisponibles: (minutosDisponibles / 60).ceil(),
      objetivo: _objetivoController.text.trim(),
      nivelProcrastinacion: _nivelProcrastinacion,
      fotoPerfil: _base64Image,
      horario: horarioParaBackend,
    );
    setState(() => _isLoading = false);
    if (resultado != null) {
      _showSnackBar(
        tr(
          resultado['reajuste_en_proceso'] == true
              ? 'Perfil guardado. Actualizando tus planes según tu nuevo horario...'
              : '¡Perfil y hábitos guardados correctamente!',
          resultado['reajuste_en_proceso'] == true
              ? 'Profile saved. Updating your plans for your new schedule...'
              : 'Profile and habits saved successfully!',
        ),
      );
    } else {
      _showSnackBar(
        tr(
          'Error al intentar guardar cambios.',
          'Error trying to save changes.',
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            colors: [Color(0xFF0D0D2B), Color(0xFF1A1040), Color(0xFF0D0D2B)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: Responsive.esEscritorio(context)
                      ? Responsive.anchoSidebar(context)
                      : 0,
                ),
                child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFCC00CC),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 16.0,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                tr('MI PERFIL', 'MY PROFILE'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar personaje',
                                      icon: const Icon(
                                        Icons.face_retouching_natural,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfileScreen(
                                                userId: _userId,
                                              ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.settings,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ConfiguracionScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: Responsive.esEscritorio(context) ? 1100 : 600),
                              child: Builder(
                                builder: (ctx) {
                                  final isDesktop = Responsive.esEscritorio(ctx);
                                  if (isDesktop) {
                                    // Desktop: avatar and name on left, rest of profile on right
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left column: avatar and basic name info
                                        Container(
                                          width: 300,
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 8),
                                              _buildAvatar(),
                                              SizedBox(height: Responsive.espacio(ctx) * 1.5),
                                              Text(
                                                tr('Nombre', 'First Name'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: Responsive.tamanioTexto(ctx),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: Responsive.espacio(ctx) / 2),
                                              _buildInputField(_nameController, tr('Ingresa tu nombre', 'Enter your first name')),
                                              SizedBox(height: Responsive.espacio(ctx) * 1.25),
                                              Text(
                                                tr('Apellido', 'Last Name'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: Responsive.tamanioTexto(ctx),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: Responsive.espacio(ctx) / 2),
                                              _buildInputField(_apellidoController, tr('Ingresa tu apellido', 'Enter your last name')),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        // Right column: rest of editable fields
                                        Expanded(
                                          child: SingleChildScrollView(
                                            padding: EdgeInsets.only(right: Responsive.paddingHorizontalRecomendado(ctx), bottom: 90),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 8),
                                                Text(
                                                  tr('Objetivo de Estudio', 'Study Goal'),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: Responsive.tamanioSubtitulo(ctx),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: Responsive.espacio(ctx) / 2),
                                                _buildInputField(_objetivoController, tr("Ej: Certificarme como programadora", "Ex: Get certified as a developer")),
                                                SizedBox(height: Responsive.espacio(ctx) * 1.5),

                                                _buildWeeklyAvailabilitySummary(),
                                                Text(
                                                  '${tr('Nivel de Procrastinación', 'Procrastination Level')}: $_nivelProcrastinacion',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: Responsive.tamanioSubtitulo(ctx),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Slider(
                                                  value: _nivelProcrastinacion.toDouble(),
                                                  min: 1,
                                                  max: 10,
                                                  divisions: 9,
                                                  activeColor: const Color(0xFFFF44AA),
                                                  inactiveColor: const Color(0xFF1F1B2E),
                                                  onChanged: (value) => setState(() => _nivelProcrastinacion = value.toInt()),
                                                ),
                                                SizedBox(height: Responsive.espacio(ctx) * 1.5),

                                                Text(
                                                  tr('HORARIO DISPONIBLE', 'AVAILABLE SCHEDULE'),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: Responsive.tamanioSubtitulo(ctx),
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                                SizedBox(height: Responsive.espacio(ctx)),
                                                _buildGridSchedule(),
                                                SizedBox(height: Responsive.espacio(ctx) * 2),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: Responsive.altoBoton(ctx) + 8,
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFCC00CC), Color(0xFFFF44AA)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: _handleSend,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.transparent,
                                                        shadowColor: Colors.transparent,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                                      ),
                                                      child: Text(
                                                        tr('Guardar Perfil', 'Save Profile'),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: Responsive.tamanioTexto(ctx) + 2,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: Responsive.espacio(ctx) * 2),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  // Mobile / tablet: original column but responsive
                                  return SingleChildScrollView(
                                    padding: EdgeInsets.only(left: Responsive.paddingHorizontalRecomendado(ctx), right: Responsive.paddingHorizontalRecomendado(ctx), bottom: 90),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 8),
                                        Center(child: _buildAvatar()),
                                        SizedBox(height: Responsive.espacio(ctx) * 3),

                                        Text(
                                          tr('Nombre', 'First Name'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: Responsive.tamanioTexto(ctx),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.espacio(ctx) / 2),
                                        _buildInputField(_nameController, tr('Ingresa tu nombre', 'Enter your first name')),
                                        SizedBox(height: Responsive.espacio(ctx) * 1.5),

                                        Text(
                                          tr('Apellido', 'Last Name'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: Responsive.tamanioTexto(ctx),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.espacio(ctx) / 2),
                                        _buildInputField(_apellidoController, tr('Ingresa tu apellido', 'Enter your last name')),
                                        SizedBox(height: Responsive.espacio(ctx) * 1.5),

                                        Text(
                                          tr('Objetivo de Estudio', 'Study Goal'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: Responsive.tamanioSubtitulo(ctx),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.espacio(ctx) / 2),
                                        _buildInputField(_objetivoController, tr("Ej: Certificarme como programadora", "Ex: Get certified as a developer")),
                                        SizedBox(height: Responsive.espacio(ctx) * 1.5),

                                        Text(
                                          '${tr('Nivel de Procrastinación', 'Procrastination Level')}: $_nivelProcrastinacion',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: Responsive.tamanioSubtitulo(ctx),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Slider(
                                          value: _nivelProcrastinacion.toDouble(),
                                          min: 1,
                                          max: 10,
                                          divisions: 9,
                                          activeColor: const Color(0xFFFF44AA),
                                          inactiveColor: const Color(0xFF1F1B2E),
                                          onChanged: (value) => setState(() => _nivelProcrastinacion = value.toInt()),
                                        ),

                                        SizedBox(height: Responsive.espacio(ctx) * 1.5),
                                        _buildWeeklyAvailabilitySummary(),
                                        Text(
                                          tr('HORARIO DISPONIBLE', 'AVAILABLE SCHEDULE'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: Responsive.tamanioSubtitulo(ctx),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        SizedBox(height: Responsive.espacio(ctx)),
                                        _buildGridSchedule(),

                                        SizedBox(height: Responsive.espacio(ctx) * 2.5),
                                        SizedBox(
                                          width: double.infinity,
                                          height: Responsive.altoBoton(ctx) + 6,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: [Color(0xFFCC00CC), Color(0xFFFF44AA)]),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _handleSend,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                              ),
                                              child: Text(tr('Guardar Perfil', 'Save Profile'), style: TextStyle(color: Colors.white, fontSize: Responsive.tamanioTexto(ctx) + 1, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: Responsive.espacio(ctx) * 3),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              AppBottomNavbar(userId: _userId, currentIndex: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6666AA), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1E1B3A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF44AA), width: 1),
        ),
      ),
    );
  }

  Widget _buildGridSchedule() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _days.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.esMovil(context) ? 3 : 4,
        childAspectRatio: Responsive.esMovil(context) ? 0.95 : 0.85,
        crossAxisSpacing: Responsive.esMovil(context) ? 8 : 6,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final tieneHoras = _scheduleData[index].isNotEmpty;
        return GestureDetector(
          onTap: () => _configurarTiemposMultiples(index),
          child: Container(
            decoration: BoxDecoration(
              color: tieneHoras
                  ? const Color(0xFFCC00CC).withAlpha(38)
                  : const Color(0xFF1E1B3A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tieneHoras
                    ? const Color(0xFFFF44AA)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  _dayLabel(index), // Muestra LUN/MON según el idioma activo
                  style: TextStyle(
                    color: tieneHoras
                        ? const Color(0xFFFF66FF)
                        : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.tamanioTexto(context) - 3,
                  ),
                ),
                const SizedBox(height: 4),
                if (tieneHoras)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _scheduleData[index].length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      itemBuilder: (ctx, bIdx) => Text(
                        _scheduleData[index][bIdx],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: Responsive.tamanioTexto(context) - 5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Icon(Icons.add, color: Colors.white38, size: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
