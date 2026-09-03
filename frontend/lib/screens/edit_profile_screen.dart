import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _accent = Color(0xFFFF44AA);
  final _characters = List<int>.generate(18, (index) => index + 1);
  final Set<int> _purchased = {};
  int _xp = 0;
  int _xpGanado = 0;
  int _xpGastado = 0;
  int? _selected;
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;

  int _cost(int character) => character * 25;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(widget.userId),
        ApiService.getEstadisticas(widget.userId),
        ApiService.getPlanesEstudio(widget.userId),
        ApiService.obtenerHistorial(widget.userId),
        ApiService.getPersonajes(widget.userId),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      final stats = results[1] as Map<String, dynamic>?;
      final plans = (results[2] as List<dynamic>?)?.length ?? 0;
      final tasks = (stats?['tareas_completadas'] as num?)?.toInt() ?? 0;
      final streak = (stats?['racha'] as num?)?.toInt() ?? 0;
      final hours = double.tryParse('${stats?['horas_estudio'] ?? 0}') ?? 0;
      final achievementCount = _achievementCount(tasks, streak, plans, hours);
      final xp =
          (tasks * 20) + (streak * 15) + (plans * 25) + (achievementCount * 35);
      final purchasedRows = (results[4] as List<dynamic>?) ?? [];
      final purchased = purchasedRows
          .whereType<Map>()
          .map((row) => (row['personaje'] as num).toInt())
          .toSet();
      final spent = purchasedRows.whereType<Map>().fold<int>(
        0,
        (sum, row) => sum + ((row['costo_xp'] as num?)?.toInt() ?? 0),
      );
      final saved = profile?['perfil_estudio']?['foto_perfil']?.toString();
      final savedCharacter = _characterFromValue(saved);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _xpGanado = xp;
        _xpGastado = spent;
        _xp = (xp - spent).clamp(0, xp);
        _selected = savedCharacter;
        _purchased.addAll(purchased);
        if (savedCharacter != null) _purchased.add(savedCharacter);
        _loading = false;
      });
    } catch (error) {
      debugPrint('Error cargando personajes: $error');
      if (mounted) setState(() => _loading = false);
    }
  }

  int _achievementCount(int tasks, int streak, int plans, double hours) {
    var count = 0;
    if (tasks >= 1) count++;
    if (tasks >= 5) count++;
    if (plans >= 1) count += 2;
    if (tasks >= 1 || hours >= 1) count++;
    if (streak >= 3) count++;
    if (streak >= 10) count++;
    if (streak >= 30) count++;
    if (tasks >= 2 || hours >= 1) count++;
    if (hours >= 1 || tasks >= 2) count++;
    if (tasks >= 8) count++;
    if (tasks >= 10) count++;
    if (tasks >= 15) count++;
    if (plans >= 2) count++;
    if (tasks >= 20) count++;
    if (count >= 10) count++;
    return count;
  }

  int? _characterFromValue(String? value) {
    if (value == null) return null;
    final match = RegExp(r'personaje(\d+)').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<void> _choose(int character) async {
    if (_xp < _cost(character)) {
      _message(
        'Necesitas ${_cost(character)} XP para desbloquear este personaje.',
      );
      return;
    }
    final isNewPurchase = !_purchased.contains(character);
    if (isNewPurchase) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1040),
          title: const Text(
            'Desbloquear personaje',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Seguro que quieres comprar el personaje $character por ${_cost(character)} XP?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: const Text('Comprar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _saving = true);
    final result = isNewPurchase
        ? await ApiService.comprarPersonaje(
            userId: widget.userId,
            personaje: character,
          )
        : await ApiService.updateProfile(
            userId: widget.userId,
            nombre: _profile?['nombre']?.toString() ?? '',
            apellido: _profile?['apellido']?.toString() ?? '',
            horasDisponibles:
                ((_profile?['perfil_estudio']
                            as Map<String, dynamic>?)?['horas_disponibles']
                        as num?)
                    ?.toInt() ??
                0,
            objetivo:
                ((_profile?['perfil_estudio']
                        as Map<String, dynamic>?)?['objetivo'])
                    ?.toString() ??
                '',
            nivelProcrastinacion:
                ((_profile?['perfil_estudio']
                            as Map<String, dynamic>?)?['nivel_procrastinacion']
                        as num?)
                    ?.toInt() ??
                1,
            fotoPerfil: 'asset:logo/personajes/personaje$character.png',
          );
    final saved = result != null;
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) {
        _purchased.add(character);
        if (isNewPurchase) {
          _xpGastado += _cost(character);
          _xp = (_xpGanado - _xpGastado).clamp(0, _xpGanado);
        }
        _selected = character;
      }
    });
    _message(
      saved
          ? 'Personaje seleccionado para tu foto de perfil.'
          : 'No se pudo guardar el personaje.',
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0813),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'EDITAR PERFIL',
          style: TextStyle(fontSize: 18, letterSpacing: 1.5),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0D2B),
                    Color(0xFF1A1040),
                    Color(0xFF0D0D2B),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '$_xp XP disponibles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .78,
                          ),
                      itemCount: _characters.length,
                      itemBuilder: (context, index) {
                        final character = _characters[index];
                        final unlocked = _xp >= _cost(character);
                        final owned = _purchased.contains(character);
                        return InkWell(
                          onTap: _saving ? null : () => _choose(character),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF17132F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selected == character
                                    ? _accent
                                    : Colors.white12,
                                width: _selected == character ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ColorFiltered(
                                    colorFilter: unlocked
                                        ? const ColorFilter.mode(
                                            Colors.white,
                                            BlendMode.modulate,
                                          )
                                        : const ColorFilter.matrix([
                                            .2126,
                                            .7152,
                                            .0722,
                                            0,
                                            0,
                                            .2126,
                                            .7152,
                                            .0722,
                                            0,
                                            0,
                                            .2126,
                                            .7152,
                                            .0722,
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            1,
                                            0,
                                          ]),
                                    child: Image.asset(
                                      'logo/personajes/personaje$character.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Text(
                                  owned
                                      ? 'Usar'
                                      : unlocked
                                      ? '${_cost(character)} XP'
                                      : '🔒 ${_cost(character)} XP',
                                  style: TextStyle(
                                    color: unlocked
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
