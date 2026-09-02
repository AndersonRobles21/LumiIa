import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/services/api_service.dart';
import 'guia_detalle_screen.dart';
import '../utils/responsive.dart';

class AgregarTareaScreen extends StatefulWidget {
  final String userId;
  const AgregarTareaScreen({super.key, required this.userId});

  @override
  State<AgregarTareaScreen> createState() => _AgregarTareaScreenState();
}

class _AgregarTareaScreenState extends State<AgregarTareaScreen> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final _enfoqueController = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 7));
  bool _isProcessing = false;

  // Dificultad para ajustar la densidad de carga de trabajo
  String _nivelDificultad = 'Media';

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    _enfoqueController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF44AA),
            surface: Color(0xFF1E1B3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  void _enviarAIA() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, pon un título al trabajo o tarea'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Se envía 'Auto' en metodoEstudio para que la IA decida la mejor estrategia
    final resultado = await ApiService.generarPlanIA(
      userId: widget.userId,
      titulo: _tituloController.text.trim(),
      descripcion: _descController.text.trim(),
      fechaEntrega: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
      metodoEstudio: 'Auto', // 👈 La IA selecciona el método ideal
      dificultad: _nivelDificultad,
      enfoqueAdicional: _enfoqueController.text.trim(),
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (resultado != null && resultado['plan'] != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuiaDetalleScreen(guiaData: resultado['plan']),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error al conectar con el servidor. Verifica que el backend esté corriendo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ ENCABEZADO SUPERIOR RESPONSIVO CON IMAGEN 'logo/tarea.png'
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva tarea',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Organiza tu próximo objetivo de estudio',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 🖼️ Nueva imagen 'logo/recordatorio.png'
                          SizedBox(
                            width: double.infinity,
                            height: Responsive.esEscritorio(context)
                                ? 160
                                : Responsive.esTablet(context)
                                    ? 140
                                    : 120,
                            child: Image.asset(
                              'logo/recordatorio.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.notifications,
                                    color: Color(0xFFFF44AA),
                                    size: 40,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: Responsive.esEscritorio(context) ? 220 : Responsive.esTablet(context) ? 180 : 112,
                    height: Responsive.esEscritorio(context) ? 220 : Responsive.esTablet(context) ? 180 : 112,
                    child: Image.asset(
                      'logo/tarea.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.smart_toy,
                        color: Color(0xFF00F0FF),
                        size: 90,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Título
              TextField(
                controller: _tituloController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Título del trabajo'),
              ),
              const SizedBox(height: 15),

              // Descripción / Rúbrica
              TextField(
                controller: _descController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Descripción o rúbrica....'),
              ),
              const SizedBox(height: 20),

              // Selector de Fecha Límite Editable
              GestureDetector(
                onTap: () => _seleccionarFecha(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16003A),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xFFFF44AA),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Fecha Límite: ${DateFormat('dd / MMM / yyyy').format(_fechaSeleccionada)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_calendar,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nivel de Dificultad
              const Text(
                'Nivel de Dificultad Percibido',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16003A),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _nivelDificultad,
                    dropdownColor: const Color(0xFF1E1B3A),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFFFF44AA),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Baja',
                        child: Text('Baja (Fácil / Rápido)'),
                      ),
                      DropdownMenuItem(
                        value: 'Media',
                        child: Text('Media (Equilibrado)'),
                      ),
                      DropdownMenuItem(
                        value: 'Alta',
                        child: Text('Alta (Exigente / Profundo)'),
                      ),
                      DropdownMenuItem(
                        value: 'Extrema',
                        child: Text('Extrema (Proyecto Complejo / Tesis)'),
                      ),
                    ],
                    onChanged: (String? nuevoValor) {
                      if (nuevoValor != null) {
                        setState(() => _nivelDificultad = nuevoValor);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Enfoque adicional para la IA
              TextField(
                controller: _enfoqueController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  'Enfoque especial (Ej. Práctica en código, lectura, resumen)',
                ),
              ),
              const SizedBox(height: 30),

              // Botón de Envío
              SizedBox(
                width: double.infinity,
                height: Responsive.altoBoton(context) + 8,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _enviarAIA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF44AA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'GENERAR CRONOGRAMA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: Responsive.tamanioSubtitulo(context) - 2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 25),

              // 🖼️ BANNER INFERIOR CON LA IMAGEN 'logo/consejo_tarea.png'
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.esEscritorio(context) ? 900 : double.infinity,
                    maxHeight: Responsive.esMovil(context) ? 150 : 220,
                  ),
                  child: Image.asset(
                    'logo/consejo_tarea.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B3A),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Cuéntame qué tienes que hacer y yo te ayudo a organizarlo.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF16003A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );
}
