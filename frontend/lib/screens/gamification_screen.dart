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

/// -----------------------------------------------------------------------------
/// MODELO DE LOGRO
/// -----------------------------------------------------------------------------
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

    final resultados = await Future.wait([
      ApiService.getEstadisticas(widget.userId),
      ApiService.obtenerHistorial(widget.userId),
    ]);

    final stats = resultados[0] as Map<String, dynamic>?;
    final historial = resultados[1] as List<dynamic>?;

    final tareasCompletadas = (stats?['tareas_completadas'] as int?) ?? 0;
    final racha = (stats?['racha'] as int?) ?? 0;
    final totalPlanes = historial?.length ?? 0;

    // XP y nivel a partir de datos reales.
    final xpTotal = (tareasCompletadas * 20) + (racha * 15) + (totalPlanes * 30);
    final nivel = (xpTotal ~/ 100) + 1;
    final xpActual = xpTotal % 100;

    final logros = _generarLogros(tareasCompletadas, racha, totalPlanes);

    if (!mounted) return;
    setState(() {
      _tareasCompletadas = tareasCompletadas;
      _racha = racha;
      _totalPlanes = totalPlanes;
      _nivel = nivel;
      _xpActual = xpActual;
      _logros = logros;
      _seleccionado = logros.firstWhere(
        (l) => l.desbloqueado,
        orElse: () => logros.first,
      );
      _isLoading = false;
    });
  }

  /// -----------------------------------------------------------------------
  /// Genera las 16 insignias. Donde ya tenemos un dato real (tareas, racha,
  /// planes) lo usamos para calcular progreso/desbloqueo. Donde todavía no
  /// existe esa métrica en el backend (ej. "sesión después de las 10pm",
  /// "técnica sin interrupciones"), queda marcado con TODO y en false/0 para
  /// que lo conectes cuando tengas ese dato disponible.
  /// -----------------------------------------------------------------------
  List<_Logro> _generarLogros(int tareas, int racha, int planes) {
    final base = <_Logro>[
      _Logro(
        id: 'primer_paso',
        titulo: 'Primer paso',
        descripcion: 'Completaste tu primer trabajo, es un gran avance con tu aprendizaje.',
        iconAsset: 'assets/images/estrella_azul.png',
        rewardXp: 50,
        desbloqueado: tareas >= 1,
        progreso: tareas.clamp(0, 1),
        meta: 1,
      ),
      _Logro(
        id: 'estrella_emergente',
        titulo: 'Estrella emergente',
        descripcion:
            'Completaste tu primer conjunto de tareas con una calificación sobresaliente.',
        iconAsset: 'logo/logros/estrella_verde.png',
        rewardXp: 50,
        desbloqueado: tareas >= 5,
        progreso: tareas.clamp(0, 5),
        meta: 5,
      ),
      _Logro(
        id: 'primer_podio',
        titulo: 'Primer podio',
        descripcion: 'Finalizaste con éxito un módulo o tema completo de estudio.',
        iconAsset: 'logo/logros/trofeo_bronce.png',
        rewardXp: 75,
        desbloqueado: planes >= 1,
        progreso: planes.clamp(0, 1),
        meta: 1,
      ),
      _Logro(
        id: 'despegue_brillante',
        titulo: 'Despegue brillante',
        descripcion: 'Creaste y organizaste tu primer proyecto o plan de estudio en Lumi.',
        iconAsset: 'logo/logroslogo/logros/cohete.png',
        rewardXp: 50,
        desbloqueado: planes >= 1,
        progreso: planes.clamp(0, 1),
        meta: 1,
      ),
      _Logro(
        id: 'mes_imparable',
        titulo: 'Mes imparable',
        descripcion: 'Mantuviste una racha de estudio activa durante 30 días consecutivos.',
        iconAsset: 'logo/logros/reloj_7.png',
        rewardXp: 100,
        desbloqueado: racha >= 30,
        progreso: racha.clamp(0, 30),
        meta: 30,
      ),
      _Logro(
        id: 'llama_encendida',
        titulo: 'Llama encendida',
        descripcion: 'Alcanzaste una racha activa de estudio sin perder el ritmo diario.',
        iconAsset: 'logo/logros/fuego.png',
        rewardXp: 50,
        desbloqueado: racha >= 3,
        progreso: racha.clamp(0, 3),
        meta: 3,
      ),
      _Logro(
        id: 'constancia_diez',
        titulo: 'Constancia diez',
        descripcion:
            'Planificaste y cumpliste tus entregas a tiempo durante 10 días seguidos.',
        iconAsset: 'logo/logros/calendario_10.png',
        rewardXp: 90,
        desbloqueado: racha >= 10,
        progreso: racha.clamp(0, 10),
        meta: 10,
      ),
      // TODO: conectar con dato real de "sesión/entrega después de las 10:00 PM".
      _Logro(
        id: 'buho_nocturno',
        titulo: 'Búho nocturno',
        descripcion:
            'Completaste una sesión de estudio o entregaste una tarea después de las 10:00 PM.',
        iconAsset: 'logo/logros/luna_estrellas.png',
        rewardXp: 50,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
      // TODO: conectar con dato real de "técnica de estudio sin interrupciones".
      _Logro(
        id: 'modo_enfocado',
        titulo: 'Modo enfocado',
        descripcion: 'Utilizaste una técnica de estudio sin interrupciones durante una sesión.',
        iconAsset: 'logo/logros/rayo.png',
        rewardXp: 60,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
      // TODO: conectar con dato real de "dominio avanzado al repasar un tema complejo".
      _Logro(
        id: 'mente_maestra',
        titulo: 'Mente maestra',
        descripcion:
            'Demostraste un dominio avanzado al repasar y sintetizar un tema complejo.',
        iconAsset: 'logo/logros/cerebro.png',
        rewardXp: 50,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
      // TODO: conectar con dato real de "100% de objetivos del día".
      _Logro(
        id: 'en_el_blanco',
        titulo: 'En el blanco',
        descripcion: 'Cumpliste el 100% de tus objetivos programados para el día.',
        iconAsset: 'logo/logros/puntero.png',
        rewardXp: 70,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
      // TODO: conectar con dato real de "máxima puntuación en una evaluación".
      _Logro(
        id: 'excelencia_academica',
        titulo: 'Excelencia académica',
        descripcion: 'Obtuviste la máxima puntuación en una evaluación o repaso.',
        iconAsset: 'logo/logros/medalla_oro.png',
        rewardXp: 60,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
      // TODO: conectar con dato real de "múltiples recursos integrados".
      _Logro(
        id: 'explorador_digital',
        titulo: 'Explorador digital',
        descripcion: 'Consultaste e integraste múltiples recursos de aprendizaje en tus tareas.',
        iconAsset: 'logo/logros/mundo.png',
        rewardXp: 60,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),

      // TODO: conectar con dato real de "examen simulado o reto de alta dificultad".
      _Logro(
        id: 'desafio_superado',
        titulo: 'Desafío superado',
        descripcion: 'Superaste un examen simulado o reto de estudio de alta dificultad.',
        iconAsset: 'logo/logros/espadas.png',
        rewardXp: 100,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
            _Logro(
        id: 'desafio_superado',
        titulo: 'Desafío superado',
        descripcion: 'Superaste un examen simulado o reto de estudio de alta dificultad.',
        iconAsset: 'logo/logros/buho_noturno.png',
        rewardXp: 100,
        desbloqueado: false,
        progreso: 0,
        meta: 1,
      ),
    ];

    // "Rey del aprendizaje" depende de cuántos de los logros anteriores
    // ya están desbloqueados, así que se calcula al final.
    final desbloqueadosPrevios = base.where((l) => l.desbloqueado).length;
    base.add(
      _Logro(
        id: 'rey_aprendizaje',
        titulo: 'Rey del aprendizaje',
        descripcion:
            'Desbloqueaste más de 10 logros y alcanzaste un nivel elevado de experiencia.',
        iconAsset: 'assets/images/corona.png',
        rewardXp: 80,
        desbloqueado: desbloqueadosPrevios > 10,
        progreso: desbloqueadosPrevios.clamp(0, 10),
        meta: 10,
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

  void _seleccionar(_Logro l) => setState(() => _seleccionado = l);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B1748), Color(0xFF0E0B2E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B6BFF)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF8B6BFF),
                  backgroundColor: const Color(0xFF1B1748),
                  onRefresh: _cargarDatos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 8),
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        _buildLogrosHeader(),
                        const SizedBox(height: 12),
                        _buildFeaturedRow(),
                        const SizedBox(height: 24),
                        const Text(
                          'Todas las insignias',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLogrosGrid(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ENCABEZADO (solo botón de regreso, sin barra de navegación)
  // ---------------------------------------------------------------------------
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
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gamificación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supera tus metas, mantén tu racha activa y desbloquea\n'
                  'insignias a medida que avanzas en tu camino de aprendizaje.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TARJETAS DE RACHA Y NIVEL
  // ---------------------------------------------------------------------------
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
                    _AssetOrFallback(
                      asset: kRachaAsset,
                      size: 28,
                      fallbackIcon: Icons.local_fire_department,
                      fallbackColor: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_racha',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _racha == 1 ? 'día' : 'días',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Racha actual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3DDC84).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _racha > 0 ? '¡Excelente!' : 'Empieza hoy',
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
                    _AssetOrFallback(
                      asset: kTrofeoAsset,
                      size: 28,
                      fallbackIcon: Icons.emoji_events,
                      fallbackColor: const Color(0xFFFFC24B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nivel $_nivel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_nombreNivel(_nivel),
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _xpActual / _xpSiguienteNivel,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFC24B)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_xpActual/$_xpSiguienteNivel XP',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ENCABEZADO "LOGROS"
  // ---------------------------------------------------------------------------
  Widget _buildLogrosHeader() {
    final desbloqueados = _logros.where((l) => l.desbloqueado).length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Logros',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(
          '$desbloqueados/${_logros.length} desbloqueados',
          style: const TextStyle(
            color: Color(0xFF9A8BFF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TARJETA DESTACADA + LISTA LATERAL
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedRow() {
    if (_seleccionado == null) return const SizedBox.shrink();
    final unlockedList = _logros.where((l) => l.desbloqueado).toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildFeaturedCard(_seleccionado!)),
          const SizedBox(width: 10),
          if (unlockedList.isNotEmpty)
            SizedBox(width: 64, child: _buildSideBadgeList(unlockedList)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(_Logro l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF221C57), Color(0xFF1B1748)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -4,
            right: -4,
            child: _AssetOrFallback(
              asset: kLumiAsset,
              size: 46,
              fallbackIcon: Icons.smart_toy,
              fallbackColor: const Color(0xFF9A8BFF),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 4),
              _AssetOrFallback(
                asset: l.iconAsset,
                size: 84,
                fallbackIcon: Icons.emoji_events,
                fallbackColor: const Color(0xFFFFC24B),
                dim: !l.desbloqueado,
              ),
              const SizedBox(height: 10),
              Text(
                l.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                l.descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Pill(
                    icon: l.desbloqueado ? Icons.check_circle : Icons.lock_outline,
                    label: l.desbloqueado ? 'Desbloqueado' : 'Bloqueado',
                    color: l.desbloqueado ? const Color(0xFF3DDC84) : Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    icon: Icons.calendar_today,
                    label: l.fechaDesbloqueo ?? 'Pendiente',
                    color: const Color(0xFF9A8BFF),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Progreso', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: l.progresoNormalizado,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    l.desbloqueado ? const Color(0xFF7C5CFC) : const Color(0xFF9A8BFF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${l.progreso}/${l.meta}',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Recompensa', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFC24B), size: 16),
                      const SizedBox(width: 4),
                      Text('+${l.rewardXp} XP',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Text(
                    l.desbloqueado ? '100%' : '${(l.progresoNormalizado * 100).round()}%',
                    style: const TextStyle(color: Color(0xFFFFC24B), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideBadgeList(List<_Logro> unlockedList) {
    return ListView.separated(
      itemCount: unlockedList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final l = unlockedList[index];
        final isSelected = l.id == _seleccionado?.id;
        return GestureDetector(
          onTap: () => _seleccionar(l),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF9A8BFF) : Colors.transparent,
                width: 2,
              ),
              color: const Color(0xFF1B1748),
            ),
            child: _AssetOrFallback(
              asset: l.iconAsset,
              size: 44,
              fallbackIcon: Icons.emoji_events,
              fallbackColor: const Color(0xFFFFC24B),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // GRID CON TODAS LAS INSIGNIAS
  // ---------------------------------------------------------------------------
  Widget _buildLogrosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: _logros.length,
      itemBuilder: (context, index) {
        final l = _logros[index];
        final isSelected = l.id == _seleccionado?.id;
        return GestureDetector(
          onTap: () => _seleccionar(l),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF9A8BFF) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _AssetOrFallback(
                  asset: l.iconAsset,
                  size: 56,
                  fallbackIcon: Icons.emoji_events,
                  fallbackColor: const Color(0xFFFFC24B),
                  dim: !l.desbloqueado,
                  showLock: !l.desbloqueado,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: l.desbloqueado ? Colors.white : Colors.white38,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// -----------------------------------------------------------------------------
/// WIDGETS AUXILIARES
/// -----------------------------------------------------------------------------
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
  const _Pill({required this.icon, required this.label, required this.color});

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
          Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Muestra una imagen de asset; si el archivo aún no existe/está en el
/// pubspec.yaml, cae de forma segura a un ícono de Material para que la
/// pantalla nunca se rompa mientras terminas de agregar los recursos.
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
      errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: size * 0.8, color: fallbackColor),
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.15)),
        ),
        Icon(Icons.lock, size: size * 0.32, color: Colors.white70),
      ],
    );
  }
}