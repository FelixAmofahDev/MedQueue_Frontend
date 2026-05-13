# Flutter Navigation System Refactoring - StartupWrapper (Auth Guard) Implementation

## Overview

This refactoring implements a clean, state-management-based navigation system using a **StartupWrapper** (Auth Guard) pattern with Provider. The solution ensures:

✅ Initial authentication check only happens once at app startup  
✅ SplashScreen displays only during the initial auth check  
✅ No back button visible on Home screens (they are the root)  
✅ Proper session persistence using `flutter_secure_storage`  
✅ Clean navigation between authenticated and unauthenticated states  
✅ Consistent logout behavior across all user roles (Patient, Doctor, Admin)

---

## Architecture

### 1. **StartupWrapper (Auth Guard)**
**File:** `lib/screens/auth/startup_wrapper.dart`

The `StartupWrapper` is the main entry point of the application that:
- Checks authentication status on app startup
- Displays `SplashScreen` during initialization
- Routes to appropriate home screen based on user role when authenticated
- Shows `LoginScreen` when not authenticated
- Responds to auth state changes in real-time via Provider's Consumer

**Key Features:**
- Single source of truth for auth-based navigation
- Automatically responds to auth state changes via Consumer
- No explicit navigation needed after login/logout

### 2. **Updated AuthService**
**File:** `lib/services/auth_service.dart`

Added initialization state tracking to prevent multiple initialization attempts:

```dart
bool _isInitialized = false;

/// Initialize auth state on app startup (called only once)
Future<void> initialize() async {
  if (_isInitialized) return; // Prevent re-initialization
  
  _isLoading = true;
  notifyListeners();

  try {
    // Check if user was previously logged in
    if (await TokenManager.isAuthenticated()) {
      _currentUser = await TokenManager.getCachedUserData();
    }
  } catch (e) {
    _errorMessage = 'Failed to initialize: $e';
  }

  _isInitialized = true;
  _isLoading = false;
  notifyListeners();
}
```

**Key Additions:**
- `_isInitialized` flag prevents redundant initialization
- `isInitialized` getter for UI state checking
- Session persistence via `TokenManager`

### 3. **Main Entry Point**
**File:** `lib/main.dart`

Changed from using `initialRoute` to setting `StartupWrapper` as the home:

```dart
MaterialApp(
  title: 'MedQueue GH',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  home: const StartupWrapper(),  // ✓ Auth Guard as home
  routes: AppRoutes.getRoutes(),
)
```

**Benefits:**
- `StartupWrapper` is always the root of the widget tree
- Named routes are pushed on top for sub-screens
- Clean separation between auth-related and feature navigation

### 4. **Session Persistence**
**Already Implemented via:** `lib/utils/token_manager.dart`

Using `flutter_secure_storage`, the system automatically:
- Saves tokens after successful login
- Saves user profile data
- Checks for existing tokens on app startup
- Clears all data on logout

**Dependencies Already Available:**
- `flutter_secure_storage: ^9.0.0` (secure local storage)
- `provider: ^6.0.0` (state management)

---

## Navigation Flow

### 1. **Cold Start (First Launch or After Clear Data)**

```
App Starts
    ↓
StartupWrapper Initializes
    ↓
AuthService.initialize() checks TokenManager
    ↓
No tokens found
    ↓
StartupWrapper shows SplashScreen (loading state)
    ↓
Initialization completes, _isInitialized = true
    ↓
Consumer rebuilds, isAuthenticated = false
    ↓
LoginScreen is displayed
```

### 2. **Warm Start (User Already Logged In)**

```
App Starts
    ↓
StartupWrapper Initializes
    ↓
AuthService.initialize() checks TokenManager
    ↓
Valid tokens and user data found
    ↓
StartupWrapper shows SplashScreen briefly
    ↓
_currentUser is restored from cache
    ↓
Consumer rebuilds, isAuthenticated = true
    ↓
PatientHomeScreen/DoctorHomeScreen/AdminHomeScreen is displayed
    ↓
(No back button - it's the root)
```

