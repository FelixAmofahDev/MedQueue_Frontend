import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/doctor_model.dart';
import '../../models/time_slot_model.dart';
import '../../services/doctor_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_components.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/slot_grid.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late int doctorId;
  Doctor? selectedDoctor;
  DateTime? selectedDate;
  TimeSlot? selectedSlot;
  bool _slotsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      doctorId = args;
      final doctorService = context.read<DoctorService>();
      selectedDoctor = doctorService.getDoctorById(doctorId);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedSlot = null;
        _slotsLoaded = false;
      });

      // Fetch slots for the selected date
      _fetchSlots();
    }
  }

  void _fetchSlots() async {
    if (selectedDate == null) return;

    final doctorService = context.read<DoctorService>();
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate!);

    final success =
        await doctorService.fetchDoctorSlots(doctorId, dateString);

    if (mounted) {
      setState(() {
        _slotsLoaded = true;
      });

      if (!success && doctorService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(doctorService.errorMessage ?? 'Error loading slots'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToBooking() {
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/patient/appointment-booking-confirm',
      arguments: {
        'slotId': selectedSlot!.id,
        'doctorName': selectedDoctor?.fullName ?? '',
        'doctorSpecialization':
            selectedDoctor?.specialization ?? '',
        'date': selectedDate,
        'time': selectedSlot!.startTime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDoctor == null) {
      return Scaffold(
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
              'Dcotor Details',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
           
          ],
        ),
       
      ),
        body: const Center(
          child: Text('Doctor not found'),
        ),
      );
    }

    return Scaffold(
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
              'Doctor Details',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
           
          ],
        ),
       
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info card
            Padding(
              padding: const EdgeInsets.all(12),
              child: DoctorCard(
                doctor: selectedDoctor!,
                showAvailability: false,
                onTap: null,
              ),
            ),
            // Doctor bio
            if (selectedDoctor!.bio != null &&
                selectedDoctor!.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDoctor!.bio ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Date selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? 'Choose a date'
                                : DateFormat('MMM dd, yyyy')
                                    .format(selectedDate!),
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedDate == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Available slots
            if (selectedDate != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text(
                  'Available Time Slots',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Consumer<DoctorService>(
                builder: (context, doctorService, _) {
                  if (doctorService.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CustomLoadingIndicator(
                        message: 'Loading slots...',
                      ),
                    );
                  }

                  if (doctorService.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            doctorService.errorMessage ??
                                'Failed to load slots',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchSlots,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return SlotGrid(
                    slots: doctorService.slots,
                    selectedSlot: selectedSlot,
                    onSlotSelected: (slot) {
                      setState(() {
                        selectedSlot = slot;
                      });
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            // Book button
            if (selectedDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: selectedSlot != null
                        ? _proceedToBooking
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Proceed to Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
