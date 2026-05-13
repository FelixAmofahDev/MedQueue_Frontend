import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import '../patient/patient_home_screen.dart';
import '../doctor/doctor_home_screen.dart';
import '../admin/admin_home_screen.dart';

/// StartupWrapper - Auth Guard that handles navigation based on auth state
/// Shows SplashScreen during initial auth check, then navigates to appropriate screen
class StartupWrapper extends StatefulWidget {
  const StartupWrapper({super.key});

  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() async {
    // Get the auth service and initialize it (check for cached user)
    final authService = context.read<AuthService>();
    await authService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show splash screen while initializing
        if (!authService.isInitialized) {
          return const SplashScreen();
        }

        // User is authenticated - show appropriate home screen based on role
        if (authService.isAuthenticated) {
          if (authService.isDoctor) {
            return const DoctorHomeScreen();
          } else if (authService.isAdmin) {
            return const AdminHomeScreen();
          } else {
            // Default to patient
            return const PatientHomeScreen();
          }
        }

        // User is not authenticated - show login screen
        return const LoginScreen();
      },
    );
  }
}
