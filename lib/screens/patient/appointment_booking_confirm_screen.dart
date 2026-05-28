import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medqueue_frontend/screens/patient/patient_home_screen.dart';
import 'package:provider/provider.dart';
import '../../services/appointment_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class AppointmentBookingConfirmScreen extends StatefulWidget {
  const AppointmentBookingConfirmScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentBookingConfirmScreen> createState() =>
      _AppointmentBookingConfirmScreenState();
}

class _AppointmentBookingConfirmScreenState
    extends State<AppointmentBookingConfirmScreen> {
  late Map<String, dynamic> args;
  final _reasonController = TextEditingController();
  bool _isBooking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
  }

  Future<void> _bookAppointment() async {
    if (_isBooking) return;

    setState(() {
      _isBooking = true;
    });

    final appointmentService = context.read<AppointmentService>();
    final result = await appointmentService.bookAppointment(
      slotId: args['slotId'] as int,
      reason: _reasonController.text,
    );

    if (!mounted) return;

    setState(() {
      _isBooking = false;
    });

    if (result != null) {
      // Success - start queue polling and navigate to queue tracker
      final queueService = context.read<QueueService>();
      final bookedDate = args['date'] as DateTime?;
      
      // Start polling for patient's queue position
      queueService.startPatientQueuePolling(date: bookedDate);
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Booked!'),
          content: const Text(
            'Your appointment has been confirmed. You will receive a confirmation shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to queue tracker screen
                Navigator.pushReplacementNamed(context, '/queue-tracker');
              },
              child: const Text('View Queue'),
            ),
          ],
        ),
      );
    } else {
      // Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appointmentService.errorMessage ?? 'Failed to book appointment',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = args['doctorName'] as String? ?? '';
    final specialization = args['doctorSpecialization'] as String? ?? '';
    final date = args['date'] as DateTime?;
    final time = args['time'] as String? ?? '';
    final slotId = args['slotId'] as int? ?? 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Confirm Booking',
        showBackButton: true,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Appointment details card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Doctor',
                        'Dr. $doctorName',
                        Icons.person,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Specialization',
                        specialization,
                        Icons.medical_services,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Date',
                        date != null
                            ? DateFormat('MMM dd, yyyy').format(date)
                            : 'Not selected',
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Time', time, Icons.access_time),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Reason field
              const Text(
                'Reason for Visit (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Consumer<AppointmentService>(
                builder: (context, appointmentService, _) {
                  final reasonError =
                      appointmentService.fieldErrors?['reason'] as List?;

                  return TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., General checkup, Follow-up consultation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: reasonError != null && reasonError.isNotEmpty
                          ? reasonError.first.toString()
                          : null,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // General error message
              Consumer<AppointmentService>(
                builder: (context, appointmentService, _) {
                  if (appointmentService.errorMessage != null &&
                      (appointmentService.fieldErrors == null ||
                          appointmentService.fieldErrors!.isEmpty)) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  appointmentService.errorMessage ?? '',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Consumer<AppointmentService>(
                  builder: (context, appointmentService, _) {
                    return ElevatedButton(
                      onPressed: appointmentService.isLoading
                          ? null
                          : _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: appointmentService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Change Slot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
