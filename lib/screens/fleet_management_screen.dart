import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/fleet_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/fleet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/driver_performance_utils.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/user_profile_avatar.dart';
import 'fleet_driver_details_screen.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _companyNameController = TextEditingController();
  late final TabController _driverTabController;

  @override
  void initState() {
    super.initState();
    _driverTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _driverTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final fleetProvider = context.watch<FleetProvider>();
    final manager = authProvider.currentUser;

    return AppScaffold(
      title: 'Fleet Management',
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: AppTheme.primaryBlue,
      appBarTitleTextStyle: const TextStyle(
        color: AppTheme.primaryBlue,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      actions: [
        if (fleetProvider.currentFleet != null)
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: fleetProvider.isLoading
                ? null
                : () => _showAddDriverDialog(context, fleetProvider),
          ),
      ],
      body: fleetProvider.isLoading && fleetProvider.currentFleet == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fleetProvider.error != null) ...[
                  _buildErrorBanner(fleetProvider.error!),
                  const SizedBox(height: 12),
                ],
                if (manager == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (manager.role != UserRole.fleetManager)
                  Expanded(child: _buildRoleMismatchCard())
                else if (fleetProvider.currentFleet == null)
                  Expanded(
                    child: _buildCreateFleetCard(
                      context,
                      authProvider,
                      fleetProvider,
                    ),
                  )
                else ...[
                  _buildFleetOverview(fleetProvider),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: SectionHeader(
                          title: 'Drivers',
                          subtitle:
                              'Joined cards now include live monitoring stats. Tap for full history.',
                          leadingIcon: Icons.groups_2_rounded,
                          titleColor: AppTheme.primaryBlue,
                          subtitleColor: Color(0xFF4D5AA6),
                          iconColor: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(
                        width: 148,
                        child: CustomButton(
                          label: 'Add Driver',
                          icon: Icons.add_rounded,
                          onPressed: () =>
                              _showAddDriverDialog(context, fleetProvider),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDriverTabBar(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      controller: _driverTabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildJoinedDriversList(fleetProvider),
                        _buildPendingDriversList(fleetProvider),
                      ],
                    ),
                  ),
                ],
              ],
            ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildCreateFleetCard(
    BuildContext context,
    AuthProvider authProvider,
    FleetProvider fleetProvider,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: CustomCard(
          color: Colors.white,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
          ),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFD7E1FF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Create Your Fleet',
                subtitle: 'Set up the company fleet before inviting drivers',
                leadingIcon: Icons.business_rounded,
                titleColor: AppTheme.primaryBlue,
                subtitleColor: Color(0xFF4D5AA6),
                iconColor: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _companyNameController,
                style: const TextStyle(color: AppTheme.primaryBlue),
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Create Fleet',
                  icon: Icons.domain_add_rounded,
                  isLoading: fleetProvider.isLoading,
                  onPressed: () async {
                    try {
                      await fleetProvider.createFleet(
                        companyName: _companyNameController.text,
                      );
                      await authProvider.refreshCurrentUser();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fleet created successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_cleanError(e))),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetOverview(FleetProvider fleetProvider) {
    final fleet = fleetProvider.currentFleet!;

    return CustomCard(
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
      ),
      border: const Border.fromBorderSide(
        BorderSide(color: Color(0xFFD7E1FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fleet.companyName,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Created ${fleet.createdAt.toLocal().toString().split(' ').first}',
            style: const TextStyle(color: Color(0xFF4D5AA6)),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _driverTabController,
            builder: (context, child) {
              final selectedIndex = _driverTabController.index;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    SizedBox(
                      width: 152,
                      child: _OverviewItemCard(
                        label: 'Joined',
                        value: fleetProvider.joinedDriverCount.toString(),
                        icon: Icons.verified_user_rounded,
                        isSelected: selectedIndex == 0,
                        onTap: () => _switchToDriverTab(0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 152,
                      child: _OverviewItemCard(
                        label: 'Pending',
                        value: fleetProvider.pendingDriverCount.toString(),
                        icon: Icons.schedule_send_rounded,
                        isSelected: selectedIndex == 1,
                        onTap: () => _switchToDriverTab(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 152,
                      child: _OverviewItemCard(
                        label: 'Monitored 24h',
                        value: fleetProvider.activeDriverCount.toString(),
                        icon: Icons.bolt_rounded,
                        isSelected: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 152,
                      child: _OverviewItemCard(
                        label: 'Total Alerts',
                        value: fleetProvider.totalAlerts.toString(),
                        icon: Icons.notification_important_rounded,
                        isSelected: false,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E1FF)),
      ),
      child: TabBar(
        controller: _driverTabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF4D5AA6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Joined'),
          Tab(text: 'Pending'),
        ],
      ),
    );
  }

  Widget _buildJoinedDriversList(FleetProvider fleetProvider) {
    final joinedDrivers = fleetProvider.joinedDriverMembers;
    if (joinedDrivers.isEmpty) {
      return const _EmptyDriverState(
        message: 'No drivers have joined this fleet yet.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: joinedDrivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = joinedDrivers[index];
        final resolvedDriverId = member.user.uid.isNotEmpty
            ? member.user.uid
            : member.fleetDriver.driverId;

        return _JoinedDriverCard(
          member: member,
          liveStats: fleetProvider.liveStatsForDriver(resolvedDriverId),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FleetDriverDetailsScreen(
                  initialDriver: member.user,
                  driverId: resolvedDriverId,
                  driverUniqueId: member.fleetDriver.driverUniqueId,
                ),
              ),
            );
          },
          onCopy: () => _copyDriverId(member.fleetDriver.driverUniqueId),
        );
      },
    );
  }

  Widget _buildPendingDriversList(FleetProvider fleetProvider) {
    final pendingDrivers = fleetProvider.pendingDrivers;
    if (pendingDrivers.isEmpty) {
      return const _EmptyDriverState(
        message: 'No pending drivers right now.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: pendingDrivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final driver = pendingDrivers[index];
        return _PendingDriverCard(
          driver: driver,
          onCopy: () => _copyDriverId(driver.driverUniqueId),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildRoleMismatchCard() {
    return const Center(
      child: Text(
        'Fleet management is available only for fleet managers.',
        style: TextStyle(
          color: Color(0xFF4D5AA6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showAddDriverDialog(
    BuildContext screenContext,
    FleetProvider fleetProvider,
  ) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messenger = ScaffoldMessenger.of(screenContext);
    var isSubmitting = false;
    String? errorText;

    await showDialog<void>(
      context: screenContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              scrollable: true,
              title: const Text(
                'Add Driver',
                style: TextStyle(color: AppTheme.primaryBlue),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add the driver name and email. LucidWheels will generate the 10-digit driver ID automatically and show the fleet invite in that commercial account.',
                      style: TextStyle(color: Color(0xFF4D5AA6)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppTheme.primaryBlue),
                      decoration: const InputDecoration(
                        labelText: 'Driver Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.primaryBlue),
                      decoration: const InputDecoration(
                        labelText: 'Driver Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Add Driver',
                        icon: Icons.person_add_rounded,
                        isLoading: isSubmitting,
                        onPressed: () async {
                          setDialogState(() {
                            errorText = null;
                            isSubmitting = true;
                          });

                          try {
                            final code = await fleetProvider.addPendingDriver(
                              driverName: nameController.text,
                              driverEmail: emailController.text,
                            );
                            if (!mounted) {
                              return;
                            }
                            _switchToDriverTab(1);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Driver added successfully. Pending ID: $code',
                                ),
                                action: SnackBarAction(
                                  label: 'Copy',
                                  onPressed: () => _copyDriverId(code),
                                ),
                              ),
                            );
                          } catch (e) {
                            if (dialogBuilderContext.mounted) {
                              setDialogState(() {
                                errorText = _cleanError(e);
                              });
                            }
                          } finally {
                            if (dialogBuilderContext.mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _copyDriverId(String driverId) async {
    await Clipboard.setData(ClipboardData(text: driverId));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied driver ID $driverId')),
    );
  }

  void _switchToDriverTab(int index) {
    if (_driverTabController.index == index) {
      return;
    }
    _driverTabController.animateTo(index);
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}

class _OverviewItemCard extends StatelessWidget {
  const _OverviewItemCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                : const Color(0xFFF3F6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isSelected ? AppTheme.primaryBlue : const Color(0xFFD7E1FF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryBlue),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF4D5AA6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDriverState extends StatelessWidget {
  const _EmptyDriverState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
      ),
      border: const Border.fromBorderSide(
        BorderSide(color: Color(0xFFD7E1FF)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF4D5AA6),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _JoinedDriverCard extends StatelessWidget {
  const _JoinedDriverCard({
    required this.member,
    required this.liveStats,
    this.onTap,
    required this.onCopy,
  });

  final FleetDriverMember member;
  final FleetDriverLiveStats liveStats;
  final VoidCallback? onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final displayName = member.user.fullName.trim().isEmpty
        ? member.user.email
        : member.user.fullName;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: CustomCard(
        color: Colors.white,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
        ),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFD7E1FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserProfileAvatar(
                  user: member.user,
                  size: 48,
                  borderRadius: 16,
                  fontSize: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.user.email,
                        style: const TextStyle(color: Color(0xFF4D5AA6)),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF4D5AA6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${member.fleetDriver.driverUniqueId}',
                    style: const TextStyle(color: Color(0xFF4D5AA6)),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy ID',
                  onPressed: onCopy,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF4D5AA6),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _DriverStatChip(
                    label: _statusLabel(),
                    icon: _statusIcon(),
                    color: _statusColor(),
                  ),
                  const SizedBox(width: 8),
                  _DriverStatChip(
                    label: '${liveStats.sessionCount} sessions',
                    icon: Icons.timelapse_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  _DriverStatChip(
                    label: '${liveStats.totalAlerts} alerts',
                    icon: Icons.notification_important_rounded,
                    color: const Color(0xFF3852C5),
                  ),
                  const SizedBox(width: 8),
                  _DriverStatChip(
                    label: '${liveStats.incidentCount} incidents',
                    icon: Icons.warning_amber_rounded,
                    color: liveStats.incidentCount == 0
                        ? const Color(0xFF2E8B57)
                        : AppTheme.accentRed,
                  ),
                  const SizedBox(width: 8),
                  _DriverStatChip(
                    label: '${liveStats.hoursDrivenLabel} hrs',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF6577D8),
                  ),
                  const SizedBox(width: 8),
                  _DriverStatChip(
                    label: '${liveStats.performanceScore}% score',
                    icon: Icons.shield_rounded,
                    color: const Color(0xFF2E8B57),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    if (liveStats.isEmergency) {
      return 'Emergency flagged';
    }
    if (liveStats.isActive) {
      return 'Active';
    }
    if (!liveStats.hasSessions || liveStats.lastSeenAt == null) {
      return 'No activity yet';
    }
    return 'Active ${formatRelativeActivity(liveStats.lastSeenAt!)}';
  }

  IconData _statusIcon() {
    if (liveStats.isEmergency) {
      return Icons.warning_amber_rounded;
    }
    if (liveStats.isActive) {
      return Icons.radar_rounded;
    }
    if (!liveStats.hasSessions) {
      return Icons.hourglass_empty_rounded;
    }
    return Icons.history_rounded;
  }

  Color _statusColor() {
    if (liveStats.isEmergency) {
      return AppTheme.accentRed;
    }
    if (liveStats.isActive) {
      return const Color(0xFF1F8B4C);
    }
    if (!liveStats.hasSessions) {
      return const Color(0xFF8A5A00);
    }
    return const Color(0xFF4D5AA6);
  }
}

class _DriverStatChip extends StatelessWidget {
  const _DriverStatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDriverCard extends StatelessWidget {
  const _PendingDriverCard({
    required this.driver,
    required this.onCopy,
  });

  final FleetDriver driver;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final displayName =
        driver.name.trim().isEmpty ? 'Pending Driver' : driver.name;

    return CustomCard(
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
      ),
      border: const Border.fromBorderSide(
        BorderSide(color: Color(0xFFD7E1FF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFDDE6FF),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ID: ${driver.driverUniqueId}',
                        style: const TextStyle(color: Color(0xFF4D5AA6)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy ID',
                      onPressed: onCopy,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF4D5AA6),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEDCF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: Color(0xFF8A5A00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


