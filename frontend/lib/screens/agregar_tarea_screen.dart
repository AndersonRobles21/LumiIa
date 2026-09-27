import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '/services/api_service.dart';
import '../services/task_notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';
import 'guia_detalle_screen.dart';

class AgregarTareaScreen extends StatefulWidget {
  final String userId;

  const AgregarTareaScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AgregarTareaScreen> createState() => _AgregarTareaScreenState();
}

class _AgregarTareaScreenState extends State<AgregarTareaScreen>
    with AppLanguageListenerMixin<AgregarTareaScreen> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final _enfoqueController = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now().add(
    const Duration(days: 7),
  );

  bool _isProcessing = false;
  bool _formatosFechaListos = false;

  // El backend recibe estos valores en español.
  String _nivelDificultad = 'Media';

  String get _locale => AppLanguage.instance.isEnglish ? 'en' : 'es';

  String get _fechaFormateada =>
      DateFormat('dd / MMM / yyyy', _locale).format(_fechaSeleccionada);

  @override
  void initState() {
    super.initState();
    _inicializarFormatosFecha();
  }

  Future<void> _inicializarFormatosFecha() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');

    if (!mounted) return;

    setState(() => _formatosFechaListos = true);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    _enfoqueController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: Locale(_locale),
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFFFF44AA),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  Future<void> _enviarAIA() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Por favor, pon un título al trabajo o tarea.',
              'Please enter a title for the assignment or task.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final resultado = await ApiService.generarPlanIA(
      userId: widget.userId,
      titulo: _tituloController.text.trim(),
      descripcion: _descController.text.trim(),
      fechaEntrega: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
      metodoEstudio: 'Auto',
      dificultad: _nivelDificultad,
      enfoqueAdicional: _enfoqueController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (resultado != null && resultado['plan'] != null) {
      final recomendacion = resultado['recomendacion_tiempo']?.toString();

      if (recomendacion != null && recomendacion.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(recomendacion),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      final tareasActualizadas =
          await ApiService.getPlanesEstudio(widget.userId);

      if (tareasActualizadas != null) {
        await TaskNotificationService.instance.syncTasks(tareasActualizadas);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuiaDetalleScreen(
            guiaData: resultado['plan'],
          ),
        ),
      );

      if (mounted) Navigator.pop(context);
    } else {
      final mensaje = resultado?['mensaje']?.toString();

      final mensajeVisible = mensaje == null || mensaje.isEmpty
          ? tr(
              'Error al conectar con el servidor. '
              'Verifica que el backend esté corriendo.',
              'Could not connect to the server. '
              'Check that the backend is running.',
            )
          : mensaje;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeVisible),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_formatosFechaListos) {
      return Scaffold(
        backgroundColor: LumiAppTheme.pageBackground(context),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF44AA),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LumiAppTheme.primaryText(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.esEscritorio(context)
                  ? 700
                  : double.infinity,
            ),
            child: Container(
              width: double.infinity,
              padding: Responsive.esEscritorio(context)
                  ? const EdgeInsets.all(28)
                  : EdgeInsets.zero,
              decoration: Responsive.esEscritorio(context)
                  ? BoxDecoration(
                      color: LumiAppTheme.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: LumiAppTheme.outline(context),
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Nueva tarea', 'New task'),
                                style: TextStyle(
                                  color: LumiAppTheme.primaryText(context),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  'Organiza tu próximo objetivo de estudio',
                                  'Organize your next study goal',
                                ),
                                style: TextStyle(
                                  color: LumiAppTheme.secondaryText(context),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildReminderCard(context),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: Responsive.esEscritorio(context)
                            ? 220
                            : Responsive.esTablet(context)
                                ? 180
                                : 112,
                        height: Responsive.esEscritorio(context)
                            ? 220
                            : Responsive.esTablet(context)
                                ? 180
                                : 112,
                        child: Image.asset(
                          'logo/tarea.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.smart_toy,
                            color: Color(0xFF00F0FF),
                            size: 90,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _tituloController,
                    style: TextStyle(
                      color: LumiAppTheme.primaryText(context),
                    ),
                    decoration: _inputDecoration(
                      context,
                      tr('Título del trabajo', 'Assignment title'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    style: TextStyle(
                      color: LumiAppTheme.primaryText(context),
                    ),
                    decoration: _inputDecoration(
                      context,
                      tr(
                        'Descripción o rúbrica...',
                        'Description or rubric...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _seleccionarFecha(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _fieldBoxDecoration(context),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xFFFF44AA),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr(
                                'Fecha límite: $_fechaFormateada',
                                'Due date: $_fechaFormateada',
                              ),
                              style: TextStyle(
                                color: LumiAppTheme.primaryText(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.edit_calendar,
                            color: LumiAppTheme.secondaryText(context),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr(
                      'Nivel de dificultad percibido',
                      'Perceived difficulty',
                    ),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: _fieldBoxDecoration(context),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _nivelDificultad,
                        dropdownColor: LumiAppTheme.surface(context),
                        style: TextStyle(
                          color: LumiAppTheme.primaryText(context),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFFF44AA),
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'Baja',
                            child: Text(
                              tr('Baja (fácil / rápido)', 'Low (easy / quick)'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Media',
                            child: Text(
                              tr('Media (equilibrado)', 'Medium (balanced)'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Alta',
                            child: Text(
                              tr(
                                'Alta (exigente / profundo)',
                                'High (demanding / in-depth)',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Extrema',
                            child: Text(
                              tr(
                                'Extrema (proyecto complejo / tesis)',
                                'Extreme (complex project / thesis)',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (valor) {
                          if (valor != null) {
                            setState(() => _nivelDificultad = valor);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _enfoqueController,
                    style: TextStyle(
                      color: LumiAppTheme.primaryText(context),
                    ),
                    decoration: _inputDecoration(
                      context,
                      tr(
                        'Enfoque especial (ej. práctica en código, lectura, resumen)',
                        'Special focus (e.g. coding practice, reading, summary)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                      child: _buildSubmitButtonContent(context),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildLumiAdviceCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    final ingles = AppLanguage.instance.isEnglish;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFB026FF),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontSize: 12.5,
                  height: 1.35,
                ),
                children: ingles
                    ? const [
                        TextSpan(
                          text: 'Remember:\n',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: 'In your title, specify whether it is a '),
                        TextSpan(
                          text: 'Task',
                          style: TextStyle(
                            color: Color(0xFF9D4EDD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'Project',
                          style: TextStyle(
                            color: Color(0xFFFFB800),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ', or an '),
                        TextSpan(
                          text: 'Exam.',
                          style: TextStyle(
                            color: Color(0xFFFF4D94),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : const [
                        TextSpan(
                          text: 'Recuerda:\n',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'En el título de tu trabajo debes especificar si es ',
                        ),
                        TextSpan(
                          text: 'Trabajo',
                          style: TextStyle(
                            color: Color(0xFF9D4EDD),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'Proyecto',
                          style: TextStyle(
                            color: Color(0xFFFFB800),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' o '),
                        TextSpan(
                          text: 'Examen.',
                          style: TextStyle(
                            color: Color(0xFFFF4D94),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLumiAdviceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB026FF),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'logo/lumi_tarea.png',
            width: 200,
            height: 190,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFFFF44AA),
              size: 52,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: tr(
                      'Cuéntame qué tienes que hacer\ny yo te ayudo a ',
                      'Tell me what you need to do,\nand I will help you ',
                    ),
                  ),
                  TextSpan(
                    text: tr('organizarlo.', 'organize it.'),
                    style: const TextStyle(
                      color: Color(0xFFB026FF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _fieldBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: LumiAppTheme.surface(context),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: LumiAppTheme.outline(context),
        width: 1.3,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: LumiAppTheme.secondaryText(context).withValues(alpha: 0.8),
        fontSize: 13,
      ),
      filled: true,
      fillColor: LumiAppTheme.surface(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: LumiAppTheme.outline(context),
          width: 1.3,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF8B5CF6),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildSubmitButtonContent(BuildContext context) {
    if (_isProcessing) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return Text(
      tr('GENERAR CRONOGRAMA', 'GENERATE SCHEDULE'),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: Responsive.tamanioSubtitulo(context) - 2,
      ),
    );
  }
}