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
  
  // Per-action loading states
  bool _addingSchedule = false;
  int? _deletingScheduleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailability();
    });
  }

  Future<void> _loadAvailability() async {
    final service = context.read<AvailabilityService>();
    await service.fetchMyAvailability();
  }

  Future<void> _addScheduleEntry() async {
    final service = context.read<AvailabilityService>();
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _addingSchedule = true);

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

    if (!mounted) return;
    setState(() => _addingSchedule = false);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability added successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _resetForm();
    } else {
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

    setState(() => _deletingScheduleId = id);
    final success = await service.deleteAvailabilityEntry(id);
    if (!mounted) return;
    setState(() => _deletingScheduleId = null);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability removed'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage ?? 'Failed to remove availability'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  Future<void> _openEditDialog(DoctorSchedule schedule) async {
    final service = context.read<AvailabilityService>();
    final startParts = schedule.startTime.split(':');
    final endParts = schedule.endTime.split(':');
    var selectedDay = schedule.day;
    var startTime = TimeOfDay(
      hour: int.tryParse(startParts.first) ?? 8,
      minute: int.tryParse(startParts.last) ?? 0,
    );
    var endTime = TimeOfDay(
      hour: int.tryParse(endParts.first) ?? 17,
      minute: int.tryParse(endParts.last) ?? 0,
    );
    var slotDuration = schedule.slotDurationMinutes;
    var maxPatients = schedule.maxPatientsPerDay;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit availability'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DaySelector(
                  selectedDay: selectedDay,
                  onChanged: (d) => setDialogState(() => selectedDay = d),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DialogTimeField(
                        label: 'Start time',
                        icon: Icons.access_time_rounded,
                        time: startTime,
                        onPick: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null && mounted) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogTimeField(
                        label: 'End time',
                        icon: Icons.access_time_filled_rounded,
                        time: endTime,
                        onPick: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null && mounted) {
                            setDialogState(() => endTime = picked);
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
                        value: slotDuration,
                        items: const [15, 20, 30],
                        onChanged: (v) =>
                            setDialogState(() => slotDuration = v ?? 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DropdownField<int>(
                        label: 'Max patients / day',
                        icon: Icons.people_rounded,
                        value: maxPatients,
                        items: const [10, 20, 30, 50],
                        onChanged: (v) =>
                            setDialogState(() => maxPatients = v ?? 30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final body = <String, dynamic>{
                  'day_of_week': selectedDay.value,
                  'start_time':
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                  'end_time':
                      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  'slot_duration_minutes': slotDuration,
                  'max_patients_per_day': maxPatients,
                };
                final success = await service.updateAvailabilityEntry(schedule.id, body);
                if (mounted) {
                  Navigator.of(context).pop(success);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability updated'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.errorMessage ?? 'Failed to update availability'),
          backgroundColor: AppColors.emergencyRed,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
            'My Availability',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
           
          ],
        ),
       
      ),
      body: Consumer<AvailabilityService>(
        builder: (context, service, _) {
          final schedules = service.schedules;

          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              // Active Schedule Section
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Schedule',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your working days and hours',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (service.isLoading && schedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading schedules...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                )
              else if (schedules.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderColor.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 32,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No availability set',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your working days below to get started',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...schedules.map(
                  (s) => _ScheduleTile(
                    schedule: s,
                    isDeleting: _deletingScheduleId == s.id,
                    onDelete: () => _deleteEntry(s.id),
                    onEdit: () => _openEditDialog(s),
                  ),
                ),
              const SizedBox(height: 32),

              // Add Schedule Section
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Schedule Entry',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a new availability slot',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
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
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _DropdownField<int>(
                              label: 'Slot duration',
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
                              label: 'Max patients',
                              icon: Icons.people_rounded,
                              value: _maxPatients,
                              items: const [10, 20, 30, 50],
                              onChanged: (v) =>
                                  setState(() => _maxPatients = v ?? 30),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child:Container(
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: _addingSchedule
        ? LinearGradient(
            colors: [
              AppColors.primaryBlue.withOpacity(0.6),
              AppColors.primaryGreen.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryBlue,
              
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
    borderRadius: BorderRadius.circular(14),
  ),
  child: ElevatedButton(
    onPressed: _addingSchedule ? null : _addScheduleEntry,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
    ),
    child: _addingSchedule
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          )
        : const Text(
            'Add Availability',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
  ),
)
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
  final VoidCallback onEdit;
  final bool isDeleting;

  const _ScheduleTile({
    required this.schedule,
    required this.onDelete,
    required this.onEdit,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final day = schedule.day.displayName;
    final start = schedule.startTime;
    final end = schedule.endTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
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
          if (isDeleting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.emergencyRed.withOpacity(0.7),
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_calendar_sharp,
                color: AppColors.primaryGreen.withOpacity(0.7),
              ),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.emergencyRed.withOpacity(0.7),
              ),
              tooltip: 'Remove',
            ),
          ],
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

class _DialogTimeField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay time;
  final VoidCallback onPick;

  const _DialogTimeField({
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