### 3. **Login Flow**

```
LoginScreen is displayed
    ↓
User enters credentials and taps "Sign In"
    ↓
authService.login() is called
    ↓
Backend validates and returns tokens + user data
    ↓
TokenManager saves tokens and user data
    ↓
_currentUser is set, notifyListeners() called
    ↓
StartupWrapper's Consumer detects auth state change
    ↓
Consumer rebuilds and shows appropriate home screen
    ↓
(No explicit navigation needed)
```

**Important:** `LoginScreen` no longer explicitly navigates. The `StartupWrapper`'s `Consumer` automatically handles the transition.

### 4. **Sub-Screen Navigation**

```
Patient is on PatientHomeScreen
    ↓
User taps "Book Appointment"
    ↓
Navigator.pushNamed('/book-appointment')
    ↓
BookAppointmentScreen is pushed as a route
    ↓
(Navigation stack: [StartupWrapper (home)] → [BookAppointmentScreen (route)])
    ↓
User can tap back to return to PatientHomeScreen
```

### 5. **Logout Flow**

```
User taps Logout button on Profile
    ↓
Confirmation dialog appears
    ↓
User confirms logout
    ↓
authService.logout() is called
    ↓
TokenManager.clearAll() removes all stored data
    ↓
_currentUser = null, notifyListeners() called
    ↓
All routes are popped back to home
    ↓
while (Navigator.of(context).canPop()) {
  Navigator.of(context).pop();
}
    ↓
StartupWrapper's Consumer detects auth state change
    ↓
Consumer rebuilds and shows LoginScreen
```

**Logout Logic Applied To:**
- `PatientHomeScreen` (Profile tab)
- `DoctorHomeScreen` (Profile section)
- `AdminHomeScreen` (Profile section)

---

## Implementation Details

### StartupWrapper Consumer Logic

```dart
Consumer<AuthService>(
  builder: (context, authService, _) {
    // Show splash screen while initializing
    if (!authService.isInitialized) {
      return const SplashScreen();
    }

    // User is authenticated - show appropriate home screen
    if (authService.isAuthenticated) {
      if (authService.isDoctor) {
        return const DoctorHomeScreen();
      } else if (authService.isAdmin) {
        return const AdminHomeScreen();
      } else {
        return const PatientHomeScreen();
      }
    }

    // User not authenticated - show login
    return const LoginScreen();
  },
)
```

### Session Persistence Flow

1. **On App Startup:**
   ```dart
   // StartupWrapper calls
   authService.initialize()
   
   // AuthService.initialize() checks:
   bool hasToken = await TokenManager.isAuthenticated();
   if (hasToken) {
     _currentUser = await TokenManager.getCachedUserData();
   }
   ```

2. **On Login:**
   ```dart
   // After successful login:
   await TokenManager.saveTokens(access, refresh);
   await TokenManager.saveUserData(userProfile);
   _currentUser = userProfile;
   ```

3. **On Logout:**
   ```dart
   // Clear everything:
   await TokenManager.clearAll();
   _currentUser = null;
   ```

---

## Navigation Rules

### ✅ DO:
- Use `StartupWrapper` as the home entry point
- Let the `Consumer` in `StartupWrapper` handle auth-based navigation
- Use named routes (`pushNamed`) for sub-screens only
- Use `popUntil` to clear all routes on logout
- Store tokens in `flutter_secure_storage`

### ❌ DON'T:
- Navigate to home screens using named routes from login
- Use multiple initialization calls
- Store sensitive data in SharedPreferences
- Pop the home screen itself
- Call `initialize()` multiple times

---

## Testing the Implementation

### Test Case 1: Cold Start
1. Uninstall the app or clear app data
2. Launch the app
3. Should see SplashScreen briefly, then LoginScreen
4. ✅ No back button on LoginScreen

