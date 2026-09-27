import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'app_language.dart';

class PomodoroScreen extends StatefulWidget {
  final String tituloTarea;
  final int tiempoEstudioMinutos;
  final int tiempoDescansoMinutos;

  const PomodoroScreen({
    super.key,
    required this.tituloTarea,
    this.tiempoEstudioMinutos = 25,
    this.tiempoDescansoMinutos = 5,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with AppLanguageListenerMixin<PomodoroScreen> {
  Timer? _timer;
  late int _segundosRestantes;
  late int _tiempoTotalInicial;

  bool _estaActivo = false;
  bool _esTiempoEstudio = true;
  int _cicloActual = 1;

  @override
  void initState() {
    super.initState();
    _configurarTiempo();
  }

  void _configurarTiempo() {
    _tiempoTotalInicial = (_esTiempoEstudio
            ? widget.tiempoEstudioMinutos
            : widget.tiempoDescansoMinutos) *
        60;

    _segundosRestantes = _tiempoTotalInicial;
    _estaActivo = false;
  }

  void _resetearTiempo() {
    _timer?.cancel();

    setState(() {
      _configurarTiempo();
    });
  }

  void _alternarTimer() {
    if (_estaActivo) {
      _timer?.cancel();
      setState(() => _estaActivo = false);
      return;
    }

    setState(() => _estaActivo = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() => _segundosRestantes--);
        return;
      }

      _timer?.cancel();
      _siguienteCiclo();
    });
  }

  void _siguienteCiclo() {
    if (_esTiempoEstudio) {
      SoundService.instance.play(LumiSound.pomodoroCompleted);
    }

    setState(() {
      if (_esTiempoEstudio) {
        _esTiempoEstudio = false;
      } else {
        _esTiempoEstudio = true;

        if (_cicloActual < 4) {
          _cicloActual++;
        } else {
          _cicloActual = 1;
        }
      }

      _configurarTiempo();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _esTiempoEstudio
              ? tr(
                  '🧠 ¡Hora de enfocarte en "${widget.tituloTarea}"!',
                  '🧠 Time to focus on "${widget.tituloTarea}"!',
                )
              : tr(
                  '☕ ¡Hora de descansar! Tómate un respiro de ${widget.tiempoDescansoMinutos} minutos.',
                  '☕ Time for a break! Take a ${widget.tiempoDescansoMinutos}-minute breather.',
                ),
        ),
        backgroundColor: const Color(0xFFBD00FF),
      ),
    );
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segundosRestantes = segundos % 60;

    return '${minutos.toString().padLeft(2, '0')}:'
        '${segundosRestantes.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final porcentajeProgreso = _tiempoTotalInicial == 0
        ? 0.0
        : _segundosRestantes / _tiempoTotalInicial;

    final tamanioTemporizador = (Responsive.anchoPantalla(context) * 0.58)
        .clamp(180.0, 240.0);

    return Scaffold(
      backgroundColor: LumiAppTheme.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LumiAppTheme.primaryText(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('Técnica Pomodoro', 'Pomodoro Technique'),
          style: TextStyle(
            color: LumiAppTheme.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: LumiAppTheme.surface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFBD00FF).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: Color(0xFF00F0FF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(
                        'Trabajo activo: ${widget.tituloTarea}',
                        'Active task: ${widget.tituloTarea}',
                      ),
                      style: TextStyle(
                        color: LumiAppTheme.primaryText(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: LumiAppTheme.surface(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF3B2F6E).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: tamanioTemporizador,
                    height: tamanioTemporizador,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: porcentajeProgreso,
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFF282052),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFBD00FF),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatearTiempo(_segundosRestantes),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _esTiempoEstudio
                                  ? tr('Enfoque profundo', 'Deep focus')
                                  : tr('Descanso corto', 'Short break'),
                              style: TextStyle(
                                color: LumiAppTheme.secondaryText(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _resetearTiempo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              LumiAppTheme.surfaceVariant(context),
                          foregroundColor: LumiAppTheme.primaryText(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          tr('Reiniciar', 'Reset'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _alternarTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF44AA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(
                          _estaActivo ? Icons.pause : Icons.play_arrow,
                          size: 20,
                        ),
                        label: Text(
                          _estaActivo
                              ? tr('Pausar', 'Pause')
                              : tr('Iniciar', 'Start'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1B163B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconoCiclo(1, Icons.alarm),
                  _buildLineaConectora(1),
                  _buildIconoCiclo(2, Icons.alarm),
                  _buildLineaConectora(2),
                  _buildIconoCiclo(3, Icons.menu_book),
                  _buildLineaConectora(3),
                  _buildIconoCiclo(4, Icons.local_cafe),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FractionallySizedBox(
              widthFactor: Responsive.esMovil(context)
                  ? 0.9
                  : Responsive.esTablet(context)
                      ? 0.7
                      : 0.55,
              child: AspectRatio(
                aspectRatio: 1.8,
                child: Image.asset(
                  'logo/pomodoro.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B163B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tr(
                        '⚡ ¿Cómo funciona?\n${widget.tiempoEstudioMinutos} min de estudio • ${widget.tiempoDescansoMinutos} min de descanso • Repite 4 ciclos',
                        '⚡ How does it work?\n${widget.tiempoEstudioMinutos} min study • ${widget.tiempoDescansoMinutos} min break • Repeat for 4 cycles',
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildIconoCiclo(int numeroCiclo, IconData icono) {
    final estaCompletadoOActivo = _cicloActual >= numeroCiclo;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: estaCompletadoOActivo
            ? const Color(0xFF3B2F6E)
            : const Color(0xFF130F2A),
        border: Border.all(
          color: estaCompletadoOActivo
              ? const Color(0xFFBD00FF)
              : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Icon(
        icono,
        color: estaCompletadoOActivo ? Colors.white : Colors.white38,
        size: 20,
      ),
    );
  }

  Widget _buildLineaConectora(int cicloAnterior) {
    final estaActiva = _cicloActual > cicloAnterior;

    return Expanded(
      child: Container(
        height: 3,
        color: estaActiva ? const Color(0xFFBD00FF) : Colors.white24,
      ),
    );
  }
}