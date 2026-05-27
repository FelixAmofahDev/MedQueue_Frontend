import 'package:flutter/material.dart';
import 'package:medqueue_frontend/models/appointment_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';
import '../../widgets/slot_grid.dart';
import '../../models/doctor_model.dart';
import '../../models/time_slot_model.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late int appointmentId;
  Appointment? appointment;
  bool _isLoading = true;
  String? _errorMessage;
  List<TimeSlot> _availableSlots = [];
  bool _isFetchingSlots = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      appointmentId = args;
      _fetchAppointmentDetail();
    } else {
      // Handle error: no appointment ID provided
      if (mounted) {
        setState(() {
          _errorMessage = 'Appointment ID not provided';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAppointmentDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appointmentService = context.read<AppointmentService>();
    final result = await appointmentService.fetchAppointmentDetail(appointmentId);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        appointment = result;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = appointmentService.errorMessage ?? 'Failed to load appointment details';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAvailableSlotsForReschedule() async {
    if (appointment == null) return;

    final doctorId = appointment!.doctorDetail.id;
    final date = appointment!.appointmentDate; // format: yyyy-MM-dd

    if (!mounted) return;
    setState(() {
      _isFetchingSlots = true;
      _availableSlots = [];
    });

    final doctorService = context.read<DoctorService>();
    final success = await doctorService.fetchDoctorSlots(doctorId, date);

    if (!mounted) return;

    if (success) {
      setState(() {
        _availableSlots = doctorService.slots.where((slot) => slot.isAvailable).toList();
        _isFetchingSlots = false;
      });
    } else {
      setState(() {
        _isFetchingSlots = false;
        // Error will be shown via snack bar in the doctor service? We'll show our own.
      });
      if (doctorService.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(doctorService.errorMessage ?? 'Failed to load available slots'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment() async {
    // Show dialog to get cancellation reason
    final TextEditingReasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text('Please provide a reason for cancellation (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for cancellation',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, TextEditingReasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );

    if (reason == null) return; // User cancelled

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final appointmentService = context.read<AppointmentService>();
    final success = await appointmentService.cancelAppointment(appointmentId, cancellationReason: reason);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success != null) {
      // Show success message and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // Wait a bit then pop
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentService.errorMessage ?? 'Failed to cancel appointment'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAppointment() async {
    if (appointment == null) return;

    // First, fetch available slots for the doctor on the appointment date
    await _fetchAvailableSlotsForReschedule();

    if (!mounted) return;

    // Show a full-screen modal to select a new slot
    final selectedSlot = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(0),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reschedule Appointment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isFetchingSlots
                    ? const Center(child: CircularProgressIndicator())
                    : _availableSlots.isEmpty
                        ? const Center(child: Text('No available slots for rescheduling'))
                        : SingleChildScrollView(
                            child: SlotGrid(
                              slots: _availableSlots,
                              selectedSlot: null,
                              onSlotSelected: (slot) {
                                // Close dialog and return the selected slot
                                Navigator.pop(context, slot);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedSlot == null) return; // User cancelled or no slot selected

    // Optional: get reason for rescheduling
    final TextEditingReasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Reason'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text('Please provide a reason for rescheduling (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for rescheduling',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, TextEditingReasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Confirm Reschedule'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final appointmentService = context.read<AppointmentService>();
    final success = await appointmentService.rescheduleAppointment(
      appointmentId,
      newSlotId: selectedSlot.id,
      reason: reason ?? '',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success != null) {
      // Show success message and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // Wait a bit then pop
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentService.errorMessage ?? 'Failed to reschedule appointment'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Appointment Details',
        showBackButton: true,
        backgroundColor: AppColors.primaryBlue,
        onBackPressed: Navigator.of(context).pop,
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(message: 'Loading appointment details...')
          : _errorMessage != null
              ? Center(
                  child: AppErrorWidget(
                    title: 'Error Loading Appointment',
                    message: _errorMessage ?? 'An error occurred',
                    onRetry: _fetchAppointmentDetail,
                  ),
                )
              : appointment == null
                  ? const Center(child: Text('Appointment not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Appointment info card
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
                                  // Doctor info
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: AppColors.primaryBlue,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appointment!.doctorDetail.fullName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Dr. ${appointment!.doctorDetail.specialization}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Date and time
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoItem(Icons.calendar_today, 'Date',
                                          DateFormat('MMM dd, yyyy').format(DateTime.parse(appointment!.appointmentDate))),
                                      _buildInfoItem(Icons.access_time, 'Time',
                                          appointment!.appointmentTime),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(appointment!.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      appointment!.statusEnum.displayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(appointment!.status),
                                      ),
                                    ),
                                  ),
                                  if (appointment!.reason.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Reason for Visit:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      appointment!.reason,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  if (appointment!.notes.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Notes:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      appointment!.notes,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action buttons
                          if (appointment!.canCancel || appointment!.canReschedule)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: appointment!.canCancel
                                        ? _cancelAppointment
                                        : null,
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancel Appointment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: appointment!.canCancel
                                          ? AppColors.errorRed
                                          : Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: appointment!.canReschedule
                                        ? _rescheduleAppointment
                                        : null,
                                    icon: const Icon(Icons.change_circle),
                                    label: const Text('Reschedule'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: appointment!.canReschedule
                                          ? AppColors.primaryBlue
                                          : AppColors.textGray,
                                      side: BorderSide(
                                        color: appointment!.canReschedule
                                            ? AppColors.primaryBlue
                                            : AppColors.borderColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                   
                                  ),
                                ),
                              ],
                            )
                          else
                            const Center(
                              child: Text(
                                'This appointment cannot be cancelled or rescheduled',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textGray),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textGray),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningOrange;
      case 'confirmed':
        return AppColors.infoBlue;
      case 'completed':
        return AppColors.successGreen;
      case 'cancelled':
        return AppColors.errorRed;
      case 'no_show':
        return AppColors.errorRed;
      case 'rescheduled':
        return AppColors.infoBlue;
      default:
        return AppColors.textGray;
    }
  }
}