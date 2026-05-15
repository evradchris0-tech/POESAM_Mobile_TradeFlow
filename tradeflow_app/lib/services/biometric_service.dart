import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const _kEmail    = 'bio_email';
  static const _kPassword = 'bio_password';
  static const _kEnabled  = 'bio_enabled';

  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    return await _storage.read(key: _kEnabled) == 'true';
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Identifiez-vous pour accéder à TradeFlow',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _kEmail,    value: email);
    await _storage.write(key: _kPassword, value: password);
    await _storage.write(key: _kEnabled,  value: 'true');
  }

  Future<(String, String)?> getCredentials() async {
    final email = await _storage.read(key: _kEmail);
    final pass  = await _storage.read(key: _kPassword);
    if (email == null || pass == null) return null;
    return (email, pass);
  }

  Future<void> setEnabled(bool value) async {
    await _storage.write(key: _kEnabled, value: value.toString());
  }

  Future<void> disable() async {
    await _storage.deleteAll();
  }

  Future<String> label() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      if (list.contains(BiometricType.face)) return 'Face ID';
      if (list.contains(BiometricType.fingerprint)) return 'Empreinte digitale';
      return 'Biométrie';
    } on PlatformException {
      return 'Biométrie';
    }
  }

  Future<IconData> icon() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      if (list.contains(BiometricType.face)) return Icons.face_outlined;
      return Icons.fingerprint;
    } on PlatformException {
      return Icons.fingerprint;
    }
  }
}
