import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../shared/constants/app_constants.dart';
import '../repositories/data_repository.dart';
import 'prize_provider.dart';

/// Provider for managing game session state.
class SessionProvider extends ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  bool _isSessionActive = false;
  int _totalAttempts = AppConstants.defaultScratchCardCount;
  int _attemptsRemaining = AppConstants.defaultScratchCardCount;
  bool _isScreenLocked = false;
  List<Map<String, dynamic>> _sessionPrizes = [];
  int? _currentSessionId;

  @override
  void dispose() {
    // Clean up resources before disposing
    _sessionPrizes.clear();
    super.dispose();
  }

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
  /// Also decrements the remaining scratch cards count in the database.
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

      // Decrement the remaining scratch cards count
      await _dataRepository.decrementRemainingScratcchCards();

      notifyListeners();
    }
  }

  /// Adds a prize to the session prizes list.
  /// 
  /// The [context] parameter is required to access the PrizeProvider.
  /// If [context] is null, the PrizeProvider will not be updated.
  Future<void> addPrize(String name, String value, {BuildContext? context}) async {
    final timestamp = DateTime.now().toIso8601String();

    _sessionPrizes.add({
      'name': name,
      'value': value,
      'timestamp': timestamp,
    });

    // Record prize win in the database
    if (_currentSessionId != null) {
      // Find the prize ID by name to ensure current_occurrences is updated
      int? prizeId;
      final prizes = await _dataRepository.getAllPrizes();
      for (var prize in prizes) {
        if (prize['name'] == name) {
          prizeId = prize['id'] as int;
          break;
        }
      }

      await _dataRepository.recordPrizeWin(
        _currentSessionId!,
        prizeId, // Now we pass the actual prizeId if found
        name
      );

      // Update the PrizeProvider if context is provided
      if (context != null) {
        try {
          final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);
          await prizeProvider.loadPrizeData(); // Reload prize data to reflect updated current_occurrences
        } catch (e) {
          print('Error updating PrizeProvider: $e');
        }
      }
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

      // Ensure prize data is up-to-date by recalculating probabilities
      // This will update current_occurrences values in the session
      try {
        await _dataRepository.recalculateProbabilities();
      } catch (probError) {
        print('Error recalculating probabilities: $probError');
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

  /// Resets the session state to default values.
  /// This should be called after resetting the database.
  Future<bool> resetSession() async {
    try {
      // End any active session
      if (_isSessionActive && _currentSessionId != null) {
        await _dataRepository.endSession(_currentSessionId!);
      }

      // Reset session state to defaults
      _isSessionActive = false;
      _isScreenLocked = false;
      _sessionPrizes = [];
      _currentSessionId = null;

      // Get the default scratch card count from the reset database
      final defaultCount = await _dataRepository.getScratchCardCount();
      _totalAttempts = defaultCount;
      _attemptsRemaining = defaultCount;

      notifyListeners();
      return true;
    } catch (e) {
      print('Error resetting session: $e');
      return false;
    }
  }
}
