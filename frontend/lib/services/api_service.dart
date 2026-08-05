import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/auth';
  static const String tareasBaseUrl = 'http://localhost:3000/api/tareas';
  static const String iaBaseUrl = 'http://localhost:3000/api/ia';

  /*
  ============================
  GET PROFILE
  ============================
  */
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/$userId'));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en ApiService getProfile: $e');
      return null;
    }
  }

  /*
  ============================
  UPDATE PROFILE
  ============================
  */
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
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  /*
  ============================
  REQUEST PASSWORD RESET
  ============================
  */
  static Future<Map<String, dynamic>?> requestPasswordReset(
    String correo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (e) {
      return null;
    }
  }

  /*
  ============================
  RESET PASSWORD
  ============================
  */
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
      return false;
    }
  }

  /*
  ============================
  LOGIN
  ============================
  */
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

  /*
  ============================
  REGISTER
  ============================
  */
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
        'Respuesta inválida del servidor (No se pudo procesar el JSON).',
      );
    } catch (e) {
      rethrow;
    }
  }

  /*
  ============================
  GET ESTADÍSTICAS (racha, tareas completadas)
  ============================
  */
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

  /*
  ============================
  REGISTRAR RACHA HOY
  ============================
  */
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

  /*
  ============================
  GET PLANES DE ESTUDIO (tareas pendientes reales del usuario)
  ============================
  */
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
      print("Error generarPlanIA: $e");
      return null;
    }
  }
  static Future<List<dynamic>?> obtenerHistorial(String usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$iaBaseUrl/historial/$usuarioId'));

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

  /*
============================
COMPLETAR TAREA
============================
*/
static Future<bool> completarTarea({
  required String tareaId,
  required bool completada,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$tareasBaseUrl/$tareaId/completar'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'completada': completada,
      }),
    );

    return response.statusCode == 200;
  } catch (e) {
    print('Error completarTarea: $e');
    return false;
  }
}
}
