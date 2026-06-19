import 'package:flutter/material.dart';
import '../services/api_service.dart'; 
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 

class EditProfileScreen extends StatefulWidget {
  final String userId; 
  final String nombreInicial;
  final String apellidoInicial;
  final String metodoInicial;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.nombreInicial,
    required this.apellidoInicial,
    required this.metodoInicial,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _visualizarEnPerfil = true; 
  String _selectedMethod = 'pomodoro'; 

  // --- VARIABLES PARA EL MANEJO DEL HORARIO EN BLOQUES ---
  final List<String> _days = ['lun', 'mar', 'mie', 'jue', 'vie'];
  late List<List<String>> _scheduleData;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 1. Inicializamos la matriz de horarios vacía para los 5 días
    _scheduleData = List.generate(5, (_) => []);
    
    // 2. Pre-cargamos los datos inmediatos que vienen del constructor para evitar pantallas vacías
    _nameController.text = widget.nombreInicial;
    _mapearMetodoInicial(widget.metodoInicial);

    // 3. Traemos el horario actualizado desde el servidor
    _cargarDatosActuales();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Sincroniza el formato de texto de la navegación con el del Dropdown
  void _mapearMetodoInicial(String metodo) {
    switch (metodo) {
      case 'SPACED_REPETITION':
        _selectedMethod = 'Spaced Repetition';
        break;
      case 'ACTIVE_RECALL':
        _selectedMethod = 'Active Recall';
        break;
      case 'FEYNMAN':
        _selectedMethod = 'Feynman';
        break;
      default:
        _selectedMethod = 'pomodoro';
    }
  }

  // Carga los datos complementarios desde Node.js/PostgreSQL
  Future<void> _cargarDatosActuales() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getProfile(widget.userId);
      
      // Control de brecha asíncrona: detiene el hilo si la pantalla se cerró en medio de la petición
      if (!mounted) return;

