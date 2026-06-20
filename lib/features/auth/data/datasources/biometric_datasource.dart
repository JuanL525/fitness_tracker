import 'package:local_auth/local_auth.dart';

import '../../domain/entities/auth_result.dart';

abstract class BiometricDataSource {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate();
}

class BiometricDataSourceImpl implements BiometricDataSource {
  BiometricDataSourceImpl({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate() async {
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Usa tu huella dactilar para acceder',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return AuthResult(
        success: success,
        message: success ? 'Autenticación exitosa' : 'Autenticación fallida',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}
