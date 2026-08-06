import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'configuracion_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profileData;

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _horasController = TextEditingController();
  final _objetivoController = TextEditingController();
  int _nivelProcrastinacion = 1;
  String? _fotoPerfilUrl;
  File? _fotoPerfilLocal;

  // Incluye sábado y domingo
  final List<String> _dias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  List<List<String>> _scheduleData = [[], [], [], [], [], [], []];

  static const Color _pink = Color(0xFFFF44AA);
  static const Color _cardBg = Color(0xFF1F1A3A);
  static const Color _textGrey = Color(0xFFB0AEC4);

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _horasController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProfile(widget.userId);

    if (data != null) {
      _profileData = data;
      _nombreController.text = data['nombre'] ?? '';
      _apellidoController.text = data['apellido'] ?? '';

      final perfilEstudio = data['perfil_estudio'] ?? {};
      _horasController.text =
          (perfilEstudio['horas_disponibles'] ?? 0).toString();
      _objetivoController.text = perfilEstudio['objetivo'] ?? '';
      _nivelProcrastinacion = perfilEstudio['nivel_procrastinacion'] ?? 1;
      _fotoPerfilUrl = perfilEstudio['foto_perfil'];

      final horarios = data['horarios'] as List? ?? [];
      _scheduleData = List.generate(_dias.length, (_) => []);
      for (final h in horarios) {
        final diaIndex = _dias.indexOf(h['dia']);
        if (diaIndex != -1) {
          // Convertir a AM/PM al cargar desde backend (formato HH:mm)
          final inicio = _to12h(h['hora_inicio']?.toString() ?? '');
          final fin = _to12h(h['hora_fin']?.toString() ?? '');
          _scheduleData[diaIndex].add('$inicio - $fin');
        }
      }
    }

    setState(() => _isLoading = false);
  }

  /// Convierte "14:30" → "2:30 PM" (o deja pasar si ya tiene AM/PM)
  String _to12h(String timeStr) {
    if (timeStr.toLowerCase().contains('am') ||
        timeStr.toLowerCase().contains('pm')) {
      return timeStr;
    }
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      final String period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) hour = 12;
      if (hour > 12) hour -= 12;
      final String minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  /// Convierte "2:30 PM" → "14:30" para enviar al backend
  String _to24h(String timeStr) {
    try {
      final upper = timeStr.toUpperCase().trim();
      final isPM = upper.contains('PM');
      final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _fotoPerfilLocal = File(picked.path));
    }
  }

  Future<void> _guardarPerfil() async {
    setState(() => _isSaving = true);

    final horarioPayload = <Map<String, dynamic>>[];
    for (int i = 0; i < _scheduleData.length; i++) {
      for (final bloque in _scheduleData[i]) {
        final partes = bloque.split(' - ');
        if (partes.length == 2) {
          horarioPayload.add({
            'dia': _dias[i],
            'hora_inicio': _to24h(partes[0].trim()),
            'hora_fin': _to24h(partes[1].trim()),
          });
        }
      }
    }

    final resultado = await ApiService.updateProfile(
      userId: widget.userId,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      horasDisponibles: int.tryParse(_horasController.text) ?? 0,
      objetivo: _objetivoController.text.trim(),
      nivelProcrastinacion: _nivelProcrastinacion,
      fotoPerfil: _fotoPerfilUrl,
      horario: horarioPayload,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado != null
            ? 'Perfil guardado correctamente'
            : 'Error al guardar el perfil'),
        backgroundColor:
            resultado != null ? const Color(0xFF2E1B4E) : Colors.redAccent,
      ),
    );
  }

  // ── MODAL DE HORARIOS ─────────────────────────────────────────────────────
  void _abrirModalHorario(int dayIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1040),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dias[dayIndex],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: _pink, size: 28),
                    onPressed: () =>
                        _abrirSelectorReloj(dayIndex, null, setDialogState),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _scheduleData[dayIndex].isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No hay horarios.\nToca "+" para agregar.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13),
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
                              leading: const Icon(Icons.access_time_filled,
                                  color: _pink, size: 18),
                              title: Text(
                                _scheduleData[dayIndex][index],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.cyanAccent, size: 18),
                                    onPressed: () => _abrirSelectorReloj(
                                        dayIndex, index, setDialogState),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent, size: 18),
                                    onPressed: () => _confirmarEliminarBloque(
                                        dayIndex, index, setDialogState),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('CERRAR',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirSelectorReloj(
      int dayIndex, int? index, StateSetter setDialogState) async {
    // showTimePicker ya usa formato AM/PM en sistemas configurados en 12h.
    // alwaysUse24HourFormat = false fuerza AM/PM sin importar la config del sistema.
    final inicio = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: _pink, surface: Color(0xFF1A1040)),
          ),
          child: child!,
        ),
      ),
    );
    if (inicio == null || !mounted) return;

    final fin = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (inicio.hour + 1) % 24,
        minute: inicio.minute,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: _pink, surface: Color(0xFF1A1040)),
          ),
          child: child!,
        ),
      ),
    );
    if (fin == null) return;

    // format() usa el locale del dispositivo pero con alwaysUse24HourFormat:false
    // devuelve "h:mm AM/PM"
    final bloque = '${inicio.format(context)} - ${fin.format(context)}';

    setDialogState(() {
      if (index != null) {
        _scheduleData[dayIndex][index] = bloque;
      } else {
        _scheduleData[dayIndex].add(bloque);
      }
    });
  }

  void _confirmarEliminarBloque(
      int dayIndex, int index, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1040),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '¿Eliminar bloque?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Este horario se borrará de la lista.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setDialogState(() {
                  _scheduleData[dayIndex].removeAt(index);
                });
              },
              child: const Text('ELIMINAR',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ── ETIQUETA DE NIVEL ─────────────────────────────────────────────────────
  String _labelProcrastinacion(int nivel) {
    switch (nivel) {
      case 1:
        return 'Muy bajo';
      case 2:
        return 'Bajo';
      case 3:
        return 'Moderado';
      case 4:
        return 'Alto';
      case 5:
        return 'Muy alto';
      default:
        return nivel.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0813),
        body: Center(child: CircularProgressIndicator(color: _pink)),
      );
    }

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
          child: Column(
            children: [
              // ── APP BAR ─────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Mi Perfil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                      tooltip: 'Configuración',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConfiguracionScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── CONTENIDO ───────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto de perfil
                      Center(
                        child: GestureDetector(
                          onTap: _seleccionarFoto,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: const Color(0xFF2A1F5A),
                                backgroundImage: _fotoPerfilLocal != null
                                    ? FileImage(_fotoPerfilLocal!)
                                    : (_fotoPerfilUrl != null
                                        ? NetworkImage(_fotoPerfilUrl!)
                                        : null) as ImageProvider?,
                                child: (_fotoPerfilLocal == null &&
                                        _fotoPerfilUrl == null)
                                    ? const Icon(Icons.person,
                                        color: Colors.white54, size: 40)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: _pink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nombre completo debajo del avatar
                      if (_nombreController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: Text(
                              '${_nombreController.text} ${_apellidoController.text}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // ── DATOS PERSONALES ─────────────────────────────────
                      _buildSectionLabel('Datos personales'),
                      const SizedBox(height: 10),
                      _buildLabel('Nombre'),
                      _buildTextField(_nombreController),
                      const SizedBox(height: 14),
                      _buildLabel('Apellido'),
                      _buildTextField(_apellidoController),
                      const SizedBox(height: 14),
                      _buildLabel('Email'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _cardBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          _profileData?['correo'] ?? '—',
                          style: const TextStyle(
                              color: _textGrey, fontSize: 14),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── PERFIL DE ESTUDIO ────────────────────────────────
                      _buildSectionLabel('Perfil de estudio'),
                      const SizedBox(height: 10),
                      _buildLabel('Horas disponibles al día'),
                      _buildTextField(_horasController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 14),
                      _buildLabel('Objetivo'),
                      _buildTextField(_objetivoController, maxLines: 3),
                      const SizedBox(height: 14),
                      _buildLabel(
                          'Nivel de procrastinación: ${_labelProcrastinacion(_nivelProcrastinacion)}'),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _pink,
                          inactiveTrackColor: _cardBg,
                          thumbColor: _pink,
                          overlayColor: _pink.withOpacity(0.2),
                          valueIndicatorColor: _pink,
                          valueIndicatorTextStyle:
                              const TextStyle(color: Colors.white),
                        ),
                        child: Slider(
                          value: _nivelProcrastinacion.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _labelProcrastinacion(_nivelProcrastinacion),
                          onChanged: (v) =>
                              setState(() => _nivelProcrastinacion = v.round()),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── HORARIO SEMANAL ───────────────────────────────────
                      _buildSectionLabel('Horario semanal'),
                      const SizedBox(height: 4),
                      const Text(
                        'Toca un día para agregar o editar tus bloques de estudio.',
                        style: TextStyle(color: _textGrey, fontSize: 11),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(_dias.length, (i) {
                        final esFinDeSemana = i >= 5;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: esFinDeSemana
                                ? _pink.withOpacity(0.06)
                                : _cardBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: esFinDeSemana
                                  ? _pink.withOpacity(0.25)
                                  : Colors.white12,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: esFinDeSemana
                                  ? _pink.withOpacity(0.2)
                                  : _cardBg,
                              child: Text(
                                _dias[i].substring(0, 2),
                                style: TextStyle(
                                  color:
                                      esFinDeSemana ? _pink : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              _dias[i],
                              style: TextStyle(
                                color: esFinDeSemana ? _pink : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _scheduleData[i].isEmpty
                                  ? 'Sin horarios'
                                  : _scheduleData[i].join(' | '),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              _scheduleData[i].isEmpty
                                  ? Icons.add_circle_outline
                                  : Icons.edit_outlined,
                              color: esFinDeSemana ? _pink : Colors.white38,
                              size: 20,
                            ),
                            onTap: () => _abrirModalHorario(i),
                          ),
                        );
                      }),

                      const SizedBox(height: 32),

                      // ── BOTÓN GUARDAR ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _guardarPerfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pink,
                            disabledBackgroundColor: _pink.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'GUARDAR PERFIL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGETS HELPERS ─────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _textGrey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _cardBg.withOpacity(0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _pink, width: 1.5),
        ),
      ),
    );
  }
}
