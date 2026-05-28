import 'package:flutter/material.dart';
import 'package:medqueue_frontend/widgets/appointment_card.dart';
import 'package:medqueue_frontend/widgets/custom_cards.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/queue_service.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';
import '../../models/queue_model.dart';
import '../../models/appointment_model.dart';


class QueueTrackerScreen extends StatefulWidget {
  const QueueTrackerScreen({super.key});

  @override
  State<QueueTrackerScreen> createState() => _QueueTrackerScreenState();
}

class _QueueTrackerScreenState extends State<QueueTrackerScreen> {
  Appointment? _currentAppointment;
  bool _isLoadingAppointment = false;
  @override
  void initState() {
    super.initState();
    // Start fetching queue position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queueService = context.read<QueueService>();
      final appointmentService = context.read<AppointmentService>();
      
      // If no date is already being polled, try to find the next appointment
      if (queueService.currentPollingDate == null) {
        // Fetch appointments first
        appointmentService.fetchAppointments().then((_) {
          // Get the next upcoming appointment date
          final upcomingAppointments = appointmentService.upcomingAppointments;
          if (upcomingAppointments.isNotEmpty) {
            // Sort by date and get the earliest one
            upcomingAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
            final nextAppointmentDateStr = upcomingAppointments.first.appointmentDate;
            final nextAppointmentDate = DateTime.parse(nextAppointmentDateStr);
            queueService.startPatientQueuePolling(date: nextAppointmentDate);
            // Fetch appointment details
            _fetchAppointmentForDate(nextAppointmentDate);
          } else {
            // No upcoming appointments, poll for today
            queueService.startPatientQueuePolling();
          }
        });
      } else {
        // Already have a polling date (from appointment confirmation), just start polling
        queueService.startPatientQueuePolling();
        // Fetch appointment details for the polling date
        if (queueService.currentPollingDate != null) {
          _fetchAppointmentForDate(queueService.currentPollingDate!);
        }
      }
    });
  }

  @override
  void dispose() {
    final queueService = context.read<QueueService>();
    queueService.clearState();
    super.dispose();
  }

  Future<void> _fetchAppointmentForDate(DateTime date) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointment = true;
    });

    try {
      final appointmentService = context.read<AppointmentService>();
      await appointmentService.fetchAppointments();
      
      if (!mounted) return;

      // Find the appointment for this date
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      Appointment? appointment;
      try {
        appointment = appointmentService.appointments.firstWhere(
          (apt) => apt.appointmentDate == dateStr && apt.status != 'cancelled',
        );
      } catch (e) {
        appointment = null;
      }

      if (!mounted) return;
      setState(() {
        _currentAppointment = appointment;
        _isLoadingAppointment = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAppointment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Queue Status'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<QueueService>(
        builder: (context, queueService, _) {
          if (queueService.isLoading && queueService.currentQueueEntry == null) {
            return const CustomLoadingIndicator(message: 'Loading queue info...');
          }

          final queueEntry = queueService.currentQueueEntry;

          if (queueEntry == null) {
            return EmptyState(
              icon: Icons.line_weight,
              title: 'No Queue Entry',
              message: 'You are not currently in a queue. Book an appointment to join.',
              action: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/book-appointment');
                },
                child: const Text('Book Appointment'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Appointment Details Card
                if (_currentAppointment != null)
                  AppointmentCard(
                        appointment: _currentAppointment!,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/patient/appointment-detail',
                            arguments: _currentAppointment!.id,
                          );
                        },
                      )
                else if (_isLoadingAppointment)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Queue Number Badge
                _buildQueueNumberBadge(queueEntry.queueNumber),
                const SizedBox(height: 32),
                // Status
                _buildStatusCard(queueEntry),
                const SizedBox(height: 24),
                // Queue Info Cards
                _buildQueueInfoCards(queueEntry),
                const SizedBox(height: 24),
                // Wait Time Info
                _buildWaitTimeCard(queueService.estimatedWaitMinutes ?? 0),
                const SizedBox(height: 32),
                // Action Buttons
                _buildActionButtons(context, queueService),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueueNumberBadge(int queueNumber) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '#$queueNumber',
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

 

  Widget _buildStatusCard(QueueEntry entry) {
    final statusColor = _getStatusColor(entry.status);
    final statusLabel = _getStatusLabel(entry.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.status == QueueEntryStatus.called
                ? 'Please proceed to the consultation room'
                : entry.status == QueueEntryStatus.completed
                    ? 'Thank you for visiting'
                    : 'Please wait for your turn',
            style: TextStyle(
              fontSize: 12,
              color: statusColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueInfoCards(QueueEntry entry) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Positions Ahead',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.positionsAhead}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Joined At',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(entry.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitTimeCard(int estimatedWait) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Estimated Wait Time',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '$estimatedWait min',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              estimatedWait == 0
                  ? 'You are being served now!'
                  : 'Based on average consultation time',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, QueueService queueService) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: queueService.isLoading
                ? null
                : () => _showLeaveConfirmation(context, queueService),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave Queue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              queueService.fetchPatientQueuePosition();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showLeaveConfirmation(BuildContext context, QueueService queueService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Queue?'),
          content: const Text(
            'Are you sure you want to leave the queue? Your appointment will be cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await queueService.leaveQueue();
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You have left the queue'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(queueService.errorMessage ?? 'Failed to leave queue'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _getStatusColor(QueueEntryStatus status) {
    switch (status) {
      case QueueEntryStatus.waiting:
        return Colors.orange;
      case QueueEntryStatus.called:
        return Colors.blue;
      case QueueEntryStatus.inConsult:
        return Colors.blue;
      case QueueEntryStatus.completed:
        return Colors.green;
      case QueueEntryStatus.left:
        return Colors.grey;
      case QueueEntryStatus.skipped:
        return Colors.red;
    }
  }

  String _getStatusLabel(QueueEntryStatus status) {
    switch (status) {
      case QueueEntryStatus.waiting:
        return 'WAITING';
      case QueueEntryStatus.called:
        return 'CALLED';
      case QueueEntryStatus.inConsult:
        return 'IN CONSULTATION';
      case QueueEntryStatus.completed:
        return 'COMPLETED';
      case QueueEntryStatus.left:
        return 'LEFT';
      case QueueEntryStatus.skipped:
        return 'SKIPPED';
    }
  }
}