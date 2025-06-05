import 'package:flutter/foundation.dart';
import '../repositories/data_repository.dart';

/// Provider for managing authentication state.
class AuthProvider extends ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _isAuthenticated;

  /// Whether an authentication operation is in progress.
  bool get isLoading => _isLoading;

  /// Error message from the last authentication operation.
  String get errorMessage => _errorMessage;

  /// Attempts to authenticate with the provided PIN.
  /// 
  /// Returns true if authentication was successful, false otherwise.
  Future<bool> authenticate(String pin) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final storedPin = await _dataRepository.getPin();
      final isValid = pin == storedPin;
      _isAuthenticated = isValid;

      if (!isValid) {
        _errorMessage = 'PIN non valido. Riprova.';
      }

      return isValid;
    } catch (e) {
      _errorMessage = 'Si è verificato un errore. Riprova più tardi.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the PIN to a new value.
  /// 
  /// Returns true if the PIN was successfully changed, false otherwise.
  Future<bool> changePin(String currentPin, String newPin) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final storedPin = await _dataRepository.getPin();
      final isValid = currentPin == storedPin;

      if (!isValid) {
        _errorMessage = 'PIN attuale non valido.';
        return false;
      }

      final success = await _dataRepository.setPin(newPin);

      if (!success) {
        _errorMessage = 'Impossibile cambiare il PIN.';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Si è verificato un errore. Riprova più tardi.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs the user out.
  void signOut() {
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Resets the error message.
  void resetError() {
    _errorMessage = '';
    notifyListeners();
  }
}
