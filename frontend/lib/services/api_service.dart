import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://localhost:3000/api/auth';

  /*
============================
GET PROFILE
============================
*/
static Future<Map<String, dynamic>?> getProfile(
  String userId,
) async {
  final response = await http.get(
    Uri.parse('$baseUrl/profile/$userId'),
  );

  if (response.statusCode != 200) {
    return null;
  }

  return jsonDecode(response.body);
}

/*
============================
UPDATE PROFILE
============================
*/
static Future<bool> updateProfile(
  String userId,
  String nombre,
  List<String> schedule, // <-- Cambiado de List<List<bool>> a List<String>
  List<bool> methods,
) async {
  final response = await http.put(
    Uri.parse('$baseUrl/profile/$userId'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nombre': nombre,
      'horario': schedule, // <-- Enviamos la lista de horas con la clave que espera tu Node.js
    }),
  );

  return response.statusCode == 200;
}

/*
============================
REQUEST PASSWORD RESET
============================
*/
static Future<Map<String, dynamic>?> requestPasswordReset(
  String correo,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/password/request'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'correo': correo,
    }),
  );

  if (response.statusCode != 200) {
    return null;
  }

  return jsonDecode(response.body);
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
  final response = await http.post(
    Uri.parse('$baseUrl/password/reset'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'correo': correo,
      'password': password,
      'code': code,
    }),
  );

  return response.statusCode == 200;
}

  /*
  ============================
  LOGIN
  POST /api/auth/login
  ============================
  */
  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['mensaje'] ?? 'Error al iniciar sesión',
      );
    }

    return data;
  }

  /*
  ============================
  REGISTER
  POST /api/auth/register
  ============================
  */
  static Future<bool> register(
    Map<String, dynamic> userData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['mensaje'] ?? 'Error al registrar usuario',
      );
    }

    return true;
  }
}