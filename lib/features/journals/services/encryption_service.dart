import 'dart:developer';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../../shared/services/supabase_service.dart';

class EncryptionService {
  static String deriveKeyFromUserId(String userId) {
    // Use SHA-256 to create a deterministic 32-byte key from the userId
    final bytes = utf8.encode(userId);
    final hash = sha256.convert(bytes);
    // Convert to base64 for the AES key
    return base64.encode(hash.bytes);
  }

  static String getCurrentUserId() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user found');
    }
    return userId;
  }

  static Future<String> getKey() async {
    try {
      final userId = getCurrentUserId();
      return deriveKeyFromUserId(userId);
    } catch (e) {
      log('Error getting encryption key: $e');
      rethrow;
    }
  }

  static Future<String> encrypt(String text) async {
    try {
      final key = await getKey();
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
      if (!isEncrypted(encryptedText)) {
        log('Text is not encrypted: $encryptedText');
        return encryptedText;
      }

      final key = await getKey();
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
      return encryptedText;
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
