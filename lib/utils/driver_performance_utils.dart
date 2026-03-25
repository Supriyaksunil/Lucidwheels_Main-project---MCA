import '../models/monitoring_session_model.dart';

const Duration _maxUnsyncedActiveSessionWindow = Duration(minutes: 15);

int resolveSessionDurationMinutes(MonitoringSession session, {DateTime? now}) {
  final window = resolveSessionWindow(session, now: now);
  final computedMinutes = window.end.difference(window.start).inMinutes;
  return computedMinutes < 0 ? 0 : computedMinutes;
}

DateTime resolveSessionActivityTime(MonitoringSession session, {DateTime? now}) {
  return resolveSessionWindow(session, now: now).end;
}

int calculateTotalDrivingMinutes(
  List<MonitoringSession> sessions, {
  DateTime? now,
}) {
  final dailyTotals = groupDrivingMinutesByDay(sessions, now: now);
  return dailyTotals.values.fold<int>(0, (sum, minutes) => sum + minutes);
}

Map<DateTime, int> groupIncidentsByDay(List<IncidentReport> incidents) {
  final totals = <DateTime, int>{};
  for (final incident in incidents) {
    final day = startOfLocalDay(incident.incidentTime);
    totals.update(day, (value) => value + 1, ifAbsent: () => 1);
  }
  return sortDailyTotals(totals);
}

Map<DateTime, int> groupDrivingMinutesByDay(
  List<MonitoringSession> sessions, {
  DateTime? now,
}) {
  final rangesByDay = <DateTime, List<_MinuteRange>>{};

  for (final session in sessions) {
    final window = resolveSessionWindow(session, now: now);
    final start = window.start.toLocal();
    final end = window.end.toLocal();
    if (!end.isAfter(start)) {
      continue;
    }

    var segmentStart = start;
    while (segmentStart.isBefore(end)) {
      final day = startOfLocalDay(segmentStart);
      final nextDay = day.add(const Duration(days: 1));
      final segmentEnd = nextDay.isBefore(end) ? nextDay : end;
      final startMinute = segmentStart.difference(day).inMinutes;
      final endMinute = segmentEnd.difference(day).inMinutes;

      if (endMinute > startMinute) {
        rangesByDay.putIfAbsent(day, () => <_MinuteRange>[]).add(
              _MinuteRange(startMinute: startMinute, endMinute: endMinute),
            );
      }

      segmentStart = segmentEnd;
    }
  }

  final totals = <DateTime, int>{};
  for (final entry in rangesByDay.entries) {
    final mergedRanges = _mergeMinuteRanges(entry.value);
    final totalMinutes = mergedRanges.fold<int>(
      0,
      (sum, range) => sum + (range.endMinute - range.startMinute),
    );
    if (totalMinutes > 0) {
      totals[entry.key] = totalMinutes.clamp(0, 24 * 60);
    }
  }

  return sortDailyTotals(totals);
}

SessionTimeWindow resolveSessionWindow(
  MonitoringSession session, {
  DateTime? now,
}) {
  final start = session.startTime.toLocal();
  final currentTime = (now ?? DateTime.now()).toLocal();

  DateTime end = start;
  final endTime = session.endTime?.toLocal();
  if (endTime != null && endTime.isAfter(start)) {
    end = endTime;
  } else if (session.durationMinutes > 0) {
    end = start.add(Duration(minutes: session.durationMinutes));
  } else if (session.status == SessionStatus.active) {
    final liveEnd = currentTime.isAfter(start) ? currentTime : start;
    final cappedEnd = start.add(_maxUnsyncedActiveSessionWindow);
    end = liveEnd.isBefore(cappedEnd) ? liveEnd : cappedEnd;
  }

  if (end.isBefore(start)) {
    end = start;
  }

  return SessionTimeWindow(start: start, end: end);
}

double calculateIncidentRate({
  required int incidentCount,
  required int totalMinutes,
}) {
  if (incidentCount <= 0) {
    return 0;
  }

  final hoursDriven = totalMinutes / 60;
  if (hoursDriven <= 0) {
    return incidentCount.toDouble();
  }

  return incidentCount / hoursDriven;
}

int calculatePerformanceScore({
  required int incidentCount,
  required int totalMinutes,
}) {
  if (incidentCount <= 0) {
    return 100;
  }

  final incidentRate = calculateIncidentRate(
    incidentCount: incidentCount,
    totalMinutes: totalMinutes,
  );
  return (100 - (incidentRate * 100)).clamp(0, 100).round();
}

String formatHoursDriven(int totalMinutes) {
  return (totalMinutes / 60).toStringAsFixed(1);
}

String formatDurationLabel(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours <= 0) {
    return '${minutes}m';
  }
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}m';
}

DateTime startOfLocalDay(DateTime dateTime) {
  final local = dateTime.toLocal();
  return DateTime(local.year, local.month, local.day);
}

Map<DateTime, int> sortDailyTotals(Map<DateTime, int> totals) {
  final entries = totals.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return {for (final entry in entries) entry.key: entry.value};
}

String formatRelativeActivity(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  return '${diff.inDays}d ago';
}

List<_MinuteRange> _mergeMinuteRanges(List<_MinuteRange> ranges) {
  if (ranges.isEmpty) {
    return const [];
  }

  final sortedRanges = [...ranges]
    ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  final merged = <_MinuteRange>[sortedRanges.first];

  for (final range in sortedRanges.skip(1)) {
    final last = merged.last;
    if (range.startMinute <= last.endMinute) {
      merged[merged.length - 1] = _MinuteRange(
        startMinute: last.startMinute,
        endMinute: range.endMinute > last.endMinute
            ? range.endMinute
            : last.endMinute,
      );
      continue;
    }

    merged.add(range);
  }

  return merged;
}

class SessionTimeWindow {
  const SessionTimeWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _MinuteRange {
  const _MinuteRange({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;
}
