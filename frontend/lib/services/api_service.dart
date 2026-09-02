import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _backendHost {
    if (kIsWeb) return 'http://localhost:3000';

    // Celular físico conectado por USB:
    // ejecutar antes: adb reverse tcp:3000 tcp:3000
    if (Platform.isAndroid) return 'http://localhost:3000';

    return 'http://localhost:3000';
  }

  static String get baseUrl => '$_backendHost/api/auth';
  static String get tareasBaseUrl => '$_backendHost/api/tareas';
  static String get iaBaseUrl => '$_backendHost/api/ia';
  static String get adminBaseUrl => '$_backendHost/api/admin';
  static String get progresoBaseUrl => '$_backendHost/api/progreso';

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/$userId'));
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService getProfile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> syncTaskStats(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estadisticas/$userId/tareas'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService syncTaskStats: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    required String nombre,
    required String apellido,
    required int horasDisponibles,
    required String objetivo,
    required int nivelProcrastinacion,
    String? fotoPerfil,
    List<Map<String, dynamic>>? horario,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'horas_disponibles': horasDisponibles,
          'objetivo': objetivo,
          'nivel_procrastinacion': nivelProcrastinacion,
          'foto_perfil': fotoPerfil,
          'horario': horario,
        }),
      );

      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService updateProfile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> requestPasswordReset(
    String correo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );

      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService requestPasswordReset: $e');
      return null;
    }
  }

  static Future<bool> resetPassword(
    String correo,
    String password,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'password': password,
          'code': code,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService resetPassword: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> login({required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId}),
      );

      if (response.body.isEmpty) {
        throw Exception(
          'El servidor Node.js devolvió una respuesta vacía en el inicio de sesión.',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['mensaje'] ?? 'Error al iniciar sesión en el servidor local.',
        );
      }

      return data;
    } catch (e) {
      throw Exception('Error en ApiService login: $e');
    }
  }

  static Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.body.isEmpty) {
        throw Exception('El servidor Node.js devolvió una respuesta vacía.');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 201) {
        throw Exception(
          data != null && data['mensaje'] != null
              ? data['mensaje']
              : 'Error al registrar usuario en el servidor.',
        );
      }

      return true;
    } on FormatException catch (_) {
      throw Exception(
        'Respuesta inválida del servidor. No se pudo procesar el JSON.',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getEstadisticas(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estadisticas/$userId'),
      );

      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService getEstadisticas: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAdminSummary(String userId) async {
    try {
      final response = await http.get(Uri.parse('$adminBaseUrl/summary/$userId'));
      if (response.statusCode != 200) {
        String mensaje = 'No se pudo cargar el resumen administrativo.';
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          if (data is Map && data['mensaje'] != null) {
            mensaje = data['mensaje'].toString();
          }
        }
        throw Exception(mensaje);
      }
      if (response.body.isEmpty) {
        throw Exception('El servidor devolvió un resumen vacío.');
      }
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('El formato del resumen administrativo no es válido.');
    } catch (e) {
      print('Error en ApiService getAdminSummary: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getAdminUsuarios(String userId, {String? order}) async {
    try {
      final uri = Uri.parse('$adminBaseUrl/usuarios/$userId').replace(queryParameters: order != null ? {'order': order} : null);
      final response = await http.get(uri);
      if (response.statusCode != 200 || response.body.isEmpty) return const [];
      final data = jsonDecode(response.body);
      if (data is Map && data['usuarios'] is List) return data['usuarios'] as List;
      return const [];
    } catch (e) {
      print('Error en ApiService getAdminUsuarios: $e');
      return const [];
    }
  }

  static Future<List<dynamic>> getAdminAdministradores(String userId) async {
    try {
      final uri = Uri.parse('$adminBaseUrl/administradores/$userId');
      final response = await http.get(uri);
      if (response.statusCode != 200 || response.body.isEmpty) return const [];
      final data = jsonDecode(response.body);
      if (data is Map && data['usuarios'] is List) return data['usuarios'] as List;
      return const [];
    } catch (e) {
      print('Error en ApiService getAdminAdministradores: $e');
      return const [];
    }
  }

  static Future<Map<String, dynamic>?> getAdminUsuarioDetalle(String adminUserId, String targetUserId) async {
    try {
      final response = await http.get(Uri.parse('$adminBaseUrl/usuarios/$adminUserId/$targetUserId'));
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      print('Error en ApiService getAdminUsuarioDetalle: $e');
      return null;
    }
  }

  static Future<bool> updateAdminUserName({
    required String adminUserId,
    required String targetUserId,
    required String nombre,
    required String apellido,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$adminBaseUrl/usuarios/$adminUserId/$targetUserId/nombre'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'apellido': apellido}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService updateAdminUserName: $e');
      return false;
    }
  }

  static Future<bool> deleteAdminUser({
    required String adminUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await http.delete(Uri.parse('$adminBaseUrl/usuarios/$adminUserId/$targetUserId'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService deleteAdminUser: $e');
      return false;
    }
  }

  static Future<bool> promoteAdminUser({
    required String adminUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$adminBaseUrl/usuarios/$adminUserId/$targetUserId/promover'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService promoteAdminUser: $e');
      return false;
    }
  }

  static Future<bool> delegateAdminUser({
    required String adminUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$adminBaseUrl/usuarios/$adminUserId/$targetUserId/delegar'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService delegateAdminUser: $e');
      return false;
    }
  }

  static Future<bool> registrarRachaHoy(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estadisticas/$userId/racha'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en ApiService registrarRachaHoy: $e');
      return false;
    }
  }

  static Future<List<dynamic>?> getPlanesEstudio(String userId) async {
    try {
      final response = await http.get(Uri.parse('$tareasBaseUrl/$userId'));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['tareas'] != null) return data['tareas'];
      return null;
    } catch (e) {
      print('Error en ApiService getPlanesEstudio: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generarPlanIA({
    required String userId,
    required String titulo,
    required String descripcion,
    required String fechaEntrega,
    required String metodoEstudio,
    required String dificultad,
    required String enfoqueAdicional,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$iaBaseUrl/generar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': userId,
          'nombre': titulo,
          'descripcion': descripcion,
          'fecha_entrega': fechaEntrega,
          'metodo_estudio': metodoEstudio,
          'dificultad': dificultad,
          'enfoque_adicional': enfoqueAdicional,
        }),
      );

      if (response.body.isEmpty) {
        throw Exception('Respuesta vacía del servidor.');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(data['mensaje'] ?? 'Error al generar el plan.');
      }

      return data;
    } catch (e) {
      print('Error generarPlanIA: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> obtenerHistorial(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$iaBaseUrl/historial/$usuarioId'),
      );

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final data = jsonDecode(response.body);
      if (data is List) return data;
      return null;
    } catch (e) {
      print('Error en ApiService obtenerHistorial: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> obtenerPlan(String planId) async {
    try {
      final response = await http.get(Uri.parse('$iaBaseUrl/plan/$planId'));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      print('Error en ApiService obtenerPlan: $e');
      return null;
    }
  }

  static Future<bool> completarTarea({
    required String tareaId,
    required bool completada,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$tareasBaseUrl/$tareaId/completar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'completada': completada}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error completarTarea: $e');
      return false;
    }
  }

  static Future<bool> eliminarPlan(String planId) async {
    try {
      final response = await http.delete(
        Uri.parse('$iaBaseUrl/plan/$planId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) return true;

      print('Error eliminando plan: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Error eliminando plan: $e');
      return false;
    }
  }

  static Future<bool> actualizarProgresoPlan({
    required String planId,
    required List<dynamic> pasos,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$iaBaseUrl/plan/$planId/progreso'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pasos': pasos}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error actualizarProgresoPlan: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> evaluarExplicacionFeynman({
    required String concepto,
    required String explicacion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$iaBaseUrl/feynman/evaluar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'concepto': concepto,
          'explicacion': explicacion,
        }),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('Error evaluando Feynman: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> regenerarPlanExistente({
    required String planId,
    required String metodoEstudio,
    required String userId,
    required String titulo,
    required String descripcion,
    required String fechaEntrega,
    required String dificultad,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$iaBaseUrl/plan/$planId/metodo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'metodo_estudio': metodoEstudio,
          'usuario_id': userId,
          'nombre': titulo,
          'descripcion': descripcion,
          'fecha_entrega': fechaEntrega,
          'dificultad': dificultad,
        }),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        return data['plan'] ?? data;
      }

      return null;
    } catch (e) {
      print('Error al conectar con el servidor para cambiar método: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProgreso(String userId) async {
    try {
      final response = await http.get(Uri.parse('$progresoBaseUrl/$userId'));

      print('GET progreso: ${response.statusCode}');
      print('BODY progreso: ${response.body}');

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      print('Error en ApiService getProgreso: $e');
      return null;
    }
  }

  static Future<bool> registrarSesionEstudio({
    required String userId,
    required String categoria,
    required int duracionMinutos,
    String tipoOrigen = 'manual',
    String? origenId,
    DateTime? inicio,
    DateTime? fin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$progresoBaseUrl/sesion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': userId,
          'tipo_origen': tipoOrigen,
          'origen_id': origenId,
          'categoria': categoria,
          'duracion_minutos': duracionMinutos,
          'inicio': inicio?.toIso8601String(),
          'fin': fin?.toIso8601String() ?? DateTime.now().toIso8601String(),
        }),
      );

      print('POST sesion estudio: ${response.statusCode}');
      print('BODY sesion estudio: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error en ApiService registrarSesionEstudio: $e');
      return false;
    }
  }
}