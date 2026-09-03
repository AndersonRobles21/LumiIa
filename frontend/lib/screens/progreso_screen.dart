import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '/services/api_service.dart';
import 'app_bottom_navbar.dart';

const String kLumiProgresoAsset = 'logo/Lumi_progreso.png';

class ProgresoScreen extends StatefulWidget {
  final String userId;

  const ProgresoScreen({super.key, required this.userId});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _Categoria {
  final String nombre;
  final double porcentaje;
  final Color color;

  const _Categoria(this.nombre, this.porcentaje, this.color);
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  bool _isLoading = true;

  double _horasEstudio = 0.0;
  int _tareasCompletadas = 0;
  int _tareasFaltantes = 0;
  int _racha = 0;
  List<double> _horasPorDia = List.filled(7, 0.0);
  String _mejorDia = '';
  double _mejorHoras = 0.0;

  static const List<String> _diasSemana = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  static const List<String> _diasCompletos = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  List<_Categoria> _distribucion = const [
    _Categoria('Estudio profundo', 50, Color(0xFF007EFF)),
    _Categoria('Repasos y tareas', 30, Color(0xFF7000FF)),
    _Categoria('Práctica y Pomodoro', 20, Color(0xFFFF2A85)),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  bool _estaCompletada(Map t) {
    final estado = (t['estado'] ?? '').toString().toUpperCase();
    return t['completada'] == true || estado == 'COMPLETADA';
  }

  bool _esDeEstaSemana(DateTime fecha) {
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);
    final inicioNormalizado = DateTime(
      inicioSemana.year,
      inicioSemana.month,
      inicioSemana.day,
    );
    final finNormalizado = inicioNormalizado.add(const Duration(days: 7));

    return (fechaNormalizada.isAtSameMomentAs(inicioNormalizado) ||
            fechaNormalizada.isAfter(inicioNormalizado)) &&
        fechaNormalizada.isBefore(finNormalizado);
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final resultados = await Future.wait([
        ApiService.getEstadisticas(widget.userId),
        ApiService.getPlanesEstudio(widget.userId),
        ApiService.obtenerHistorial(widget.userId),
      ]);

      final stats = resultados[0] as Map<String, dynamic>?;
      final tareasRaw = resultados[1] as List<dynamic>?;
      final historialRaw = resultados[2] as List<dynamic>?;

      int completadas = 0;
      int faltantes = 0;
      double totalHorasReales = 0.0;
      final List<double> horasPorDia = List.filled(7, 0.0);
      final ahora = DateTime.now();

      final tareas = (tareasRaw ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      for (final t in tareas) {
        final estaComp = _estaCompletada(t);

        if (estaComp) {
          completadas++;
          totalHorasReales += 1.0;

          final raw = t['fecha_entrega'] ??
              t['fecha'] ??
              t['fecha_creacion'] ??
              t['created_at'];

          final fecha = DateTime.tryParse('$raw');

          if (fecha != null && _esDeEstaSemana(fecha)) {
            final idx = (fecha.weekday - 1).clamp(0, 6);
            horasPorDia[idx] += 1.0;
          }
        } else {
          faltantes++;
        }
      }

      for (final h in (historialRaw ?? [])) {
        if (h is! Map) continue;

        final planId = h['id']?.toString();
        if (planId == null) continue;

        final tiempoEstimadoMin =
            (h['tiempo_estimado_total'] as num?)?.toInt() ?? 60;

        final duracionHoras = double.parse(
          (tiempoEstimadoMin / 60.0).toStringAsFixed(1),
        );

        final estado = (h['estado'] ?? '').toString().toUpperCase();
        bool planTerminado = estado == 'COMPLETADO' || estado == 'FINALIZADO';

        final planCompleto = await ApiService.obtenerPlan(planId);

        if (planCompleto != null && planCompleto['pasos'] is List) {
          final pasos = planCompleto['pasos'] as List;

          if (pasos.isNotEmpty) {
            int totalSub = 0;
            int compSub = 0;

            for (var p in pasos) {
              if (p['subpasos'] is List) {
                final subList = p['subpasos'] as List;
                totalSub += subList.length;
                compSub += subList
                    .where(
                      (s) => s['completado'] == true || s['completado'] == 1,
                    )
                    .length;
              }
            }

            if (totalSub > 0) {
              planTerminado = (compSub / totalSub) >= 1.0;
            }
          }
        }

        if (planTerminado) {
          completadas++;
          totalHorasReales += duracionHoras;

          final rawFecha = h['fecha_creacion'] ?? h['fecha_entrega'];
          final fecha = DateTime.tryParse('$rawFecha');

          if (fecha != null && _esDeEstaSemana(fecha)) {
            final idx = (fecha.weekday - 1).clamp(0, 6);
            horasPorDia[idx] += duracionHoras;
          } else {
            final hoyIdx = (ahora.weekday - 1).clamp(0, 6);
            horasPorDia[hoyIdx] += duracionHoras;
          }
        } else {
          faltantes++;
        }
      }

      final racha = (stats?['racha'] as num?)?.toInt() ?? 0;

      final horasFinales = totalHorasReales > 0
          ? double.parse(totalHorasReales.toStringAsFixed(1))
          : (completadas > 0
              ? double.parse((completadas * 1.5).toStringAsFixed(1))
              : 0.0);

      double maxHoras = 0.0;
      int mejorDiaIndex = -1;

      for (int i = 0; i < horasPorDia.length; i++) {
        horasPorDia[i] = double.parse(horasPorDia[i].toStringAsFixed(1));

        if (horasPorDia[i] > maxHoras) {
          maxHoras = horasPorDia[i];
          mejorDiaIndex = i;
        }
      }

      final totalItems = completadas + faltantes;

      final distribucion = <_Categoria>[
        _Categoria(
          'Estudio profundo',
          totalItems > 0 ? 55 : 50,
          const Color(0xFF007EFF),
        ),
        _Categoria(
          'Repasos y tareas',
          completadas > 0 ? 30 : 35,
          const Color(0xFF7000FF),
        ),
        const _Categoria(
          'Práctica y Pomodoro',
          15,
          Color(0xFFFF2A85),
        ),
      ];

      if (!mounted) return;

      setState(() {
        _horasEstudio = horasFinales;
        _tareasCompletadas = completadas;
        _tareasFaltantes = faltantes;
        _racha = racha;
        _horasPorDia = horasPorDia;
        _mejorDia = (mejorDiaIndex >= 0 && maxHoras > 0)
            ? _diasCompletos[mejorDiaIndex]
            : '';
        _mejorHoras = maxHoras;
        _distribucion = distribucion;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error en ProgresoScreen: $e');

      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatearHoras(double horas) {
    if (horas <= 0) return '0';

    final totalMinutos = (horas * 60).round();
    final h = totalMinutos ~/ 60;
    final min = totalMinutos % 60;

    if (h == 0) return '$min min';
    if (min == 0) return '$h h';

    return '$h h $min min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070619),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C0A2D), Color(0xFF070619)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: Responsive.esEscritorio(context)
                      ? Responsive.anchoSidebar(context)
                      : 0,
                ),
                child: RefreshIndicator(
                color: const Color(0xFF8B6BFF),
                backgroundColor: const Color(0xFF141038),
                onRefresh: _cargarDatos,
                child: _isLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 220),
                          Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B6BFF),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildTopSectionGrid(),
                          const SizedBox(height: 20),
                          _buildGraficaCard(),
                          const SizedBox(height: 20),
                          _buildDistribucionCard(),
                        ],
                      ),
                ),
              ),
              AppBottomNavbar(userId: widget.userId, currentIndex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        'Tu Progreso',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTopSectionGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildCardCompletadas(),
                const SizedBox(height: 14),
                _buildCardHorasEstudio(),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildCardFaltantes(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCompletadas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF221A52), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF381B85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A32C8).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                '$_tareasCompletadas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tareas completadas',
            style: TextStyle(
              color: Color(0xFFB4ACDE),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '¡Excelente trabajo! 🎉',
            style: TextStyle(
              color: Color(0xFF7000FF),
              fontSize: Responsive.tamanioTexto(context) - 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHorasEstudio() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF221A52), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF381B85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A32C8).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatearHoras(_horasEstudio),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Horas de estudio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'en total acumuladas',
            style: TextStyle(
              color: Color(0xFF867DAE),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF18103A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Text(
                  '$_racha ${_racha == 1 ? "día" : "días"} de racha',
                    style: TextStyle(
                    color: Color(0xFF8B6BFF),
                    fontSize: Responsive.tamanioTexto(context) - 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFaltantes() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF221A52), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B21A8), Color(0xFF3B0764)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                '$_tareasFaltantes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tareas faltantes',
            style: TextStyle(
              color: Color(0xFFE879F9),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '¡Tú puedes con ellas! 💪',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Center(
            child: Image.asset(
              kLumiProgresoAsset,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 110,
                child: Icon(
                  Icons.smart_toy,
                  size: 70,
                  color: Color(0xFF8B6BFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildGraficaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B29),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF221A52), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiempo de estudio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Horas dedicadas por día',
            style: TextStyle(color: Color(0xFF867DAE), fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: CustomPaint(
              size: const Size(double.infinity, 170),
              painter: _BarChartPainter(
                valores: _horasPorDia,
                etiquetas: _diasSemana,
                labelFontSize: Responsive.tamanioTexto(context) - 3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_mejorDia.isNotEmpty && _mejorHoras > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF140F37),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFC24B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFFB4ACDE),
                          fontSize: 11,
                        ),
                        children: [
                          const TextSpan(text: 'Tu día más activo fue '),
                          TextSpan(
                            text: _mejorDia,
                            style: const TextStyle(
                              color: Color(0xFF007EFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' con ${_formatearHoras(_mejorHoras)} de estudio.',
                            style: const TextStyle(
                              color: Color(0xFF7000FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistribucionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B29),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF221A52), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de tiempo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 125,
                height: 125,
                child: CustomPaint(
                  painter: _DonutChartPainter(categorias: _distribucion),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: _distribucion
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  c.nombre,
                                  style: const TextStyle(
                                    color: Color(0xFFB4ACDE),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${c.porcentaje.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> valores;
  final List<String> etiquetas;
  final double labelFontSize;

  _BarChartPainter({
    required this.valores,
    required this.etiquetas,
    required this.labelFontSize,
  });

  String _labelHoras(double valor) {
    if (valor <= 0) return '0';

    final totalMinutos = (valor * 60).round();
    final h = totalMinutos ~/ 60;
    final min = totalMinutos % 60;

    if (h == 0) return '${min}m';
    if (min == 0) return '${h}h';

    return '${h}h ${min}m';
  }

  @override
  void paint(Canvas canvas, Size size) {
    const ejeAncho = 20.0;
    const etiquetaAlto = 24.0;
    final chartHeight = size.height - etiquetaAlto;
    final chartWidth = size.width - ejeAncho;

    final maxValor = valores.isEmpty
        ? 6.0
        : (valores.reduce((a, b) => a > b ? a : b)).clamp(
            4.0,
            double.infinity,
          );

    final topeEje = maxValor.ceilToDouble();
    const pasos = 4;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    for (int i = 0; i <= pasos; i++) {
      final y = chartHeight - (chartHeight / pasos) * i;

      canvas.drawLine(
        Offset(ejeAncho, y),
        Offset(size.width, y),
        gridPaint,
      );

      final label = (topeEje / pasos * i).round().toString();

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF5E5785), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final n = valores.length;
    final slotWidth = chartWidth / n;
    final barWidth = slotWidth * 0.45;

    for (int i = 0; i < n; i++) {
      final valor = valores[i];
      final alturaBarra = (valor / topeEje) * chartHeight;
      final cx = ejeAncho + slotWidth * i + slotWidth / 2;

      final isBlueGradient = i == 0 || i == 2 || i == 4;

      final colors = isBlueGradient
          ? [const Color(0xFF3570FF), const Color(0xFF7000FF)]
          : [const Color(0xFFB82AFF), const Color(0xFF5A18C9)];

      if (alturaBarra > 0) {
        final rect = RRect.fromLTRBAndCorners(
          cx - barWidth / 2,
          chartHeight - alturaBarra,
          cx + barWidth / 2,
          chartHeight,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );

        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(
            Rect.fromLTWH(
              cx - barWidth / 2,
              chartHeight - alturaBarra,
              barWidth,
              alturaBarra,
            ),
          );

        canvas.drawRRect(rect, paint);
      }

      final valLabel = _labelHoras(valor);

      final valTp = TextPainter(
        text: TextSpan(
          text: valLabel,
          style: TextStyle(
            color: valor > 0 ? Colors.white : Colors.white24,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      valTp.paint(
        canvas,
        Offset(
          cx - valTp.width / 2,
          math.max(0, chartHeight - alturaBarra - 16),
        ),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: etiquetas[i],
          style: const TextStyle(
            color: Color(0xFFB4ACDE),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(cx - tp.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.valores != valores;
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_Categoria> categorias;

  _DonutChartPainter({required this.categorias});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    double startAngle = -90 * math.pi / 180;
    final total = categorias.fold<double>(0, (a, c) => a + c.porcentaje);

    for (final c in categorias) {
      final sweep = (c.porcentaje / total) * 2 * math.pi;

      final paint = Paint()
        ..color = c.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => false;
}