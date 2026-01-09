// lib/services/security_service.dart
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticateUser() async {
    try {
      // Supports Biometrics or PIN/Passcode [6, 7]
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access Tour Buddy',
        //options: const AuthenticationOptions(biometricOnly: false),
      );
    } catch (e) {
      return false;
    }
  }
}