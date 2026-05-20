/// Day of week values (0 = Monday, 6 = Sunday)
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

extension DayOfWeekExtension on DayOfWeek {
  int get value => index;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  static DayOfWeek fromValue(int value) {
    return DayOfWeek.values.firstWhere(
      (day) => day.value == value,
      orElse: () => DayOfWeek.monday,
    );
  }
}

class DoctorSchedule {
  final int id;
  final int doctorId;
  final String doctorName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final int maxPatientsPerDay;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorSchedule({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    required this.maxPatientsPerDay,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  DayOfWeek get day => DayOfWeekExtension.fromValue(dayOfWeek);

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      id: json['id'] as int? ?? 0,
      doctorId: json['doctor'] as int? ?? 0,
      doctorName: json['doctor_name'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      startTime: json['start_time'] as String? ?? '08:00',
      endTime: json['end_time'] as String? ?? '17:00',
      slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 15,
      maxPatientsPerDay: json['max_patients_per_day'] as int? ?? 30,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctor': doctorId,
        'doctor_name': doctorName,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'slot_duration_minutes': slotDurationMinutes,
        'max_patients_per_day': maxPatientsPerDay,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
