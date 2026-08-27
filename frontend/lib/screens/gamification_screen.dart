import 'package:flutter/material.dart';
import '/services/api_service.dart';

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

class _GamificationScreenState extends State<GamificationScreen> {
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
        _logros = _generarLogros(tareas: 0, racha: 0, planes: 0, horas: 0);
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
    final base = <_Logro>[
      _Logro(
        id: 'primer_paso',
        titulo: 'Primer paso',
        descripcion:
            'Completaste tu primer trabajo, es un gran avance en tu aprendizaje.',
        iconAsset: 'logo/logros/estrella_azul.png',
        rewardXp: 50,
        desbloqueado: tareas >= 1,
        progreso: tareas.clamp(0, 1),
        meta: 1,
        fechaDesbloqueo: tareas >= 1 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'estrella_emergente',
        titulo: 'Estrella emergente',
        descripcion:
            'Completaste al menos 5 tareas exitosamente en la plataforma.',
        iconAsset: 'logo/logros/estrella_verde.png',
        rewardXp: 50,
        desbloqueado: tareas >= 5,
        progreso: tareas.clamp(0, 5),
        meta: 5,
        fechaDesbloqueo: tareas >= 5 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'primer_podio',
        titulo: 'Primer podio',
        descripcion:
            'Finalizaste o creaste tu primer plan o módulo completo de estudio.',
        iconAsset: 'logo/logros/trofeo_bronce.png',
        rewardXp: 75,
        desbloqueado: planes >= 1,
        progreso: planes.clamp(0, 1),
        meta: 1,
        fechaDesbloqueo: planes >= 1 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'despegue_brillante',
        titulo: 'Despegue brillante',
        descripcion: 'Creaste y organizaste tu plan de estudio guiado por IA.',
        iconAsset: 'logo/logros/cohete.png',
        rewardXp: 50,
        desbloqueado: planes >= 1,
        progreso: planes.clamp(0, 1),
        meta: 1,
        fechaDesbloqueo: planes >= 1 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'noche_estudio',
        titulo: 'Noche de estudio',
        descripcion:
            'Completaste una sesión de estudio bajo el cielo estrellado.',
        iconAsset: 'logo/luna_estrellas.png',
        rewardXp: 25,
        desbloqueado: tareas >= 1 || horas >= 1,
        progreso: (tareas >= 1 || horas >= 1) ? 1 : 0,
        meta: 1,
        fechaDesbloqueo: (tareas >= 1 || horas >= 1) ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'llama_encendida',
        titulo: 'Llama encendida',
        descripcion:
            'Alcanzaste una racha activa de al menos 3 días consecutivos de estudio.',
        iconAsset: 'logo/logros/fuego.png',
        rewardXp: 50,
        desbloqueado: racha >= 3,
        progreso: racha.clamp(0, 3),
        meta: 3,
        fechaDesbloqueo: racha >= 3 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'constancia_diez',
        titulo: 'Constancia diez',
        descripcion:
            'Mantuviste tu constancia y entregas a tiempo durante 10 días seguidos.',
        iconAsset: 'logo/logros/calendario_10.png',
        rewardXp: 90,
        desbloqueado: racha >= 10,
        progreso: racha.clamp(0, 10),
        meta: 10,
        fechaDesbloqueo: racha >= 10 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'mes_imparable',
        titulo: 'Mes imparable',
        descripcion:
            'Mantuviste una racha de estudio activa durante 30 días consecutivos.',
        iconAsset: 'logo/logros/reloj_7.png',
        rewardXp: 100,
        desbloqueado: racha >= 30,
        progreso: racha.clamp(0, 30),
        meta: 30,
        fechaDesbloqueo: racha >= 30 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'buho_nocturno',
        titulo: 'Búho nocturno',
        descripcion:
            'Dedicaste tiempo y completaste actividades de estudio nocturnas.',
        iconAsset: 'logo/logros/buho_noturno.png',
        rewardXp: 50,
        desbloqueado: tareas >= 2 || horas >= 1,
        progreso: (tareas >= 2 || horas >= 1) ? 1 : 0,
        meta: 1,
        fechaDesbloqueo: (tareas >= 2 || horas >= 1) ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'modo_enfocado',
        titulo: 'Modo enfocado',
        descripcion:
            'Completaste sesiones de estudio concentrado y técnicas avanzadas.',
        iconAsset: 'logo/logros/rayo.png',
        rewardXp: 60,
        desbloqueado: horas >= 1 || tareas >= 2,
        progreso: (horas >= 1 || tareas >= 2) ? 1 : 0,
        meta: 1,
        fechaDesbloqueo: (horas >= 1 || tareas >= 2) ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'excelencia_academica',
        titulo: 'Excelencia académica',
        descripcion:
            'Completaste 8 tareas académicas demostrando gran disciplina.',
        iconAsset: 'logo/logros/medalla_oro.png',
        rewardXp: 60,
        desbloqueado: tareas >= 8,
        progreso: tareas.clamp(0, 8),
        meta: 8,
        fechaDesbloqueo: tareas >= 8 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'en_el_blanco',
        titulo: 'En el blanco',
        descripcion:
            'Cumpliste con más de 10 objetivos de estudio y tareas completadas.',
        iconAsset: 'logo/logros/puntero.png',
        rewardXp: 70,
        desbloqueado: tareas >= 10,
        progreso: tareas.clamp(0, 10),
        meta: 10,
        fechaDesbloqueo: tareas >= 10 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'mente_maestra',
        titulo: 'Mente maestra',
        descripcion:
            'Demostraste un dominio avanzado finalizando 15 tareas en Lumi.',
        iconAsset: 'logo/logros/cerebro.png',
        rewardXp: 75,
        desbloqueado: tareas >= 15,
        progreso: tareas.clamp(0, 15),
        meta: 15,
        fechaDesbloqueo: tareas >= 15 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'explorador_digital',
        titulo: 'Explorador digital',
        descripcion:
            'Generaste y utilizaste múltiples planes de estudio interactivos.',
        iconAsset: 'logo/logros/mundo.png',
        rewardXp: 60,
        desbloqueado: planes >= 2,
        progreso: planes.clamp(0, 2),
        meta: 2,
        fechaDesbloqueo: planes >= 2 ? 'Alcanzado' : null,
      ),
      _Logro(
        id: 'desafio_superado',
        titulo: 'Desafío superado',
        descripcion:
            'Superaste un gran reto completando más de 20 tareas en tu trayecto.',
        iconAsset: 'logo/logros/espadas.png',
        rewardXp: 100,
        desbloqueado: tareas >= 20,
        progreso: tareas.clamp(0, 20),
        meta: 20,
        fechaDesbloqueo: tareas >= 20 ? 'Alcanzado' : null,
      ),
    ];