      if (data != null) {
        setState(() {
          if (data['nombre'] != null && data['nombre'].toString().isNotEmpty) {
            _nameController.text = data['nombre'];
          }
          
          // Mapeamos el horario que viene en texto desde la base de datos
          if (data['horario'] != null) {
            List<dynamic> horarioServer = data['horario'];
            for (int i = 0; i < horarioServer.length && i < 5; i++) {
              String diaTexto = horarioServer[i].toString();
              if (diaTexto != 'Sin asignar' && diaTexto.isNotEmpty) {
                _scheduleData[i] = diaTexto.split(', ');
              } else {
                _scheduleData[i] = [];
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando horario: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Diálogo interactivo para añadir/remover las horas disponibles por día
  Future<void> _configurarTiemposMultiples(int dayIndex) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F0647),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EDITAR HORA: ${_days[dayIndex].toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF7B51D3), size: 28),
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

                      TimeOfDay horaFin = TimeOfDay(hour: pickedInicio.hour + 2, minute: pickedInicio.minute);
                      final TimeOfDay? pickedFin = await showTimePicker(
                        context: context,
                        initialTime: horaFin,
                        helpText: 'HORA FIN',
                        builder: (context, child) => _timePickerTheme(child),
                      );
                      if (pickedFin == null) return;
                      if (!context.mounted) return;

                      final String nuevoRango = '${pickedInicio.format(context)} - ${pickedFin.format(context)}';
                      
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
                          'No hay horas en este día.\nToca el "+" para añadir.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
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
                              color: const Color(0xFF2C274C).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.access_time_filled, color: Color(0xFF7B51D3), size: 18),
                              title: Text(
                                _scheduleData[dayIndex][index],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                onPressed: () {
                                  setDialogState(() {
                                    _scheduleData[dayIndex].removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {}); 
                    Navigator.pop(context);
                  },
                  child: const Text('ACEPTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          primary: Color(0xFF7B51D3),
          onPrimary: Colors.white,
          surface: Color(0xFF1F0647),
          onSurface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _seleccionarImagen() async {
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
      _showSnackBar('No se pudo acceder a la galería.');
    }
  }

  // Guarda toda la información modificada en la Base de Datos
  void _guardarCambios() async {
  if (_nameController.text.trim().isEmpty) {
    _showSnackBar('Por favor, ingresa tu nombre.');
    return;
  }

  setState(() => _isLoading = true);

  // 1. Convertimos el string del dropdown al formato en MAYÚSCULAS esperado por el backend
  String metodoBackend = 'POMODORO';
  if (_selectedMethod == 'Spaced Repetition') metodoBackend = 'SPACED_REPETITION';
  if (_selectedMethod == 'Active Recall') metodoBackend = 'ACTIVE_RECALL';
  if (_selectedMethod == 'Feynman') metodoBackend = 'FEYNMAN';

  // 2. CORREGIDO: Recibimos el resultado como un mapa (o null) en vez de un bool
  final resultado = await ApiService.updateProfile(
    userId: widget.userId,
    nombre: _nameController.text.trim(),
    apellido: widget.apellidoInicial, 
    metodoEstudio: metodoBackend,
  );

  if (!mounted) return;
  setState(() => _isLoading = false);

  // 3. CORREGIDO: Si el resultado no es nulo, significa que el backend respondió con éxito (200 OK)
  if (resultado != null) {
    _showSnackBar('¡Perfil y método actualizados con éxito!');
    if (mounted) Navigator.pop(context, true); 
  } else {
    _showSnackBar('Error al conectar con el servidor.');
  }
}

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            colors: [Color(0xFF1F0647), Color(0xFF0B0813)], 
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFCC00CC)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // --- HEADER ---
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'EDITAR PERFIL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
                      ),
                      const SizedBox(height: 35),

                      // --- AVATAR ---
                      Center(
                        child: GestureDetector(
                          onTap: _seleccionarImagen,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(_imageFile!, width: 120, height: 120, fit: BoxFit.cover)
                                  : Image.network(
                                      'https://api.dicebear.com/7.x/bottts/png?seed=lumi&backgroundColor=2A1F5A',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      // --- NOMBRE ---
                      const Text('Nombre', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Ingresa tu nombre',
                      ),
                      const SizedBox(height: 24),

                      // --- HORARIO INTERACTIVO EN BLOQUES ---
                      const Text('Horario (Toca un día para editarlo)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildGridSchedule(),
                      const SizedBox(height: 24),

                      // --- MÉTODOS DISPONIBLES ---
                      const Text('Método disponible', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildDropdownField(),
                      const SizedBox(height: 30),

                      // --- SWITCH ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Visualizar en el perfil',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _visualizarEnPerfil,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF7B51D3),
                            inactiveTrackColor: const Color(0xFF2C274C),
                            onChanged: (value) {
                              setState(() {
                                _visualizarEnPerfil = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // --- BOTÓN GUARDAR ---
                      Center(
                        child: ElevatedButton(
                          onPressed: _guardarCambios,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B51D3),
                            padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // --- CUADRÍCULA DE HORARIO ---
  Widget _buildGridSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C274C).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_days.length, (index) {
              final bool tieneTiempos = _scheduleData[index].isNotEmpty;
              return SizedBox(
                width: 45,
                child: Center(
                  child: Text(
                    _days[index],
                    style: TextStyle(
                      color: tieneTiempos ? const Color(0xFF7B51D3) : Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_days.length, (dayIndex) {
              final bool tieneTiempo = _scheduleData[dayIndex].isNotEmpty;
              
              return GestureDetector(
                onTap: () => _configurarTiemposMultiples(dayIndex),
                child: Column(
                  children: List.generate(3, (rowIndex) {
                    Color blockColor = const Color(0xFF2C274C).withOpacity(0.8); 
                    if (tieneTiempo) {
                      if (rowIndex == 0) blockColor = const Color(0xFF5A32A8);
                      if (rowIndex == 1) blockColor = const Color(0xFF7B51D3);
                      if (rowIndex == 2) blockColor = const Color(0xFF9F7BE6);
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 45,
                      height: 35,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF2C274C).withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C274C).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMethod,
          dropdownColor: const Color(0xFF1F0647),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMethod = newValue;
              });
            }
          },
          items: <String>['pomodoro', 'Spaced Repetition', 'Active Recall', 'Feynman']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}