### Test Case 2: Login and Navigation
1. From LoginScreen, enter valid credentials
2. ✅ SplashScreen shows briefly
3. ✅ PatientHomeScreen appears (no back button)
4. Tap "Book Appointment"
5. ✅ BookAppointmentScreen appears with back button
6. Tap back
7. ✅ Returns to PatientHomeScreen

### Test Case 3: Logout
1. From PatientHomeScreen, tap Profile
2. Tap "Logout"
3. Confirm logout in dialog
4. ✅ All routes cleared
5. ✅ LoginScreen appears (no back button)

### Test Case 4: Session Persistence
1. Login successfully
2. Fully close the app (swipe from recent apps)
3. Relaunch the app
4. ✅ SplashScreen appears briefly
5. ✅ PatientHomeScreen appears directly (no LoginScreen)
6. User is still logged in

### Test Case 5: Backend Token Expiry
1. Login successfully
2. Wait for access token to expire (or simulate in TokenManager)
3. Navigate to a sub-screen
4. ✅ Should handle gracefully (error handling in ApiClient)

---

## Files Modified

| File | Changes |
|------|---------|
| `lib/main.dart` | Use `StartupWrapper` as home instead of `initialRoute: '/splash'` |
| `lib/services/auth_service.dart` | Add `_isInitialized` flag and update `initialize()` method |
| `lib/screens/auth/startup_wrapper.dart` | **NEW** - Create Auth Guard that checks auth state |
| `lib/screens/auth/splash_screen.dart` | Remove auto-navigation logic (now controlled by StartupWrapper) |
| `lib/screens/auth/login_screen.dart` | Remove explicit navigation after login (Consumer handles it) |
| `lib/screens/patient/patient_home_screen.dart` | Update logout to clear all routes via loop |
| `lib/screens/doctor/doctor_home_screen.dart` | Update logout to clear all routes via loop |
| `lib/screens/admin/admin_home_screen.dart` | Update logout to clear all routes via loop |

---

## Key Improvements

### Before (Old Navigation)
```
- SplashScreen auto-navigates every time
- Multiple navigation calls for login/logout
- No consistent auth check at startup
- Navigation state inconsistent
- Back button issues on home screens
```

### After (New Navigation)
```
✓ Single StartupWrapper handles all auth navigation
✓ Auth check happens once at startup
✓ SplashScreen shown only during initialization
✓ Consistent navigation state via Provider
✓ Home screens have no back button
✓ Clean logout flow with complete stack clearing
✓ Session persistence automatic
```

---

## Troubleshooting

### Issue: User sees SplashScreen then back to LoginScreen
**Cause:** Token validation failed or user is not authenticated
**Solution:** Check TokenManager and ensure tokens are being saved correctly

### Issue: Back button appears on PatientHomeScreen
**Cause:** PatientHomeScreen is pushed as a named route instead of shown by Consumer
**Solution:** Verify login doesn't use `pushNamed` to home screen; let Consumer handle it

### Issue: Logout doesn't return to LoginScreen
**Cause:** `_currentUser` is not being cleared or notifyListeners not called
**Solution:** Verify `authService.logout()` is called and contains `notifyListeners()`

### Issue: User is logged out on app restart
**Cause:** Tokens not being saved to secure storage
**Solution:** Verify `TokenManager.saveTokens()` and `TokenManager.saveUserData()` are called after successful login

---

## Future Enhancements

1. **Token Refresh:** Implement automatic token refresh before expiry
2. **Biometric Auth:** Add fingerprint/face recognition for quick login
3. **Error Recovery:** Add retry logic for failed authentication
4. **Analytics:** Track navigation events for user behavior analysis
5. **Deep Linking:** Handle app links that route to specific screens
6. **Multi-Device:** Invalidate tokens on other devices when logging in on a new device

---

## References

- Flutter Navigation Documentation: https://flutter.dev/docs/development/ui/navigation
- Provider Documentation: https://pub.dev/packages/provider
- Flutter Secure Storage: https://pub.dev/packages/flutter_secure_storage
- JWT Token Management: https://jwt.io/
