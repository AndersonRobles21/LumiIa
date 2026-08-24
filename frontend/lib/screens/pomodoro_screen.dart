import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroScreen extends StatefulWidget {
  final String tituloTarea;
  final int tiempoEstudioMinutos; // Por defecto 25 min
  final int tiempoDescansoMinutos; // Por defecto 5 min

  const PomodoroScreen({
    super.key,
    required this.tituloTarea,
    this.tiempoEstudioMinutos = 25,
    this.tiempoDescansoMinutos = 5,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Timer? _timer;
  late int _segundosRestantes;
  late int _tiempoTotalInicial;
  bool _estaActivo = false;
  bool _esTiempoEstudio = true; // true = Enfoque, false = Descanso
  int _cicloActual = 1; // De 1 a 4 ciclos

  @override
  void initState() {
    super.initState();
    _resetearTiempo();
  }

  void _resetearTiempo() {
    setState(() {
      _tiempoTotalInicial = (_esTiempoEstudio
              ? widget.tiempoEstudioMinutos
              : widget.tiempoDescansoMinutos) *
          60;
      _segundosRestantes = _tiempoTotalInicial;
      _estaActivo = false;
    });
    _timer?.cancel();
  }

  void _alternarTimer() {
    if (_estaActivo) {
      _timer?.cancel();
      setState(() => _estaActivo = false);
    } else {
      setState(() => _estaActivo = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_segundosRestantes > 0) {
          setState(() => _segundosRestantes--);
        } else {
          _timer?.cancel();
          _siguienteCiclo();
        }
      });
    }
  }

  void _siguienteCiclo() {
    setState(() {
      if (_esTiempoEstudio) {
        _esTiempoEstudio = false; // Pasar a descanso
      } else {
        _esTiempoEstudio = true; // Pasar a estudio
        if (_cicloActual < 4) {
          _cicloActual++;
        } else {
          _cicloActual = 1; // Reiniciar ciclo tras completar sesión
        }
      }
      _resetearTiempo();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _esTiempoEstudio
              ? '🧠 ¡Hora de enfocarse en "${widget.tituloTarea}"!'
              : '☕ ¡Hora de descansar! Tómate un respiro de 5 minutos.',
        ),
      ),
    );
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    final mStr = minutos.toString().padLeft(2, '0');
    final sStr = segs.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final porcentajeProgreso = _segundosRestantes / _tiempoTotalInicial;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Técnica Pomodoro',
          style: TextStyle(
            color: Colors.white,
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
            // 📌 TARJETA DE LA TAREA ACTUAL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B163B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBD00FF).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.task_alt, color: Color(0xFF00F0FF), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trabajo activo: ${widget.tituloTarea}',
                      style: const TextStyle(
                        color: Colors.white,
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

            // ⏰ TARJETA PRINCIPAL DEL TEMPORIZADOR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B163B),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF3B2F6E).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  // Círculo del Temporizador
                  SizedBox(
                    width: 220,
                    height: 220,
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
                                  ? 'Enfoque profundo'
                                  : 'Descanso corto',
                              style: const TextStyle(
                                color: Colors.white70,
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

                  // BOTONES DE CONTROL (Reiniciar / Pausar-Iniciar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón Reiniciar
                      ElevatedButton.icon(
                        onPressed: _resetearTiempo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D255A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          'Reiniciar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Botón Pausar / Iniciar
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
                          _estaActivo ? 'Pausar' : 'Iniciar',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🎯 BARRA DE CICLOS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

            // 🖼️ IMAGEN INFERIOR
            Center(
              child: Image.asset(
                'logo/pomodoro.png',
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B163B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '⚡ ¿Cómo funciona?\n25 min estudio • 5 min descanso • Repite 4 ciclos',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
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