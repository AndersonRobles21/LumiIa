/// Stub web para LocalAuthentication cuando no está disponible.
/// Este archivo se usa mediante conditional import en biometric_service.dart y olvidar_contraseña.dart.
/// Proporciona la misma interfaz que local_auth pero sin funcionalidad real.

class LocalAuthentication {
  Future<bool> get canCheckBiometrics async => false;
  Future<bool> isDeviceSupported() async => false;
  Future<List<BiometricType>> getAvailableBiometrics() async => const [];
  Future<bool> authenticate({
    String? localizedReason,
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = false,
  }) async => false;
}

enum BiometricType { fingerprint, face, iris, none }