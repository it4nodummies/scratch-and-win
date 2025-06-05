import 'package:flutter/foundation.dart';
import '../../shared/constants/app_constants.dart';
import '../repositories/data_repository.dart';

/// Provider for managing game session state.
class SessionProvider extends ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  bool _isSessionActive = false;
  int _totalAttempts = AppConstants.defaultScratchCardCount;
  int _attemptsRemaining = AppConstants.defaultScratchCardCount;
  bool _isScreenLocked = false;
  List<Map<String, dynamic>> _sessionPrizes = [];
  int? _currentSessionId;

  /// Whether a game session is currently active.
  bool get isSessionActive => _isSessionActive;

  /// The total number of attempts allowed in the current session.
  int get totalAttempts => _totalAttempts;

  /// The number of attempts remaining in the current session.
  int get attemptsRemaining => _attemptsRemaining;

  /// Whether the screen is locked (when attempts are exhausted).
  bool get isScreenLocked => _isScreenLocked;

  /// The prizes won in the current session.
  List<Map<String, dynamic>> get sessionPrizes => _sessionPrizes;

  /// Starts a new game session with the specified number of attempts.
  Future<void> startSession(int attempts) async {
    _isSessionActive = true;
    _totalAttempts = attempts;
    _attemptsRemaining = attempts;
    _isScreenLocked = false;
    _sessionPrizes = [];

    // Create a new session in the database
    _currentSessionId = await _dataRepository.startSession(attempts);

    notifyListeners();
  }

  /// Decrements the number of attempts remaining and checks if the screen should be locked.
  Future<void> decrementAttempts() async {
    if (_attemptsRemaining > 0) {
      _attemptsRemaining--;
      if (_attemptsRemaining == 0) {
        _isScreenLocked = true;
      }

      // Update session attempts in the database
      if (_currentSessionId != null) {
        await _dataRepository.updateSessionAttempts(
          _currentSessionId!, 
          _totalAttempts - _attemptsRemaining
        );
      }

      notifyListeners();
    }
  }

  /// Adds a prize to the session prizes list.
  Future<void> addPrize(String name, String value) async {
    final timestamp = DateTime.now().toIso8601String();

    _sessionPrizes.add({
      'name': name,
      'value': value,
      'timestamp': timestamp,
    });

    // Record prize win in the database
    if (_currentSessionId != null) {
      await _dataRepository.recordPrizeWin(
        _currentSessionId!,
        null, // prizeId is null since we're just using name
        name
      );
    }

    notifyListeners();
  }

  /// Ends the current game session.
  Future<void> endSession() async {
    _isSessionActive = false;
    _isScreenLocked = false;

    // End session in the database
    if (_currentSessionId != null) {
      await _dataRepository.endSession(_currentSessionId!);
      _currentSessionId = null;
    }

    notifyListeners();
  }

  /// Unlocks the screen (for operator use).
  void unlockScreen() {
    _isScreenLocked = false;
    notifyListeners();
  }


  /// Loads the session state from persistent storage.
  Future<void> loadSessionState() async {
    try {
      // Get default scratch card count from configuration
      final defaultCount = await _dataRepository.getScratchCardCount();
      _totalAttempts = defaultCount;
      _attemptsRemaining = defaultCount;

      // Check for active session in the database
      final activeSession = await _dataRepository.getActiveSession();

      if (activeSession != null) {
        _isSessionActive = true;
        _currentSessionId = activeSession['id'] as int;
        _totalAttempts = activeSession['total_attempts'] as int;
        _attemptsRemaining = _totalAttempts - (activeSession['attempts_used'] as int);
        _isScreenLocked = _attemptsRemaining <= 0;

        // Load prize history for this session
        try {
          final history = await _dataRepository.getPrizeHistory();
          _sessionPrizes = history.map((prize) {
            return {
              'name': prize['prize_name'],
              'value': prize['prize_value'] ?? '', // Use prize_value if available, empty string otherwise
              'timestamp': prize['timestamp'],
            };
          }).toList();
        } catch (historyError) {
          // If we can't load the prize history, continue with an empty list
          print('Error loading prize history: $historyError');
          _sessionPrizes = [];
        }
      } else {
        _isSessionActive = false;
        _isScreenLocked = false;
        _sessionPrizes = [];
        _currentSessionId = null;
      }

      notifyListeners();
    } catch (e) {
      // Handle error with fallback to default values
      print('Error loading session state: $e');
      // Set safe default values
      _isSessionActive = false;
      _isScreenLocked = false;
      _sessionPrizes = [];
      _currentSessionId = null;
      _totalAttempts = AppConstants.defaultScratchCardCount;
      _attemptsRemaining = AppConstants.defaultScratchCardCount;

      notifyListeners();
    }
  }
}
