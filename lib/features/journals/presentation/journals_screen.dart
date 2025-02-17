import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:planner/features/journals/presentation/journal_shimmer.dart';
import 'package:planner/features/journals/presentation/search_bar.dart';
import 'package:planner/shared/models/journal.dart';
import '../providers/journals_provider.dart';
import '../providers/search_provider.dart';

class JournalsScreen extends ConsumerWidget {
  const JournalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop ? const _DesktopLayout() : const _MobileLayout();
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);
    final filteredJournals = ref.watch(filteredJournalsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Journal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture your thoughts and reflections',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const JournalSearchBar(),
                ],
              ),
            ),

            // Content
            Expanded(
              child: journalsAsync.when(
                data: (journals) {
                  if (journals.isEmpty) {
                    return const _EmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(journalsProvider);
                    },
                    child: MasonryGridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemCount: filteredJournals.length,
                      itemBuilder: (context, index) {
                        final journal = filteredJournals[index];
                        return _JournalCard(journal: journal);
                      },
                    ),
                  );
                },
                loading: () => const JournalsShimmer(),
                error:
                    (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(journalsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/journals/new'),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);
    final filteredJournals = ref.watch(filteredJournalsProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 400,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture your thoughts and reflections',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/journals/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('New Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: JournalSearchBar(isDesktop: true)),
                      const SizedBox(width: 16),
                      journalsAsync.when(
                        data:
                            (journals) => Text(
                              '${journals.length} entries',
                              style: const TextStyle(color: Colors.grey),
                            ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),

                // Journals grid
                Expanded(
                  child: journalsAsync.when(
                    data: (journals) {
                      if (journals.isEmpty) {
                        return const _EmptyState();
                      }

                      return MasonryGridView.count(
                        padding: const EdgeInsets.all(24),
                        crossAxisCount: 3,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        itemCount: filteredJournals.length,
                        itemBuilder: (context, index) {
                          final journal = filteredJournals[index];
                          return _JournalCard(
                            journal: journal,
                            isDesktop: true,
                          );
                        },
                      );
                    },
                    loading: () => const JournalsShimmer(isDesktop: true),
                    error:
                        (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: $error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    () => ref.invalidate(journalsProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalCard extends ConsumerWidget {
  final Journal journal;
  final bool isDesktop;

  const _JournalCard({required this.journal, this.isDesktop = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(journal.createdAt.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/journals/${journal.id}', extra: journal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            onTap:
                                () => context.push(
                                  '/journals/${journal.id}',
                                  extra: journal,
                                ),
                            child: const Text('Edit'),
                          ),
                          PopupMenuItem(
                            onTap: () => _confirmDelete(context, ref),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                journal.encryptedContent,
                style: const TextStyle(fontSize: 14, height: 1.5),
                maxLines: isDesktop ? 8 : 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Journal Entry'),
            content: const Text(
              'Are you sure you want to delete this entry? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref.read(journalOperationsProvider).deleteJournal(journal.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Ionicons.book_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No journal entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing your thoughts',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
