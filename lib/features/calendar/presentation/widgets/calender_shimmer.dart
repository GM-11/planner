import 'package:flutter/material.dart';
import 'package:planner/features/calendar/providers/calendar_provider.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class CalendarShimmer extends StatelessWidget {
  final CalendarViewType viewType;

  const CalendarShimmer({super.key, required this.viewType});

  @override
  Widget build(BuildContext context) {
    return switch (viewType) {
      CalendarViewType.daily => const _DailyViewShimmer(),
      CalendarViewType.weekly => const _WeeklyViewShimmer(),
      CalendarViewType.monthly => const _MonthlyViewShimmer(),
    };
  }
}

class _DailyViewShimmer extends StatelessWidget {
  const _DailyViewShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 12,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              ShimmerLoading(
                child: Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShimmerLoading(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyViewShimmer extends StatelessWidget {
  const _WeeklyViewShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Week header shimmer
        ShimmerLoading(child: Container(height: 60, color: Colors.white)),
        Expanded(
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              return Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 1),
                child: Row(
                  children: [
                    ShimmerLoading(
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.all(8),
                        color: Colors.white,
                      ),
                    ),
                    ...List.generate(
                      7,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          child: ShimmerLoading(
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthlyViewShimmer extends StatelessWidget {
  const _MonthlyViewShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerLoading(
          child: Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerLoading(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
