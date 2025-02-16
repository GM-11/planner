import 'package:encrypt/encrypt.dart';
import './storage_service.dart';

class EncryptionService {
  static const _keyStorageKey = 'encryption_key';
  static final _storage = StorageService();

  static Future<String> getOrCreateKey() async {
    String? key = await _storage.read(_keyStorageKey);
    if (key == null) {
      key = Key.fromSecureRandom(32).base64;
      await _storage.write(_keyStorageKey, key);
    }
    return key;
  }

  static Future<String> encrypt(String text) async {
    final key = await getOrCreateKey();
    final encrypter = Encrypter(AES(Key.fromBase64(key)));
    final iv = IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(text, iv: iv);
    return '${encrypted.base64}:${iv.base64}';
  }

  static Future<String> decrypt(String encryptedText) async {
    final key = await getOrCreateKey();
    final encrypter = Encrypter(AES(Key.fromBase64(key)));

    final parts = encryptedText.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted text format');

    final encrypted = Encrypted.fromBase64(parts[0]);
    final iv = IV.fromBase64(parts[1]);

    return encrypter.decrypt(encrypted, iv: iv);
  }
}
