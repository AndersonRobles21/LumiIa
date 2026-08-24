import 'package:flutter/material.dart';
import '/services/api_service.dart'; // Asegúrate de tener tu ApiService importado

class FeynmanScreen extends StatefulWidget {
  final String tituloTarea;
  final List<String> conceptos;

  const FeynmanScreen({
    super.key,
    required this.tituloTarea,
    this.conceptos = const [],
  });

  @override
  State<FeynmanScreen> createState() => _FeynmanScreenState();
}

class _FeynmanScreenState extends State<FeynmanScreen> {
  final _explicacionController = TextEditingController();
  int _indexConceptoActual = 0;
  int _longitudActual = 0;
  bool _isEvaluando = false; // Estado de carga mientras la IA evalúa

  @override
  void initState() {
    super.initState();
    _explicacionController.addListener(() {
      setState(() {
        _longitudActual = _explicacionController.text.trim().length;
      });
    });
  }

  @override
  void dispose() {
    _explicacionController.dispose();
    super.dispose();
  }

  Future<void> _evaluarExplicacion() async {
    final texto = _explicacionController.text.trim();
    const int minimoCaracteres = 40;

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu explicación sencilla antes de continuar')),
      );
      return;
    }

    if (_longitudActual < minimoCaracteres) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Tu explicación es muy corta. Escribe al menos $minimoCaracteres caracteres detallando el tema.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final listaConceptos = widget.conceptos.isNotEmpty
        ? widget.conceptos
        : [widget.tituloTarea];
    final conceptoActual = listaConceptos[_indexConceptoActual];

    setState(() => _isEvaluando = true);

    // LLAMADA AL BACKEND PARA QUE LA IA EVALÚE LA EXPLICACIÓN
    final resultado = await ApiService.evaluarExplicacionFeynman(
      concepto: conceptoActual,
      explicacion: texto,
    );

    setState(() => _isEvaluando = false);

    if (!mounted) return;

    if (resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error de conexión con el servidor. Inténtalo de nuevo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bool aprobado = resultado['aprobado'] == true;
    final String mensajeIa = resultado['mensaje'] ?? 'Revisa tu explicación.';

    if (!aprobado) {
      // Si la IA detecta que es una broma, incoherente o superficial
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🤖 Lumi dice: "$mensajeIa"'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // ¡Aprobado por la IA!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ¡Brillante! $mensajeIa'),
        backgroundColor: const Color(0xFFBD00FF),
      ),
    );
    
    _explicacionController.clear();

    // Avanzar al siguiente concepto si existe
    if (widget.conceptos.isNotEmpty && _indexConceptoActual < widget.conceptos.length - 1) {
      setState(() {
        _indexConceptoActual++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaConceptos = widget.conceptos.isNotEmpty
        ? widget.conceptos
        : [widget.tituloTarea];

    final conceptoActual = listaConceptos[_indexConceptoActual];
    const int minimoRequerido = 40;

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
          'Técnica Feynman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF261D4C),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFBD00FF).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lightbulb_outline, color: Color(0xFFFF44AA), size: 14),
                  SizedBox(width: 6),
                  Text('Domina un concepto con IA', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enseñar es la mejor forma de aprender.\nLumi evaluará tu explicación.',
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (listaConceptos.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(listaConceptos.length, (index) {
                    final esSel = index == _indexConceptoActual;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Concepto ${index + 1}'),
                        selected: esSel,
                        selectedColor: const Color(0xFFBD00FF),
                        backgroundColor: const Color(0xFF26204E),
                        labelStyle: TextStyle(
                          color: esSel ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _indexConceptoActual = index;
                            _explicacionController.clear();
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B163B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatarLumiSmall(),
                      const SizedBox(width: 10),
                      const Text(
                        'Tu concepto a explicar',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26204E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conceptoActual,
                      style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B163B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatarLumiSmall(),
                      const SizedBox(width: 10),
                      const Text(
                        'Explícalo con tus propias palabras',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explicacionController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Escribe una explicación seria y detallada del concepto...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF26204E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_longitudActual / $minimoRequerido mín.',
                      style: TextStyle(
                        color: _longitudActual >= minimoRequerido ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isEvaluando ? null : _evaluarExplicacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF44AA),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isEvaluando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Hecho',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'logo/feyman.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy, color: Color(0xFF00F0FF), size: 60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarLumiSmall() {
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFF1F1A3A),
      child: ClipOval(
        child: Image.asset(
          'logo/chat_ia.png',
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy, color: Color(0xFF00F0FF), size: 14),
        ),
      ),
    );
  }
}