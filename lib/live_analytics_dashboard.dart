import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'live_analytics_service.dart';

class LiveAnalyticsDashboardPage extends StatelessWidget {
  const LiveAnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Attendance Analytics')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: LiveAnalyticsPanel(compact: false),
      ),
    );
  }
}

class LiveAnalyticsPanel extends StatefulWidget {
  const LiveAnalyticsPanel({super.key, this.compact = true});

  final bool compact;

  @override
  State<LiveAnalyticsPanel> createState() => _LiveAnalyticsPanelState();
}

class _LiveAnalyticsPanelState extends State<LiveAnalyticsPanel> {
  final LiveAnalyticsService _service = LiveAnalyticsService();

  bool _usePollingFallback = false;
  String? _lastRealtimeError;

  Stream<AttendanceAnalyticsSnapshot> get _activeStream {
    if (_usePollingFallback) {
      return _service.pollAnalytics();
    }
    return _service.streamAnalytics();
  }

  void _switchToPolling(String errorText) {
    if (!mounted || _usePollingFallback) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastRealtimeError = errorText;
        _usePollingFallback = true;
      });
    });
  }

  void _retryRealtime() {
    setState(() {
      _usePollingFallback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AttendanceAnalyticsSnapshot>(
      stream: _activeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final errorText = snapshot.error.toString();
          if (!_usePollingFallback) {
            _switchToPolling(errorText);
            return _statusCard(
              title: 'Realtime unavailable, switching to refresh mode',
              message: errorText,
              color: Colors.orange,
            );
          }

          return _statusCard(
            title: 'Could not load live analytics',
            message: errorText,
            color: Colors.red,
            action: OutlinedButton.icon(
              onPressed: _retryRealtime,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry realtime mode'),
            ),
          );
        }

        final analytics = snapshot.data;
        if (analytics == null) {
          return _statusCard(
            title: 'No analytics yet',
            message: 'Start scanning attendance to populate this dashboard.',
            color: Colors.grey,
          );
        }

        final topNetworks = _limit(analytics.networkCounts, 5);
        final topEvents =
            _limit(analytics.eventCounts, widget.compact ? 6 : 10);
        final newcomerNetworks = _limit(analytics.newcomerByNetwork, 5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(
                    'Total Attendance', analytics.totalAttendance, Colors.teal),
                _metricCard('Scans Today', analytics.scansToday, Colors.indigo),
                _metricCard('Newcomers Today', analytics.newcomerScansToday,
                    Colors.amber.shade800),
                _metricCard('Newcomer Total', analytics.newcomerAttendanceTotal,
                    Colors.orange),
                _metricCard('Networks', analytics.networkCounts.length,
                    Colors.blueGrey),
                _metricCard(
                    'Events', analytics.eventCounts.length, Colors.deepOrange),
              ],
            ),
            if (analytics.newcomerScansToday > 0) ...[
              const SizedBox(height: 16),
              _statusCard(
                title: 'Newcomers to welcome now',
                message:
                    '${analytics.newcomerScansToday} newcomer scan(s) today. Ushers can follow up after service.',
                color: Colors.amber.shade800,
              ),
            ],
            const SizedBox(height: 20),
            _chartSection(
              title: 'Attendance by Network',
              counts: topNetworks,
              color: Colors.teal,
              emptyText: 'No network attendance yet',
              height: widget.compact ? 220 : 260,
            ),
            const SizedBox(height: 20),
            _chartSection(
              title: 'Newcomers by Network',
              counts: newcomerNetworks,
              color: Colors.amber.shade800,
              emptyText: 'No newcomer attendance yet',
              height: widget.compact ? 200 : 240,
            ),
            const SizedBox(height: 20),
            _chartSection(
              title: 'Attendance by Event',
              counts: topEvents,
              color: Colors.deepOrange,
              emptyText: 'No event attendance yet',
              height: widget.compact ? 240 : 280,
            ),
            if (_usePollingFallback) ...[
              const SizedBox(height: 16),
              _statusCard(
                title: 'Running in refresh mode',
                message: _lastRealtimeError == null
                    ? 'Realtime is unavailable, so the dashboard refreshes every few seconds.'
                    : 'Realtime error: $_lastRealtimeError',
                color: Colors.blueGrey,
                action: OutlinedButton.icon(
                  onPressed: _retryRealtime,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Try realtime again'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _metricCard(String label, int value, Color color) {
    return Container(
      width: widget.compact ? 150 : 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartSection({
    required String title,
    required Map<String, int> counts,
    required Color color,
    required String emptyText,
    required double height,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: counts.isEmpty
                ? Center(child: Text(emptyText))
                : _CountsBarChart(counts: counts, color: color),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String message,
    required Color color,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(message),
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }

  Map<String, int> _limit(Map<String, int> counts, int take) {
    final entries = counts.entries.toList();
    if (entries.length <= take) {
      return counts;
    }
    return {for (final entry in entries.take(take)) entry.key: entry.value};
  }
}

class _CountsBarChart extends StatelessWidget {
  const _CountsBarChart({required this.counts, required this.color});

  final Map<String, int> counts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList();
    final values = entries.map((entry) => entry.value.toDouble()).toList();

    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return BarChart(
      BarChartData(
        maxY: maxValue * 1.2,
        barGroups: List.generate(entries.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value.toDouble(),
                color: color,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 34),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }

                final raw = entries[index].key;
                final text = raw.length > 10 ? '${raw.substring(0, 10)}…' : raw;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
