import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/api_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';

const String kLumiAsset = 'logo/lumi_gamificacion.png';
const String kRachaAsset = 'logo/racha.png';
const String kTrofeoAsset = 'logo/trofeo.png';

class GamificationScreen extends StatefulWidget {
  final String userId;

  const GamificationScreen({super.key, required this.userId});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _Logro {
  final String id;
  final String titulo;
  final String descripcion;
  final String iconAsset;
  final int rewardXp;
  final bool desbloqueado;
  final int progreso;
  final int meta;
  final String? fechaDesbloqueo;

  const _Logro({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.iconAsset,
    required this.rewardXp,
    required this.desbloqueado,
    required this.progreso,
    required this.meta,
    this.fechaDesbloqueo,
  });

  double get progresoNormalizado =>
      meta == 0 ? 0 : (progreso / meta).clamp(0.0, 1.0);
}

class _GamificationScreenState extends State<GamificationScreen>
    with AppLanguageListenerMixin<GamificationScreen> {
  bool _isLoading = true;

  int _tareasCompletadas = 0;
  int _racha = 0;
  int _totalPlanes = 0;
  double _horasEstudio = 0.0;
  int _nivel = 1;
  int _xpActual = 0;
  final int _xpSiguienteNivel = 100;

  List<_Logro> _logros = [];
  _Logro? _seleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final resultados = await Future.wait([
        ApiService.getEstadisticas(widget.userId),
        ApiService.obtenerHistorial(widget.userId),
        ApiService.getPlanesEstudio(widget.userId),
      ]);

      final stats = resultados[0] as Map<String, dynamic>?;
      final historial = resultados[1] as List<dynamic>?;
      final tareasRaw = resultados[2] as List<dynamic>?;

      final tareasLista = (tareasRaw ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final completadasCalculadas = tareasLista.where((t) {
        final estado = (t['estado'] ?? '').toString().toUpperCase();
        return t['completada'] == true || estado == 'COMPLETADA';
      }).length;

      final tareasCompletadas =
          stats != null && stats['tareas_completadas'] != null
              ? ((stats['tareas_completadas'] as num).toInt())
              : completadasCalculadas;

      final racha = stats != null && stats['racha'] != null
          ? ((stats['racha'] as num).toInt())
          : 0;

      final horasEstudio = stats != null && stats['horas_estudio'] != null
          ? (double.tryParse('${stats['horas_estudio']}') ?? 0.0)
          : 0.0;

      final totalPlanes = historial?.length ?? 0;

      final logros = _generarLogros(
        tareas: tareasCompletadas,
        racha: racha,
        planes: totalPlanes,
        horas: horasEstudio,
      );

      final totalDesbloqueados = logros.where((l) => l.desbloqueado).length;

      final xpTotal = (tareasCompletadas * 20) +
          (racha * 15) +
          (totalPlanes * 25) +
          (totalDesbloqueados * 35);

      final nivel = (xpTotal ~/ 100) + 1;
      final xpActual = xpTotal % 100;

      final preferences = await SharedPreferences.getInstance();
      final previousLevel = preferences.getInt('lumi_sound_level') ?? nivel;
      final previousAchievements =
          preferences.getInt('lumi_sound_achievements') ??
              totalDesbloqueados;

      if (nivel > previousLevel) {
        SoundService.instance.play(LumiSound.levelUp);
      } else if (totalDesbloqueados > previousAchievements) {
        SoundService.instance.play(LumiSound.achievement);
      }

      await preferences.setInt('lumi_sound_level', nivel);
      await preferences.setInt(
        'lumi_sound_achievements',
        totalDesbloqueados,
      );

      if (!mounted) return;

      setState(() {
        _tareasCompletadas = tareasCompletadas;
        _racha = racha;
        _totalPlanes = totalPlanes;
        _horasEstudio = horasEstudio;
        _nivel = nivel;
        _xpActual = xpActual;
        _logros = logros;
        _seleccionado = logros.firstWhere(
          (l) => l.desbloqueado,
          orElse: () => logros.first,
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error en GamificationScreen: $e');

      if (!mounted) return;

      setState(() {
        _logros = _generarLogros(
          tareas: 0,
          racha: 0,
          planes: 0,
          horas: 0,
        );
        _seleccionado = _logros.isNotEmpty ? _logros.first : null;
        _isLoading = false;
      });
    }
  }

  List<_Logro> _generarLogros({
    required int tareas,
    required int racha,
    required int planes,
    required double horas,
  }) {
    final alcanzado = tr('Alcanzado', 'Achieved');

    final base = <_Logro>[
      _Logro(
        id: 'primer_paso',
        titulo: tr('Primer paso', 'First step'),
        descripcion: tr(
          'Completaste tu primer trabajo, es un gran avance en tu aprendizaje.',
          'You completed your first task, a great step forward in your learning.',
        ),
        iconAsset: 'logo/logros/estrella_azul.png',
        rewardXp: 50,
        desbloqueado: tareas >= 1,
        progreso: tareas.clamp(0, 1),
        meta: 1,
        fechaDesbloqueo: tareas >= 1 ? alcanzado : null,
      ),
      _Logro(
        id: 'estrella_emergente',
        titulo: tr('Estrella emergente', 'Rising star'),
        descripcion: tr(
          'Completaste al menos 5 tareas exitosamente en la plataforma.',
          'You successfully completed at least 5 tasks on the platform.',
        ),
        iconAsset: 'logo/logros/estrella_verde.png',
        rewardXp: 50,
        desbloqueado: tareas >= 5,
        progreso: tareas.clamp(0, 5),
        meta: 5,
        fechaDesbloqueo: tareas >= 5 ? alcanzado : null,
      ),
      _Logro(
        id: 'primer_podio',
        titulo: tr('Primer podio', 'First podium'),
        descripcion: tr(
          'Finalizaste o creaste tu primer plan o módulo completo de estudio.',
          'You completed or created your first full study plan or module.',
        ),
        iconAsset: 'logo/logros/trofeo_bronce.png',
        rewardXp: 75,
        desbloqueado: planes >= 1,
        progreso: planes.clamp(0, 1),
        meta: 1,
        fechaDesbloqueo: planes >= 1 ? alcanzado : null,
      ),
      _Logro(
        id: 'despegue_brillante',
        titulo: tr('Despegue brillante', 'Brilliant launch'),
        descripcion: tr(
          'Creaste y organizaste tu plan de estudio guiado por IA.',
          'You created and organized your AI-guided study plan.',
        ),
        iconAsset: 'logo/logros/cohete.png',
        rewardXp: 50,
        desbloqueado: planes >= 1,
        progreso: planes.clamp(0, 1),
        meta: 1,
        fechaDesbloqueo: planes >= 1 ? alcanzado : null,
      ),
      _Logro(
        id: 'noche_estudio',
        titulo: tr('Noche de estudio', 'Study night'),
        descripcion: tr(
          'Completaste una sesión de estudio bajo el cielo estrellado.',
          'You completed a study session under the starry sky.',
        ),
        iconAsset: 'logo/luna_estrellas.png',
        rewardXp: 25,
        desbloqueado: tareas >= 1 || horas >= 1,
        progreso: (tareas >= 1 || horas >= 1) ? 1 : 0,
        meta: 1,
        fechaDesbloqueo: (tareas >= 1 || horas >= 1) ? alcanzado : null,
      ),
      _Logro(
        id: 'llama_encendida',
        titulo: tr('Llama encendida', 'Flame ignited'),
        descripcion: tr(
          'Alcanzaste una racha activa de al menos 3 días consecutivos de estudio.',
          'You reached an active streak of at least 3 consecutive study days.',
        ),
        iconAsset: 'logo/logros/fuego.png',
        rewardXp: 50,
        desbloqueado: racha >= 3,
        progreso: racha.clamp(0, 3),
        meta: 3,
        fechaDesbloqueo: racha >= 3 ? alcanzado : null,
      ),
      _Logro(
        id: 'constancia_diez',
        titulo: tr('Constancia diez', 'Ten-day consistency'),
        descripcion: tr(
          'Mantuviste tu constancia y entregas a tiempo durante 10 días seguidos.',
          'You stayed consistent and met deadlines for 10 consecutive days.',
        ),
        iconAsset: 'logo/logros/calendario_10.png',
        rewardXp: 90,
        desbloqueado: racha >= 10,
        progreso: racha.clamp(0, 10),
        meta: 10,
        fechaDesbloqueo: racha >= 10 ? alcanzado : null,
      ),
      _Logro(
        id: 'mes_imparable',
        titulo: tr('Mes imparable', 'Unstoppable month'),
        descripcion: tr(
          'Mantuviste una racha de estudio activa durante 30 días consecutivos.',
          'You maintained an active study streak for 30 consecutive days.',
        ),
        iconAsset: 'logo/logros/reloj_7.png',
        rewardXp: 100,
        desbloqueado: racha >= 30,
        progreso: racha.clamp(0, 30),
        meta: 30,
        fechaDesbloqueo: racha >= 30 ? alcanzado : null,
      ),
      _Logro(
        id: 'buho_nocturno',
        titulo: tr('Búho nocturno', 'Night owl'),
        descripcion: tr(
          'Dedicaste tiempo y completaste actividades de estudio nocturnas.',
          'You spent time completing late-night study activities.',
        ),
        iconAsset: 'logo/logros/buho_noturno.png',
        rewardXp: 50,
        desbloqueado: tareas >= 2 || horas >= 1,
        progreso: (tareas >= 2 || horas >= 1) ? 1 : 0,
        meta: 1,
        fechaDesbloqueo: (tareas >= 2 || horas >= 1) ? alcanzado : null,
      ),
      _Logro(
        id: 'modo_enfocado',
        titulo: tr('Modo enfocado', 'Focus mode'),
        descripcion: tr(
          'Completaste sesiones de estudio concentrado y técnicas avanzadas.',
          'You completed focused study sessions and advanced techniques.',
        ),
        iconAsset: 'logo/logros/rayo.png',
        rewardXp: 60,
        desbloqueado: horas >= 1 || tareas >= 2,
        progreso: (horas >= 1 || tareas >= 2) ? 1 : 0,
        meta: 1,
        fechaDesbloqueo: (horas >= 1 || tareas >= 2) ? alcanzado : null,
      ),
      _Logro(
        id: 'excelencia_academica',
        titulo: tr('Excelencia académica', 'Academic excellence'),
        descripcion: tr(
          'Completaste 8 tareas académicas demostrando gran disciplina.',
          'You completed 8 academic tasks, showing great discipline.',
        ),
        iconAsset: 'logo/logros/medalla_oro.png',
        rewardXp: 60,
        desbloqueado: tareas >= 8,
        progreso: tareas.clamp(0, 8),
        meta: 8,
        fechaDesbloqueo: tareas >= 8 ? alcanzado : null,
      ),
      _Logro(
        id: 'en_el_blanco',
        titulo: tr('En el blanco', 'On target'),
        descripcion: tr(
          'Cumpliste con más de 10 objetivos de estudio y tareas completadas.',
          'You achieved more than 10 study goals and completed tasks.',
        ),
        iconAsset: 'logo/logros/puntero.png',
        rewardXp: 70,
        desbloqueado: tareas >= 10,
        progreso: tareas.clamp(0, 10),
        meta: 10,
        fechaDesbloqueo: tareas >= 10 ? alcanzado : null,
      ),
      _Logro(
        id: 'mente_maestra',
        titulo: tr('Mente maestra', 'Mastermind'),
        descripcion: tr(
          'Demostraste un dominio avanzado finalizando 15 tareas en Lumi.',
          'You demonstrated advanced mastery by completing 15 tasks in Lumi.',
        ),
        iconAsset: 'logo/logros/cerebro.png',
        rewardXp: 75,
        desbloqueado: tareas >= 15,
        progreso: tareas.clamp(0, 15),
        meta: 15,
        fechaDesbloqueo: tareas >= 15 ? alcanzado : null,
      ),
      _Logro(
        id: 'explorador_digital',
        titulo: tr('Explorador digital', 'Digital explorer'),
        descripcion: tr(
          'Generaste y utilizaste múltiples planes de estudio interactivos.',
          'You generated and used multiple interactive study plans.',
        ),
        iconAsset: 'logo/logros/mundo.png',
        rewardXp: 60,
        desbloqueado: planes >= 2,
        progreso: planes.clamp(0, 2),
        meta: 2,
        fechaDesbloqueo: planes >= 2 ? alcanzado : null,
      ),
      _Logro(
        id: 'desafio_superado',
        titulo: tr('Desafío superado', 'Challenge conquered'),
        descripcion: tr(
          'Superaste un gran reto completando más de 20 tareas en tu trayecto.',
          'You overcame a major challenge by completing more than 20 tasks.',
        ),
        iconAsset: 'logo/logros/espadas.png',
        rewardXp: 100,
        desbloqueado: tareas >= 20,
        progreso: tareas.clamp(0, 20),
        meta: 20,
        fechaDesbloqueo: tareas >= 20 ? alcanzado : null,
      ),
    ];

    final desbloqueadosPrevios = base.where((l) => l.desbloqueado).length;

    base.add(
      _Logro(
        id: 'rey_aprendizaje',
        titulo: tr('Rey del aprendizaje', 'King of learning'),
        descripcion: tr(
          'Desbloqueaste 10 o más insignias y dominaste tus metas de estudio.',
          'You unlocked 10 or more badges and mastered your study goals.',
        ),
        iconAsset: 'logo/logros/corona.png',
        rewardXp: 120,
        desbloqueado: desbloqueadosPrevios >= 10,
        progreso: desbloqueadosPrevios.clamp(0, 10),
        meta: 10,
        fechaDesbloqueo:
            desbloqueadosPrevios >= 10 ? alcanzado : null,
      ),
    );

    return base;
  }

  String _nombreNivel(int nivel) {
    if (nivel <= 2) return tr('Aprendiz principiante', 'Beginner learner');
    if (nivel <= 5) return tr('Aprendiz', 'Learner');
    if (nivel <= 10) return tr('Estudiante', 'Student');
    if (nivel <= 20) return tr('Avanzado', 'Advanced');
    if (nivel <= 50) return tr('Experto', 'Expert');
    return tr('Maestro', 'Master');
  }

  void _seleccionar(_Logro logro) {
    if (_seleccionado?.id != logro.id) {
      setState(() => _seleccionado = logro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color.fromARGB(255, 7, 5, 25),
                    Color(0xFF0E0B2E),
                  ]
                : const [
                    Color(0xFFF8F5FC),
                    Color(0xFFF0E4F8),
                  ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B6BFF),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF8B6BFF),
                  backgroundColor: LumiAppTheme.surface(context),
                  onRefresh: _cargarDatos,
                  child: Responsive.esEscritorio(context)
                      ? _buildDesktopGamificationLayout()
                      : Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: Responsive.anchoMaximoContenido(
                                context,
                              ),
                            ),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                10,
                                18,
                                48,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(context),
                                  const SizedBox(height: 12),
                                  _buildStatsRow(),
                                  const SizedBox(height: 24),
                                  _buildLogrosHeader(),
                                  const SizedBox(height: 14),
                                  if (_seleccionado != null)
                                    _buildFeaturedCard(_seleccionado!),
                                  const SizedBox(height: 26),
                                  Text(
                                    tr(
                                      'Todas las insignias',
                                      'All badges',
                                    ),
                                    style: TextStyle(
                                      color: LumiAppTheme.primaryText(context),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLogrosGrid(),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopGamificationLayout() {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.anchoMaximoContenido(context),
          ),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 10, 4, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 14),
                        _buildDesktopStatsGrid(),
                        const SizedBox(height: 26),
                        Text(
                          tr('Todas las insignias', 'All badges'),
                          style: TextStyle(
                            color: LumiAppTheme.primaryText(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLogrosGrid(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 350,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(4, 14, 18, 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LumiAppTheme.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: LumiAppTheme.outline(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildLogrosHeader(),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _seleccionado == null
                              ? Center(
                                  child: Text(
                                    tr(
                                      'Selecciona una insignia para ver sus detalles.',
                                      'Select a badge to see its details.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: LumiAppTheme.secondaryText(
                                        context,
                                      ),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: _buildFeaturedCard(
                                    _seleccionado!,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LumiAppTheme.primaryText(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Gamificación', 'Gamification'),
                  style: TextStyle(
                    color: LumiAppTheme.primaryText(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    'Supera tus metas, mantén tu racha activa y desbloquea\n'
                    'insignias a medida que avanzas en tu camino de aprendizaje.',
                    'Reach your goals, keep your streak active, and unlock\n'
                    'badges as you progress on your learning journey.',
                  ),
                  style: TextStyle(
                    color: LumiAppTheme.secondaryText(context),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
    Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _AssetOrFallback(
                      asset: kRachaAsset,
                      size: 28,
                      fallbackIcon: Icons.local_fire_department,
                      fallbackColor: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_racha',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _racha == 1 ? tr('día', 'day') : tr('días', 'days'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr('Racha actual', 'Current streak'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3DDC84).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _racha > 0
                        ? tr('¡Racha activa!', 'Active streak!')
                        : tr('Empieza hoy', 'Start today'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3DDC84),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _AssetOrFallback(
                      asset: kTrofeoAsset,
                      size: 28,
                      fallbackIcon: Icons.emoji_events,
                      fallbackColor: Color(0xFFFFC24B),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tr('Nivel $_nivel', 'Level $_nivel'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _nombreNivel(_nivel),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: Responsive.tamanioTexto(context) - 2,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_xpActual / _xpSiguienteNivel).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFFC24B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_xpActual/$_xpSiguienteNivel XP',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: Responsive.tamanioTexto(context) - 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 2.1,
      children: [
        _StatCard(
          child: _buildDesktopStat(
            icon: Icons.local_fire_department,
            color: const Color(0xFFFF9E45),
            value: tr('$_racha días', '$_racha days'),
            label: tr('Racha actual', 'Current streak'),
          ),
        ),
        _StatCard(
          child: _buildDesktopStat(
            icon: Icons.emoji_events,
            color: const Color(0xFFFFC24B),
            value: tr('Nivel $_nivel', 'Level $_nivel'),
            label: '${_nombreNivel(_nivel)} · $_xpActual/$_xpSiguienteNivel XP',
          ),
        ),
        _StatCard(
          child: _buildDesktopStat(
            icon: Icons.task_alt,
            color: const Color(0xFF3DDC84),
            value: tr(
              '$_tareasCompletadas tareas',
              '$_tareasCompletadas tasks',
            ),
            label: tr(
              '$_totalPlanes planes · ${_horasEstudio.toStringAsFixed(1)} h de estudio',
              '$_totalPlanes plans · ${_horasEstudio.toStringAsFixed(1)} study hours',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLogrosHeader() {
    final desbloqueados = _logros.where((l) => l.desbloqueado).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LumiAppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiAppTheme.outline(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              tr('Insignia destacada', 'Featured badge'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6BFF).withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tr(
                  '$desbloqueados/${_logros.length} desbloqueados',
                  '$desbloqueados/${_logros.length} unlocked',
                ),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A8BFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(_Logro logro) {
    return Container(
      key: ValueKey('featured_${logro.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 12, 7, 46), Color(0xFF1B1748)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: logro.desbloqueado
              ? const Color(0xFF8B6BFF).withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -2,
            right: -2,
            child: _AssetOrFallback(
              asset: kLumiAsset,
              size: 48,
              fallbackIcon: Icons.smart_toy,
              fallbackColor: Color(0xFF9A8BFF),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              _AssetOrFallback(
                asset: logro.iconAsset,
                size: 92,
                fallbackIcon: Icons.emoji_events,
                fallbackColor: const Color(0xFFFFC24B),
                dim: !logro.desbloqueado,
              ),
              const SizedBox(height: 12),
              Text(
                logro.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                logro.descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _Pill(
                      icon: logro.desbloqueado
                          ? Icons.check_circle
                          : Icons.lock_outline,
                      label: logro.desbloqueado
                          ? tr('Desbloqueado', 'Unlocked')
                          : tr('Bloqueado', 'Locked'),
                      color: logro.desbloqueado
                          ? const Color(0xFF3DDC84)
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _Pill(
                      icon: Icons.calendar_today,
                      label: logro.fechaDesbloqueo ?? tr('En progreso', 'In progress'),
                      color: const Color(0xFF9A8BFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('Progreso', 'Progress'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: logro.progresoNormalizado,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    logro.desbloqueado
                        ? const Color(0xFF3DDC84)
                        : const Color(0xFF9A8BFF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${logro.progreso}/${logro.meta}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('Recompensa', 'Reward'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFC24B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${logro.rewardXp} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    logro.desbloqueado
                        ? '100%'
                        : '${(logro.progresoNormalizado * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFFFFC24B),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogrosGrid() {
    return GridView.builder(
      key: const PageStorageKey('gamification_grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.esEscritorio(context)
            ? 3
            : Responsive.esMovil(context)
                ? 3
                : 4,
        mainAxisSpacing: Responsive.esMovil(context) ? 14 : 18,
        crossAxisSpacing: Responsive.esMovil(context) ? 12 : 10,
        mainAxisExtent: Responsive.esMovil(context) ? 136 : 126,
      ),
      itemCount: _logros.length,
      itemBuilder: (context, index) {
        final logro = _logros[index];
        final isSelected = logro.id == _seleccionado?.id;

        return InkWell(
          key: ValueKey('grid_${logro.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _seleccionar(logro),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF9A8BFF)
                        : Colors.transparent,
                    width: 2.2,
                  ),
                ),
                child: _AssetOrFallback(
                  asset: logro.iconAsset,
                  size: Responsive.esMovil(context) ? 58 : 54,
                  fallbackIcon: Icons.emoji_events,
                  fallbackColor: const Color(0xFFFFC24B),
                  dim: !logro.desbloqueado,
                  showLock: !logro.desbloqueado,
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 36,
                child: Text(
                  logro.titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: logro.desbloqueado ? Colors.white : Colors.white38,
                    fontSize: Responsive.esMovil(context) ? 11.5 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final Widget child;

  const _StatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumiAppTheme.outline(context)),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetOrFallback extends StatelessWidget {
  final String asset;
  final double size;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final bool dim;
  final bool showLock;

  const _AssetOrFallback({
    required this.asset,
    required this.size,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.dim = false,
    this.showLock = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        size: size * 0.8,
        color: fallbackColor,
      ),
    );

    if (dim) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0.55, 0,
        ]),
        child: Opacity(opacity: 0.55, child: image),
      );
    }

    if (!showLock) return image;

    return Stack(
      alignment: Alignment.center,
      children: [
        image,
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        Icon(
          Icons.lock,
          size: size * 0.32,
          color: Colors.white70,
        ),
      ],
    );
  }
}