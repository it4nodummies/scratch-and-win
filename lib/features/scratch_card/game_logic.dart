import 'dart:math';
import 'package:intl/intl.dart';
import '../../core/models/prize_provider.dart';
import '../../core/repositories/data_repository.dart';

/// Service for handling the game logic of the scratch card game.
class GameLogic {
  final PrizeProvider _prizeProvider;
  final Random _random;

  /// Creates a new GameLogic instance.
  /// 
  /// If [random] is provided, it will be used for random number generation.
  /// This is useful for testing.
  GameLogic(this._prizeProvider, {Random? random}) : _random = random ?? Random();

  /// Determines if the user wins a prize based on the configured probabilities.
  /// 
  /// Returns a map with the result information:
  /// - 'isWinner': Whether the user won a prize
  /// - 'prizeName': The name of the prize won (empty if not a winner)
  /// - 'prizeValue': The value of the prize won (empty if not a winner)
  Map<String, dynamic> determineResult() {
    // Get the list of available prizes (those that haven't reached their maximum occurrences)
    final availablePrizes = _prizeProvider.availablePrizes;

    // If there are no available prizes, the user can't win
    if (availablePrizes.isEmpty) {
      return {
        'isWinner': false,
        'prizeName': '',
        'prizeValue': '',
      };
    }

    // Calculate the total probability of winning
    double totalWinProbability = 0;
    for (final prize in availablePrizes) {
      totalWinProbability += prize['probability'] as double;
    }

    // Ensure the total probability doesn't exceed 100%
    if (totalWinProbability > 100) {
      totalWinProbability = 100;
    }

    // Generate a random number between 0 and 100
    final randomValue = _random.nextDouble() * 100;

    // If the random value is greater than the total win probability, the user doesn't win
    if (randomValue > totalWinProbability) {
      return {
        'isWinner': false,
        'prizeName': '',
        'prizeValue': '',
      };
    }

    // The user wins! Determine which prize they won
    double cumulativeProbability = 0;
    for (final prize in availablePrizes) {
      cumulativeProbability += prize['probability'] as double;
      if (randomValue <= cumulativeProbability) {
        // This is the prize the user won
        final prizeName = prize['name'] as String;

        // Generate a more descriptive prize value based on the prize name
        String prizeValue;
        if (prizeName.contains('Sconto')) {
          prizeValue = 'Valido fino al ${_formatDate(DateTime.now().add(const Duration(days: 30)))}';
        } else if (prizeName.contains('Omaggio')) {
          prizeValue = 'Ritira subito in farmacia!';
        } else if (prizeName.contains('€')) {
          prizeValue = 'Buono acquisto';
        } else {
          prizeValue = 'Premio vinto!';
        }

        return {
          'isWinner': true,
          'prizeName': prizeName,
          'prizeValue': prizeValue,
        };
      }
    }

    // This should never happen, but just in case
    return {
      'isWinner': false,
      'prizeName': '',
      'prizeValue': '',
    };
  }

  /// Validates that the prize probabilities are correctly configured.
  /// 
  /// Returns true if the probabilities are valid, false otherwise.
  Future<bool> validateProbabilities() async {
    return await _prizeProvider.validateProbabilities();
  }

  /// Validates that the total number of winning tickets doesn't exceed the total available tickets,
  /// and that all prizes are distributed across the available tickets.
  /// 
  /// Returns true if the configuration is valid, false otherwise.
  Future<bool> validatePrizeDistribution() async {
    // Get the total number of scratch cards
    final dataRepository = DataRepository();
    final totalScratchCards = await dataRepository.getScratchCardCount();

    // Get all prizes
    final prizes = _prizeProvider.prizes;

    // Calculate the total number of winning tickets
    int totalWinningTickets = 0;
    for (final prize in prizes) {
      totalWinningTickets += prize['max_occurrences'] as int;
    }

    // Ensure the total number of winning tickets doesn't exceed the total available tickets
    return totalWinningTickets <= totalScratchCards;
  }

  /// Formats a date in the Italian format (dd/MM/yyyy).
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }
}
