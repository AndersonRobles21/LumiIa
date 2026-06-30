import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/services/api_service.dart';
import 'guia_detalle_screen.dart';

class AgregarTareaScreen extends StatefulWidget {
  final String userId;
  const AgregarTareaScreen({super.key, required this.userId});

  @override
  State<AgregarTareaScreen> createState() => _AgregarTareaScreenState();
}

class _AgregarTareaScreenState extends State<AgregarTareaScreen> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 7));
  bool _isProcessing = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
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
        const SnackBar(content: Text('Por favor, pon un título')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final resultado = await ApiService.generarPlanIA(
      userId: widget.userId,
      titulo: _tituloController.text.trim(),
      descripcion: _descController.text.trim(),
      fechaEntrega: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

   if (resultado != null && resultado['plan'] != null) {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GuiaDetalleScreen(
        guiaData: resultado['plan'],
      ),
    ),
  );

  if (mounted) {
    Navigator.pop(context);
  }
} else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al conectar con el servidor. Verifica que el backend esté corriendo.'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Text(
                'NUEVA TAREA',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Se guardará en tu plan de estudio',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _tituloController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Título del trabajo'),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _descController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Descripción o rúbrica...'),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => _seleccionarFecha(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B3A),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFFFF44AA)),
                      const SizedBox(width: 10),
                      Text(
                        'Fecha Límite: ${DateFormat('dd / MMM / yyyy').format(_fechaSeleccionada)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _enviarAIA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF44AA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'GENERAR CRONOGRAMA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF16003A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      );
}