import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '/services/api_service.dart';
import 'app_bottom_navbar.dart';
import 'app_language.dart';

const String kLumiProgresoAsset = 'logo/Lumi_progreso.png';

class ProgresoScreen extends StatefulWidget {
  final String userId;

  const ProgresoScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen>
    with AppLanguageListenerMixin<ProgresoScreen> {
  bool _isLoading = true;
  bool _hasHoursError = false;

  double _horasEstudio = 0.0;
  int _tareasCompletadas = 0;
  int _tareasFaltantes = 0;
  int _racha = 0;
  List<double> _horasPorDia = List.filled(7, 0.0);
  String _mejorDiaKey = '';
  double _mejorHoras = 0.0;

  static const List<String> _diasSemanaEs = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  static const List<String> _diasSemanaEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _diasCompletosEs = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _diasCompletosEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<String> get _diasSemana =>
      AppLanguage.instance.isEnglish ? _diasSemanaEn : _diasSemanaEs;

  List<String> get _diasCompletos =>
      AppLanguage.instance.isEnglish ? _diasCompletosEn : _diasCompletosEs;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  int? _enteroEstadistica(dynamic valor) {
    final numero = valor is num ? valor : num.tryParse(valor?.toString() ?? '');
    if (numero == null || !numero.isFinite) return null;
    return numero.toInt();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final resultados = await Future.wait([
        ApiService.getEstadisticas(widget.userId),
        ApiService.getHorasPorSemana(widget.userId),
      ]);

      final stats = resultados[0] as Map<String, dynamic>?;
      final horasPorDiaApi = resultados[1] as List<double>?;

      final completadas =
          _enteroEstadistica(stats?['planes_principales_completados']) ?? 0;
      final faltantes =
          _enteroEstadistica(stats?['tareas_faltantes']) ?? 0;

      final horasPorDia =
          horasPorDiaApi != null && horasPorDiaApi.length == 7
              ? horasPorDiaApi
              : List.filled(7, 0.0);

      double maxHoras = 0.0;
      int mejorDiaIndex = -1;

      for (int i = 0; i < horasPorDia.length; i++) {
        if (horasPorDia[i] > maxHoras) {
          maxHoras = horasPorDia[i];
          mejorDiaIndex = i;
        }
      }

      final horasTotalesRaw = stats?['horas_estudio'];
      final horasTotales = horasTotalesRaw is num
          ? horasTotalesRaw.toDouble()
          : double.tryParse('$horasTotalesRaw') ?? 0.0;

      final racha = _enteroEstadistica(stats?['racha']) ?? 0;

      if (!mounted) return;

      setState(() {
        _horasEstudio = horasTotales.isFinite && horasTotales >= 0
          ? horasTotales
          : 0;
        _tareasCompletadas = completadas;
        _tareasFaltantes = faltantes;
        _racha = racha;
        _horasPorDia = horasPorDia;
        _hasHoursError = horasPorDiaApi == null;
        _mejorDiaKey = mejorDiaIndex >= 0 && maxHoras > 0
            ? mejorDiaIndex.toString()
            : '';
        _mejorHoras = maxHoras;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error en ProgresoScreen: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasHoursError = true;
      });
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

  String get _mejorDia {
    final index = int.tryParse(_mejorDiaKey);

    if (index == null || index < 0 || index >= _diasCompletos.length) {
      return '';
    }

    return _diasCompletos[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color(0xFF0C0A2D),
                    Color(0xFF070619),
                  ]
                : const [
                    Color(0xFFF8F5FC),
                    Color(0xFFF0E4F8),
                  ],
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
                  backgroundColor: LumiAppTheme.surface(context),
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
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            14,
                            20,
                            110,
                          ),
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 18),
                            _buildTopSectionGrid(),
                            const SizedBox(height: 20),
                            _buildGraficaCard(),
                          ],
                        ),
                ),
              ),
              AppBottomNavbar(
                userId: widget.userId,
                currentIndex: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        tr('Tu progreso', 'Your progress'),
        style: TextStyle(
          color: LumiAppTheme.primaryText(context),
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
          Expanded(child: _buildCardFaltantes()),
        ],
      ),
    );
  }

  Widget _buildCardCompletadas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _roundIcon(
                icon: Icons.check,
                color: const Color(0xFF381B85),
              ),
              const SizedBox(width: 14),
              Text(
                '$_tareasCompletadas',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr('Tareas completadas', 'Completed tasks'),
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('¡Excelente trabajo! 🎉', 'Excellent work! 🎉'),
            style: TextStyle(
              color: const Color(0xFF7000FF),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _roundIcon(
                icon: Icons.timer_outlined,
                color: const Color(0xFF381B85),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatearHoras(_horasEstudio),
                    maxLines: 1,
                    style: TextStyle(
                      color: LumiAppTheme.primaryText(context),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr('Horas de estudio', 'Study hours'),
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tr('acumuladas en total', 'total accumulated'),
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: LumiAppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Text(
                  tr(
                    '$_racha ${_racha == 1 ? 'día' : 'días'} de racha',
                    '$_racha ${_racha == 1 ? 'day' : 'days'} streak',
                  ),
                  style: TextStyle(
                    color: const Color(0xFF8B6BFF),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _roundIcon(
                icon: Icons.close,
                color: const Color(0xFF6B21A8),
              ),
              const SizedBox(width: 14),
              Text(
                '$_tareasFaltantes',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr('Tareas faltantes', 'Remaining tasks'),
            style: const TextStyle(
              color: Color(0xFFE879F9),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('¡Tú puedes con ellas! 💪', 'You can do it! 💪'),
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
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
              errorBuilder: (_, __, ___) => const SizedBox(
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: LumiAppTheme.surface(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.26),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6D4BC1).withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _roundIcon({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildGraficaCard() {
    final noHayHoras = _horasPorDia.every((horas) => horas <= 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.26),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Tiempo de estudio', 'Study time'),
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('Horas dedicadas por día', 'Hours spent per day'),
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 11,
            ),
          ),
          if (_hasHoursError || noHayHoras) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _hasHoursError
                      ? Icons.error_outline
                      : Icons.info_outline,
                  size: 16,
                  color: _hasHoursError
                      ? const Color(0xFFE87979)
                      : LumiAppTheme.secondaryText(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasHoursError
                        ? tr(
                            'No se pudo cargar el resumen semanal. Desliza para reintentar.',
                            'Could not load the weekly summary. Pull down to try again.',
                          )
                        : tr(
                            'Aún no hay sesiones de estudio registradas esta semana.',
                            'No study sessions have been recorded this week yet.',
                          ),
                    style: TextStyle(
                      color: LumiAppTheme.secondaryText(context),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: CustomPaint(
              size: const Size(double.infinity, 170),
              painter: _BarChartPainter(
                valores: _horasPorDia,
                etiquetas: _diasSemana,
                labelFontSize: Responsive.tamanioTexto(context) - 3,
                textColor: LumiAppTheme.primaryText(context),
                mutedColor: LumiAppTheme.secondaryText(context),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_mejorDia.isNotEmpty && _mejorHoras > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF140F37),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFC24B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFFB4ACDE),
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: tr(
                              'Tu día más activo fue ',
                              'Your most active day was ',
                            ),
                          ),
                          TextSpan(
                            text: _mejorDia,
                            style: const TextStyle(
                              color: Color(0xFF007EFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: tr(
                              ' con ${_formatearHoras(_mejorHoras)} de estudio.',
                              ' with ${_formatearHoras(_mejorHoras)} of study.',
                            ),
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
}

class _BarChartPainter extends CustomPainter {
  final List<double> valores;
  final List<String> etiquetas;
  final double labelFontSize;
  final Color textColor;
  final Color mutedColor;

  _BarChartPainter({
    required this.valores,
    required this.etiquetas,
    required this.labelFontSize,
    required this.textColor,
    required this.mutedColor,
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
        : valores.reduce((a, b) => a > b ? a : b).clamp(
              4.0,
              double.infinity,
            );

    final topeEje = maxValor.ceilToDouble();
    const pasos = 4;

    final gridPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    for (int i = 0; i <= pasos; i++) {
      final y = chartHeight - (chartHeight / pasos) * i;

      canvas.drawLine(
        Offset(ejeAncho, y),
        Offset(size.width, y),
        gridPaint,
      );

      final label = (topeEje / pasos * i).round().toString();

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: mutedColor,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height / 2),
      );
    }

    final cantidad = valores.length;
    final slotWidth = chartWidth / cantidad;
    final barWidth = slotWidth * 0.45;

    for (int i = 0; i < cantidad; i++) {
      final valor = valores[i];
      final alturaBarra = (valor / topeEje) * chartHeight;
      final centroX = ejeAncho + slotWidth * i + slotWidth / 2;

      final azul = i == 0 || i == 2 || i == 4;

      final colores = azul
          ? [const Color(0xFF3570FF), const Color(0xFF7000FF)]
          : [const Color(0xFFB82AFF), const Color(0xFF5A18C9)];

      if (alturaBarra > 0) {
        final rect = RRect.fromLTRBAndCorners(
          centroX - barWidth / 2,
          chartHeight - alturaBarra,
          centroX + barWidth / 2,
          chartHeight,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );

        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colores,
          ).createShader(
            Rect.fromLTWH(
              centroX - barWidth / 2,
              chartHeight - alturaBarra,
              barWidth,
              alturaBarra,
            ),
          );

        canvas.drawRRect(rect, paint);
      }

      final valorTexto = TextPainter(
        text: TextSpan(
          text: _labelHoras(valor),
          style: TextStyle(
            color: valor > 0 ? textColor : mutedColor.withValues(alpha: 0.5),
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      valorTexto.paint(
        canvas,
        Offset(
          centroX - valorTexto.width / 2,
          math.max(0, chartHeight - alturaBarra - 16),
        ),
      );

      final diaTexto = TextPainter(
        text: TextSpan(
          text: etiquetas[i],
          style: TextStyle(
            color: mutedColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      diaTexto.paint(
        canvas,
        Offset(
          centroX - diaTexto.width / 2,
          chartHeight + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.valores != valores ||
        oldDelegate.etiquetas != etiquetas ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}