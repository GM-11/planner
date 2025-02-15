import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/features/auth/providers/auth_provider.dart';
import 'package:planner/features/profile/widgets/chart_type_toggle.dart';
import 'package:planner/features/profile/widgets/time_filter.dart';
import '../providers/profile_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/constant.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/profile_data_navigator.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
    final user = ref.watch(authStateProvider).value;
    final timeFilter = ref.watch(timeFilterProvider);
    final chartType = ref.watch(chartTypeProvider);
    final metrics = ref.watch(performanceMetricsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ProfileDateNavigator(),
                  const SizedBox(height: 16),
                  // Time Filter
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TimeFilterWidget(
                        onChanged: (filter) {
                          ref.read(timeFilterProvider.notifier).state = filter;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart Type Toggle
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ChartTypeToggle(
                        onChanged: (type) {
                          if (timeFilter == TimeFilter.daily &&
                              type == ChartType.line) {
                            ref.read(timeFilterProvider.notifier).state =
                                TimeFilter.week;
                          }
                          ref.read(chartTypeProvider.notifier).state = type;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Performance Overview
                  _buildPerformanceCard(context, chartType, metrics),
                  const SizedBox(height: 16),

                  // Task Distribution
                  _buildDistributionCard(context, metrics),
                  const SizedBox(height: 16),

                  // Summary Stats
                  _buildSummaryCard(context, metrics),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(authControllerProvider).signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final timeFilter = ref.watch(timeFilterProvider);
    final chartType = ref.watch(chartTypeProvider);
    final metrics = ref.watch(performanceMetricsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 400,
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: ProfileDateNavigator(isDesktop: true),
                ),
                const SizedBox(height: 32),

                // Time Range Section
                const Text(
                  'Time Range',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TimeFilterWidget(
                  onChanged: (filter) {
                    ref.read(timeFilterProvider.notifier).state = filter;
                  },
                  isDesktop: true,
                ),
                const SizedBox(height: 32),

                // Chart Type Section
                const Text(
                  'Chart Type',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ChartTypeToggle(
                  onChanged: (type) {
                    if (timeFilter == TimeFilter.daily &&
                        type == ChartType.line) {
                      ref.read(timeFilterProvider.notifier).state =
                          TimeFilter.week;
                    }
                    ref.read(chartTypeProvider.notifier).state = type;
                  },
                  isDesktop: true,
                ),
                const Spacer(),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authControllerProvider).signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Charts Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPerformanceCard(
                          context,
                          chartType,
                          metrics,
                          isDesktop: true,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildDistributionCard(
                          context,
                          metrics,
                          isDesktop: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryCard(context, metrics, isDesktop: true),
                  const SizedBox(height: 24),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildPerformanceCard(
  BuildContext context,
  ChartType chartType,
  PerformanceMetrics metrics, {
  bool isDesktop = false,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text(
                'Performance Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: isDesktop ? 300 : 220,
            child:
                chartType == ChartType.circular
                    ? _buildCircularProgress(
                      context,
                      metrics.averageCompletionRate,
                    )
                    : _buildLineChart(context, metrics),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCircularProgress(BuildContext context, double percentage) {
  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 200,
        height: 200,
        child: CircularProgressIndicator(
          value: percentage / 100,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
          strokeWidth: 15,
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Text(
            'Completion Rate',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    ],
  );
}

Widget _buildLineChart(BuildContext context, PerformanceMetrics metrics) {
  return LineChart(
    LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 &&
                  value.toInt() < metrics.dailyCompletion.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      metrics.dailyCompletion[value.toInt()].date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots:
              metrics.dailyCompletion.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.total > 0
                      ? (entry.value.completed / entry.value.total) * 100
                      : 0,
                );
              }).toList(),
          isCurved: true,
          color: Theme.of(context).primaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        ),
      ],
      minY: 0,
      maxY: 100,
    ),
  );
}

Widget _buildDistributionCard(
  BuildContext context,
  PerformanceMetrics metrics, {
  bool isDesktop = false,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Distribution',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: isDesktop ? 300 : 250,
            child:
                metrics.totalTasks > 0
                    ? PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections:
                            metrics.importanceDistribution.entries.map((entry) {
                              final percentage =
                                  (entry.value / metrics.totalTasks) * 100;
                              return PieChartSectionData(
                                color: AppConstants.importanceColors[entry.key],
                                value: entry.value.toDouble(),
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 100,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                      ),
                    )
                    : const Center(
                      child: Text(
                        'No tasks available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children:
                AppConstants.importanceLevels
                    .asMap()
                    .entries
                    .map(
                      (entry) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppConstants.importanceColors[entry.key],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.value.replaceAll('-', ' '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSummaryCard(
  BuildContext context,
  PerformanceMetrics metrics, {
  bool isDesktop = false,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Total Tasks',
                  metrics.totalTasks.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Completed',
                  metrics.completedTasks.toString(),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Completion Rate',
                    '${metrics.averageCompletionRate.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 16),
            _buildSummaryItem(
              context,
              'Completion Rate',
              '${metrics.averageCompletionRate.toStringAsFixed(1)}%',
              fullWidth: true,
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildSummaryItem(
  BuildContext context,
  String label,
  String value, {
  bool fullWidth = false,
}) {
  return Container(
    width: fullWidth ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildFooter(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Built with ❤️ • ',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        InkWell(
          onTap: () async {
            const url = 'https://github.com/GM-11/planner';
            try {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                await Clipboard.setData(ClipboardData(text: url));
              }
            } catch (e) {
              await Clipboard.setData(ClipboardData(text: url));
            }
          },
          child: const Text(
            'Source Code',
            style: TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.underline,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}
