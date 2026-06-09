import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/doctor_schedule_model.dart';
import '../../services/availability_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  DayOfWeek _selectedDay = DayOfWeek.monday;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 15;
  int _maxPatients = 30;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final service = context.read<AvailabilityService>();
    await service.fetchMyAvailability();
  }

  Future<void> _addScheduleEntry() async {
    final service = context.read<AvailabilityService>();
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final startStr =
        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    final success = await service.createAvailabilityEntry({
      'day_of_week': _selectedDay.value,
      'start_time': startStr,
      'end_time': endStr,
      'slot_duration_minutes': _slotDuration,
      'max_patients_per_day': _maxPatients,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability added successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _resetForm();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage ?? 'Failed to add availability'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  Future<void> _deleteEntry(int id) async {
    final service = context.read<AvailabilityService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Remove Availability',
        message: 'Are you sure you want to remove this schedule entry?',
        confirmButtonText: 'Remove',
        cancelButtonText: 'Cancel',
        confirmButtonColor: AppColors.emergencyRed,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed != true) return;

    final success = await service.deleteAvailabilityEntry(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability removed'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDay = DayOfWeek.monday;
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _slotDuration = 15;
      _maxPatients = 30;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'My Availability',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AvailabilityService>(
        builder: (context, service, _) {
          final schedules = service.schedules;

          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              const Text(
                'Active schedule',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              if (service.isLoading && schedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (schedules.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 40,
                        color: AppColors.textGray.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No availability set',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your working days below.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...schedules.map(
                  (s) => _ScheduleTile(
                    schedule: s,
                    onDelete: () => _deleteEntry(s.id),
                  ),
                ),
              const SizedBox(height: 24),

              const Text(
                'Add schedule entry',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _DaySelector(
                        selectedDay: _selectedDay,
                        onChanged: (d) => setState(() => _selectedDay = d),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _TimePickerField(
                              label: 'Start time',
                              icon: Icons.access_time_rounded,
                              time: _startTime,
                              onPick: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime,
                                );
                                if (picked != null) {
                                  setState(() => _startTime = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimePickerField(
                              label: 'End time',
                              icon: Icons.access_time_filled_rounded,
                              time: _endTime,
                              onPick: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (picked != null) {
                                  setState(() => _endTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownField<int>(
                              label: 'Slot duration (min)',
                              icon: Icons.timer_rounded,
                              value: _slotDuration,
                              items: const [15, 20, 30],
                              onChanged: (v) =>
                                  setState(() => _slotDuration = v ?? 15),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DropdownField<int>(
                              label: 'Max patients / day',
                              icon: Icons.people_rounded,
                              value: _maxPatients,
                              items: const [10, 20, 30, 50],
                              onChanged: (v) =>
                                  setState(() => _maxPatients = v ?? 30),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: service.isLoading
                              ? null
                              : _addScheduleEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: service.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Add availability',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final DoctorSchedule schedule;
  final VoidCallback onDelete;

  const _ScheduleTile({required this.schedule, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final day = schedule.day.displayName;
    final start = schedule.startTime;
    final end = schedule.endTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$start – $end',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.emergencyRed.withOpacity(0.85),
            ),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final DayOfWeek selectedDay;
  final ValueChanged<DayOfWeek> onChanged;

  const _DaySelector({
    required this.selectedDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DayOfWeek.values.map((day) {
          final isSelected = day == selectedDay;
          return GestureDetector(
            onTap: () => onChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryBlue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.borderColor.withOpacity(0.4),
                ),
              ),
              child: Text(
                day.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textGray,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay time;
  final VoidCallback onPick;

  const _TimePickerField({
    required this.label,
    required this.icon,
    required this.time,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 10),
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
                    formatted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textGray),
                items: items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text('$item'),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
