
import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(userId: 'UUID_DE_PRUEBA'),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String get _userId => widget.userId;

  final List<String> _days = ['lun', 'mar', 'mie', 'jue', 'vie'];

  // --- CAMBIO CLAVE: Ahora cada día maneja una LISTA de bloques de tiempo ---
  late List<List<String>> _scheduleData;

  final List<String> _methods = [
    'pomodoro',
    'Spaced Repetition',
    'Active Recall',
    'Feynman',
  ];
  late List<bool> _methodSelected;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inicializamos los 5 días de la semana vacíos (sin bloques asignados)
    _scheduleData = List.generate(5, (_) => []);
    _methodSelected = [true, true, true, true];
    _cargarDatosDeBaseDeDatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Cuadro de diálogo interactivo para añadir, ver y remover múltiples tiempos por día
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
                    'HORARIOS: ${_days[dayIndex].toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  // Botón "+" para agregar un nuevo rango de horas a este día
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFFFF44AA),
                      size: 28,
                    ),
                    onPressed: () async {
                      TimeOfDay horaInicio = TimeOfDay.now();
                      final TimeOfDay? pickedInicio = await showTimePicker(
                        context: context,
                        initialTime: horaInicio,
                        helpText: 'HORA INICIO',
                        builder: (context, child) => _timePickerTheme(child),
                      );
                      if (pickedInicio == null) return;

                      if (!context.mounted) return;

                      TimeOfDay horaFin = TimeOfDay(
                        hour: pickedInicio.hour + 2,
                        minute: pickedInicio.minute,
                      );
                      final TimeOfDay? pickedFin = await showTimePicker(
                        context: context,
                        initialTime: horaFin,
                        helpText: 'HORA FIN',
                        builder: (context, child) => _timePickerTheme(child),
                      );
                      if (pickedFin == null) return;

                      final String nuevoRango =
                          '${pickedInicio.format(context)} - ${pickedFin.format(context)}';

                      setDialogState(() {
                        _scheduleData[dayIndex].add(nuevoRango);
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _scheduleData[dayIndex].isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No hay tiempos agregados.\nToca el "+" arriba para añadir.',
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
                              trailing: IconButton(
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
        backgroundColor: const Color(0xFF1A1040),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '¿Eliminar bloque?',
          style: TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Este horario se borrará por completo de la lista actual.',
          style: TextStyle(
            color: Colors.white70, 
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Cierra la alerta sin borrar
            child: const Text(
              'CANCELAR', 
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Cierra la alerta
              // Borra el horario real dentro del modal de horarios
              setDialogState(() {
                _scheduleData[dayIndex].removeAt(index);
              });
            },
            child: const Text(
              'ELIMINAR', 
              style: TextStyle(
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
                    // Cierra el cuadro guardando el estado general de la app
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'LISTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

  Theme _timePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF44AA),
          onPrimary: Colors.white,
          surface: Color(0xFF1A1040),
          onSurface: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFCC00CC)),
        ),
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
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('No se pudo acceder a la galería o seleccionar la imagen.');
    }
  }

  Future<void> _cargarDatosDeBaseDeDatos() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getProfile(_userId);

    if (data != null) {
      setState(() {
        _nameController.text = data['nombre'] ?? '';

        // Leemos el método de estudio real de la BD y activamos el checkbox correspondiente
        String metodoServer = data['metodo_estudio'] ?? 'POMODORO';
        _methodSelected = [false, false, false, false]; // Reseteamos todos

        if (metodoServer == 'POMODORO') _methodSelected[0] = true;
        if (metodoServer == 'SPACED_REPETITION') _methodSelected[1] = true;
        if (metodoServer == 'ACTIVE_RECALL') _methodSelected[2] = true;
        if (metodoServer == 'FEYNMAN') _methodSelected[3] = true;

        // Si por alguna razón ninguno se marcó, dejamos el primero por defecto
        if (!_methodSelected.contains(true)) _methodSelected[0] = true;
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

    String metodoParaEnviar = "POMODORO";
    if (_methodSelected[0]) {
      metodoParaEnviar = "POMODORO";
    } else if (_methodSelected[2]) {
      metodoParaEnviar = "ACTIVE_RECALL";
    } else if (_methodSelected[3]) {
      metodoParaEnviar = "FEYNMAN";
    }

    // CAMBIO AQUÍ: Recibimos el Map? en lugar de un bool
    final resultado = await ApiService.updateProfile(
      userId: _userId,
      nombre: _nameController.text.trim(),
      apellido: '',
      metodoEstudio: metodoParaEnviar,
    );

    setState(() => _isLoading = false);

    // CAMBIO AQUÍ: Si el resultado NO es null, la actualización fue exitosa
    if (resultado != null) {
      _showSnackBar('¡Perfil guardado en la Base de Datos correctamente!');
    } else {
      _showSnackBar('Error al intentar guardar en el servidor.');
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFCC00CC)),
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.maybePop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1B3A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'TU PERFIL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          // ========================================================
                          // NUEVO BOTÓN: ENTRAR A EDITAR PERFIL (AGREGAR DESDE AQUÍ)
                          // ========================================================
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                // 1. Detectamos cuál método de estudio está seleccionado actualmente en los checkboxes
                                String metodoActual = 'POMODORO';
                                if (_methodSelected[1]) {
                                  metodoActual = 'SPACED_REPETITION';
                                }
                                if (_methodSelected[2]) {
                                  metodoActual = 'ACTIVE_RECALL';
                                }
                                if (_methodSelected[3]) {
                                  metodoActual = 'FEYNMAN';
                                }

                                // 2. Navegamos pasando todos los parámetros obligatorios que exige EditProfileScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      userId: _userId,
                                      nombreInicial: _nameController.text.trim(),
                                      apellidoInicial: '', // Enviamos vacío por integridad, igual que en tu función _handleSend
                                      metodoInicial: metodoActual,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1B3A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFF44AA).withOpacity(0.4),
                                    width: 1,
                                  ), // Borde neón sutil
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Color(0xFFFF44AA),
                                  size: 18,
                                ), // Icono rosa neón tecnológico
                              ),
                            ),
                          ),
                          // ========================================================
                          // TÉRMINO DEL NUEVO BOTÓN
                          // ========================================================
                        ],
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Center(child: _buildAvatar()),
                                const SizedBox(height: 28),
                                const Text(
                                  'Nombre',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Ingresa tu nombre',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF6666AA),
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1B3A),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
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
                                      borderSide: const BorderSide(
                                        color: Color(0xFF5555CC),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'HORARIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Cuadrícula interactiva estilizada
                                _buildGridSchedule(),

                                const SizedBox(height: 28),
                                const Text(
                                  'Metodos de estudio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildMethods(),
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
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _handleSend,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Enviar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
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
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _seleccionarNuevaImagen,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFCC00CC), Color(0xFF6633FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCC00CC).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2A1F5A),
              ),
              clipBehavior: Clip.hardEdge,
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : Image.network(
                      'https://api.dicebear.com/7.x/bottts/png?seed=lumi&backgroundColor=2A1F5A',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 52,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF44AA),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Renderiza los bloques físicos. Se iluminan si el día tiene al menos 1 horario agregado.
  Widget _buildGridSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_days.length, (index) {
            final bool tieneTiempos = _scheduleData[index].isNotEmpty;
            return SizedBox(
              width: 55,
              child: Center(
                child: Text(
                  _days[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    decoration: tieneTiempos
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: const Color(0xFF00AAFF),
                    decorationThickness: 2,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_days.length, (dayIndex) {
            final bool tieneTiempo = _scheduleData[dayIndex].isNotEmpty;

            return GestureDetector(
              onTap: () => _configurarTiemposMultiples(dayIndex),
              child: Column(
                children: List.generate(3, (rowIndex) {
                  Color blockColor = const Color(0xFF3A3560);
                  if (tieneTiempo) {
                    if (rowIndex == 0) blockColor = const Color(0xFF9900CC);
                    if (rowIndex == 1) blockColor = const Color(0xFFFF44AA);
                    if (rowIndex == 2) blockColor = const Color(0xFF6633FF);
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 55,
                    height: 42,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: blockColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: tieneTiempo
                          ? [
                              BoxShadow(
                                color: blockColor.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Pequeño visor de texto resumido abajo de la matriz para verificar los rangos activos
        Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: List.generate(_days.length, (index) {
              if (_scheduleData[index].isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B3A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_days[index].toUpperCase()}: ${_scheduleData[index].length} slots',
                  style: const TextStyle(
                    color: Color(0xFFFF44AA),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMethods() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _methods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) {
        final selected = _methodSelected[index];
        return GestureDetector(
          onTap: () => setState(() => _methodSelected[index] = !selected),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFCC00CC)
                      : const Color(0xFF2A2550),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFCC00CC)
                        : const Color(0xFF5555AA),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                _methods[index],
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

