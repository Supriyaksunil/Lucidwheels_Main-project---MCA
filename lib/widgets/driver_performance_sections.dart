import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/monitoring_session_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/driver_performance_utils.dart';
import 'common/custom_card.dart';
import 'common/section_header.dart';
import 'common/status_indicator.dart';

class DriverPerformanceSections extends StatelessWidget {
  const DriverPerformanceSections({
    super.key,
    required this.user,
    this.showHistoryDetails = false,
  });

  static const Color _cardBackground = Colors.white;
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
  );

  final UserModel? user;
  final bool showHistoryDetails;

  @override
  Widget build(BuildContext context) {
    final userId = _resolveUserId(user);
    if (userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<MonitoringSession>>(
      stream: FirebaseService().getUserSessions(userId),
      builder: (context, sessionsSnapshot) {
        final sessions = sessionsSnapshot.data ?? [];

        return StreamBuilder<List<IncidentReport>>(
          stream: FirebaseService().getUserIncidents(
            userId,
            limit: showHistoryDetails ? 500 : 100,
          ),
          builder: (context, incidentsSnapshot) {
            final incidents = incidentsSnapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(sessions, incidents),
                const SizedBox(height: 18),
                _buildDailyIncidentsSection(incidents),
                const SizedBox(height: 18),
                _buildDailyDrivingSection(sessions),
                const SizedBox(height: 18),
                if (showHistoryDetails) ...[
                  _buildIncidentsHistory(incidents),
                  const SizedBox(height: 18),
                  _buildSessionHistory(sessions, incidents),
                ] else ...[
                  _buildRecentAlerts(userId),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatsGrid(
    List<MonitoringSession> sessions,
    List<IncidentReport> incidents,
  ) {
    final totalSessions = sessions.length;
    final totalMinutes = calculateTotalDrivingMinutes(sessions);
    final incidentCount = incidents.length;
    final performanceScore = calculatePerformanceScore(
      incidentCount: incidentCount,
      totalMinutes: totalMinutes,
    );
    final incidentsPerDay = groupIncidentsByDay(incidents);
    final peakDailyIncidents = incidentsPerDay.values.isEmpty
        ? 0
        : incidentsPerDay.values.reduce((a, b) => a > b ? a : b);
    final dailyDrivingMinutes = groupDrivingMinutesByDay(sessions);
    final todayDrivingMinutes =
        dailyDrivingMinutes[startOfLocalDay(DateTime.now())] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Live Stats',
          subtitle: 'Daily incident and driving summaries from monitoring data',
          leadingIcon: Icons.insights_rounded,
          titleColor: _primaryText,
          subtitleColor: _secondaryText,
          iconColor: _primaryText,
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: [
            _buildStatCard(
              title: 'Sessions',
              value: totalSessions.toString(),
              icon: Icons.timelapse_rounded,
              color: AppTheme.primaryBlue,
            ),
            _buildStatCard(
              title: 'Hours Driven',
              value: formatHoursDriven(totalMinutes),
              icon: Icons.schedule_rounded,
              color: const Color(0xFF3852C5),
            ),
            _buildStatCard(
              title: 'Incidents',
              value: incidentCount.toString(),
              icon: Icons.warning_amber_rounded,
              color: AppTheme.accentRed,
            ),
            _buildStatCard(
              title: 'Peak Daily Incidents',
              value: peakDailyIncidents.toString(),
              icon: Icons.calendar_view_day_rounded,
              color: const Color(0xFF6276D6),
            ),
            _buildStatCard(
              title: 'Today Driving',
              value: formatDurationLabel(todayDrivingMinutes),
              icon: Icons.today_rounded,
              color: const Color(0xFF4D5AA6),
            ),
            _buildStatCard(
              title: 'Performance Score',
              value: '$performanceScore%',
              icon: Icons.shield_rounded,
              color: const Color(0xFF2E8B57),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: Border.all(color: color.withValues(alpha: 0.24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const Spacer(),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.92, end: 1),
            curve: Curves.easeOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              alignment: Alignment.centerLeft,
              child: child,
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: _secondaryText)),
        ],
      ),
    );
  }

  Widget _buildDailyIncidentsSection(List<IncidentReport> incidents) {
    final dailyTotals = groupIncidentsByDay(incidents);
    final points = _buildIncidentPoints(dailyTotals);

    return _buildDailyBarChartCard(
      title: 'Incidents Per Day',
      subtitle: 'Daily incident totals grouped from incident timestamps',
      emptyMessage: 'No incidents recorded yet.',
      points: points,
      barColor: AppTheme.accentRed,
      valueFormatter: (point) => '${point.value.toInt()} incident(s)',
    );
  }

  Widget _buildDailyDrivingSection(List<MonitoringSession> sessions) {
    final dailyTotals = groupDrivingMinutesByDay(sessions);
    final points = _buildDrivingPoints(dailyTotals);

    return _buildDailyBarChartCard(
      title: 'Daily Driving Hours',
      subtitle: 'Session durations grouped and summed by calendar day',
      emptyMessage: 'No driving sessions recorded yet.',
      points: points,
      barColor: const Color(0xFF3852C5),
      valueFormatter: (point) => formatDurationLabel(point.rawMinutes),
    );
  }

  Widget _buildDailyBarChartCard({
    required String title,
    required String subtitle,
    required String emptyMessage,
    required List<_DailyMetricPoint> points,
    required Color barColor,
    required String Function(_DailyMetricPoint point) valueFormatter,
  }) {
    final visiblePoints =
        points.length > 7 ? points.sublist(points.length - 7) : points;
    final maxY = visiblePoints.isEmpty
        ? 1.0
        : visiblePoints
            .map((point) => point.value)
            .reduce((a, b) => a > b ? a : b);

    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            subtitle: subtitle,
            leadingIcon: Icons.bar_chart_rounded,
            titleColor: _primaryText,
            subtitleColor: _secondaryText,
            iconColor: barColor,
          ),
          const SizedBox(height: 14),
          if (visiblePoints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                emptyMessage,
                style: const TextStyle(color: _secondaryText),
              ),
            )
          else ...[
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxY <= 1 ? 1 : maxY + _axisInterval(maxY),
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _axisInterval(maxY),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: _axisInterval(maxY),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(value >= 10 ? 0 : 1),
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= visiblePoints.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            visiblePoints[index].label,
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = visiblePoints[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('dd MMM yyyy').format(point.day)}\n${valueFormatter(point)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < visiblePoints.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: visiblePoints[i].value,
                            width: 18,
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visiblePoints.reversed.map((point) {
                return StatusIndicator(
                  label:
                      '${DateFormat('dd MMM').format(point.day)}: ${valueFormatter(point)}',
                  icon: Icons.bolt_rounded,
                  color: barColor,
                  compact: true,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncidentsHistory(List<IncidentReport> incidents) {
    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'All Incidents',
            subtitle: 'Complete incident history for this driver',
            leadingIcon: Icons.warning_amber_rounded,
            titleColor: _primaryText,
            subtitleColor: _secondaryText,
            iconColor: AppTheme.accentRed,
          ),
          const SizedBox(height: 14),
          if (incidents.isEmpty)
            const Text(
              'No incidents reported. Performance score remains at 100%.',
              style: TextStyle(color: _secondaryText),
            )
          else
            ...incidents.map((incident) {
              final severityColor = _severityColor(incident.severity);
              final hasLocation =
                  incident.latitude != null && incident.longitude != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusIndicator(
                            label: _severityLabel(incident.severity),
                            icon: Icons.report_gmailerrorred_rounded,
                            color: severityColor,
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            _formatDateTime(incident.incidentTime),
                            style: const TextStyle(color: _secondaryText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        incident.description,
                        style: const TextStyle(
                          color: _primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasLocation) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${incident.latitude!.toStringAsFixed(5)}, ${incident.longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(color: _secondaryText),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSessionHistory(
    List<MonitoringSession> sessions,
    List<IncidentReport> incidents,
  ) {
    final incidentCountsBySession = <String, int>{};
    for (final incident in incidents) {
      incidentCountsBySession.update(
        incident.sessionId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return CustomCard(
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'All Sessions',
            subtitle: 'Monitoring sessions with incident totals',
            leadingIcon: Icons.timelapse_rounded,
            titleColor: _primaryText,
            subtitleColor: _secondaryText,
            iconColor: _primaryText,
          ),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            const Text(
              'No sessions available yet.',
              style: TextStyle(color: _secondaryText),
            )
          else
            ...sessions.map((session) {
              final durationMinutes = resolveSessionDurationMinutes(session);
              final incidentCount =
                  incidentCountsBySession[session.sessionId] ?? 0;
              final statusColor = _sessionStatusColor(session);
              final endedAt = session.status == SessionStatus.active
                  ? 'In progress'
                  : session.endTime != null
                      ? _formatDateTime(session.endTime!)
                      : 'Not recorded';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE4FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusIndicator(
                            label: _sessionStatusLabel(session.status),
                            icon: Icons.circle,
                            color: statusColor,
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            _formatDateTime(session.startTime),
                            style: const TextStyle(color: _secondaryText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusIndicator(
                            label:
                                '${formatDurationLabel(durationMinutes)} driven',
                            icon: Icons.schedule_rounded,
                            color: AppTheme.primaryBlue,
                            compact: true,
                          ),
                          StatusIndicator(
                            label: '${session.totalAlerts} alerts',
                            icon: Icons.notifications_active_rounded,
                            color: const Color(0xFF3852C5),
                            compact: true,
                          ),
                          StatusIndicator(
                            label: '$incidentCount incidents',
                            icon: Icons.warning_amber_rounded,
                            color: incidentCount == 0
                                ? const Color(0xFF2E8B57)
                                : AppTheme.accentRed,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ended: $endedAt',
                        style: const TextStyle(color: _secondaryText),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(String userId) {
    final stream = FirebaseService().getUserAlerts(userId, limit: 5);

    return StreamBuilder<List<AlertEvent>>(
      stream: stream,
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];

        return CustomCard(
          color: _cardBackground,
          gradient: _cardGradient,
          border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Recent Alerts',
                subtitle: 'Most recent monitoring events',
                leadingIcon: Icons.notifications_active_rounded,
                titleColor: _primaryText,
                subtitleColor: _secondaryText,
                iconColor: _primaryText,
              ),
              const SizedBox(height: 14),
              if (alerts.isEmpty)
                const Text(
                  'No recent alerts',
                  style: TextStyle(color: _secondaryText),
                )
              else
                ...alerts.map((alert) {
                  final color = _alertColor(alert.type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        StatusIndicator(
                          label: _alertTypeLabel(alert.type),
                          icon: Icons.bolt_rounded,
                          color: color,
                          compact: true,
                        ),
                        const Spacer(),
                        Text(
                          formatRelativeActivity(alert.alertTime),
                          style: const TextStyle(color: _secondaryText),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  List<_DailyMetricPoint> _buildIncidentPoints(Map<DateTime, int> dailyTotals) {
    return dailyTotals.entries
        .map(
          (entry) => _DailyMetricPoint(
            day: entry.key,
            label: DateFormat('dd MMM').format(entry.key),
            value: entry.value.toDouble(),
            rawMinutes: 0,
          ),
        )
        .toList();
  }

  List<_DailyMetricPoint> _buildDrivingPoints(Map<DateTime, int> dailyTotals) {
    return dailyTotals.entries
        .map(
          (entry) => _DailyMetricPoint(
            day: entry.key,
            label: DateFormat('dd MMM').format(entry.key),
            value: entry.value / 60,
            rawMinutes: entry.value,
          ),
        )
        .toList();
  }

  double _axisInterval(double maxValue) {
    if (maxValue <= 1) {
      return 0.25;
    }
    if (maxValue <= 5) {
      return 1;
    }
    if (maxValue <= 10) {
      return 2;
    }
    if (maxValue <= 25) {
      return 5;
    }
    return 10;
  }

  String _alertTypeLabel(AlertType type) {
    switch (type) {
      case AlertType.drowsiness:
        return 'Drowsiness';
      case AlertType.distraction:
        return 'Distraction';
      case AlertType.accident:
        return 'Emergency';
      case AlertType.fatigue:
        return 'Fatigue';
    }
  }

  Color _alertColor(AlertType type) {
    switch (type) {
      case AlertType.accident:
        return AppTheme.accentRed;
      case AlertType.drowsiness:
        return const Color(0xFF2D3DA6);
      case AlertType.distraction:
        return const Color(0xFF4A5AC2);
      case AlertType.fatigue:
        return const Color(0xFF6577D8);
    }
  }

  String _severityLabel(Severity severity) {
    switch (severity) {
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Medium';
      case Severity.high:
        return 'High';
      case Severity.critical:
        return 'Critical';
    }
  }

  Color _severityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return const Color(0xFF2E8B57);
      case Severity.medium:
        return const Color(0xFF8A5A00);
      case Severity.high:
        return const Color(0xFFC76A00);
      case Severity.critical:
        return AppTheme.accentRed;
    }
  }

  String _sessionStatusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.emergency:
        return 'Emergency';
    }
  }

  Color _sessionStatusColor(MonitoringSession session) {
    if (session.status == SessionStatus.emergency ||
        session.isAccidentDetected) {
      return AppTheme.accentRed;
    }
    if (session.status == SessionStatus.active) {
      return const Color(0xFF1F8B4C);
    }
    return const Color(0xFF4D5AA6);
  }

  String _resolveUserId(UserModel? user) {
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return FirebaseService().currentUser?.uid ?? '';
  }

  String _formatDateTime(DateTime time) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(time.toLocal());
  }
}

class _DailyMetricPoint {
  const _DailyMetricPoint({
    required this.day,
    required this.label,
    required this.value,
    required this.rawMinutes,
  });

  final DateTime day;
  final String label;
  final double value;
  final int rawMinutes;
}

