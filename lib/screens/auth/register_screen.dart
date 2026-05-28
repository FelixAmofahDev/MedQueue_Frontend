import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  final String? role;

  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedRole;

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  String _selectedGender = 'unspecified';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? 'patient';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _handleRegister(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _passwordConfirmController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
      gender: _selectedGender,
      dateOfBirth: _dateOfBirthController.text.isEmpty ? null : _dateOfBirthController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text.trim(),
      bloodGroup: _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
      emergencyContactName: _emergencyContactController.text.isEmpty ? null : _emergencyContactController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.isEmpty ? null : _emergencyPhoneController.text.trim(),
    );

    if (success && mounted) {
      // Show OTP screen
      _showOTPDialog(authService);
    }
  }

  void _showOTPDialog(AuthService authService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OTPDialog(
        phoneNumber: _phoneController.text.trim(),
        onSuccess: () {
          Navigator.pop(context); // Close OTP dialog
          Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, _) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Register',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your $_selectedRole account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Error Message
                      if (authService.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.errorRed.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.errorRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authService.errorMessage ?? '',
                                  style: const TextStyle(
                                    color: AppColors.errorRed,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (authService.errorMessage != null)
                        const SizedBox(height: 16),
                      // Username
                      TextFormField(
                        controller: _usernameController,
                        enabled: !authService.isLoading,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: authService.fieldErrors?['username'] != null
                              ? (authService.fieldErrors!['username'] as List).first
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        enabled: !authService.isLoading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: authService.fieldErrors?['email'] != null
                              ? (authService.fieldErrors!['email'] as List).first
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        enabled: !authService.isLoading,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number (e.g., +233201234567)',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: authService.fieldErrors?['phone_number'] != null
                              ? (authService.fieldErrors!['phone_number'] as List).first
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        readOnly: authService.isLoading,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        readOnly: authService.isLoading,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Gender Dropdown
                      DropdownButtonFormField(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.wc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'unspecified', child: Text('Not specified')),
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGender = value ?? 'unspecified');
                        },
                      ),
                      const SizedBox(height: 12),
                      // Date of Birth
                      TextFormField(
                        controller: _dateOfBirthController,
                        enabled: !authService.isLoading,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth (optional)',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _dateOfBirthController.text = date.toString().split(' ')[0];
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Address
                      TextFormField(
                        controller: _addressController,
                        enabled: !authService.isLoading,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Address (optional)',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Patient-specific fields
                      if (_selectedRole == 'patient') ...[
                        // Blood Group
                        DropdownButtonFormField(
                          value: _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
                          decoration: InputDecoration(
                            labelText: 'Blood Group (optional)',
                            prefixIcon: const Icon(Icons.bloodtype),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'O+', child: Text('O+')),
                            DropdownMenuItem(value: 'O-', child: Text('O-')),
                            DropdownMenuItem(value: 'A+', child: Text('A+')),
                            DropdownMenuItem(value: 'A-', child: Text('A-')),
                            DropdownMenuItem(value: 'B+', child: Text('B+')),
                            DropdownMenuItem(value: 'B-', child: Text('B-')),
                            DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                            DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                          ],
                          onChanged: (value) {
                            _bloodGroupController.text = value ?? '';
                          },
                        ),
                        const SizedBox(height: 12),
                        // Emergency Contact Name
                        TextFormField(
                          controller: _emergencyContactController,
                          enabled: !authService.isLoading,
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Name (optional)',
                            prefixIcon: const Icon(Icons.contacts),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Emergency Contact Phone
                        TextFormField(
                          controller: _emergencyPhoneController,
                          enabled: !authService.isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Emergency Contact Phone (optional)',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        enabled: !authService.isLoading,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          helperText: 'At least 8 characters, mix of letters and numbers',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Confirm Password
                      TextFormField(
                        controller: _passwordConfirmController,
                        enabled: !authService.isLoading,
                        obscureText: _obscurePasswordConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePasswordConfirm = !_obscurePasswordConfirm;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Register Button
                      ElevatedButton(
                        onPressed: authService.isLoading ? null : () => _handleRegister(authService),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: 16),
                      // Already have account
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? '),
                            TextButton(
                              onPressed: authService.isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, AppRoutes.login);
                                    },
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OTPDialog extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onSuccess;

  const _OTPDialog({
    required this.phoneNumber,
    required this.onSuccess,
  });

  @override
  State<_OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<_OTPDialog> {
  final _otpController = TextEditingController();
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _sendOTP();
  }

  Future<void> _sendOTP() async {
    await _authService.sendOTP(widget.phoneNumber, OtpPurpose.phoneReg.value);
  }

  void _handleVerify() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    final success = await _authService.verifyOTP(
      phoneNumber: widget.phoneNumber,
      code: _otpController.text,
      purpose: OtpPurpose.phoneReg.value,
    );

    if (success && mounted) {
      widget.onSuccess();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Phone Number'),
      content: Consumer<AuthService>(
        builder: (context, authService, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                style: const TextStyle(color: AppColors.textGray),
              ),
              const SizedBox(height: 16),
              if (authService.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authService.errorMessage!,
                    style: const TextStyle(color: AppColors.errorRed),
                  ),
                ),
              TextField(
                controller: _otpController,
                enabled: !authService.isLoading,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer<AuthService>(
          builder: (context, authService, _) {
            return ElevatedButton(
              onPressed: authService.isLoading ? null : _handleVerify,
              child: authService.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            );
          },
        ),
      ],
    );
  }
}