import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medqueue_frontend/widgets/bottom_navbar.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_cards.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_components.dart';
import 'appointment_history_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch appointments on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appointmentService = context.read<AppointmentService>();
      appointmentService.fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MedQueue GH'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).pushNamed('/patient-notifications');
                },
              ),
              Consumer<NotificationService>(
                builder: (context, notificationService, _) {
                  final unreadCount = notificationService.unreadCount;
                  if (unreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: ModernBottomNavBar(
  selectedIndex: _selectedIndex,
  onTap: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildAppointments();
      case 2:
        return _buildChat();
      case 3:
        return _buildProfile();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero Welcome Banner ──────────────────────────────
        Consumer<AuthService>(
          builder: (context, authService, _) {
            final user = authService.currentUser;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    color: Color(0xFF90EE90), size: 8),
                                SizedBox(width: 4),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hello, ${user?.fullName?.split(' ').first ?? "there"} 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Health stats row
                      Row(
                        children: [
                          _StatChip(
                              icon: Icons.calendar_today_rounded,
                              label: 'Next Appt',
                              value: 'Today'),
                          const SizedBox(width: 10),
                          _StatChip(
                              icon: Icons.queue_rounded,
                              label: 'Queue',
                              value: '#4'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 28),

        // ── Quick Actions ────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _ModernQuickAction(
                icon: Icons.calendar_month_rounded,
                label: 'Book\nAppointment',
                color: AppColors.primaryBlue,
                bgColor: const Color(0xFFEBF4FF),
                onTap: () =>
                    Navigator.of(context).pushNamed('/patient/doctors'),
              ),
              _ModernQuickAction(
                icon: Icons.queue_rounded,
                label: 'Queue\nStatus',
                color: AppColors.primaryGreen,
                bgColor: const Color(0xFFE8F8F2),
                onTap: () =>
                    Navigator.of(context).pushNamed('/queue-tracker'),
              ),
              _ModernQuickAction(
                icon: Icons.smart_toy_rounded,
                label: 'AI Health\nAssistant',
                color: AppColors.warningOrange,
                bgColor: const Color(0xFFFFF5E6),
                onTap: () =>
                    Navigator.of(context).pushNamed('/patient-chatbot'),
              ),
              _ModernQuickAction(
                icon: Icons.emergency_rounded,
                label: 'Emergency\nSOS',
                color: AppColors.emergencyRed,
                bgColor: const Color(0xFFFFECEB),
                onTap: () =>
                    Navigator.of(context).pushNamed('/emergency-sos'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
      ],
    ),
  );
}

  Widget _buildAppointments() {
    return const AppointmentHistoryScreen();
  }

  Widget _buildChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            'AI Health Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get instant health guidance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Start Chat',
            onPressed: () {
              Navigator.of(context).pushNamed('/patient-chatbot');
            },
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
  return Consumer<AuthService>(
    builder: (context, authService, _) {
      final user = authService.currentUser;
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero Header ──────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -30,
                    top: 10,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.fullName ?? 'Patient',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ProfileStat(
                              label: 'Appointments',
                              value: '12',
                              icon: Icons.calendar_month_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withOpacity(0.3),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            _ProfileStat(
                              label: 'Blood Type',
                              value: user?.patientProfile?.bloodGroup ?? '—',
                              icon: Icons.bloodtype_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withOpacity(0.3),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            _ProfileStat(
                              label: 'Status',
                              value: 'Active',
                              icon: Icons.verified_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Personal Info Card ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
                children: [
                  _ModernInfoTile(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: user?.phoneNumber ?? 'N/A',
                    iconColor: AppColors.primaryBlue,
                  ),
                  _ModernInfoTile(
                    icon: Icons.cake_rounded,
                    label: 'Date of Birth',
                    value: user?.dateOfBirth ?? 'N/A',
                    iconColor: AppColors.primaryGreen,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Medical Info Card ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                title: 'Medical Information',
                icon: Icons.medical_information_rounded,
                children: [
                  _ModernInfoTile(
                    icon: Icons.bloodtype_rounded,
                    label: 'Blood Type',
                    value: user?.patientProfile?.bloodGroup ?? 'N/A',
                    iconColor: AppColors.emergencyRed,
                    valueWidget: user?.patientProfile?.bloodGroup != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emergencyRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.emergencyRed
                                      .withOpacity(0.3)),
                            ),
                            child: Text(
                              user!.patientProfile!.bloodGroup!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emergencyRed,
                              ),
                            ),
                          )
                        : null,
                  ),
                  _ModernInfoTile(
                    icon: Icons.contact_emergency_rounded,
                    label: 'Emergency Contact',
                    value:
                        '${user?.patientProfile?.emergencyContactName ?? 'N/A'}\n${user?.patientProfile?.emergencyContactPhone ?? ''}',
                    iconColor: AppColors.warningOrange,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Edit Profile
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryGreen
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Logout
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, authService),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.emergencyRed.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: AppColors.emergencyRed, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: AppColors.emergencyRed,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}

  void _showCancelDialog(BuildContext context, int appointmentId, AppointmentService appointmentService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await appointmentService.cancelAppointment(appointmentId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled')),
                );
              }
            },
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, int appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text('This feature will be available soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        confirmButtonText: 'Logout',
        cancelButtonText: 'Cancel',
        confirmButtonColor: AppColors.emergencyRed,
        onConfirm: () async {
          await authService.logout();
          if (mounted) {
            // Clear all routes and return to StartupWrapper home (which shows LoginScreen)
            while (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    );
  }
}

class _ModernQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ModernQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textGray),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...children,
        ],
      ),
    );
  }
}

class _ModernInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool showDivider;
  final Widget? valueWidget;

  const _ModernInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.showDivider = true,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (valueWidget != null) valueWidget!,
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 66),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
      ],
    );
  }
}