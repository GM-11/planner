import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/features/journals/providers/search_provider.dart';

class JournalSearchBar extends ConsumerWidget {
  final bool isDesktop;

  const JournalSearchBar({super.key, this.isDesktop = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 48),
      decoration: BoxDecoration(
        color: isDesktop ? Colors.white : Colors.white70,
        borderRadius: BorderRadius.circular(12),
        border:
            isDesktop
                ? Border.all(color: Colors.grey.shade200)
                : Border.all(color: Colors.transparent),
      ),
      child: TextField(
        onChanged: (value) {
          ref.read(journalSearchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Search journals...',
          hintStyle: TextStyle(
            color: isDesktop ? Colors.grey : Theme.of(context).primaryColor,
          ),

          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
        ),
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}
