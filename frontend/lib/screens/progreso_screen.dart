import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'app_bottom_navbar.dart';

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

  double _horasEstudio = 0;
  int _tareasCompletadas = 0;
  int _tareasFaltantes = 0;
  int _racha = 0;
  List<double> _horasPorDia = List.filled(7, 0);
  String _mejorDia = '';
  double _mejorHoras = 0;

  static const List<String> _diasSemana = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom',
  ];

  static const List<String> _diasCompletos = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  List<_Categoria> _distribucion = const [
    _Categoria('Estudio profundo', 55, Color(0xFF007EFF)),
    _Categoria('Repasos', 25, Color(0xFF7000FF)),
    _Categoria('Práctica', 15, Color(0xFFFF2A85)),
    _Categoria('Otros', 5, Color(0xFFFFB800)),
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
    final inicioNormalizado = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    final finNormalizado = inicioNormalizado.add(const Duration(days: 7));

    return fechaNormalizada.isAtSameMomentAs(inicioNormalizado) ||
        (fechaNormalizada.isAfter(inicioNormalizado) && fechaNormalizada.isBefore(finNormalizado));
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    final resultados = await Future.wait([
      ApiService.getEstadisticas(widget.userId),
      ApiService.getPlanesEstudio(widget.userId),
    ]);

    final stats = resultados[0] as Map<String, dynamic>?;
    final tareasRaw = resultados[1] as List<dynamic>?;

    final tareas = (tareasRaw ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final completadas = tareas.where(_estaCompletada).toList();
    final faltantes = tareas.length - completadas.length;

    final horas = double.tryParse('${stats?['horas_estudio'] ?? 0}') ?? 0;
    final racha = (stats?['racha'] as int?) ?? 0;

    final conteoPorDia = List<int>.filled(7, 0);
    for (final t in completadas) {
      final raw = t['fecha_entrega'] ?? t['fecha_creacion'];
      final fecha = DateTime.tryParse('$raw');
      if (fecha != null && _esDeEstaSemana(fecha)) {
        conteoPorDia[fecha.weekday - 1]++;
      }
    }

    final totalConteo = conteoPorDia.fold<int>(0, (a, b) => a + b);

    List<double> horasPorDia;
    if (horas > 0 && totalConteo > 0) {
      horasPorDia = List<double>.generate(7, (i) {
        return horas * (conteoPorDia[i] / totalConteo);
      });
    } else if (horas > 0) {
      horasPorDia = List<double>.filled(7, horas / 7);
    } else {
      horasPorDia = [4, 2, 5, 3, 6, 1, 0];
    }

    double maxHoras = 0;
    int mejorDiaIndex = 0;
    for (int i = 0; i < horasPorDia.length; i++) {
      if (horasPorDia[i] > maxHoras) {
        maxHoras = horasPorDia[i];
        mejorDiaIndex = i;
      }
    }

    if (!mounted) return;
    setState(() {
      _horasEstudio = horas;
      _tareasCompletadas = (stats?['tareas_completadas'] as int?) ?? completadas.length;
      _tareasFaltantes = faltantes < 0 ? 0 : faltantes;
      _racha = racha;
      _horasPorDia = horasPorDia;
      _mejorDia = _diasCompletos[mejorDiaIndex];
      _mejorHoras = maxHoras;
      _isLoading = false;
    });
  }

  String _formatearHoras(double horas) {
    if (horas == 0) return '0';
    if (horas == horas.roundToDouble()) return horas.toInt().toString();
    return horas.toStringAsFixed(1);
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
              RefreshIndicator(
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildTopSectionGrid(),
                          const SizedBox(height: 20),
                          _buildGraficaCard(),
                          const SizedBox(height: 20),
                          _buildDistribucionCard(),
                        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tu Progreso',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1B4E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Esta semana',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ],
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
                    )
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
          const Text(
            '¡Excelente trabajo! 🎉',
            style: TextStyle(
              color: Color(0xFF7000FF),
              fontSize: 10,
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
                    )
                  ],
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                _formatearHoras(_horasEstudio),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
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
            'en total esta semana',
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
                  '$_racha h vs. semana pasada',
                  style: const TextStyle(
                    color: Color(0xFF8B6BFF),
                    fontSize: 9,
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
                    )
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
          const SizedBox(height: 8),
          const Text(
            'Tareas faltantes',
            style: TextStyle(
              color: Color(0xFFB4ACDE),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '¡Tú puedes con ellas! 💪',
            style: TextStyle(
              color: Color(0xFF7000FF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Center(
            child: Image.asset(
              'logo/Lumi_progreso.png',
              height: 105,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'logo/Lumi_progreso.png',
                  height: 105,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(
                    height: 105,
                    child: Icon(Icons.smart_toy, size: 70, color: Color(0xFF8B6BFF)),
                  ),
                );
              },
            ),
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo de estudio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Horas dedicadas por día',
                    style: TextStyle(color: Color(0xFF867DAE), fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1347),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.north_east, color: Color(0xFF8B6BFF), size: 12),
                        SizedBox(width: 2),
                        Text(
                          '+ 18%',
                          style: TextStyle(
                            color: Color(0xFF8B6BFF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'vs. semana pasada',
                      style: TextStyle(color: Color(0xFF867DAE), fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: CustomPaint(
              size: const Size(double.infinity, 170),
              painter: _BarChartPainter(
                valores: _horasPorDia,
                etiquetas: _diasSemana,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_mejorDia.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF140F37),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFF8B6BFF), size: 16),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Color(0xFFB4ACDE), fontSize: 11),
                      children: [
                        const TextSpan(text: 'Tu mejor día fue '),
                        TextSpan(
                          text: _mejorDia,
                          style: const TextStyle(
                            color: Color(0xFF007EFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' con ${_formatearHoras(_mejorHoras)} horas ',
                          style: const TextStyle(
                            color: Color(0xFF7000FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: 'de estudio.'),
                      ],
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

  _BarChartPainter({
    required this.valores,
    required this.etiquetas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const ejeAncho = 20.0;
    const etiquetaAlto = 24.0;
    final chartHeight = size.height - etiquetaAlto;
    final chartWidth = size.width - ejeAncho;

    final maxValor = valores.isEmpty
        ? 6.0
        : (valores.reduce((a, b) => a > b ? a : b)).clamp(6.0, double.infinity);

    final topeEje = maxValor.ceilToDouble();
    const pasos = 6;

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
          ).createShader(Rect.fromLTWH(
            cx - barWidth / 2,
            chartHeight - alturaBarra,
            barWidth,
            alturaBarra,
          ));

        canvas.drawRRect(rect, paint);
      }

      final valLabel = valor == valor.roundToDouble()
          ? '${valor.toInt()} h'
          : '${valor.toStringAsFixed(1)} h';
      final valTp = TextPainter(
        text: TextSpan(
          text: valLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valTp.paint(
        canvas,
        Offset(cx - valTp.width / 2, math.max(0, chartHeight - alturaBarra - 16)),
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
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.valores != valores;
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