import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/journal.dart';
import '../../../shared/services/supabase_service.dart';
import '../services/encryption_service.dart';

final journalsRepositoryProvider = Provider<JournalsRepository>((ref) {
  return JournalsRepository();
});

class JournalsRepository {
  final _supabase = SupabaseService.client;

  Future<List<Journal>> getJournals() async {
    try {
      final response = await _supabase
          .from('journals')
          .select()
          .order('created_at', ascending: false);

      return Future.wait(
        response.map((journal) async {
          String decryptedContent;
          try {
            // Make sure we're getting the encrypted content from the database
            final encryptedContent = journal['encrypted_content'] as String;

            // Attempt to decrypt the content
            decryptedContent = await EncryptionService.decrypt(
              encryptedContent,
            );

            // Log for debugging
            log('Original content: $encryptedContent');
            log('Decrypted content: $decryptedContent');
          } catch (e) {
            log('Decryption error: $e');
            decryptedContent = journal['encrypted_content']; // Fallback
          }

          return Journal.fromJson({
            'id': journal['id'],
            'user_id': journal['user_id'],
            'created_at': journal['created_at'],
            'updated_at': journal['updated_at'],
            'encrypted_content': decryptedContent, // Use the decrypted content
          });
        }).toList(),
      );
    } catch (e) {
      log('Error fetching journals: $e');
      rethrow;
    }
  }

  Future<Journal> addJournal(String content) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Encrypt the content before saving
      final encryptedContent = await EncryptionService.encrypt(content);

      log('Adding journal - Original: $content');
      log('Adding journal - Encrypted: $encryptedContent');

      final response =
          await _supabase
              .from('journals')
              .insert({
                'user_id': userId,
                'encrypted_content': encryptedContent,
              })
              .select()
              .single();

      // Return the journal with decrypted content
      return Journal.fromJson({
        ...response,
        'encrypted_content':
            content, // Use original content for the returned object
      });
    } catch (e) {
      log('Error adding journal: $e');
      rethrow;
    }
  }

  Future<Journal> updateJournal(Journal journal, String newContent) async {
    try {
      // Encrypt the new content
      final encryptedContent = await EncryptionService.encrypt(newContent);

      log('Updating journal - Original: $newContent');
      log('Updating journal - Encrypted: $encryptedContent');

      final response =
          await _supabase
              .from('journals')
              .update({
                'encrypted_content': encryptedContent,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', journal.id)
              .select()
              .single();

      // Return the journal with decrypted content
      return Journal.fromJson({
        ...response,
        'encrypted_content':
            newContent, // Use the new content for the returned object
      });
    } catch (e) {
      log('Error updating journal: $e');
      rethrow;
    }
  }

  Future<void> deleteJournal(String id) async {
    try {
      await _supabase.from('journals').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
