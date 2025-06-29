import 'dart:convert';
import '../services/database_service.dart';

/// Repository for managing application data.
/// 
/// This class provides a clean interface for the application to interact with the data layer.
/// It abstracts the database operations and provides methods for managing configuration,
/// prizes, sessions, and prize history.
class DataRepository {
  final DatabaseService _databaseService = DatabaseService();

  /// Gets a configuration value by key.
  Future<String?> getConfigValue(String key) async {
    return await _databaseService.getConfigValue(key);
  }

  /// Sets a configuration value.
  Future<void> setConfigValue(String key, String value) async {
    await _databaseService.setConfigValue(key, value);
  }

  /// Delete the prize history
  Future<void> deletePrizeHistory() async {
    await _databaseService.deleteAllPrizeHistory();
  }

  /// Gets the PIN code.
  Future<String> getPin() async {
    final pin = await _databaseService.getConfigValue('pin_code');
    return pin ?? '1234'; // Default PIN if none is set
  }

  /// Sets the PIN code.
  Future<bool> setPin(String pin) async {
    try {
      await _databaseService.setConfigValue('pin_code', pin);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the scratch card count.
  Future<int> getScratchCardCount() async {
    final countStr = await _databaseService.getConfigValue('scratch_card_count');
    return int.tryParse(countStr ?? '1') ?? 1; // Default count if none is set
  }

  /// Sets the scratch card count.
  Future<bool> setScratchCardCount(int count) async {
    try {
      await _databaseService.setConfigValue('scratch_card_count', count.toString());
      // Also update the remaining scratch cards to match the new total
      await _databaseService.setConfigValue('remaining_scratch_cards', count.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the remaining scratch cards count.
  Future<int> getRemainingScratcchCards() async {
    final countStr = await _databaseService.getConfigValue('remaining_scratch_cards');
    return int.tryParse(countStr ?? '0') ?? 0; // Default to 0 if none is set
  }

  /// Sets the remaining scratch cards count.
  Future<bool> setRemainingScratcchCards(int count) async {
    try {
      await _databaseService.setConfigValue('remaining_scratch_cards', count.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Decrements the remaining scratch cards count by 1.
  Future<bool> decrementRemainingScratcchCards() async {
    try {
      final currentCount = await getRemainingScratcchCards();
      if (currentCount > 0) {
        await setRemainingScratcchCards(currentCount - 1);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Aliases with correct spelling for backward compatibility
  Future<int> getRemainingScrachCards() => getRemainingScratcchCards();
  Future<bool> setRemainingScrachCards(int count) => setRemainingScratcchCards(count);
  Future<bool> decrementRemainingScrachCards() => decrementRemainingScratcchCards();

  /// Gets all prizes.
  Future<List<Map<String, dynamic>>> getAllPrizes() async {
    return await _databaseService.getAllPrizes();
  }

  /// Adds a new prize.
  Future<bool> addPrize(String name, double probability) async {
    try {
      await _databaseService.addPrize(name, probability);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates an existing prize.
  Future<bool> updatePrize(int id, String name, double probability) async {
    try {
      final result = await _databaseService.updatePrize(id, name, probability);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a prize.
  Future<bool> deletePrize(int id) async {
    try {
      final result = await _databaseService.deletePrize(id);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// Starts a new session.
  Future<int?> startSession(int totalAttempts) async {
    try {
      return await _databaseService.startSession(totalAttempts);
    } catch (e) {
      return null;
    }
  }

  /// Updates a session with attempts used.
  Future<bool> updateSessionAttempts(int sessionId, int attemptsUsed) async {
    try {
      final result = await _databaseService.updateSessionAttempts(sessionId, attemptsUsed);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// Ends a session.
  Future<bool> endSession(int sessionId) async {
    try {
      final result = await _databaseService.endSession(sessionId);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// Gets the active session, if any.
  Future<Map<String, dynamic>?> getActiveSession() async {
    return await _databaseService.getActiveSession();
  }

  /// Records a prize win in the history.
  Future<bool> recordPrizeWin(int sessionId, int? prizeId, String prizeName, [String? customer]) async {
    try {
      await _databaseService.recordPrizeWin(sessionId, prizeId, prizeName, customer);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets all prize history.
  /// TODO
  /// cambiare i dati di ritorno con un COUNT dei premi per ID
  Future<List<Map<String, dynamic>>> getPrizeHistory() async {
    return await _databaseService.getPrizeHistory();
  }

  /// Exports all data as a JSON string.
  Future<String> exportDataAsJson() async {
    try {
      final data = await _databaseService.exportData();
      return jsonEncode(data);
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// Validates that the sum of all prize probabilities is less than or equal to 100%.
  Future<bool> validateProbabilities() async {
    final prizes = await getAllPrizes();
    double total = 0;
    for (var prize in prizes) {
      total += prize['probability'] as double;
    }
    return total <= 100.0;
  }
}
