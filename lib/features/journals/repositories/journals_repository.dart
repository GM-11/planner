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
          final decryptedContent = await EncryptionService.decrypt(
            journal['encrypted_content'],
          );
          return Journal.fromJson({
            ...journal,
            'encrypted_content': decryptedContent,
          });
        }).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Journal> addJournal(String content) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final encryptedContent = await EncryptionService.encrypt(content);

      final response =
          await _supabase
              .from('journals')
              .insert({
                'user_id': userId,
                'encrypted_content': encryptedContent,
              })
              .select()
              .single();

      return Journal.fromJson({...response, 'encrypted_content': content});
    } catch (e) {
      rethrow;
    }
  }

  Future<Journal> updateJournal(Journal journal, String newContent) async {
    try {
      final encryptedContent = await EncryptionService.encrypt(newContent);

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

      return Journal.fromJson({...response, 'encrypted_content': newContent});
    } catch (e) {
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
