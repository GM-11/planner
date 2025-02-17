import 'dart:developer';
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
      log('Created new encryption key: $key');
    }
    return key;
  }

  static Future<String> encrypt(String text) async {
    try {
      final key = await getOrCreateKey();
      final encrypter = Encrypter(AES(Key.fromBase64(key)));
      final iv = IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(text, iv: iv);
      return '${encrypted.base64}:${iv.base64}';
    } catch (e) {
      log('Encryption error: $e');
      rethrow;
    }
  }

  static Future<String> decrypt(String encryptedText) async {
    try {
      // Check if the text is actually encrypted
      if (!isEncrypted(encryptedText)) {
        log('Text is not encrypted: $encryptedText');
        return encryptedText;
      }

      final key = await getOrCreateKey();
      final encrypter = Encrypter(AES(Key.fromBase64(key)));

      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        log('Invalid encrypted text format');
        return encryptedText;
      }

      final encrypted = Encrypted.fromBase64(parts[0]);
      final iv = IV.fromBase64(parts[1]);

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      log('Decryption error: $e');
      return encryptedText; // Return original text if decryption fails
    }
  }

  static bool isEncrypted(String text) {
    try {
      final parts = text.split(':');
      return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
