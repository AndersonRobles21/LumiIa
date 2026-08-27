import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'configuracion_screen.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';

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
        maxWidth: 250,   // Reducido para que la resolución sea ligera
        maxHeight: 250,  // Reducido para que la resolución sea ligera
        imageQuality: 40, // Alta compresión para que pese muy pocos KB y no dé error 413
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
              return const Icon(Icons.broken_image, size: 40, color: Colors.white54);
            },
          ),
        );
      } catch (e) {
        avatarChild = const Icon(Icons.person, size: 50, color: Colors.white30);
      }
    }

    return GestureDetector(
      onTap: _seleccionarNuevaImagen,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF2A1F5A),
            child: avatarChild,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF44AA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
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
      horasDisponibles: 10,
      objetivo: _objetivoController.text.trim(),
      nivelProcrastinacion: _nivelProcrastinacion,
      fotoPerfil: _base64Image,
      horario: horarioParaBackend,
    );
    setState(() => _isLoading = false);
    if (resultado != null) {
      _showSnackBar(
        tr(
          '¡Perfil y hábitos guardados correctamente!',
          'Profile and habits saved successfully!',
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
              _isLoading
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
                                child: IconButton(
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
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(
                                  left: 28.0,
                                  right: 28.0,
                                  bottom: 90.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Center(child: _buildAvatar()),
                                    const SizedBox(height: 24),

                                    Text(
                                      tr('Nombre', 'First Name'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildInputField(
                                      _nameController,
                                      tr(
                                        'Ingresa tu nombre',
                                        'Enter your first name',
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    Text(
                                      tr('Apellido', 'Last Name'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildInputField(
                                      _apellidoController,
                                      tr(
                                        'Ingresa tu apellido',
                                        'Enter your last name',
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    Text(
                                      tr('Objetivo de Estudio', 'Study Goal'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildInputField(
                                      _objetivoController,
                                      tr(
                                        "Ej: Certificarme como programadora",
                                        "Ex: Get certified as a developer",
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    Text(
                                      '${tr('Nivel de Procrastinación', 'Procrastination Level')}: $_nivelProcrastinacion',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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
                                      onChanged: (value) => setState(
                                        () => _nivelProcrastinacion = value
                                            .toInt(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    Text(
                                      tr(
                                        'HORARIO DISPONIBLE',
                                        'AVAILABLE SCHEDULE',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    _buildGridSchedule(),

                                    const SizedBox(height: 36),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFCC00CC),
                                              Color(0xFFFF44AA),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _handleSend,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: Text(
                                            tr(
                                              'Guardar Perfil',
                                              'Save Profile',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
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
                    fontSize: 11,
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
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 7,
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
