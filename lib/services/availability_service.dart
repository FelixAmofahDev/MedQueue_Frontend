import 'package:flutter/foundation.dart';
import '../models/api_response_model.dart';
import '../models/doctor_schedule_model.dart';
import '../utils/api_constants.dart';
import '../utils/token_manager.dart';
import 'api_client.dart';

class AvailabilityService extends ChangeNotifier {
  final List<DoctorSchedule> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;

  List<DoctorSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get fieldErrors => _fieldErrors;

  Future<bool> fetchMyAvailability() async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      final response = await ApiClient.getWithAuth<dynamic>(
        ApiConstants.availabilityMyEndpoint,
        parser: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        _schedules.clear();
        final raw = response.data!;
        debugPrint('Raw availability data: $raw');
        final List<dynamic> rawList = raw is List<dynamic>
            ? raw
            : (raw is Map && raw['data'] is List)
                ? raw['data'] as List<dynamic>
                : const <dynamic>[];
        _schedules.addAll(
          rawList.map((item) => DoctorSchedule.fromJson(item as Map<String, dynamic>)),
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message;
      _fieldErrors = response.errors;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAvailabilityEntry(Map<String, dynamic> body) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      final response = await ApiClient.postWithAuth<Map<String, dynamic>>(
        ApiConstants.availabilityMyEndpoint,
        body: body,
        parser: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final newSchedule = DoctorSchedule.fromJson(response.data!);
        _schedules.add(newSchedule);
        _schedules.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message;
      _fieldErrors = response.errors;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvailabilityEntry(int id, Map<String, dynamic> body) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      final endpoint = '${ApiConstants.availabilityMyEndpoint}$id/';
      final response = await ApiClient.patchWithAuth<Map<String, dynamic>>(
        endpoint,
        body: body,
        parser: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final updated = DoctorSchedule.fromJson(response.data!);
        final index = _schedules.indexWhere((s) => s.id == id);
        if (index != -1) {
          _schedules[index] = updated;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message;
      _fieldErrors = response.errors;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAvailabilityEntry(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      final endpoint = '${ApiConstants.availabilityMyEndpoint}$id/';
      final response = await ApiClient.deleteWithAuth<Map<String, dynamic>>(
        endpoint,
        parser: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        _schedules.removeWhere((s) => s.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message;
      _fieldErrors = response.errors;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();
  }
}
