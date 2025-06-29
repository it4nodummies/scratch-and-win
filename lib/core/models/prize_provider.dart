import 'package:flutter/foundation.dart';
import '../repositories/data_repository.dart';

/// Provider for managing prize configurations and history.
class PrizeProvider extends ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  List<Map<String, dynamic>> _prizes = [];
  List<Map<String, dynamic>> _prizeHistory = [];

  @override
  void dispose() {
    // Clean up resources before disposing
    _prizes.clear();
    _prizeHistory.clear();
    super.dispose();
  }

  /// The list of configured prizes.
  List<Map<String, dynamic>> get prizes => _prizes;

  /// The history of all prizes won.
  List<Map<String, dynamic>> get prizeHistory => _prizeHistory;

  /// Constructor that loads the prize data from the database.
  PrizeProvider() {
    // Initialize data loading asynchronously
    Future.microtask(() async {
      await loadPrizeData();
      // Recalculate probabilities to ensure they are up-to-date
      await recalculateProbabilities();
    });
  }

  /// Loads prize configurations and history from persistent storage.
  Future<void> loadPrizeData() async {
    try {
      // Load prize configurations
      _prizes = await _dataRepository.getAllPrizes();

      // Load prize history
      _prizeHistory = await _dataRepository.getPrizeHistory();

      notifyListeners();
    } catch (e) {
      // Handle error (could add logging here)
      print('Error loading prize data: $e');
    }
  }

  /// Calculates the probability of a prize based on its remaining occurrences and the remaining scratch cards.
  Future<double> calculateProbability(int maxOccurrences, int currentOccurrences) async {
    final remainingOccurrences = maxOccurrences - currentOccurrences;
    final remainingCards = await _dataRepository.getRemainingScratcchCards();
    if (remainingCards <= 0 || remainingOccurrences <= 0) return 0.0;

    // Calculate probability as (remainingOccurrences / remainingCards) * 100
    return (remainingOccurrences / remainingCards) * 100;
  }

  /// Adds a new prize configuration.
  Future<void> addPrize(String name, int maxOccurrences) async {
    // For new prizes, current occurrences is 0
    final probability = await calculateProbability(maxOccurrences, 0);

    final success = await _dataRepository.addPrize(name, probability, maxOccurrences);
    if (success) {
      await loadPrizeData(); // Reload prizes from database
    }
  }

  /// Updates an existing prize configuration.
  Future<void> updatePrize(int id, String name, int maxOccurrences) async {
    // Get the current occurrences for this prize
    int currentOccurrences = 0;
    for (var prize in _prizes) {
      if (prize['id'] == id) {
        currentOccurrences = prize['current_occurrences'] as int;
        break;
      }
    }

    // Calculate probability automatically
    final probability = await calculateProbability(maxOccurrences, currentOccurrences);

    final success = await _dataRepository.updatePrize(id, name, probability, maxOccurrences);
    if (success) {
      await loadPrizeData(); // Reload prizes from database
    }
  }

  /// Deletes a prize configuration.
  Future<void> deletePrize(int id) async {
    final success = await _dataRepository.deletePrize(id);
    if (success) {
      await loadPrizeData(); // Reload prizes from database
    }
  }

  /// Records a prize win in the history.
  Future<void> recordPrizeWin(String prizeName, String customer) async {
    // Find the prize ID if it exists
    int? prizeId;
    for (var prize in _prizes) {
      if (prize['name'] == prizeName) {
        prizeId = prize['id'] as int;
        break;
      }
    }

    // Get the active session or create a new one if none exists
    int? sessionId;
    final activeSession = await _dataRepository.getActiveSession();
    if (activeSession != null) {
      sessionId = activeSession['id'] as int;
    } else {
      // Default to 1 attempt if no active session
      sessionId = await _dataRepository.startSession(1);
    }

    if (sessionId != null) {
      await _dataRepository.recordPrizeWin(sessionId, prizeId, prizeName, customer);

      // Recalculate probabilities after a prize is won
      await recalculateProbabilities();

      await loadPrizeData(); // Reload prize history
    }
  }

  /// Clears all prize history.
  Future<void> clearHistory() async {
    await _dataRepository.deletePrizeHistory();

    await loadPrizeData();
    notifyListeners();
  }

  /// Validates that the sum of all prize probabilities is less than or equal to 100%.
  Future<bool> validateProbabilities() async {
    return await _dataRepository.validateProbabilities();
  }

  /// Recalculates probabilities for all prizes based on max occurrences and total scratch cards.
  Future<bool> recalculateProbabilities() async {
    final success = await _dataRepository.recalculateProbabilities();
    if (success) {
      await loadPrizeData(); // Reload prizes from database
    }
    return success;
  }

  /// Checks if a prize has reached its maximum occurrences.
  bool hasPrizeReachedMaxOccurrences(String prizeName) {
    for (var prize in _prizes) {
      if (prize['name'] == prizeName) {
        final int maxOccurrences = prize['max_occurrences'] as int;
        final int currentOccurrences = prize['current_occurrences'] as int;
        return currentOccurrences >= maxOccurrences;
      }
    }
    return false; // Prize not found, assume it hasn't reached max occurrences
  }

  /// Gets the available prizes (those that haven't reached their maximum occurrences).
  List<Map<String, dynamic>> get availablePrizes {
    return _prizes.where((prize) {
      final int maxOccurrences = prize['max_occurrences'] as int;
      final int currentOccurrences = prize['current_occurrences'] as int;
      return currentOccurrences < maxOccurrences;
    }).toList();
  }
}
