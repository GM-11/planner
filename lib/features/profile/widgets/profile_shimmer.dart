import 'package:flutter/material.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class ProfileShimmer extends StatelessWidget {
  final bool isDesktop;

  const ProfileShimmer({super.key, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return isDesktop ? const _DesktopShimmer() : const _MobileShimmer();
  }
}

class _MobileShimmer extends StatelessWidget {
  const _MobileShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(120),
          const SizedBox(height: 16),
          _buildCard(250),
          const SizedBox(height: 16),
          _buildCard(200),
          const SizedBox(height: 16),
          _buildCard(100),
        ],
      ),
    );
  }
}

class _DesktopShimmer extends StatelessWidget {
  const _DesktopShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCard(300)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCard(300)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCard(200),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildCard(double height) {
  return ShimmerLoading(
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
