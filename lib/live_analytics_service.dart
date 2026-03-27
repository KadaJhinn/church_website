import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceAnalyticsSnapshot {
  final int totalAttendance;
  final int scansToday;
  final int newcomerAttendanceTotal;
  final int newcomerScansToday;
  final Map<String, int> networkCounts;
  final Map<String, int> eventCounts;
  final Map<String, int> newcomerByNetwork;

  const AttendanceAnalyticsSnapshot({
    required this.totalAttendance,
    required this.scansToday,
    required this.newcomerAttendanceTotal,
    required this.newcomerScansToday,
    required this.networkCounts,
    required this.eventCounts,
    required this.newcomerByNetwork,
  });
}

class LiveAnalyticsService {
  LiveAnalyticsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<AttendanceAnalyticsSnapshot> streamAnalytics() {
    return _client
        .from('attendance')
        .stream(primaryKey: ['id']).map(_buildSnapshot);
  }

  Stream<AttendanceAnalyticsSnapshot> pollAnalytics({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      yield await fetchAnalytics();
      await Future<void>.delayed(interval);
    }
  }

  Future<AttendanceAnalyticsSnapshot> fetchAnalytics() async {
    final rows = await _client.from('attendance').select('*');

    return _buildSnapshot(List<Map<String, dynamic>>.from(rows));
  }

  AttendanceAnalyticsSnapshot _buildSnapshot(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final networkCounts = <String, int>{};
    final eventCounts = <String, int>{};
    final newcomerByNetwork = <String, int>{};

    var scansToday = 0;
    var newcomerAttendanceTotal = 0;
    var newcomerScansToday = 0;

    for (final row in rows) {
      final network = _readString(row, const ['network', 'event_network']);
      final eventTitle =
          _readString(row, const ['event_title', 'event', 'title']);
      final createdAtRaw = _readString(
        row,
        const ['created_at', 'timestamp', 'time', 'date'],
      );
      final isNewcomer = _readBool(row, const ['is_newcomer', 'newcomer']);

      final networkKey =
          (network == null || network.isEmpty) ? 'Unknown' : network;
      final eventKey = (eventTitle == null || eventTitle.isEmpty)
          ? 'Unknown Event'
          : eventTitle;

      networkCounts[networkKey] = (networkCounts[networkKey] ?? 0) + 1;
      eventCounts[eventKey] = (eventCounts[eventKey] ?? 0) + 1;

      if (isNewcomer) {
        newcomerAttendanceTotal += 1;
        newcomerByNetwork[networkKey] =
            (newcomerByNetwork[networkKey] ?? 0) + 1;
      }

      if (createdAtRaw != null) {
        final createdAt = DateTime.tryParse(createdAtRaw)?.toLocal();
        if (createdAt != null &&
            createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day) {
          scansToday += 1;
          if (isNewcomer) {
            newcomerScansToday += 1;
          }
        }
      }
    }

    return AttendanceAnalyticsSnapshot(
      totalAttendance: rows.length,
      scansToday: scansToday,
      newcomerAttendanceTotal: newcomerAttendanceTotal,
      newcomerScansToday: newcomerScansToday,
      networkCounts: _sortByCountDesc(networkCounts),
      eventCounts: _sortByCountDesc(eventCounts),
      newcomerByNetwork: _sortByCountDesc(newcomerByNetwork),
    );
  }

  Map<String, int> _sortByCountDesc(Map<String, int> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in entries) entry.key: entry.value};
  }

  String? _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) {
        continue;
      }

      final asText = value.toString().trim();
      if (asText.isNotEmpty) {
        return asText;
      }
    }

    return null;
  }

  bool _readBool(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }

      final asText = value.toString().trim().toLowerCase();
      if (asText == 'true' || asText == '1' || asText == 'yes') {
        return true;
      }
      if (asText == 'false' || asText == '0' || asText == 'no') {
        return false;
      }
    }

    return false;
  }
}
