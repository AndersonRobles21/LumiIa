import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'active_recall_screen.dart';
import 'app_language.dart';
import 'feynman_screen.dart';
import 'pomodoro_screen.dart';
import 'seleccionar_metodo_screen.dart';
import 'spaced_repetition_screen.dart';

class GuiaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> guiaData;

  const GuiaDetalleScreen({
    super.key,
    required this.guiaData,
  });

  @override
  State<GuiaDetalleScreen> createState() => _GuiaDetalleScreenState();
}

class _GuiaDetalleScreenState extends State<GuiaDetalleScreen>
    with AppLanguageListenerMixin<GuiaDetalleScreen> {
  bool _isLoading = true;
  bool _cambiandoMetodo = false;

  Map<String, dynamic> guiaActual = {};
  List<dynamic> fasesPasos = [];
  List<dynamic> _historialConversaciones = [];
  List<dynamic> consejos = [];
  List<dynamic> recursos = [];
  List<dynamic> conceptosClave = [];
  List<dynamic> preguntasRecall = [];

  int _faseActualIndex = 0;
  List<bool> cargandoFases = [];

  final Map<int, int> _nivelesExplicacionFase = {};
  int _nivelExplicacionGeneral = 0;

  final List<Map<String, dynamic>> _mensajes = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _sidebarSearchController =
      TextEditingController();

  String _userId = '';

  String formatearTiempo(int minutos) {
    final horas = minutos ~/ 60;
    final minutosRestantes = minutos % 60;

    if (horas == 0) {
      return tr('$minutosRestantes min', '$minutosRestantes min');
    }

    if (minutosRestantes == 0) {
      return tr('$horas h', '$horas h');
    }

    return tr(
      '$horas h $minutosRestantes min',
      '$horas h $minutosRestantes min',
    );
  }

  Future<void> _abrirUrl(String urlString) async {
    if (urlString.trim().isEmpty) return;

    final uri = Uri.parse(urlString.trim());

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'No se pudo abrir el enlace: $urlString',
              'Could not open the link: $urlString',
            ),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _userId = widget.guiaData['usuario_id']?.toString() ?? '';
    _cargarDetallePlan();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sidebarSearchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetallePlan() async {
    final planId = widget.guiaData['id'] ?? widget.guiaData['plan_id'];

    if (planId != null) {
      final detalle = await ApiService.obtenerPlan(planId.toString());

      if (detalle != null && mounted) {
        if (_userId.isEmpty && detalle['usuario_id'] != null) {
          _userId = detalle['usuario_id'].toString();
        }

        setState(() {
          guiaActual = Map<String, dynamic>.from(detalle);
          _extraerListasDetalle();
          _inicializarMensajesChat();
          _isLoading = false;
        });

        _scrollToBottom();
        _cargarHistorialConversaciones();
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      guiaActual = Map<String, dynamic>.from(widget.guiaData);
      _extraerListasDetalle();
      _inicializarMensajesChat();
      _isLoading = false;
    });

    _scrollToBottom();
    _cargarHistorialConversaciones();
  }

  Future<void> _cargarHistorialConversaciones() async {
    if (_userId.isEmpty) return;

    final historial = await ApiService.obtenerHistorial(_userId);

    if (!mounted || historial == null) return;

    setState(() => _historialConversaciones = historial);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _extraerListasDetalle() {
    consejos = (guiaActual['consejos'] as List?) ?? [];
    recursos = (guiaActual['recursos'] as List?) ?? [];
    conceptosClave = (guiaActual['conceptos_clave'] as List?) ?? [];
    preguntasRecall = (guiaActual['preguntas_recall'] as List?) ?? [];

    fasesPasos = (guiaActual['pasos'] as List?) ?? [];
    cargandoFases = List.generate(fasesPasos.length, (_) => false);
  }

  void _inicializarMensajesChat() {
    final nombrePlan = guiaActual['nombre'] ??
        guiaActual['titulo'] ??
        tr('Trabajo o tarea', 'Work or assignment');
    final metodoEstudio = guiaActual['metodo_estudio'] ?? 'Pomodoro';
    final recomendacionTiempo = guiaActual['recomendacion_tiempo'];

    _mensajes.clear();

    if (recomendacionTiempo != null &&
        recomendacionTiempo.toString().isNotEmpty) {
      _mensajes.add({
        'esBot': true,
        'texto': tr(
          '⚠️ ALERTA DE TIEMPO:\n$recomendacionTiempo',
          '⚠️ TIME ALERT:\n$recomendacionTiempo',
        ),
        'tipo': 'alerta_tiempo',
      });
    }

    var materialInicial = tr(
      '🛠️ HERRAMIENTAS Y RECURSOS DE APOYO PARA TU TAREA:\n\n',
      '🛠️ TOOLS AND SUPPORTING RESOURCES FOR YOUR ASSIGNMENT:\n\n',
    );

    if (recursos.isNotEmpty) {
      for (var i = 0; i < recursos.length; i++) {
        final rec = recursos[i];
        final nombreRec = rec['nombre'] ??
            rec['titulo'] ??
            tr('Material de apoyo ${i + 1}', 'Support material ${i + 1}');

        materialInicial += '• ${i + 1}. $nombreRec\n\n';
      }
    } else {
      materialInicial += tr(
        '• Ten listos tus apuntes, editor de código o libreta de notas antes de comenzar.\n\n',
        '• Have your notes, code editor, or notebook ready before you begin.\n\n',
      );
    }

    if (consejos.isNotEmpty) {
      materialInicial += tr(
        '💡 Consejo general de Lumi:\n${consejos.first}',
        '💡 General Lumi tip:\n${consejos.first}',
      );
    }

    _mensajes.add({
      'esBot': true,
      'texto': materialInicial,
      'tipo': 'herramientas_iniciales',
      'listaRecursos': recursos,
    });

    _mensajes.add({
      'esBot': true,
      'texto': tr(
        '¡Hola! Vamos a empezar a trabajar en tu "$nombrePlan".\n\nHe seleccionado el método **$metodoEstudio** porque es el que mejor se adapta a esta actividad. ¿Deseas mantenerlo o prefieres cambiarlo?',
        'Hello! Let’s start working on "$nombrePlan".\n\nI selected the **$metodoEstudio** method because it best fits this activity. Would you like to keep it or change it?',
      ),
      'tipo': 'bienvenida',
    });

    var hayFasesPendientes = false;

    for (var i = 0; i < fasesPasos.length; i++) {
      final fase = fasesPasos[i];

      if (fase is Map) {
        final subpasos = (fase['subpasos'] as List?) ?? [];
        final todosCompletos = subpasos.isNotEmpty &&
            subpasos.every((sub) => sub['completado'] == true);
        final faseCompletaDirecta = fase['completado'] == true;

        if (todosCompletos || faseCompletaDirecta) {
          _mensajes.add({
            'esBot': true,
            'texto': tr(
              '📋 PASO ${i + 1} DE ${fasesPasos.length}: ${fase['titulo'] ?? 'Paso'}\n\n✅ ¡Fase completada con anterioridad!',
              '📋 STEP ${i + 1} OF ${fasesPasos.length}: ${fase['titulo'] ?? 'Step'}\n\n✅ This phase was already completed!',
            ),
            'faseIndexChat': i,
          });
        } else {
          _faseActualIndex = i;
          hayFasesPendientes = true;
          _agregarMensajeFase(i);
          break;
        }
      }
    }

    if (!hayFasesPendientes && fasesPasos.isNotEmpty) {
      _faseActualIndex = fasesPasos.length - 1;

      _mensajes.add({
        'esBot': true,
        'texto': tr(
          '🏆 ¡Increíble! Has finalizado por completo todos los pasos de esta guía.',
          '🏆 Amazing! You have completed every step in this guide.',
        ),
      });
    }
  }

  void _agregarMensajeFase(int index) {
    if (index >= fasesPasos.length) return;

    final fase = fasesPasos[index];
    final tituloFase =
        fase['titulo'] ?? tr('Paso ${index + 1}', 'Step ${index + 1}');
    final descFase = fase['descripcion'] ?? '';
    final consejoPaso = fase['consejo_paso'] ?? fase['consejo'] ?? '';
    final duracion = fase['duracion_minutos'] ?? 20;

    var mensajePaso = tr(
      '📋 PASO ${index + 1} DE ${fasesPasos.length}: $tituloFase\n\n'
      '🎯 ¿Qué debes hacer exactamente?\n$descFase\n\n'
      '⏱️ Tiempo estimado de enfoque: $duracion minutos.',
      '📋 STEP ${index + 1} OF ${fasesPasos.length}: $tituloFase\n\n'
      '🎯 What exactly should you do?\n$descFase\n\n'
      '⏱️ Estimated focus time: $duracion minutes.',
    );

    if (consejoPaso.toString().isNotEmpty) {
      mensajePaso += tr(
        '\n\n💡 Tip clave para este paso:\n$consejoPaso',
        '\n\n💡 Key tip for this step:\n$consejoPaso',
      );
    }

    _mensajes.add({
      'esBot': true,
      'texto': mensajePaso,
      'faseIndexChat': index,
    });
  }

  Future<void> _reiniciarProgreso() async {
    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    for (final fase in fasesPasos) {
      if (fase is Map) {
        fase['completado'] = false;
        final subpasos = (fase['subpasos'] as List?) ?? [];

        for (final sub in subpasos) {
          if (sub is Map) sub['completado'] = false;
        }
      }
    }

    if (planId != null) {
      await ApiService.actualizarProgresoPlan(
        planId: planId,
        pasos: fasesPasos,
      );
    }

    if (!mounted) return;

    setState(() {
      _faseActualIndex = 0;
      _inicializarMensajesChat();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            '🔄 ¡Progreso reiniciado! Volviste al Paso 1.',
            '🔄 Progress reset! You are back at Step 1.',
          ),
        ),
        backgroundColor: const Color(0xFF00F0FF),
      ),
    );

    _scrollToBottom();
  }

  Future<void> _actualizarSubpasoFase(
    int faseIndex,
    int subpasoIndex,
    bool? val,
  ) async {
    if (faseIndex < fasesPasos.length) {
      final fase = fasesPasos[faseIndex];
      final subpasosList = (fase['subpasos'] as List?) ?? [];

      if (subpasoIndex < subpasosList.length) {
        subpasosList[subpasoIndex]['completado'] = val ?? false;
      }
    }

    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    if (planId != null) {
      await ApiService.actualizarProgresoPlan(
        planId: planId,
        pasos: fasesPasos,
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _completarFasePaso(int faseIndex) async {
    if (faseIndex >= fasesPasos.length) return;

    final fase = fasesPasos[faseIndex];
    final subpasosList = (fase['subpasos'] as List?) ?? [];

    final faltanSubpasos =
        subpasosList.any((sub) => sub['completado'] != true);

    if (faltanSubpasos && subpasosList.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              '⚠️ Debes marcar todos los subpasos de esta fase antes de continuar.',
              '⚠️ Complete every substep in this phase before continuing.',
            ),
          ),
          backgroundColor: const Color(0xFFFF44AA),
        ),
      );
      return;
    }

    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    setState(() => cargandoFases[faseIndex] = true);

    fase['completado'] = true;

    for (final sub in subpasosList) {
      sub['completado'] = true;
    }

    if (planId != null) {
      await ApiService.actualizarProgresoPlan(
        planId: planId,
        pasos: fasesPasos,
      );
    }

    if (!mounted) return;

    setState(() {
      cargandoFases[faseIndex] = false;

      _mensajes.add({
        'esBot': true,
        'texto': tr(
          '✅ ¡Paso ${faseIndex + 1} completado y guardado con éxito!',
          '✅ Step ${faseIndex + 1} completed and saved successfully!',
        ),
      });

      if (faseIndex + 1 < fasesPasos.length) {
        _faseActualIndex = faseIndex + 1;
        _agregarMensajeFase(_faseActualIndex);
      } else {
        _mensajes.add({
          'esBot': true,
          'texto': tr(
            '🏆 ¡Increíble! Has finalizado por completo todos los pasos de esta guía.',
            '🏆 Amazing! You have completed every step in this guide.',
          ),
        });
      }
    });

    _scrollToBottom();
  }

  void _explicarFase(int index) {
    if (index >= fasesPasos.length) return;

    final fase = fasesPasos[index];
    final tituloFase = fase['titulo'] ?? '';
    final descFase = fase['descripcion'] ?? '';
    final metodoEstudio = guiaActual['metodo_estudio'] ?? 'Pomodoro';

    final nivel = (_nivelesExplicacionFase[index] ?? 0) + 1;
    _nivelesExplicacionFase[index] = nivel;

    final explicacion = nivel == 1
        ? tr(
            '🧠 EXPLICACIÓN PROFUNDA (Paso ${index + 1}: $tituloFase)\n\n'
            '1. Objetivo metodológico ($metodoEstudio):\n'
            'En este punto la meta es: $descFase.\n\n'
            '2. Guía de ejecución:\n'
            '• Abre tu entorno de trabajo y céntrate solo en los subpasos indicados arriba.\n'
            '• Ve marcando cada casilla a medida que los vayas ejecutando.',
            '🧠 IN-DEPTH EXPLANATION (Step ${index + 1}: $tituloFase)\n\n'
            '1. Method goal ($metodoEstudio):\n'
            'At this point, your goal is: $descFase.\n\n'
            '2. How to do it:\n'
            '• Open your workspace and focus only on the substeps above.\n'
            '• Check each box as you complete it.',
          )
        : tr(
            '🔍 EXPLICACIÓN SENCILLA (Nivel $nivel - Paso ${index + 1})\n\n'
            'Tranquil@, divide "$tituloFase" en pequeñas acciones de 10 minutos y completa los subpasos uno por uno.',
            '🔍 SIMPLE EXPLANATION (Level $nivel - Step ${index + 1})\n\n'
            'Take it easy: break "$tituloFase" into small 10-minute actions and complete the substeps one at a time.',
          );

    setState(() {
      _mensajes.add({
        'esBot': false,
        'texto': tr(
          '¿Me explicas mejor el Paso ${index + 1}?',
          'Can you explain Step ${index + 1} better?',
        ),
      });

      _mensajes.add({
        'esBot': true,
        'texto': explicacion,
        'faseIndexChat': index,
      });
    });

    _scrollToBottom();
  }

  void _procesarOpcionRapida(String opcion) {
    String textoUsuario;
    String respuestaBot = '';

    switch (opcion) {
      case 'step':
        textoUsuario = tr('Paso a paso', 'Step by step');
        break;
      case 'explain':
        textoUsuario = tr('Explica qué toca hacer', 'Explain what I need to do');
        break;
      case 'topic':
        textoUsuario = tr('¿Qué es este tema?', 'What is this topic?');
        break;
      default:
        textoUsuario = tr('Dame un consejo', 'Give me advice');
    }

    setState(() {
      _mensajes.add({'esBot': false, 'texto': textoUsuario});

      if (opcion == 'step') {
        _agregarMensajeFase(_faseActualIndex);
      } else if (opcion == 'explain') {
        _nivelExplicacionGeneral++;

        respuestaBot = tr(
          '📌 EXPLICACIÓN GENERAL DEL TRABAJO\n\n'
          'Este plan divide tu proyecto en fases independientes. Completa los subpasos de la tarjeta actual para avanzar a la siguiente.',
          '📌 GENERAL EXPLANATION\n\n'
          'This plan divides your project into independent phases. Complete the substeps on the current card to move on to the next one.',
        );

        _mensajes.add({'esBot': true, 'texto': respuestaBot});
      } else if (opcion == 'topic') {
        final titulo = guiaActual['nombre'] ??
            guiaActual['titulo'] ??
            tr('el tema de tu tarea', 'your assignment topic');

        respuestaBot = tr(
          '📚 SOBRE EL TEMA: "$titulo"\n\nEsta actividad abarca conceptos fundamentales según la rúbrica.',
          '📚 ABOUT THE TOPIC: "$titulo"\n\nThis activity covers fundamental concepts based on the rubric.',
        );

        _mensajes.add({'esBot': true, 'texto': respuestaBot});
      } else {
        final consejo = consejos.isNotEmpty
            ? consejos.first
            : tr(
                'Elimina distracciones por los próximos 25 minutos.',
                'Remove distractions for the next 25 minutes.',
              );

        respuestaBot = tr(
          '💡 CONSEJO DE LUMI:\n$consejo',
          '💡 LUMI TIP:\n$consejo',
        );

        _mensajes.add({'esBot': true, 'texto': respuestaBot});
      }
    });

    _scrollToBottom();
  }

  void _abrirPantallaTecnicaDinamica() {
    final metodo = (guiaActual['metodo_estudio'] ?? 'Pomodoro')
        .toString()
        .toLowerCase();

    final titulo = (guiaActual['nombre'] ??
            guiaActual['titulo'] ??
            tr('Trabajo', 'Assignment'))
        .toString();

    final conceptosIA =
        List<String>.from(conceptosClave.map((e) => e.toString()));

    final preguntasIA = List<Map<String, dynamic>>.from(
      preguntasRecall
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)),
    );

    if (metodo.contains('feynman')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeynmanScreen(
            tituloTarea: titulo,
            conceptos: conceptosIA.isNotEmpty ? conceptosIA : [titulo],
          ),
        ),
      );
    } else if (metodo.contains('active')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveRecallScreen(
            tituloTarea: titulo,
            preguntasRespuestas: preguntasIA,
          ),
        ),
      );
    } else if (metodo.contains('spaced') || metodo.contains('repetic')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpacedRepetitionScreen(
            tituloTarea: titulo,
            conceptos: conceptosIA.isNotEmpty ? conceptosIA : [titulo],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PomodoroScreen(tituloTarea: titulo),
        ),
      );
    }
  }

  Future<void> _cambiarMetodoEstudio() async {
    final tituloPlan = (guiaActual['nombre'] ??
            guiaActual['titulo'] ??
            tr('Trabajo', 'Assignment'))
        .toString();

    final nuevoMetodo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarMetodoScreen(
          tituloTarea: tituloPlan,
          metodoRecomendado: guiaActual['metodo_estudio'] ?? 'Pomodoro',
          onMetodoSeleccionado: (_) {},
        ),
      ),
    );

    if (nuevoMetodo == null || !mounted) return;

    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();
    final userId = _userId.isNotEmpty
        ? _userId
        : guiaActual['usuario_id']?.toString() ?? '';

    if (planId == null || planId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Error: no se encontró el ID del plan.',
              'Error: the plan ID was not found.',
            ),
          ),
          backgroundColor: const Color(0xFFFF4444),
        ),
      );
      return;
    }

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Error: no se encontró el usuario. Cierra y vuelve a abrir el plan.',
              'Error: the user was not found. Close and reopen the plan.',
            ),
          ),
          backgroundColor: const Color(0xFFFF4444),
        ),
      );
      return;
    }

    setState(() => _cambiandoMetodo = true);

    try {
      final planRegenerado = await ApiService.regenerarPlanExistente(
        planId: planId,
        metodoEstudio: nuevoMetodo,
        userId: userId,
        titulo: guiaActual['nombre'] ?? guiaActual['titulo'] ?? tituloPlan,
        descripcion: guiaActual['descripcion'] ?? '',
        fechaEntrega: guiaActual['fecha_entrega'] ??
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        dificultad: guiaActual['dificultad'] ?? 'Media',
      );

      if (!mounted) return;

      if (planRegenerado != null) {
        setState(() {
          guiaActual = Map<String, dynamic>.from(planRegenerado);
          guiaActual['metodo_estudio'] = nuevoMetodo;

          if (guiaActual['usuario_id'] == null ||
              guiaActual['usuario_id'].toString().isEmpty) {
            guiaActual['usuario_id'] = userId;
          }

          _userId = userId;
          _extraerListasDetalle();
          _faseActualIndex = 0;
          _inicializarMensajesChat();
          _cambiandoMetodo = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                '¡Método cambiado a $nuevoMetodo! 🚀',
                'Method changed to $nuevoMetodo! 🚀',
              ),
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );

        _scrollToBottom();
      } else {
        setState(() => _cambiandoMetodo = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'Error: el servidor no respondió correctamente.',
                'Error: the server did not respond correctly.',
              ),
            ),
            backgroundColor: const Color(0xFFFF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _cambiandoMetodo = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Error al cambiar método: $e',
              'Error changing the method: $e',
            ),
          ),
          backgroundColor: const Color(0xFFFF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tituloPlan = (guiaActual['nombre'] ??
            guiaActual['titulo'] ??
            tr('Trabajo', 'Assignment'))
        .toString();

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: LumiAppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LumiAppTheme.primaryText(context),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatarLumi(radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tituloPlan,
                style: const TextStyle(
                  color: Color(0xFFBD00FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF00F0FF),
              size: 22,
            ),
            tooltip: tr('Reiniciar pasos', 'Reset steps'),
            onPressed: _mostrarDialogoReinicio,
          ),
          IconButton(
            icon: const Icon(
              Icons.flash_on,
              color: Colors.amberAccent,
              size: 24,
            ),
            tooltip: tr('Abrir técnica de estudio', 'Open study technique'),
            onPressed: _abrirPantallaTecnicaDinamica,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            )
          : _cambiandoMetodo
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFBD00FF),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(
                          'Cambiando método de estudio...\nEsto puede tardar unos segundos.',
                          'Changing study method...\nThis may take a few seconds.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LumiAppTheme.secondaryText(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final conversation = _buildConversation();

                    if (!Responsive.esEscritorio(context)) {
                      return conversation;
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 300,
                                child: _buildConversationSidebar(tituloPlan),
                              ),
                              VerticalDivider(
                                width: 1,
                                color: LumiAppTheme.outline(context),
                              ),
                              Expanded(child: conversation),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _mostrarDialogoReinicio() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LumiAppTheme.surface(context),
        title: Text(
          tr('¿Reiniciar progreso?', 'Reset progress?'),
          style: TextStyle(color: LumiAppTheme.primaryText(context)),
        ),
        content: Text(
          tr(
            'Esto desmarcará todos tus checkboxes y te devolverá al Paso 1. ¿Deseas continuar?',
            'This will uncheck every checkbox and return you to Step 1. Do you want to continue?',
          ),
          style: TextStyle(
            color: LumiAppTheme.secondaryText(context),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              tr('Cancelar', 'Cancel'),
              style: const TextStyle(color: Color(0xFF9E9AC8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF44AA),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _reiniciarProgreso();
            },
            child: Text(
              tr('Sí, reiniciar', 'Yes, reset'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF13102A),
          child: Text(
            tr(
              'Consejo: toca 🔄 arriba para reiniciar tus pasos o ⚡ para abrir tu técnica de estudio.',
              'Tip: tap 🔄 above to reset your steps or ⚡ to open your study technique.',
            ),
            style: const TextStyle(
              color: Color(0xFF9E9AC8),
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: _mensajes.length,
            itemBuilder: _buildMensaje,
          ),
        ),
        _buildQuickSuggestions(),
      ],
    );
  }

  Widget _buildMensaje(BuildContext context, int index) {
    final msg = _mensajes[index];
    final esBot = msg['esBot'] as bool;
    final esAlerta = msg['tipo'] == 'alerta_tiempo';
    final esBienvenida = msg['tipo'] == 'bienvenida';
    final faseIndexChat = msg['faseIndexChat'];
    final listaRecursosMsg = (msg['listaRecursos'] as List?) ?? [];

    List<dynamic> subpasos = [];
    var faseCompletada = false;
    var faseCargando = false;

    if (faseIndexChat != null && faseIndexChat < fasesPasos.length) {
      final fase = fasesPasos[faseIndexChat];
      subpasos = (fase['subpasos'] as List?) ?? [];
      faseCompletada = fase['completado'] == true;
      faseCargando = cargandoFases[faseIndexChat];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            esBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esBot) ...[
            _buildAvatarLumi(radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.esEscritorio(context)
                    ? 720
                    : double.infinity,
              ),
              child: Column(
                crossAxisAlignment:
                    esBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: esAlerta
                          ? const Color(0xFF3D1414)
                          : esBot
                              ? const Color(0xFF1A1736)
                              : const Color(0xFF32285E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esAlerta
                            ? Colors.redAccent
                            : esBot
                                ? const Color(0xFF4A3E8D).withOpacity(0.4)
                                : const Color(0xFFBD00FF),
                        width: esAlerta ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['texto'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: esAlerta
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (listaRecursosMsg.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...listaRecursosMsg.map(
                            (rec) => _buildResourceLink(rec),
                          ),
                        ],
                        if (subpasos.isNotEmpty && faseIndexChat != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF4A3E8D), height: 1),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              '📌 Subpasos obligatorios para este paso:',
                              '📌 Required substeps for this step:',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...List.generate(
                            subpasos.length,
                            (subIndex) => _buildSubpaso(
                              faseIndexChat,
                              subIndex,
                              subpasos[subIndex],
                              faseCompletada,
                            ),
                          ),
                        ],
                        if (faseIndexChat != null && !faseCompletada) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00F0FF),
                                  side: const BorderSide(
                                    color: Color(0xFF00F0FF),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: () => _explicarFase(faseIndexChat),
                                icon: const Icon(
                                  Icons.help_outline,
                                  size: 14,
                                ),
                                label: Text(
                                  tr(
                                    'Explicar paso ${faseIndexChat + 1}',
                                    'Explain step ${faseIndexChat + 1}',
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              faseCargando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFF44AA),
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF44AA),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _completarFasePaso(faseIndexChat),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        size: 14,
                                      ),
                                      label: Text(
                                        tr(
                                          'Completar paso ${faseIndexChat + 1}',
                                          'Complete step ${faseIndexChat + 1}',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (esBienvenida) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _cambiarMetodoEstudio,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF261D4C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFBD00FF),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.settings_suggest,
                              color: Color(0xFF00F0FF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr(
                                'Cambiar método de estudio',
                                'Change study method',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Color(0xFFBD00FF),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!esBot && !Responsive.esEscritorio(context)) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceLink(dynamic rec) {
    final nombreRec = rec['nombre'] ??
        rec['titulo'] ??
        tr('Enlace de apoyo', 'Support link');
    final urlRec = rec['url'] ?? '';

    if (urlRec.toString().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _abrirUrl(urlRec.toString()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00F0FF)),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, color: Color(0xFF00F0FF), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Abrir: $nombreRec 🚀', 'Open: $nombreRec 🚀'),
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubpaso(
    int faseIndex,
    int subpasoIndex,
    dynamic subMap,
    bool faseCompletada,
  ) {
    final subCompletado = subMap['completado'] == true;

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        subMap['texto'] ?? '',
        style: TextStyle(
          color: subCompletado ? Colors.white38 : Colors.white,
          fontSize: 11.5,
          decoration:
              subCompletado ? TextDecoration.lineThrough : null,
        ),
      ),
      value: subCompletado,
      activeColor: const Color(0xFFFF44AA),
      checkColor: Colors.black,
      onChanged: faseCompletada
          ? null
          : (val) => _actualizarSubpasoFase(
                faseIndex,
                subpasoIndex,
                val,
              ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBotonPredeterminado(
                tr('Paso a paso', 'Step by step'),
                'step',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBotonPredeterminado(
                tr('Explica qué toca hacer', 'Explain what I need to do'),
                'explain',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBotonPredeterminado(
                tr('¿Qué es este tema?', 'What is this topic?'),
                'topic',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBotonPredeterminado(
                tr('Dame un consejo', 'Give me advice'),
                'advice',
              ),
            ),
          ],
        ),
      ],
    );

    final panel = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      color: const Color(0xFF0D0B1E),
      child: suggestions,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 34),
      child: Responsive.esEscritorio(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: panel,
              ),
            )
          : panel,
    );
  }

  Widget _buildConversationSidebar(String tituloPlan) {
    final query = _sidebarSearchController.text.trim().toLowerCase();
    final currentId =
        (guiaActual['id'] ?? guiaActual['plan_id'] ?? '').toString();

    final conversations = _historialConversaciones.where((conversation) {
      final title = (conversation['nombre'] ?? conversation['titulo'] ?? '')
          .toString()
          .toLowerCase();
      final description =
          (conversation['descripcion'] ?? '').toString().toLowerCase();

      return query.isEmpty ||
          title.contains(query) ||
          description.contains(query);
    }).toList();

    return Container(
      color: LumiAppTheme.surface(context),
      padding: const EdgeInsets.fromLTRB(12, 20, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Conversaciones', 'Conversations'),
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tituloPlan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _sidebarSearchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: LumiAppTheme.primaryText(context)),
            decoration: InputDecoration(
              hintText: tr(
                'Buscar conversaciones',
                'Search conversations',
              ),
              prefixIcon: const Icon(Icons.search, size: 19),
              isDense: true,
              filled: true,
              fillColor: LumiAppTheme.surfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('HISTORIAL', 'HISTORY'),
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? tr(
                              'No hay conversaciones anteriores.',
                              'There are no previous conversations.',
                            )
                          : tr(
                              'No se encontraron conversaciones.',
                              'No conversations were found.',
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LumiAppTheme.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final conversationId =
                          (conversation['id'] ?? conversation['plan_id'] ?? '')
                              .toString();
                      final isCurrent = conversationId == currentId;
                      final title = (conversation['nombre'] ??
                              conversation['titulo'] ??
                              tr('Plan de estudio', 'Study plan'))
                          .toString();

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: LumiAppTheme.primaryText(context),
                            fontSize: 12,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          (conversation['descripcion'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: LumiAppTheme.secondaryText(context),
                            fontSize: 11,
                          ),
                        ),
                        selected: isCurrent,
                        selectedTileColor: const Color(0xFF00F0FF)
                            .withOpacity(0.08),
                        minVerticalPadding: 9,
                        onTap: () async {
                          if (isCurrent || conversationId.isEmpty) return;

                          final navigator = Navigator.of(context);
                          final plan =
                              await ApiService.obtenerPlan(conversationId);

                          if (!mounted || plan == null) return;

                          await navigator.pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  GuiaDetalleScreen(guiaData: plan),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarLumi({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1F1A3A),
      child: ClipOval(
        child: Image.asset(
          'logo/chat_ia.png',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Icon(
              Icons.smart_toy,
              color: const Color(0xFF00F0FF),
              size: radius * 1.1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBotonPredeterminado(String texto, String opcion) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F1A3A),
        foregroundColor: const Color(0xFF9E9AC8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF4A3E8D)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      ),
      onPressed: () => _procesarOpcionRapida(opcion),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}