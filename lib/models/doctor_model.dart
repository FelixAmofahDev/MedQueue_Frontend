class Doctor {
  final int id;
  final String fullName;
  final String specialization;
  final String hospitalName;
  final double consultationFee;
  final int yearsOfExperience;
  final int avgConsultationMinutes;
  final bool isAcceptingPatients;
  final String profilePictureUrl;

  Doctor({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.hospitalName,
    required this.consultationFee,
    required this.yearsOfExperience,
    required this.avgConsultationMinutes,
    required this.isAcceptingPatients,
    required this.profilePictureUrl,
  });

  String get displayName => fullName;

  String get initials {
    final names = fullName.split(' ');
    return names.map((n) => n.isNotEmpty ? n[0] : '').join();
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      hospitalName: json['hospital_name'] as String? ?? '',
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0.0,
      yearsOfExperience: json['years_of_experience'] as int? ?? 0,
      avgConsultationMinutes: json['avg_consultation_minutes'] as int? ?? 15,
      isAcceptingPatients: json['is_accepting_patients'] as bool? ?? true,
      profilePictureUrl: json['profile_picture_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'specialization': specialization,
        'hospital_name': hospitalName,
        'consultation_fee': consultationFee,
        'years_of_experience': yearsOfExperience,
        'avg_consultation_minutes': avgConsultationMinutes,
        'is_accepting_patients': isAcceptingPatients,
        'profile_picture_url': profilePictureUrl,
      };
}
