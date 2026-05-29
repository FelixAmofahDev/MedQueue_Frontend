import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../utils/app_colors.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final bool showPatientName;

  const AppointmentCard( {
    super.key,
    required this.appointment,
    this.onTap,
    this.actions,
    this.showPatientName = false,
  });

  _StatusStyle get _statusStyle {
    switch (appointment.status) {
      case 'pending':
        return _StatusStyle(
          color: AppColors.warningOrange,
          bg: const Color(0xFFFFF5E6),
          icon: Icons.hourglass_top_rounded,
        );
      case 'confirmed':
        return _StatusStyle(
          color: AppColors.primaryBlue,
          bg: const Color(0xFFEBF4FF),
          icon: Icons.check_circle_rounded,
        );
      case 'completed':
        return _StatusStyle(
          color: AppColors.successGreen,
          bg: const Color(0xFFE8F8F2),
          icon: Icons.task_alt_rounded,
        );
      case 'cancelled':
        return _StatusStyle(
          color: AppColors.emergencyRed,
          bg: const Color(0xFFFFECEB),
          icon: Icons.cancel_rounded,
        );
      case 'no_show':
        return _StatusStyle(
          color: AppColors.emergencyLight,
          bg: const Color(0xFFFFECEB),
          icon: Icons.person_off_rounded,
        );
      case 'rescheduled':
        return _StatusStyle(
          color: const Color(0xFF8B5CF6),
          bg: const Color(0xFFF3EEFF),
          icon: Icons.update_rounded,
        );
      default:
        return _StatusStyle(
          color: AppColors.textGray,
          bg: AppColors.backgroundGray,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  String _formatDateWithDay(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final dayName = DateFormat('EEE').format(date);
      final formattedDate = DateFormat('MMM d, y').format(date);
      return '$dayName, $formattedDate';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderColor.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.07),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Colored top accent bar ───────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ─────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryGreen,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Doctor/Patient name & specialization/phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              showPatientName
                                  ? appointment.patientDetail.fullName
                                  : 'Dr. ${appointment.doctorDetail.fullName}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                showPatientName
                                    ? appointment.patientDetail.phone
                                    : appointment.doctorDetail.specialization,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: status.color.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon,
                                size: 12, color: status.color),
                            const SizedBox(width: 4),
                            Text(
                              appointment.statusEnum.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF2F4F6)),
                  const SizedBox(height: 12),

                  // ── Date / Time / Reason row ───────────────
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_month_rounded,
                        label: _formatDateWithDay(appointment.appointmentDate),
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: appointment.appointmentTime,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),

                  if (appointment.reason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 13,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            appointment.reason,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Action buttons ─────────────────────────
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF2F4F6)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: a,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting types & widgets ──────────────────────────────────

class _StatusStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusStyle(
      {required this.color, required this.bg, required this.icon});
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}