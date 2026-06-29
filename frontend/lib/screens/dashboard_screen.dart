import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'profile_screen.dart';
import 'agregar_tarea_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _tareasPendientes = [];

  @override
  void initState() {
    super.initState();
    _cargarPlanesYTareas();
  }

  void _cargarPlanesYTareas() async {
    setState(() => _isLoading = true);
    // Jalamos los planes/tareas reales guardados transaccionalmente por la IA
    final lista = await ApiService.getPlanesEstudio(widget.userId);
    setState(() {
      _tareasPendientes = lista ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0B0813,
      ), // Tu fondo ultra oscuro original
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF14002A),
              Color(0xFF0B0813),
            ], // Degradado violeta profundo de la captura
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ORIGINAL ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tu plan de estudio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () {}, // Icono de la campanita
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- REQUISITO: CUADRADITO DE TRABAJOS PENDIENTES (CON AGREGAR) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1A3A).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Trabajos pendientes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              // Botón neón para abrir la pantalla dedicada de agregar tareas
                              GestureDetector(
                                onTap: () async {
                                  final cargoNuevo = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AgregarTareaScreen(
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                  if (cargoNuevo == true) {
                                    _cargarPlanesYTareas(); // Actualiza reactivamente
                                  }
                                },
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFFF44AA),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF44AA),
                                  ),
                                )
                              : _tareasPendientes.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                    child: Text(
                                      'No hay tareas agregadas.\nToca el "+" para crear una con IA.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white30,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _tareasPendientes.length,
                                  itemBuilder: (context, index) {
                                    final t = _tareasPendientes[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                '• ',
                                                style: TextStyle(
                                                  color: Color(0xFFFF44AA),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                (t['nombre'] ?? '')
                                                    .toString()
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Text(
                                            '7:00 am - 1hr', // Formato estético mapeado de tu captura
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- SECCIÓN: LA RACHA DE HOY ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LA RACHA DE HOY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'VER',
                            style: TextStyle(
                              color: Color(0xFFFF44AA),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1A3A).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MAÑANA 16',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'DIA 15',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight
                                            .bold, // Corregido aquí con la propiedad nativa de Flutter
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                // Icono del fuego original de la captura
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E1B4E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1A3A).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- SECCIÓN: IA ESTADÍSTICAS ---
                    const Text(
                      'IA Estadisticas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1A3A).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TU PROGRESO EN TUS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'TAREAS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Mira tu ultimo progreso en tus trabajos',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E1B4E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.timer_outlined,
                                    color: Colors.orangeAccent,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1A3A).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 80,
                    ), // Espaciador final para el navbar
                  ],
                ),
              ),
              _buildBottomNavbar(),
            ],
          ),
        ),
      ),
    );
  }

  // --- REQUISITO: NAVBAR REDIRECCIONANDO AL PERFIL ---
  Widget _buildBottomNavbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1437),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(
              Icons.home,
              color: Color(0xFFFF44AA),
              size: 24,
            ), // Seleccionado
            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white38,
              size: 24,
            ),
            const Icon(
              Icons.psychology_outlined,
              color: Colors.white38,
              size: 24,
            ),
            // REQUISITO: Al darle click a la personita te manda al perfil perfectamente
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Icon(
                Icons.person_outline,
                color: Colors.white38,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}