    final desbloqueadosPrevios = base.where((l) => l.desbloqueado).length;

    base.add(
      _Logro(
        id: 'rey_aprendizaje',
        titulo: 'Rey del aprendizaje',
        descripcion:
            'Desbloqueaste 10 o más insignias y dominaste tus metas de estudio.',
        iconAsset: 'logo/logros/corona.png',
        rewardXp: 120,
        desbloqueado: desbloqueadosPrevios >= 10,
        progreso: desbloqueadosPrevios.clamp(0, 10),
        meta: 10,
        fechaDesbloqueo: desbloqueadosPrevios >= 10 ? 'Alcanzado' : null,
      ),
    );

    return base;
  }

  String _nombreNivel(int nivel) {
    if (nivel <= 2) return 'Aprendiz Principiante';
    if (nivel <= 5) return 'Aprendiz';
    if (nivel <= 10) return 'Estudiante';
    if (nivel <= 20) return 'Avanzado';
    if (nivel <= 50) return 'Experto';
    return 'Maestro';
  }

  void _seleccionar(_Logro l) {
    if (_seleccionado?.id != l.id) {
      setState(() => _seleccionado = l);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 7, 5, 25), Color(0xFF0E0B2E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B6BFF)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF8B6BFF),
                  backgroundColor: const Color.fromARGB(255, 18, 14, 58),
                  onRefresh: _cargarDatos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 48),
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
                        const Text(
                          'Todas las insignias',
                          style: TextStyle(
                            color: Colors.white,
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gamificación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supera tus metas, mantén tu racha activa y desbloquea\n'
                  'insignias a medida que avanzas en tu camino de aprendizaje.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
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
                          _racha == 1 ? 'día' : 'días',
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
                const Text(
                  'Racha actual',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3DDC84).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _racha > 0 ? '¡Racha activa!' : 'Empieza hoy',
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
                        'Nivel $_nivel',
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_xpActual / _xpSiguienteNivel).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFC24B)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_xpActual/$_xpSiguienteNivel XP',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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
        color: const Color(0xFF1B1748).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Text(
              'Insignia destacada',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6BFF).withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$desbloqueados/${_logros.length} desbloqueados',
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

  Widget _buildFeaturedCard(_Logro l) {
    return Container(
      key: ValueKey('featured_${l.id}'),
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
          color: l.desbloqueado
              ? const Color(0xFF8B6BFF).withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: l.desbloqueado
                ? const Color(0xFF8B6BFF).withOpacity(0.12)
                : Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                asset: l.iconAsset,
                size: 92,
                fallbackIcon: Icons.emoji_events,
                fallbackColor: const Color(0xFFFFC24B),
                dim: !l.desbloqueado,
              ),
              const SizedBox(height: 12),
              Text(
                l.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  l.descripcion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _Pill(
                      icon: l.desbloqueado
                          ? Icons.check_circle
                          : Icons.lock_outline,
                      label: l.desbloqueado ? 'Desbloqueado' : 'Bloqueado',
                      color: l.desbloqueado
                          ? const Color(0xFF3DDC84)
                          : Colors.white38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _Pill(
                      icon: Icons.calendar_today,
                      label: l.fechaDesbloqueo ?? 'En progreso',
                      color: const Color(0xFF9A8BFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Progreso',
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
                  value: l.progresoNormalizado,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    l.desbloqueado
                        ? const Color(0xFF3DDC84)
                        : const Color(0xFF9A8BFF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${l.progreso}/${l.meta}',
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
                  'Recompensa',
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
                        '+${l.rewardXp} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l.desbloqueado
                        ? '100%'
                        : '${(l.progresoNormalizado * 100).round()}%',
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 10,
        mainAxisExtent: 126,
      ),
      itemCount: _logros.length,
      itemBuilder: (context, index) {
        final l = _logros[index];
        final isSelected = l.id == _seleccionado?.id;

        return InkWell(
          key: ValueKey('grid_${l.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _seleccionar(l),
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
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B6BFF).withOpacity(0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: _AssetOrFallback(
                  asset: l.iconAsset,
                  size: 54,
                  fallbackIcon: Icons.emoji_events,
                  fallbackColor: const Color(0xFFFFC24B),
                  dim: !l.desbloqueado,
                  showLock: !l.desbloqueado,
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 36,
                child: Text(
                  l.titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: l.desbloqueado ? Colors.white : Colors.white38,
                    fontSize: 10.2,
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
        color: const Color(0xFF1B1748),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          fallbackIcon,
          size: size * 0.8,
          color: fallbackColor,
        );
      },
    );

    if (dim) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          0.55,
          0,
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