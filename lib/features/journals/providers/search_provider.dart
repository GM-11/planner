import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/features/journals/providers/journals_provider.dart';

import '../../../shared/models/journal.dart';

final journalSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredJournalsProvider = Provider<List<Journal>>((ref) {
  final journalsAsyncValue = ref.watch(journalsProvider);
  final searchQuery = ref.watch(journalSearchQueryProvider).toLowerCase();

  return journalsAsyncValue.when(
    data: (journals) {
      if (searchQuery.isEmpty) return journals;
      return journals.where((journal) {
        return journal.encryptedContent.toLowerCase().contains(searchQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
