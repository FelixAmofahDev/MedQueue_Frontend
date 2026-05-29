import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final doctor = authService.currentUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(doctor),
                const SizedBox(height: 32),

                // Doctor Information Section
                _buildSectionTitle('Doctor Information'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  label: 'Full Name',
                  value: doctor?.fullName ?? 'N/A',
                  icon: Icons.person,
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  label: 'Email',
                  value: doctor?.email ?? 'N/A',
                  icon: Icons.email,
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  label: 'Phone',
                  value: doctor?.phoneNumber ?? 'N/A',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 24),

                // Professional Information Section
                _buildSectionTitle('Professional Information'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  label: 'Specialization',
                  value: doctor?.doctorProfile?.specialization ?? 'N/A',
                  icon: Icons.medical_services,
                ),
                if (doctor?.doctorProfile?.medicalLicense != null &&
                    doctor!.doctorProfile!.medicalLicense!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    label: 'Medical License',
                    value: doctor.doctorProfile!.medicalLicense!,
                    icon: Icons.card_membership,
                  ),
                ],
                if (doctor?.doctorProfile?.hospitalName != null &&
                    doctor!.doctorProfile!.hospitalName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    label: 'Hospital',
                    value: doctor.doctorProfile!.hospitalName!,
                    icon: Icons.local_hospital,
                  ),
                ],
                const SizedBox(height: 24),

                // Consultation Fee Section (if available)
                if (doctor?.doctorProfile?.consultationFee != null) ...[
                  _buildSectionTitle('Consultation Details'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    label: 'Consultation Fee',
                    value: '\$${doctor!.doctorProfile!.consultationFee}',
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 24),
                ],

                // Account Settings Section
                _buildSectionTitle('Account Settings'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlineCustomButton(
                    label: 'Logout',
                    textColor: AppColors.emergencyRed,
                    borderColor: AppColors.emergencyRed,
                    onPressed: () async {
                      final confirmed = await _showLogoutConfirmation(context);
                      if (confirmed && context.mounted) {
                        await authService.logout();
                        if (context.mounted) {
                          // Clear all routes and return to StartupWrapper home
                          while (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryBlue,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.local_hospital,
            size: 60,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Dr. ${doctor?.fullName ?? "Doctor"}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          doctor?.doctorProfile?.specialization ?? 'Specialist',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Are you sure you want to logout? You\'ll need to login again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.emergencyRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
