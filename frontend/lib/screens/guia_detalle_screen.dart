import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/services/api_service.dart';
import 'seleccionar_metodo_screen.dart';
import 'pomodoro_screen.dart';
import 'feynman_screen.dart';
import 'active_recall_screen.dart';
import 'spaced_repetition_screen.dart';

class GuiaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> guiaData;

  const GuiaDetalleScreen({super.key, required this.guiaData});

  @override
  State<GuiaDetalleScreen> createState() => _GuiaDetalleScreenState();
}

class _GuiaDetalleScreenState extends State<GuiaDetalleScreen> {
  bool _isLoading = true;
  bool _cambiandoMetodo = false; // ← NUEVO: loading solo para cambio de método
  Map<String, dynamic> guiaActual = {};
  List<dynamic> fasesPasos = [];
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

  // ← NUEVO: guardar el userId desde el inicio
  String _userId = '';

  String formatearTiempo(int minutos) {
    final horas = minutos ~/ 60;
    final minutosRestantes = minutos % 60;
    if (horas == 0) return "$minutosRestantes min";
    if (minutosRestantes == 0) return "$horas h";
    return "$horas h $minutosRestantes min";
  }

  Future<void> _abrirUrl(String urlString) async {
    if (urlString.trim().isEmpty) return;
    final Uri uri = Uri.parse(urlString.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // ← NUEVO: guardar userId desde widget.guiaData antes de cargar
    _userId = widget.guiaData['usuario_id']?.toString() ?? '';
    _cargarDetallePlan();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetallePlan() async {
    final planId = widget.guiaData['id'] ?? widget.guiaData['plan_id'];

    if (planId != null) {
      final detalle = await ApiService.obtenerPlan(planId.toString());
      if (detalle != null && mounted) {
        // ← NUEVO: guardar userId del backend si no lo teníamos
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
        return;
      }
    }

    if (mounted) {
      setState(() {
        guiaActual = Map<String, dynamic>.from(widget.guiaData);
        _extraerListasDetalle();
        _inicializarMensajesChat();
        _isLoading = false;
      });
      _scrollToBottom();
    }
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
    final nombrePlan =
        guiaActual['nombre'] ?? guiaActual['titulo'] ?? 'Trabajo o Tarea';
    final metodoEstudio = guiaActual['metodo_estudio'] ?? 'Pomodoro';

    _mensajes.clear();

    String materialIncial =
        "🛠️ HERRAMIENTAS Y RECURSOS DE APOYO PARA TU TAREA:\n\n";
    if (recursos.isNotEmpty) {
      for (var i = 0; i < recursos.length; i++) {
        final rec = recursos[i];
        final nombreRec =
            rec['nombre'] ?? rec['titulo'] ?? 'Material de apoyo ${i + 1}';
        materialIncial += "• ${i + 1}. $nombreRec\n\n";
      }
    } else {
      materialIncial +=
          "• Ten listos tus apuntes, editor de código o libreta de notas antes de comenzar.\n\n";
    }

    if (consejos.isNotEmpty) {
      materialIncial += "💡 Consejo general de Lumi:\n${consejos.first}";
    }

    _mensajes.add({
      'esBot': true,
      'texto': materialIncial,
      'tipo': 'herramientas_iniciales',
      'listaRecursos': recursos,
    });

    _mensajes.add({
      'esBot': true,
      'texto':
          '¡Hola! Vamos a empezar a trabajar en tu "$nombrePlan".\n\nHe seleccionado el método **$metodoEstudio** porque es el que mejor se adapta a esta actividad. ¿Deseas mantenerlo o prefieres cambiarlo?',
      'tipo': 'bienvenida',
    });

    bool hayFasesPendientes = false;
    for (int i = 0; i < fasesPasos.length; i++) {
      final fase = fasesPasos[i];
      if (fase is Map) {
        final subpasos = (fase['subpasos'] as List?) ?? [];
        bool todosCompletos =
            subpasos.isNotEmpty &&
            subpasos.every((sub) => sub['completado'] == true);
        bool faseCompletaDirecta = fase['completado'] == true;

        if (todosCompletos || faseCompletaDirecta) {
          _mensajes.add({
            'esBot': true,
            'texto':
                '📋 PASO ${i + 1} DE ${fasesPasos.length}: ${fase['titulo'] ?? 'Paso'}\n\n✅ ¡Fase completada con anterioridad!',
            'faseIndexChat': i,
          });
        } else {
          _faseActualIndex = i;
          hayFasesPendientes = true;
          _mostrarFasePaso(i);
          break;
        }
      }
    }

    if (!hayFasesPendientes && fasesPasos.isNotEmpty) {
      _faseActualIndex = fasesPasos.length - 1;
      _mensajes.add({
        'esBot': true,
        'texto':
            '🏆 ¡Increíble! Has finalizado por completo todos los pasos de esta guía.',
      });
    }

    _scrollToBottom();
  }

  Future<void> _reiniciarProgreso() async {
    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    for (var fase in fasesPasos) {
      if (fase is Map) {
        fase['completado'] = false;
        final subpasos = (fase['subpasos'] as List?) ?? [];
        for (var sub in subpasos) {
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

    setState(() {
      _faseActualIndex = 0;
      _inicializarMensajesChat();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 ¡Progreso reiniciado! Volviste al Paso 1.'),
          backgroundColor: Color(0xFF00F0FF),
        ),
      );
    }
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

    setState(() {});
  }

  Future<void> _completarFasePaso(int faseIndex) async {
    if (faseIndex >= fasesPasos.length) return;

    final fase = fasesPasos[faseIndex];
    final subpasosList = (fase['subpasos'] as List?) ?? [];

    bool faltanSubpasos = subpasosList.any((sub) => sub['completado'] != true);
    if (faltanSubpasos && subpasosList.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Debes marcar todos los subpasos de esta fase antes de continuar.',
          ),
          backgroundColor: Color(0xFFFF44AA),
        ),
      );
      return;
    }

    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    setState(() => cargandoFases[faseIndex] = true);

    fase['completado'] = true;
    for (var sub in subpasosList) {
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
        'texto': '✅ ¡Paso ${faseIndex + 1} completado y guardado con éxito!',
      });

      if (faseIndex + 1 < fasesPasos.length) {
        _faseActualIndex = faseIndex + 1;
        _mostrarFasePaso(_faseActualIndex);
      } else {
        _mensajes.add({
          'esBot': true,
          'texto':
              '🏆 ¡Increíble! Has finalizado por completo todos los pasos de esta guía.',
        });
      }
    });

    _scrollToBottom();
  }

  void _mostrarFasePaso(int index) {
    if (index >= fasesPasos.length) return;

    final fase = fasesPasos[index];
    final tituloFase = fase['titulo'] ?? 'Paso ${index + 1}';
    final descFase = fase['descripcion'] ?? '';
    final consejoPaso = fase['consejo_paso'] ?? fase['consejo'] ?? '';
    final duracion = fase['duracion_minutos'] ?? 20;

    String mensajePaso =
        '📋 PASO ${index + 1} DE ${fasesPasos.length}: $tituloFase\n\n'
        '🎯 ¿Qué debes hacer exactamente?\n$descFase\n\n'
        '⏱️ Tiempo estimado de enfoque: $duracion minutos.';

    if (consejoPaso.toString().isNotEmpty) {
      mensajePaso += '\n\n💡 Tip clave para este paso:\n$consejoPaso';
    }

    setState(() {
      _mensajes.add({
        'esBot': true,
        'texto': mensajePaso,
        'faseIndexChat': index,
      });
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

    String explicacionExtensa = "";

    if (nivel == 1) {
      explicacionExtensa =
          '🧠 EXPLICACIÓN PROFUNDA (Paso ${index + 1}: $tituloFase)\n\n'
          '1. Objetivo Metodológico ($metodoEstudio):\n'
          'En este punto la meta es: $descFase.\n\n'
          '2. Guía de Ejecución:\n'
          '• Abre tu entorno de trabajo y céntrate solo en los subpasos indicados arriba.\n'
          '• Ve marcando cada casilla a medida que los vayas ejecutando.';
    } else {
      explicacionExtensa =
          '🔍 EXPLICACIÓN SENCILLA (Nivel $nivel - Paso ${index + 1})\n\n'
          'Tranquil@, divide "$tituloFase" en pequeñas acciones de 10 minutos y completa los subpasos uno por uno.';
    }

    setState(() {
      _mensajes.add({
        'esBot': false,
        'texto': '¿Me explicas mejor el Paso ${index + 1}?',
      });

      _mensajes.add({
        'esBot': true,
        'texto': explicacionExtensa,
        'faseIndexChat': index,
      });
    });

    _scrollToBottom();
  }

  void _procesarOpcionRapida(String opcion) {
    setState(() {
      _mensajes.add({'esBot': false, 'texto': opcion});

      final opLower = opcion.toLowerCase();
      String respuestaBot = "";

      if (opLower.contains('paso a paso')) {
        _mostrarFasePaso(_faseActualIndex);
        return;
      } else if (opLower.contains('explica que toca hacer')) {
        _nivelExplicacionGeneral++;
        respuestaBot =
            '📌 EXPLICACIÓN GENERAL DEL TRABAJO\n\n'
            'Este plan divide tu proyecto en fases independientes. Completa los subpasos de la tarjeta actual para avanzar a la siguiente.';
      } else if (opLower.contains('qué es este tema') ||
          opLower.contains('que es este tema')) {
        final titulo =
            guiaActual['nombre'] ??
            guiaActual['titulo'] ??
            'el tema de tu tarea';
        respuestaBot =
            '📚 SOBRE EL TEMA: "$titulo"\n\nEsta actividad abarca conceptos fundamentales según la rúbrica.';
      } else if (opLower.contains('dame un consejo')) {
        final consejo = consejos.isNotEmpty
            ? consejos.first
            : "Elimina distracciones por los próximos 25 minutos.";
        respuestaBot = '💡 CONSEJO DE LUMI:\n$consejo';
      } else {
        respuestaBot =
            "Entendido. Selecciona una opción de abajo para continuar.";
      }

      _mensajes.add({'esBot': true, 'texto': respuestaBot});
    });

    _scrollToBottom();
  }

  void _abrirPantallaTecnicaDinamica() {
    final metodo = (guiaActual['metodo_estudio'] ?? 'Pomodoro')
        .toString()
        .toLowerCase();
    final titulo = (guiaActual['nombre'] ?? guiaActual['titulo'] ?? 'Trabajo')
        .toString();
    final conceptosIA = List<String>.from(
      conceptosClave.map((e) => e.toString()),
    );
    final preguntasIA = List<Map<String, dynamic>>.from(
      preguntasRecall.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
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
        MaterialPageRoute(builder: (_) => PomodoroScreen(tituloTarea: titulo)),
      );
    }
  }

  // ← NUEVO: función separada para cambiar método
  Future<void> _cambiarMetodoEstudio() async {
    final tituloPlan =
        (guiaActual['nombre'] ?? guiaActual['titulo'] ?? 'Trabajo').toString();

    final nuevoMetodo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarMetodoScreen(
          tituloTarea: tituloPlan,
          metodoRecomendado: guiaActual['metodo_estudio'] ?? 'Pomodoro',
          onMetodoSeleccionado: (metodo) {},
        ),
      ),
    );

    if (nuevoMetodo == null || !mounted) return;

    final planId = (guiaActual['id'] ?? guiaActual['plan_id'])?.toString();

    // ← CLAVE: usar _userId que guardamos al inicio
    final userId = _userId.isNotEmpty
        ? _userId
        : guiaActual['usuario_id']?.toString() ?? '';

    print('🔍 Cambiar método - planId: $planId, userId: $userId, método: $nuevoMetodo');

    if (planId == null || planId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el ID del plan'),
          backgroundColor: Color(0xFFFF4444),
        ),
      );
      return;
    }

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el usuario. Cierra y vuelve a abrir el plan.'),
          backgroundColor: Color(0xFFFF4444),
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
          // ← Mantener el userId después de regenerar
          if (guiaActual['usuario_id'] == null || guiaActual['usuario_id'].toString().isEmpty) {
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
            content: Text('¡Método cambiado a $nuevoMetodo! 🚀'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        setState(() => _cambiandoMetodo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: El servidor no respondió correctamente'),
            backgroundColor: Color(0xFFFF4444),
          ),
        );
      }
    } catch (e) {
      print('❌ Error cambiando método: $e');
      if (mounted) {
        setState(() => _cambiandoMetodo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar método: $e'),
            backgroundColor: const Color(0xFFFF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tituloPlan =
        (guiaActual['nombre'] ?? guiaActual['titulo'] ?? 'Trabajo').toString();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161331),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
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
            icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF), size: 22),
            tooltip: 'Reiniciar pasos',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1736),
                  title: const Text(
                    '¿Reiniciar progreso?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Esto desmarcará todos tus checkboxes y te devolverá al Paso 1. ¿Deseas continuar?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Color(0xFF9E9AC8)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF44AA),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _reiniciarProgreso();
                      },
                      child: const Text(
                        'Sí, reiniciar',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.flash_on,
              color: Colors.amberAccent,
              size: 24,
            ),
            onPressed: _abrirPantallaTecnicaDinamica,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            )
          : _cambiandoMetodo
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFBD00FF)),
                      SizedBox(height: 16),
                      Text(
                        'Cambiando método de estudio...\nEsto puede tardar unos segundos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: const Color(0xFF13102A),
                      child: const Text(
                        'Consejo: Toca 🔄 arriba para reiniciar tus pasos o ⚡ para abrir tu técnica de estudio.',
                        style: TextStyle(
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
                        padding: const EdgeInsets.all(16),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final msg = _mensajes[index];
                          final esBot = msg['esBot'] as bool;
                          final esBienvenida = msg['tipo'] == 'bienvenida';
                          final faseIndexChat = msg['faseIndexChat'];
                          final listaRecursosMsg =
                              (msg['listaRecursos'] as List?) ?? [];

                          List<dynamic> subpasosDeEstaFase = [];
                          bool faseCompletadaEstado = false;
                          bool faseCargandoEstado = false;

                          if (faseIndexChat != null &&
                              faseIndexChat < fasesPasos.length) {
                            final faseObj = fasesPasos[faseIndexChat];
                            subpasosDeEstaFase =
                                (faseObj['subpasos'] as List?) ?? [];
                            faseCompletadaEstado = faseObj['completado'] == true;
                            faseCargandoEstado = cargandoFases[faseIndexChat];
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: esBot
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (esBot) ...[
                                  _buildAvatarLumi(radius: 16),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: esBot
                                        ? CrossAxisAlignment.start
                                        : CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: esBot
                                              ? const Color(0xFF1A1736)
                                              : const Color(0xFF32285E),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: esBot
                                                ? const Color(
                                                    0xFF4A3E8D,
                                                  ).withOpacity(0.4)
                                                : const Color(0xFFBD00FF),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg['texto'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                height: 1.4,
                                              ),
                                            ),

                                            // Enlaces recomendados
                                            if (listaRecursosMsg.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              ...listaRecursosMsg.map((rec) {
                                                final nombreRec =
                                                    rec['nombre'] ??
                                                    rec['titulo'] ??
                                                    'Enlace de apoyo';
                                                final urlRec = rec['url'] ?? '';
                                                if (urlRec.isEmpty)
                                                  return const SizedBox.shrink();

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _abrirUrl(urlRec),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF00F0FF,
                                                        ).withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFF00F0FF,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.link,
                                                            color: Color(
                                                              0xFF00F0FF,
                                                            ),
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              'Abrir: $nombreRec 🚀',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Color(
                                                                      0xFF00F0FF,
                                                                    ),
                                                                    fontSize: 12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],

                                            // Checklist de subpasos
                                            if (subpasosDeEstaFase.isNotEmpty &&
                                                faseIndexChat != null) ...[
                                              const SizedBox(height: 12),
                                              const Divider(
                                                color: Color(0xFF4A3E8D),
                                                height: 1,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                '📌 Subpasos obligatorios para este paso:',
                                                style: TextStyle(
                                                  color: Color(0xFF00F0FF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              ...List.generate(
                                                subpasosDeEstaFase.length,
                                                (sIdx) {
                                                  final subMap =
                                                      subpasosDeEstaFase[sIdx];
                                                  bool subCompletado =
                                                      subMap['completado'] ==
                                                      true;
                                                  return CheckboxListTile(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    dense: true,
                                                    title: Text(
                                                      subMap['texto'] ?? '',
                                                      style: TextStyle(
                                                        color: subCompletado
                                                            ? Colors.white38
                                                            : Colors.white,
                                                        fontSize: 11.5,
                                                        decoration:
                                                            subCompletado
                                                            ? TextDecoration
                                                                  .lineThrough
                                                            : null,
                                                      ),
                                                    ),
                                                    value: subCompletado,
                                                    activeColor: const Color(
                                                      0xFFFF44AA,
                                                    ),
                                                    checkColor: Colors.black,
                                                    onChanged:
                                                        faseCompletadaEstado
                                                        ? null
                                                        : (bool? val) {
                                                            _actualizarSubpasoFase(
                                                              faseIndexChat,
                                                              sIdx,
                                                              val,
                                                            );
                                                          },
                                                  );
                                                },
                                              ),
                                            ],

                                            // Botones de la fase
                                            if (faseIndexChat != null &&
                                                !faseCompletadaEstado) ...[
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  OutlinedButton.icon(
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              const Color(
                                                                0xFF00F0FF,
                                                              ),
                                                          side:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFF00F0FF,
                                                                ),
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                        ),
                                                    onPressed: () =>
                                                        _explicarFase(
                                                          faseIndexChat,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.help_outline,
                                                      size: 14,
                                                    ),
                                                    label: Text(
                                                      'Explicar Paso ${faseIndexChat + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  faseCargandoEstado
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Color(
                                                                  0xFFFF44AA,
                                                                ),
                                                              ),
                                                        )
                                                      : ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                  0xFFFF44AA,
                                                                ),
                                                            foregroundColor:
                                                                Colors.black,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 6,
                                                                ),
                                                          ),
                                                          onPressed: () =>
                                                              _completarFasePaso(
                                                                faseIndexChat,
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .check_circle_outline,
                                                            size: 14,
                                                          ),
                                                          label: Text(
                                                            'Completar Paso ${faseIndexChat + 1}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // ← Botón cambiar método simplificado
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFBD00FF),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.settings_suggest,
                                                  color: Color(0xFF00F0FF),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Cambiar método de estudio',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                CircleAvatar(
                                                  radius: 10,
                                                  backgroundColor: Color(
                                                    0xFFBD00FF,
                                                  ),
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
                                if (!esBot) ...[
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFF2E7D32),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFF0D0B1E),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child:
                                    _buildBotonPredeterminado("Paso a Paso"),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBotonPredeterminado(
                                  "Explica que toca hacer",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBotonPredeterminado(
                                  "¿Qué es este tema?",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBotonPredeterminado(
                                  "Dame un consejo",
                                ),
                              ),
                            ],
                          ),
                        ],
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
          errorBuilder: (context, error, stackTrace) {
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

  Widget _buildBotonPredeterminado(String texto) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F1A3A),
        foregroundColor: const Color(0xFF9E9AC8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF4A3E8D)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => _procesarOpcionRapida(texto),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}