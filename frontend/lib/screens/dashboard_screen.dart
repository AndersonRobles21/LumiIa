import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'agregar_tarea_screen.dart';
import 'app_language.dart';
import 'app_bottom_navbar.dart';
import 'guia_detalle_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;

  const DashboardScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int activeTab = 0;
  bool isLoading = true;

  String userName = 'Laura';
  int activeStreak = 0;

  List<StudyPlan> plans = [];
  List<bool> completedDays = List<bool>.filled(7, false);

  final List<String> weekDays = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Cargar nombre del usuario desde el perfil
    final profileData = await ApiService.getProfile(widget.userId);
    if (profileData != null) {
      userName = profileData['nombre'] ?? 'Laura';
    }

    // Cargar planes de IA activos (no completados)
    await _loadActivePlans();

    // Actualizar racha automáticamente (solo una vez al día)
    await _updateStreakAutomatically(prefs);

    setState(() => isLoading = false);

    // Mostrar diálogo de racha solo si no se ha mostrado hoy
    final lastShownDate = prefs.getString('last_streak_dialog_${widget.userId}');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastShownDate != today) {
      await prefs.setString('last_streak_dialog_${widget.userId}', today);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStreakDialog();
      });
    }
  }

  Future<void> _loadActivePlans() async {
    // Obtener planes de IA del historial
    final historialData = await ApiService.obtenerHistorial(widget.userId);

    if (historialData == null || historialData.isEmpty) {
      setState(() => plans = []);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    List<StudyPlan> loadedPlans = [];

    for (var plan in historialData) {
      final planId = plan['id']?.toString();
      if (planId == null) continue;

      final nombre = plan['nombre'] ?? plan['titulo'] ?? 'Sin título';
      final descripcion = plan['descripcion'] ?? 'Plan de estudio';

      // OBTENER EL PLAN COMPLETO PARA TENER LOS PASOS ACTUALIZADOS
      final planCompleto = await ApiService.obtenerPlan(planId);
      
      double progress = 0.0;
      bool allCompleted = false;

      if (planCompleto != null && planCompleto['pasos'] != null && planCompleto['pasos'] is List) {
        final pasos = planCompleto['pasos'] as List;
        if (pasos.isNotEmpty) {
          int totalSubpasos = 0;
          int subpasosCompletados = 0;

          for (var paso in pasos) {
            if (paso['subpasos'] != null && paso['subpasos'] is List) {
              final subpasos = paso['subpasos'] as List;
              totalSubpasos += subpasos.length;
              subpasosCompletados += subpasos
                  .where((s) => s['completado'] == true || s['completado'] == 1)
                  .length;
            }
          }

          if (totalSubpasos > 0) {
            progress = subpasosCompletados / totalSubpasos;
            allCompleted = progress >= 1.0;
          }
        }
      }

      // NUEVA LÓGICA: Solo ocultar si está al 100% Y han pasado 5 horas
      if (allCompleted) {
        final completedKey = 'plan_completed_time_$planId';
        final completedTimeStr = prefs.getString(completedKey);

        if (completedTimeStr == null) {
          // Primera vez que se completa, guardar la hora
          await prefs.setString(completedKey, now.toIso8601String());
          print('✅ Plan $planId completado al 100% - guardando hora: ${now.toIso8601String()}');
        } else {
          // Ya se había completado antes, verificar si han pasado 5 horas
          final completedTime = DateTime.parse(completedTimeStr);
          final difference = now.difference(completedTime);

          print('⏰ Plan $planId - Tiempo desde completado: ${difference.inHours} horas');

          if (difference.inHours >= 5) {
            // Han pasado 5 horas, ocultar el plan
            print('🚫 Plan $planId - Ocultando después de 5 horas');
            continue;
          } else {
            // Aún no han pasado 5 horas, mostrar con 100%
            print('⏳ Plan $planId - Mostrando al 100%, faltan ${5 - difference.inHours} horas para ocultar');
          }
        }
      } else {
        // Si el plan NO está al 100%, eliminar la marca de completado
        final completedKey = 'plan_completed_time_$planId';
        if (prefs.containsKey(completedKey)) {
          await prefs.remove(completedKey);
          print('🔄 Plan $planId - Reiniciado, eliminando marca de completado');
        }
      }

      loadedPlans.add(StudyPlan(
        id: planId,
        title: nombre,
        subtitle: descripcion,
        progress: progress,
        completed: allCompleted,
      ));
    }

    setState(() => plans = loadedPlans);
  }

  Future<void> _updateStreakAutomatically(SharedPreferences prefs) async {
    final today = DateTime.now();
    final todayString = today.toIso8601String().split('T')[0];

    final lastUpdateDate = prefs.getString('last_streak_update_${widget.userId}');

    if (lastUpdateDate == todayString) {
      await _loadStreakFromServer();
      return;
    }

    final success = await ApiService.registrarRachaHoy(widget.userId);

    if (success) {
      await prefs.setString('last_streak_update_${widget.userId}', todayString);
      await _loadStreakFromServer();

      final todayIndex = today.weekday - 1;
      setState(() {
        completedDays[todayIndex] = true;
      });

      await prefs.setString(
        'streak_days_${widget.userId}',
        jsonEncode(completedDays),
      );
    }
  }

  Future<void> _loadStreakFromServer() async {
    final stats = await ApiService.getEstadisticas(widget.userId);

    if (stats != null) {
      final racha = stats['racha'] ?? 0;

      setState(() {
        activeStreak = racha is int ? racha : int.tryParse(racha.toString()) ?? 0;
      });

      _updateCompletedDaysFromStreak(activeStreak);
    }
  }

  void _updateCompletedDaysFromStreak(int streak) {
    final today = DateTime.now();
    final todayIndex = today.weekday - 1;

    completedDays = List<bool>.filled(7, false);

    for (int i = 0; i < streak && i <= todayIndex; i++) {
      completedDays[todayIndex - i] = true;
    }

    setState(() {});
  }

  void _showStreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF17122F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2B2251)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'logo/racha.png',
                  height: 110,
                  width: 110,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_fire_department,
                    size: 90,
                    color: Color(0xFFFF9D00),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$activeStreak ${activeStreak == 1 ? 'Racha activa !' : 'Rachas activas !'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Completar una lección al día como rutina.',
                  style: TextStyle(
                    color: Color(0xFFBDB5D6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    weekDays.length,
                    (index) {
                      final isCompleted = completedDays[index];
                      return Column(
                        children: [
                          Text(
                            weekDays[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 28,
                            width: 28,
                            child: isCompleted
                                ? Image.asset(
                                    'logo/racha.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_fire_department,
                                      size: 24,
                                      color: Color(0xFFFF9D00),
                                    ),
                                  )
                                : Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2B2251),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD72CFA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Seguir Aprendiendo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddTaskScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarTareaScreen(
          userId: widget.userId,
        ),
      ),
    );
    await _loadActivePlans();
  }

  Future<void> _openPlanDetail(StudyPlan plan) async {
    final planData = await ApiService.obtenerPlan(plan.id);

    if (planData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el plan seleccionado.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuiaDetalleScreen(guiaData: planData),
      ),
    );

    // Recargar planes después de ver el detalle para actualizar el progreso
    await _loadActivePlans();
  }

  Future<void> _confirmDeletePlan(StudyPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF17122F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          '¿Eliminar plan?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${plan.title}"? Esta acción no se puede deshacer.',
          style: const TextStyle(
            color: Color(0xFFBDB5D6),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFBDB5D6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deletePlan(plan.id);
    }
  }

  Future<void> _deletePlan(String planId) async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.eliminarPlan(planId);

      if (response == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('plan_completed_time_$planId');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan eliminado correctamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        await _loadActivePlans();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar el plan'),
            backgroundColor: Color(0xFFFF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el plan'),
          backgroundColor: Color(0xFFFF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100B2C),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD942FF),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD942FF),
                      onRefresh: _loadActivePlans,
                      child: _buildDashboard(),
                    ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          _buildRobotHeader(),
          _buildWelcome(),
          _buildStudyPlan(),
          _buildAddTaskCard(),
        ],
      ),
    );
  }

  Widget _buildRobotHeader() {
    return Container(
      height: 185,
      width: double.infinity,
      color: const Color(0xFF55588D),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.asset(
            'logo/Lumi_inicio.png',
            width: 245,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy,
              size: 80,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 20,
            right: 12,
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF100A32),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Text(
                    'Lumi:',
                    style: TextStyle(
                      color: Color(0xFFE871FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tu asistente personal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Divider(
                  color: Colors.white,
                  thickness: 2,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Principiante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white,
                  thickness: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '¡Hola, $userName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Listo para aprender hoy?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPlan() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF17122F),
        border: Border.all(
          color: const Color(0xFF2B2251),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu plan de estudio de hoy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plans.length} ${plans.length == 1 ? 'Plan activo' : 'Planes activos'}',
            style: const TextStyle(
              color: Color(0xFFE474FF),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No tienes planes activos. ¡Crea uno nuevo!',
                style: TextStyle(color: Color(0xFFAAA2C9), fontSize: 9),
              ),
            )
          else
            ...List.generate(
              plans.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildPlanCard(plans[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(StudyPlan plan) {
    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _confirmDeletePlan(plan);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: const Color(0xFFFF4444),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: InkWell(
        onTap: () => _openPlanDetail(plan),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF211A42),
            border: Border.all(
              color: const Color(0xFF33285D),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.school_outlined,
                color: Color(0xFFD942FF),
                size: 22,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAA2C9),
                        fontSize: 8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: plan.progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: const Color(0xFF4B426A),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFC23CFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${(plan.progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTaskCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF17122F),
        border: Border.all(
          color: const Color(0xFF2B2251),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crea un nuevo plan de estudio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Usa la IA de Lumi para generar planes personalizados.',
            style: TextStyle(
              color: Color(0xFFAAA4C5),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddTaskScreen,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD72CFA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return AppBottomNavbar(
      userId: widget.userId,
      currentIndex: activeTab,
    );
  }
}

class StudyPlan {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final bool completed;

  const StudyPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.completed,
  });
}