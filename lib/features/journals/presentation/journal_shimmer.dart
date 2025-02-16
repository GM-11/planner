import 'package:flutter/material.dart';
import 'package:planner/shared/widgets/shimmer_loading.dart';

class JournalsShimmer extends StatelessWidget {
  final bool isDesktop;

  const JournalsShimmer({super.key, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return isDesktop ? const _DesktopShimmer() : const _MobileShimmer();
  }
}

class _MobileShimmer extends StatelessWidget {
  const _MobileShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildShimmerCard(),
        );
      },
    );
  }
}

class _DesktopShimmer extends StatelessWidget {
  const _DesktopShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }
}

Widget _buildShimmerCard() {
  return ShimmerLoading(
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const SizedBox(height: 160),
    ),
  );
}
