import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/services/api_service.dart';
import 'guia_detalle_screen.dart';
import '../utils/responsive.dart';
import '../services/task_notification_service.dart';
import '../theme/app_theme.dart';
import 'app_language.dart';

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

  // Se mantiene en español porque se envía así al backend.
  String _nivelDificultad = 'Media';

  String get _locale => AppLanguage.instance.isEnglish ? 'en' : 'es';

  String get _fechaFormateada =>
      DateFormat('dd / MMM / yyyy', _locale).format(_fechaSeleccionada);

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

  void _enviarAIA() async {
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

      if (mounted) {
        Navigator.pop(context);
      }
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
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 10,
          ),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
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
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                  errorBuilder: (_, __, ___) => const Icon(
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
                      decoration: BoxDecoration(
                        color: LumiAppTheme.surface(context),
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
                            tr(
                              'Fecha límite: $_fechaFormateada',
                              'Due date: $_fechaFormateada',
                            ),
                            style: TextStyle(
                              color: LumiAppTheme.primaryText(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
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
                    decoration: BoxDecoration(
                      color: LumiAppTheme.surface(context),
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                              tr(
                                'Media (equilibrado)',
                                'Medium (balanced)',
                              ),
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
                        onChanged: (nuevoValor) {
                          if (nuevoValor != null) {
                            setState(
                              () => _nivelDificultad = nuevoValor,
                            );
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
                    child: Responsive.esEscritorio(context)
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF44AA),
                                  Color(0xFFB026FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isProcessing ? null : _enviarAIA,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: _buildSubmitButtonContent(context),
                            ),
                          )
                        : ElevatedButton(
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
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.esEscritorio(context)
                            ? 900
                            : double.infinity,
                        maxHeight: Responsive.esMovil(context) ? 150 : 220,
                      ),
                      child: Image.asset(
                        'logo/consejo_tarea.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: LumiAppTheme.surface(context),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            tr(
                              'Cuéntame qué tienes que hacer y yo te ayudo a organizarlo.',
                              'Tell me what you need to do and I will help you organize it.',
                            ),
                            style: TextStyle(
                              color: LumiAppTheme.secondaryText(context),
                              fontSize: 12,
                            ),
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
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: LumiAppTheme.secondaryText(context),
        fontSize: 13,
      ),
      filled: true,
      fillColor: LumiAppTheme.surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
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