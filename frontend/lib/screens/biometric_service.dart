import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación biométrica (huella / Face ID).
///
/// Requiere en pubspec.yaml:
///   local_auth: ^3.0.1   (ya lo tienes)
///
/// Y configuración nativa:
///  - Android: en android/app/src/main/AndroidManifest.xml agregar
///      <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
///    y que MainActivity.kt extienda FlutterFragmentActivity (no FlutterActivity).
///  - iOS: en ios/Runner/Info.plist agregar
///      <key>NSFaceIDUsageDescription</key>
///      <string>Usamos Face ID para iniciar sesión más rápido en Lumi</string>
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('biometric_enabled') ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
  }

  /// Revisa si el dispositivo puede usar biometría: tiene el hardware Y
  /// el usuario ya tiene huella/Face ID configurados en su celular.
  static Future<bool> isDeviceSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool supported = await _auth.isDeviceSupported();
      final bool hasEnrolled = await _auth.getAvailableBiometrics().then(
        (value) => value.isNotEmpty,
      );
      return canCheck && supported && hasEnrolled;
    } catch (_) {
      // Cualquier fallo de plataforma (sensor no disponible, permiso
      // negado, etc.) lo tratamos simplemente como "no soportado".
      return false;
    }
  }

  /// Lanza el prompt nativo de huella/Face ID.
  /// true  -> el usuario se autenticó correctamente.
  /// false -> falló, canceló, o el dispositivo no soporta biometría.
  /// En todos los casos "false" la pantalla de login debe caer a contraseña.
  static Future<bool> authenticate({
    String reason = 'Confirma tu identidad para entrar a Lumi',
  }) async {
    try {
      final soportado = await isDeviceSupported();
      if (!soportado) return false;

      final available = await _auth.getAvailableBiometrics();
      if (available.isEmpty) return false;

      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      // Cubre tanto LocalAuthException (local_auth 3.x) como cualquier
      // otro error de plataforma. Nunca dejamos que esto tumbe la app:
      // si algo sale mal, simplemente no se autenticó.
      return false;
    }
  }
}
