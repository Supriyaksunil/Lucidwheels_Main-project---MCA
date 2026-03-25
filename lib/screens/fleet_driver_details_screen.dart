import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/fleet_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../utils/driver_performance_utils.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_indicator.dart';
import '../widgets/common/user_profile_avatar.dart';
import '../widgets/driver_performance_sections.dart';

class FleetDriverDetailsScreen extends StatelessWidget {
  const FleetDriverDetailsScreen({
    super.key,
    this.initialDriver,
    this.driverId,
    this.driverUniqueId,
  });

  final UserModel? initialDriver;
  final String? driverId;
  final String? driverUniqueId;

  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );
  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
  );

  @override
  Widget build(BuildContext context) {
    final normalizedDriverId = (driverId ?? initialDriver?.uid ?? '').trim();
    final normalizedDriverUniqueId =
        (driverUniqueId ?? initialDriver?.driverUniqueId ?? '').trim();

    if (normalizedDriverId.isEmpty && normalizedDriverUniqueId.isEmpty) {
      return _buildStateScaffold(
        const Center(
          child: Text(
            'Driver record is missing. Open the driver again from the fleet list.',
            style: TextStyle(
              color: _secondaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (normalizedDriverId.isNotEmpty) {
      return StreamBuilder<UserModel?>(
        stream: FirebaseService().streamUserDocument(normalizedDriverId),
        initialData: initialDriver,
        builder: (context, snapshot) {
          final driver = snapshot.data;
          if (driver == null && normalizedDriverUniqueId.isNotEmpty) {
            return _buildFallbackStream(normalizedDriverUniqueId);
          }
          return _buildResolvedDriverView(
            context,
            snapshot: snapshot,
            driver: driver,
            resolvedDriverUniqueId: normalizedDriverUniqueId,
          );
        },
      );
    }

    return _buildFallbackStream(normalizedDriverUniqueId);
  }

  Widget _buildFallbackStream(String normalizedDriverUniqueId) {
    return StreamBuilder<UserModel?>(
      stream: FirebaseService()
          .streamUserByDriverUniqueId(normalizedDriverUniqueId),
      initialData: initialDriver,
      builder: (context, snapshot) {
        return _buildResolvedDriverView(
          context,
          snapshot: snapshot,
          driver: snapshot.data,
          resolvedDriverUniqueId: normalizedDriverUniqueId,
        );
      },
    );
  }

  Widget _buildResolvedDriverView(
    BuildContext context, {
    required AsyncSnapshot<UserModel?> snapshot,
    required UserModel? driver,
    required String resolvedDriverUniqueId,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting && driver == null) {
      return _buildStateScaffold(
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return _buildStateScaffold(
        Center(
          child: Text(
            'Could not load this driver dashboard. ${snapshot.error}',
            style: const TextStyle(
              color: AppTheme.accentRed,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (driver == null) {
      return _buildStateScaffold(
        const Center(
          child: Text(
            'No driver details were found in Firestore for this fleet member.',
            style: TextStyle(
              color: _secondaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final fleetProvider = context.watch<FleetProvider>();
    final liveStats = fleetProvider.liveStatsForDriver(driver.uid.trim());
    final displayName =
        driver.fullName.trim().isEmpty ? driver.email : driver.fullName;
    final visibleDriverId = resolvedDriverUniqueId.isNotEmpty
        ? resolvedDriverUniqueId
        : (driver.driverUniqueId ?? '').trim();

    return AppScaffold(
      title: 'Driver Report',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              color: Colors.white,
              gradient: _cardGradient,
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFFD7E1FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Driver Overview',
                    subtitle:
                        'Live profile, monitoring state, and daily history',
                    leadingIcon: Icons.person_search_rounded,
                    titleColor: _primaryText,
                    subtitleColor: _secondaryText,
                    iconColor: _primaryText,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      UserProfileAvatar(
                        user: driver,
                        size: 76,
                        borderRadius: 24,
                        fontSize: 26,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: _primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              driver.email,
                              style: const TextStyle(color: _secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusIndicator(
                        label: _activityLabel(liveStats),
                        icon: _activityIcon(liveStats),
                        color: _activityColor(liveStats),
                        compact: true,
                      ),
                      StatusIndicator(
                        label: '${liveStats.performanceScore}% score',
                        icon: Icons.shield_rounded,
                        color: const Color(0xFF2E8B57),
                        compact: true,
                      ),
                      StatusIndicator(
                        label: '${liveStats.incidentCount} incidents',
                        icon: Icons.warning_amber_rounded,
                        color: liveStats.incidentCount == 0
                            ? const Color(0xFF2E8B57)
                            : AppTheme.accentRed,
                        compact: true,
                      ),
                      StatusIndicator(
                        label: '${liveStats.hoursDrivenLabel} hrs',
                        icon: Icons.schedule_rounded,
                        color: _primaryText,
                        compact: true,
                      ),
                      if (visibleDriverId.isNotEmpty)
                        StatusIndicator(
                          label: 'ID: $visibleDriverId',
                          icon: Icons.badge_rounded,
                          color: _primaryText,
                          compact: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DriverPerformanceSections(
              user: driver,
              showHistoryDetails: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateScaffold(Widget child) {
    return AppScaffold(
      title: 'Driver Report',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: Padding(
        padding: AppTheme.pagePadding,
        child: CustomCard(
          color: Colors.white,
          gradient: _cardGradient,
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFD7E1FF)),
          ),
          child: SizedBox(height: 220, child: child),
        ),
      ),
    );
  }

  String _activityLabel(FleetDriverLiveStats liveStats) {
    if (liveStats.isEmergency) {
      return 'Emergency flagged';
    }
    if (liveStats.isActive) {
      return 'Active';
    }
    if (liveStats.lastSeenAt == null) {
      return 'No activity yet';
    }
    return 'Active ${formatRelativeActivity(liveStats.lastSeenAt!)}';
  }

  IconData _activityIcon(FleetDriverLiveStats liveStats) {
    if (liveStats.isEmergency) {
      return Icons.warning_amber_rounded;
    }
    if (liveStats.isActive) {
      return Icons.radar_rounded;
    }
    if (liveStats.lastSeenAt == null) {
      return Icons.hourglass_empty_rounded;
    }
    return Icons.history_rounded;
  }

  Color _activityColor(FleetDriverLiveStats liveStats) {
    if (liveStats.isEmergency) {
      return AppTheme.accentRed;
    }
    if (liveStats.isActive) {
      return const Color(0xFF1F8B4C);
    }
    if (liveStats.lastSeenAt == null) {
      return const Color(0xFF8A5A00);
    }
    return const Color(0xFF4D5AA6);
  }
}
