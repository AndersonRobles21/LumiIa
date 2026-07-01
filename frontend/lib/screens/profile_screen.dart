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

  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  List<List<String>> _scheduleData = [[], [], [], [], [], [], []];

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
      _horasController.text = (perfilEstudio['horas_disponibles'] ?? 0).toString();
      _objetivoController.text = perfilEstudio['objetivo'] ?? '';
      _nivelProcrastinacion = perfilEstudio['nivel_procrastinacion'] ?? 1;
      _fotoPerfilUrl = perfilEstudio['foto_perfil'];

      final horarios = data['horarios'] as List? ?? [];
      _scheduleData = [[], [], [], [], [], [], []];
      for (final h in horarios) {
        final diaIndex = _dias.indexOf(h['dia']);
        if (diaIndex != -1) {
          _scheduleData[diaIndex].add('${h['hora_inicio']} - ${h['hora_fin']}');
        }
      }
    }

    setState(() => _isLoading = false);
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
            'hora_inicio': partes[0].trim(),
            'hora_fin': partes[1].trim(),
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

    if (resultado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el perfil')),
      );
    }
  }

  // ---------------------------------------------------------------
  // MODAL DE HORARIOS POR DÍA
  // ---------------------------------------------------------------
  void _abrirModalHorario(int dayIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1040),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dias[dayIndex],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('CERRAR', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirSelectorReloj(int dayIndex, int? index, StateSetter setDialogState) async {
    final inicio = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFFF44AA), surface: Color(0xFF1A1040)),
        ),
        child: child!,
      ),
    );
    if (inicio == null) return;

    final fin = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFFF44AA), surface: Color(0xFF1A1040)),
        ),
        child: child!,
      ),
    );
    if (fin == null) return;

    final bloque = '${inicio.format(context)} - ${fin.format(context)}';

    setDialogState(() {
      if (index != null) {
        _scheduleData[dayIndex][index] = bloque;
      } else {
        _scheduleData[dayIndex].add(bloque);
      }
    });
  }

  void _confirmarEliminarBloque(int dayIndex, int index, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1040),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            '¿Eliminar bloque?',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Este horario se borrará por completo de la lista actual.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setDialogState(() {
                  _scheduleData[dayIndex].removeAt(index);
                });
              },
              child: const Text(
                'ELIMINAR',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0813),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF44AA))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfiguracionScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _seleccionarFoto,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2A1F5A),
                  backgroundImage: _fotoPerfilLocal != null
                      ? FileImage(_fotoPerfilLocal!)
                      : (_fotoPerfilUrl != null ? NetworkImage(_fotoPerfilUrl!) : null) as ImageProvider?,
                  child: (_fotoPerfilLocal == null && _fotoPerfilUrl == null)
                      ? const Icon(Icons.camera_alt, color: Colors.white54, size: 30)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Nombre'),
            _buildTextField(_nombreController),
            const SizedBox(height: 16),

            _buildLabel('Apellido'),
            _buildTextField(_apellidoController),
            const SizedBox(height: 16),

            _buildLabel('Horas disponibles al día'),
            _buildTextField(_horasController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            _buildLabel('Objetivo'),
            _buildTextField(_objetivoController, maxLines: 3),
            const SizedBox(height: 16),

            _buildLabel('Nivel de procrastinación (1-5)'),
            Slider(
              value: _nivelProcrastinacion.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: const Color(0xFFFF44AA),
              label: _nivelProcrastinacion.toString(),
              onChanged: (v) => setState(() => _nivelProcrastinacion = v.round()),
            ),
            const SizedBox(height: 24),

            const Text('Horario semanal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...List.generate(_dias.length, (i) {
              return Card(
                color: const Color(0xFF1F1A3A),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(_dias[i], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _scheduleData[i].isEmpty ? 'Sin horarios' : _scheduleData[i].join(', '),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () => _abrirModalHorario(i),
                ),
              );
            }),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF44AA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR PERFIL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1F1A3A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}