import 'package:flutter/material.dart';
import '/services/api_service.dart'; 
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfileScreen(
  userId: 'UUID_DE_PRUEBA',
),
  ));
}

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String get _userId => widget.userId;

  final List<String> _days = ['lun', 'mar', 'mie', 'jue', 'vie'];
  late List<List<bool>> _schedule;

  final List<String> _methods = [
    'pomodoro',
    'Spaced Repetition',
    'Active Recall',
    'Feynman',
  ];
  late List<bool> _methodSelected;

  @override
  void initState() {
    super.initState();

    _schedule = [
      [false, true, false, true, false],
      [false, false, true, false, true],
    ];
    _methodSelected = [true, true, true, true];
    

    _cargarDatosDeBaseDeDatos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosDeBaseDeDatos() async {
    setState(() => _isLoading = true);
    
    final data = await ApiService.getProfile(_userId);
    
    if (data != null) {
  setState(() {
    _nameController.text = data['nombre'] ?? '';
  });
}
else {
      _showSnackBar('No se pudieron cargar los datos del servidor.');
    }
    
    setState(() => _isLoading = false);
  }

  void _handleSend() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Por favor, ingresa tu nombre.');
      return;
    }

    setState(() => _isLoading = true);

    bool guardadoExitoso = await ApiService.updateProfile(
      _userId, 
      _nameController.text.trim(), 
      _schedule, 
      _methodSelected
    );

    setState(() => _isLoading = false);

    if (guardadoExitoso) {
      _showSnackBar('¡Perfil guardado en la Base de Datos correctamente!');
    } else {
      _showSnackBar('Error al intentar guardar en el servidor.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D2B), Color(0xFF1A1040), Color(0xFF0D0D2B)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFCC00CC)))
            : Column(
                children: [

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1B3A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        const Text(
                          'TU PERFIL',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Center(child: _buildAvatar()),
                          const SizedBox(height: 28),
                          const Text('Nombre', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ingresa tu nombre',
                              hintStyle: const TextStyle(color: Color(0xFF6666AA), fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFF1E1B3A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5555CC), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text('HORARIO', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          _buildScheduleGrid(),
                          const SizedBox(height: 28),
                          const Text('Metodos de estudio', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 14),
                          _buildMethods(),
                          const SizedBox(height: 36),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFCC00CC), Color(0xFFFF44AA)]),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: _handleSend,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                child: const Text('Enviar', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFFCC00CC), Color(0xFF6633FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFFCC00CC).withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2A1F5A)),
        clipBehavior: Clip.hardEdge,
        child: Image.network(
          'https://api.dicebear.com/7.x/bottts/png?seed=lumi&backgroundColor=2A1F5A',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 52),
        ),
      ),
    );
  }

  Widget _buildScheduleGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: _days.map((day) => Expanded(child: Center(child: Text(day, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))))).toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(2, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: List.generate(5, (col) {
                final active = _schedule[row][col];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _schedule[row][col] = !_schedule[row][col]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: active ? const LinearGradient(colors: [Color(0xFFCC00CC), Color(0xFFFF44AA)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                        color: active ? null : const Color(0xFF2A2550),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: active ? [BoxShadow(color: const Color(0xFFCC00CC).withOpacity(0.4), blurRadius: 8, spreadRadius: 1)] : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMethods() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _methods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 4.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (_, index) {
        final selected = _methodSelected[index];
        return GestureDetector(
          onTap: () => setState(() => _methodSelected[index] = !selected),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFCC00CC) : const Color(0xFF2A2550),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: selected ? const Color(0xFFCC00CC) : const Color(0xFF5555AA), width: 1.5),
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
              ),
              const SizedBox(width: 8),
              Text(_methods[index], style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}