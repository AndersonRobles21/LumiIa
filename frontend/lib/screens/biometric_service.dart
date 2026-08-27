import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

  /// aca se verifica q el usuario ya tiene huella/Face ID en su cel
  static Future<bool> isDeviceSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool supported = await _auth.isDeviceSupported();
      final bool hasEnrolled = await _auth.getAvailableBiometrics().then(
        (value) => value.isNotEmpty,
      );
      return canCheck && supported && hasEnrolled;
    } catch (_) {
      // si el sensor o algo del sipositivo falla se manda como no reportado
      return false;
    }
  }

  /// muestra el prom del autentificador, entonces true es si el usuario se autenticó corectamnete
  /// false pss si falló, canceló, o el dispositivo no soporta biometría.
  /// y si tiene fallo false esta para q la pantalla de login pida la contraseña.
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
      // Cubre tanto LocalAuthException local_auth 3.x como cualquierotro error de plataforma
      // esto evita q se caiga la app y si pasa hace como q el usuario no se autentificó corectamente
      return false;
    }
  }
}
