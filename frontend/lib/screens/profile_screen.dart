import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController(); 
  final _objetivoController = TextEditingController(); 
  
  int _nivelProcrastinacion = 1; 
  bool _isLoading = true;
  String get _userId => widget.userId;
  final List<String> _days = ['lun', 'mar', 'mie', 'jue', 'vie'];
  
  // Estructura de matriz que almacena múltiples rangos por día
  late List<List<String>> _scheduleData;
  
  File? _imageFile;
  String? _base64Image; 
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scheduleData = List.generate(5, (_) => []);
    _cargarDatosDeBaseDeDatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  int _convertTimeToMinutes(String timeStr, BuildContext context) {
    try {
      final timeOfDay = TimeOfDay.fromDateTime(DateTime.parse("2026-01-01 $timeStr"));
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

  bool _verificarChoqueHorario(int dayIndex, int nuevoInicioMin, int nuevoFinMin, {int? excluirIndex}) {
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

  void _mostrarDialogoCerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext logoutContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1040),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFFFF44AA).withAlpha(76), width: 1.5),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          content: const Text(
            '¿Quieres cerrar sesión de tu cuenta?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(logoutContext),
              child: const Text('No', style: TextStyle(color: Colors.white54, fontSize: 15)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFCC00CC).withAlpha(51),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFCC00CC), width: 1),
                ),
              ),
              onPressed: () async {
                Navigator.pop(logoutContext);
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Sí', style: TextStyle(color: Color(0xFFFF66FF), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        );
      },
    );
  }

  // --- MODAL DE CONTROL CENTRALIZADO POR DÍA (CON BOTÓN "+" PARA AGREGAR MÚLTIPLES HORARIOS) ---
  Future<void> _configurarTiemposMultiples(int dayIndex) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1040),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HORARIOS: ${_days[dayIndex].toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  // ¡AQUÍ ESTÁ EL BOTÓN DE AGREGAR MÁS HORARIOS AL MISMO DÍA!
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFFFF44AA), size: 28),
                    onPressed: () => _abrirSelectorReloj(dayIndex, null, setDialogState), 
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _scheduleData[dayIndex].isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No hay tiempos agregados.\nToca el "+" arriba para añadir varios.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
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
                              leading: const Icon(Icons.access_time_filled, color: Color(0xFFFF44AA), size: 18),
                              title: Text(
                                _scheduleData[dayIndex][index],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botoncito para editar las horas de este bloque específico con tu reloj nativo
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 18),
                                    onPressed: () => _abrirSelectorReloj(dayIndex, index, setDialogState),
                                  ),
                                  // Botoncito para eliminar este bloque específico con letrero de confirmación
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    onPressed: () => _confirmarEliminarBloque(dayIndex, index, setDialogState),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {}); // Sincroniza los múltiples bloques con la interfaz externa
                    Navigator.pop(context);
                  },
                  child: const Text('LISTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Cuadro de confirmación real con letrero para eliminar el horario
  void _confirmarEliminarBloque(int dayIndex, int index, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (BuildContext confirmContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D0D2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
          ),
          title: const Text(
            '¿Estás seguro?',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Realmente quieres eliminar este horario asignado?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(confirmContext);
                setDialogState(() {
                  _scheduleData[dayIndex].removeAt(index);
                });
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Tu reloj nativo original reutilizado para Adición y Edición limpia
  Future<void> _abrirSelectorReloj(int dayIndex, int? editarIndex, StateSetter setDialogState) async {
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
      helpText: editarIndex == null ? 'HORA INICIO' : 'EDITAR INICIO',
      builder: (context, child) => _timePickerTheme(child),
    );
    if (pickedInicio == null) return;

    TimeOfDay horaFin = TimeOfDay(hour: (pickedInicio.hour + 2) % 24, minute: pickedInicio.minute);
    
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
      helpText: editarIndex == null ? 'HORA FIN' : 'EDITAR FIN',
      builder: (context, child) => _timePickerTheme(child),
    );
    if (pickedFin == null) return;

    final int nuevoInicioMin = (pickedInicio.hour * 60) + pickedInicio.minute;
    final int nuevoFinMin = (pickedFin.hour * 60) + pickedFin.minute;
    
    if (nuevoInicioMin >= nuevoFinMin) {
      _showSnackBar('La hora de fin debe ser mayor a la de inicio.');
      return;
    }
    // ¡La validación de choques impide que metas horas cruzadas el mismo día!
    if (_verificarChoqueHorario(dayIndex, nuevoInicioMin, nuevoFinMin, excluirIndex: editarIndex)) {
      _showSnackBar('Ya tienes un horario que se cruza o coincide en este mismo día.');
      return;
    }

    final String nuevoRango = '${pickedInicio.format(context)} - ${pickedFin.format(context)}';
    setDialogState(() {
      if (editarIndex == null) {
        _scheduleData[dayIndex].add(nuevoRango); // Suma un bloque adicional sin borrar los anteriores
      } else {
        _scheduleData[dayIndex][editarIndex] = nuevoRango; // Guarda la edición
      }
    });
  }

  Theme _timePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF44AA),
          onPrimary: Colors.white,
          surface: Color(0xFF1A1040),
          onSurface: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFFCC00CC))),
      ),
      child: child!,
    );
  }

  Future<void> _seleccionarNuevaImagen() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes).replaceAll('\n', '').replaceAll('\r', '');
        setState(() {
          _imageFile = file;
          _base64Image = base64String; 
        });
      }
    } catch (e) {
      _showSnackBar('No se pudo acceder a la galería.');
    }
  }

  Future<void> _cargarDatosDeBaseDeDatos() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProfile(_userId);
    if (data != null) {
      final scheduleFromServer = List<List<String>>.generate(5, (_) => []);
      
      if (data['perfil_estudio'] != null) {
        _base64Image = data['perfil_estudio']['foto_perfil'];
        _objetivoController.text = data['perfil_estudio']['objetivo'] ?? '';
        _nivelProcrastinacion = data['perfil_estudio']['nivel_procrastinacion'] ?? 1;
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

            final int dayIndex = _days.indexOf(dia.toLowerCase().trim().substring(0, 3));
            if (dayIndex != -1 && horaInicio.isNotEmpty && horaFin.isNotEmpty) {
              scheduleFromServer[dayIndex].add('$horaInicio - $horaFin');
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

  void _handleSend() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Por favor, ingresa tu nombre.');
      return;
    }
    setState(() => _isLoading = true);
    final horarioParaBackend = <Map<String, String>>[];
    for (int i = 0; i < _scheduleData.length; i++) {
      String diaCompleto = "lunes";
      if (i == 1) diaCompleto = "martes";
      if (i == 2) diaCompleto = "miercoles";
      if (i == 3) diaCompleto = "jueves";
      if (i == 4) diaCompleto = "viernes";

      for (final rango in _scheduleData[i]) {
        final partes = rango.split(' - ');
        if (partes.length == 2) {
          horarioParaBackend.add({
            'dia': diaCompleto,
            'hora_inicio': partes[0].trim(),
            'hora_fin': partes[1].trim(),
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
      _showSnackBar('¡Perfil y hábitos guardados correctamente!');
    } else {
      _showSnackBar('Error al intentar guardar cambios.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFCC00CC)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => _mostrarDialogoCerrarSesion(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1B3A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.logout, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          const Text(
                            'TU PERFIL',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 28.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Center(child: _buildAvatar()), 
                                const SizedBox(height: 24),
                                
                                const Text('Nombre', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), 
                                const SizedBox(height: 6), 
                                _buildInputField(_nameController, 'Ingresa tu nombre'),
                                const SizedBox(height: 14), 
                                
                                const Text('Apellido', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), 
                                const SizedBox(height: 6), 
                                _buildInputField(_apellidoController, 'Ingresa tu apellido'),
                                const SizedBox(height: 14), 

                                const Text('Objetivo de Estudio', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                _buildInputField(_objetivoController, "Ej: Certificarme como programadora"),
                                const SizedBox(height: 16),
                                
                                Text('Nivel de Procrastinación: $_nivelProcrastinacion', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                Slider(
                                  value: _nivelProcrastinacion.toDouble(),
                                  min: 1, max: 10, divisions: 9,
                                  activeColor: const Color(0xFFFF44AA),
                                  inactiveColor: const Color(0xFF1F1B2E),
                                  onChanged: (value) => setState(() => _nivelProcrastinacion = value.toInt()),
                                ),
                                const SizedBox(height: 16),
                                
                                const Text(
                                  'HORARIO DISPONIBLE',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 12),
                                
                                _buildGridSchedule(), // Tu hermosa cuadrícula de horarios intacta
                                
                                const SizedBox(height: 36),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
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
                                      child: const Text(
                                        'Guardar Perfil',
                                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF44AA), width: 1)), 
      ),
    );
  }

  Widget _buildAvatar() {
    Widget avatarChild = const Icon(Icons.person, size: 50, color: Colors.white30);
    
    if (_imageFile != null) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.file(_imageFile!, width: 100, height: 100, fit: BoxFit.cover),
      );
    } else if (_base64Image != null && _base64Image!.trim().isNotEmpty) {
      try {
        avatarChild = ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.memory(base64Decode(_base64Image!), width: 100, height: 100, fit: BoxFit.cover),
        );
      } catch (_) {}
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
              decoration: const BoxDecoration(color: Color(0xFFFF44AA), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- RENDEREADO DE LA CUADRÍCULA EXTERNA TOTALMENTE COMPACTA CON MÚLTIPLES RANGOS VISUALES ---
  Widget _buildGridSchedule() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.7, // Ajustado a 0.7 para que la tarjeta se estire y soporte ver varios bloques
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final tieneHoras = _scheduleData[index].isNotEmpty;
        return GestureDetector(
          onTap: () => _configurarTiemposMultiples(index), 
          child: Container(
            decoration: BoxDecoration(
              color: tieneHoras ? const Color(0xFFCC00CC).withAlpha(38) : const Color(0xFF1E1B3A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tieneHoras ? const Color(0xFFFF44AA) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  _days[index].toUpperCase(),
                  style: TextStyle(
                    color: tieneHoras ? const Color(0xFFFF66FF) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11, 
                  ),
                ),
                const SizedBox(height: 4),
                // Renderizado exterior en cascada de todos los bloques asignados al día
                if (tieneHoras)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _scheduleData[index].length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      itemBuilder: (ctx, bIdx) => Text(
                        _scheduleData[index][bIdx],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 7, fontWeight: FontWeight.bold),
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