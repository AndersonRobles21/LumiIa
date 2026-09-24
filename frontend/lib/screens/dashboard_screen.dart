import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import 'agregar_tarea_screen.dart';
import 'app_bottom_navbar.dart';
import 'guia_detalle_screen.dart';
import '../utils/responsive.dart';
import '../services/task_notification_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _completedPlansTimer;
  bool _isStreakDialogOpen = false;
  int activeTab = 0;
  bool isLoading = true;

  String userName = '';
  int activeStreak = 0;

  List<StudyPlan> plans = [];
  List<dynamic> _profileAlerts = [];
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
    _completedPlansTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadActivePlans(),
    );
  }

  @override
  void dispose() {
    _completedPlansTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    final profileData = await ApiService.getProfile(widget.userId);
    final profileAlerts = await ApiService.getProfileAlerts(widget.userId);
    if (mounted) {
      setState(() {
        userName = profileData?['nombre']?.toString().trim() ?? '';
        _profileAlerts = profileAlerts;
      });
    }

    await _loadActivePlans();
    final prefs = await SharedPreferences.getInstance();
    await _updateStreakAutomatically(prefs);

    if (!mounted) return;

    setState(() => isLoading = false);
  }

  Future<void> _loadActivePlans() async {
    final historialData = await ApiService.obtenerHistorial(widget.userId);

    if (historialData == null || historialData.isEmpty) {
      if (!mounted) return;
      setState(() => plans = []);
      return;
    }

    final now = DateTime.now();

    List<StudyPlan> loadedPlans = [];

    for (var plan in historialData) {
      final planId = plan['id']?.toString();
      if (planId == null) continue;

      final nombre = plan['nombre'] ?? plan['titulo'] ?? 'Sin título';
      final descripcion = plan['descripcion'] ?? 'Plan de estudio';

      final planCompleto = await ApiService.obtenerPlan(planId);

      double progress = 0.0;
      bool allCompleted = false;

      if (planCompleto != null &&
          planCompleto['pasos'] != null &&
          planCompleto['pasos'] is List) {
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

      final completedAt = DateTime.tryParse(
        plan['completado_en']?.toString() ?? '',
      )?.toLocal();
      if (completedAt != null &&
          now.difference(completedAt) >= const Duration(hours: 5)) {
        continue;
      }

      loadedPlans.add(
        StudyPlan(
          id: planId,
          title: nombre.toString(),
          subtitle: descripcion.toString(),
          progress: progress,
          completed: allCompleted,
        ),
      );
    }

    if (!mounted) return;
    setState(() => plans = loadedPlans);
  }

  Future<void> _updateStreakAutomatically(SharedPreferences prefs) async {
    final success = await ApiService.registrarRachaHoy(widget.userId);
    if (!success) debugPrint('No se pudo actualizar la racha diaria.');

    await _loadStreakFromServer();
    await _verificarYMostrarStreakDiario(prefs);
  }

  Future<void> _loadStreakFromServer() async {
    final stats = await ApiService.getEstadisticas(widget.userId);

    if (stats == null) return;

    final racha = stats['racha'] ?? 0;
    final parsedRacha = racha is int
        ? racha
        : int.tryParse(racha.toString()) ?? 0;

    if (!mounted) return;

    setState(() {
      activeStreak = parsedRacha;
      _updateCompletedDaysFromStreakWithoutSetState(parsedRacha);
    });
  }

  void _updateCompletedDaysFromStreakWithoutSetState(int streak) {
    final today = DateTime.now();
    final todayIndex = today.weekday - 1;

    completedDays = List<bool>.filled(7, false);

    for (int i = 0; i < streak && i <= todayIndex; i++) {
      completedDays[todayIndex - i] = true;
    }
  }

  void _showStreakDialog() {
    if (_isStreakDialogOpen || !mounted) return;

    setState(() {
      _isStreakDialogOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: LumiAppTheme.surface(context),
      barrierColor: Colors.black.withOpacity(0.0),
      builder: (BuildContext sheetContext) {
        return _buildStreakBottomSheet(sheetContext);
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isStreakDialogOpen = false;
        });
      }
    });
  }

  Future<void> _verificarYMostrarStreakDiario(SharedPreferences prefs) async {
    if (_isStreakDialogOpen) return;

    final todayString = DateTime.now().toIso8601String().split('T')[0];
    final lastShownDate = prefs.getString(
      'last_streak_dialog_shown_${widget.userId}',
    );

    if (lastShownDate != todayString) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && !_isStreakDialogOpen) {
        await prefs.setString(
          'last_streak_dialog_shown_${widget.userId}',
          todayString,
        );
        _showStreakDialog();
      }
    }
  }

  Widget _buildStreakBottomSheet(BuildContext sheetContext) {
    return Container(
      padding: EdgeInsets.only(
        top: Responsive.espacio(sheetContext) * 2,
        bottom: Responsive.espacio(sheetContext) * 3,
      ),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: LumiAppTheme.secondaryText(context).withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: Responsive.espacio(sheetContext) * 2),
          Image.asset(
            'logo/racha.png',
            height: Responsive.esEscritorio(sheetContext) ? 120 : 80,
            width: Responsive.esEscritorio(sheetContext) ? 120 : 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Text('🔥', style: TextStyle(fontSize: 64)),
          ),
          SizedBox(height: Responsive.espacio(sheetContext)),
          Text(
            '$activeStreak Racha activa !',
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: Responsive.tamanioTitulo(sheetContext),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.espacio(sheetContext) / 2),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.paddingHorizontalRecomendado(sheetContext),
            ),
            child: Text(
              'Completar una lección al día como rutina.',
              style: TextStyle(
                color: LumiAppTheme.secondaryText(context),
                fontSize: Responsive.tamanioTexto(sheetContext),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: Responsive.espacio(sheetContext) * 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(weekDays.length, (index) {
                final isCompleted = completedDays[index];

                return Column(
                  children: [
                    Text(
                      weekDays[index],
                      style: TextStyle(
                        color: LumiAppTheme.primaryText(context),
                        fontSize: Responsive.tamanioTexto(sheetContext) - 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.espacio(sheetContext) / 1.5),
                    SizedBox(
                      height: Responsive.esEscritorio(sheetContext) ? 42 : 30,
                      width: Responsive.esEscritorio(sheetContext) ? 42 : 30,
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2B2251),
                                border: Border.all(
                                  color: const Color(0xFF4B9EFF),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                size: 14,
                                color: Color(0xFF4B9EFF),
                              ),
                            ),
                    ),
                  ],
                );
              }),
            ),
          ),
          SizedBox(height: Responsive.espacio(sheetContext) * 2.5),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.paddingHorizontalRecomendado(sheetContext),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD72CFA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.altoBoton(sheetContext) - 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Seguir Aprendiendo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddTaskScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarTareaScreen(userId: widget.userId),
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
      MaterialPageRoute(builder: (_) => GuiaDetalleScreen(guiaData: planData)),
    );

    await _loadActivePlans();
  }

  Future<void> _confirmDeletePlan(StudyPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumiAppTheme.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          '¿Eliminar plan?',
          style: TextStyle(
            color: LumiAppTheme.primaryText(ctx),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${plan.title}"? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: LumiAppTheme.secondaryText(ctx),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: LumiAppTheme.secondaryText(ctx)),
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

        final tareasActualizadas = await ApiService.getPlanesEstudio(
          widget.userId,
        );
        if (tareasActualizadas != null) {
          debugPrint(
            '[LUMI notifications] eliminación exitosa; sincronizando tareas desde DashboardScreen',
          );
          await TaskNotificationService.instance.syncTasks(tareasActualizadas);
        }

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
      backgroundColor: LumiAppTheme.pageBackground(context),
      body: SafeArea(
        child: Responsive.esEscritorio(context)
            ? Row(
                children: [
                  _buildBottomNavigation(),
                  Expanded(child: _buildMainContent()),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _buildMainContent()),
                  _buildBottomNavigation(),
                ],
              ),
      ),
    );
  }

  Widget _buildMainContent() {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFD942FF)),
          )
        : RefreshIndicator(
            color: const Color(0xFFD942FF),
            onRefresh: _loadDashboardData,
            child: _buildDashboard(),
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
          _buildProfileAlerts(),
          _buildStudyPlan(),
          _buildAddTaskCard(),
        ],
      ),
    );
  }

  Widget _buildProfileAlerts() {
    if (_profileAlerts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LumiAppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF44AA).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFFF8ACB),
              ),
              SizedBox(width: 8),
              Text(
                'Alertas de tu perfil',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._profileAlerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• ${(alert['mensaje'] ?? 'Se actualizó tu perfil.').toString()}',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRobotHeader() {
    return Container(
      height: Responsive.esEscritorio(context) ? 260 : 185,
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF55588D)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image.asset(
            'logo/Lumi_inicio.png',
            width: Responsive.esEscritorio(context) ? 340 : 245,
            height: Responsive.esEscritorio(context) ? 260 : 180,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.smart_toy, size: 80, color: Colors.white),
          ),
          Positioned(
            top: Responsive.espacio(context) * 2,
            right: Responsive.espacio(context) * 1.5,
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: LumiAppTheme.surface(context),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text(
                    'Lumi:',
                    style: TextStyle(
                      color: const Color(0xFFE871FF),
                      fontSize: Responsive.tamanioTexto(context) - 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.espacio(context) / 2),
                  Text(
                    'Tu asistente personal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: LumiAppTheme.primaryText(context),
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
      padding: EdgeInsets.fromLTRB(
        Responsive.paddingHorizontalRecomendado(context) / 2,
        Responsive.espacio(context),
        Responsive.paddingHorizontalRecomendado(context) / 2,
        Responsive.espacio(context) / 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: LumiAppTheme.outline(context),
                  thickness: 2,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.espacio(context) * 1.5,
                ),
                child: Text(
                  'Principiante',
                  style: TextStyle(
                    color: LumiAppTheme.primaryText(context),
                    fontSize: Responsive.tamanioTexto(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: LumiAppTheme.outline(context),
                  thickness: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.espacio(context) * 1.25),
          Text(
            '¡Hola, $userName!',
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: Responsive.tamanioTitulo(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.espacio(context) / 2),
          Text(
            '¿Listo para aprender hoy?',
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPlan() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        Responsive.paddingHorizontalRecomendado(context) / 2,
        Responsive.espacio(context),
        Responsive.paddingHorizontalRecomendado(context) / 2,
        Responsive.espacio(context),
      ),
      padding: EdgeInsets.all(Responsive.espacio(context) * 1.5),
      decoration: BoxDecoration(
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.24),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4BC1).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu plan de estudio de hoy',
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: Responsive.tamanioSubtitulo(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.espacio(context) / 2),
          Text(
            '${plans.length} ${plans.length == 1 ? 'Plan activo' : 'Planes activos'}',
            style: const TextStyle(color: Color(0xFFE474FF), fontSize: 9),
          ),
          SizedBox(height: Responsive.espacio(context) * 1.5),
          if (plans.isEmpty)
            Container(
              height: Responsive.esEscritorio(context) ? 70 : 56,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: Text(
                'No tienes planes activos. ¡Crea uno nuevo!',
                style: TextStyle(
                  color: LumiAppTheme.secondaryText(context),
                  fontSize: Responsive.tamanioTexto(context),
                ),
              ),
            )
          else
            ...List.generate(
              plans.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.espacio(context)),
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
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      child: InkWell(
        onTap: () => _openPlanDetail(plan),
        child: Container(
          padding: EdgeInsets.all(Responsive.espacio(context)),
          decoration: BoxDecoration(
            color: LumiAppTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D4BC1).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: const Color(0xFFD942FF),
                size: Responsive.tamanioSubtitulo(context),
              ),
              SizedBox(width: Responsive.espacio(context) + 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        color: LumiAppTheme.primaryText(context),
                        fontSize: Responsive.tamanioSubtitulo(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Responsive.espacio(context) / 2),
                    Text(
                      plan.subtitle,
                      style: TextStyle(
                        color: LumiAppTheme.secondaryText(context),
                        fontSize: Responsive.tamanioTexto(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.espacio(context)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: plan.progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFC23CFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.espacio(context)),
              Text(
                '${(plan.progress * 100).round()}%',
                style: TextStyle(
                  color: LumiAppTheme.primaryText(context),
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
        color: LumiAppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.24),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4BC1).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crea un nuevo plan de estudio',
            style: TextStyle(
              color: LumiAppTheme.primaryText(context),
              fontSize: Responsive.tamanioSubtitulo(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.espacio(context)),
          Text(
            'Usa la IA de Lumi para generar planes personalizados.',
            style: TextStyle(
              color: LumiAppTheme.secondaryText(context),
              fontSize: 9,
            ),
          ),
          SizedBox(height: Responsive.espacio(context) * 1.5),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openAddTaskScreen,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD72CFA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                minimumSize: const Size(0, 44),
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
    return AppBottomNavbar(userId: widget.userId, currentIndex: activeTab);
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
