import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/features/journals/repositories/journals_repository.dart';
import 'package:planner/shared/models/journal.dart';

final journalsRepositoryProvider = Provider<JournalsRepository>((ref) {
  return JournalsRepository();
});

// Change this provider to be auto-disposable
final journalsProvider = AutoDisposeFutureProvider<List<Journal>>((ref) async {
  final repository = ref.watch(journalsRepositoryProvider);
  return repository.getJournals();
});

final journalOperationsProvider = Provider((ref) {
  final repository = ref.watch(journalsRepositoryProvider);
  return JournalOperations(ref, repository);
});

class JournalOperations {
  final Ref _ref;
  final JournalsRepository _repository;

  JournalOperations(this._ref, this._repository);

  Future<void> addJournal(String content) async {
    await _repository.addJournal(content);
    _ref.invalidate(journalsProvider);
  }

  Future<void> updateJournal(Journal journal, String newContent) async {
    await _repository.updateJournal(journal, newContent);
    _ref.invalidate(journalsProvider);
  }

  Future<void> deleteJournal(String id) async {
    await _repository.deleteJournal(id);
    _ref.invalidate(journalsProvider);
  }
}
