import 'package:flutter/material.dart';

class GuiaDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> guiaData;

  const GuiaDetalleScreen({super.key, required this.guiaData});

  @override
  Widget build(BuildContext context) {
    final actividades = guiaData['actividades'] as List? ?? [];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('GUÍA LUMI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: actividades.length,
        itemBuilder: (context, index) {
          final act = actividades[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16003A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF44AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(act['titulo'], style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(act['descripcion'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }
}