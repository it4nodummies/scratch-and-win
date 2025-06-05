import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/constants/app_constants.dart';

/// Service for handling authentication-related operations.
class AuthService {
  /// Default PIN code used when no PIN is set.
  static const String defaultPin = '1234';

  /// Retrieves the stored PIN code.
  /// 
  /// Returns the stored PIN if available, otherwise returns the default PIN.
  Future<String> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.pinStorageKey) ?? defaultPin;
  }

  /// Stores a new PIN code.
  /// 
  /// Returns true if the PIN was successfully stored, false otherwise.
  Future<bool> setPin(String pin) async {
    if (pin.length != AppConstants.defaultPinLength) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(AppConstants.pinStorageKey, pin);
  }

  /// Validates if the provided PIN matches the stored PIN.
  /// 
  /// Returns true if the PIN is valid, false otherwise.
  Future<bool> validatePin(String pin) async {
    final storedPin = await getPin();
    return pin == storedPin;
  }

  /// Resets the PIN to the default value.
  /// 
  /// Returns true if the PIN was successfully reset, false otherwise.
  Future<bool> resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(AppConstants.pinStorageKey, defaultPin);
  }
}