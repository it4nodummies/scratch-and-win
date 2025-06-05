import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/session_provider.dart';
import '../../core/models/prize_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import 'scratch_card_widget.dart';
import 'game_logic.dart';
import 'confetti_overlay.dart';

class ScratchCardScreen extends StatefulWidget {
  final int attemptsRemaining;

  const ScratchCardScreen({
    super.key,
    required this.attemptsRemaining,
  });

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  late int _attemptsRemaining;
  bool _isScratched = false;
  bool _isWinner = false;
  String _prizeName = '';
  String _prizeValue = '';
  bool _showConfetti = false;
  late GameLogic _gameLogic;

  @override
  void initState() {
    super.initState();
    // Initialize from widget parameter, but will be managed by SessionProvider
    _attemptsRemaining = widget.attemptsRemaining;

    // Ensure we have an active session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);

      // Initialize game logic
      _gameLogic = GameLogic(prizeProvider);

      if (!sessionProvider.isSessionActive) {
        // If no active session, start one with the provided attempts
        sessionProvider.startSession(_attemptsRemaining);
      }
    });
  }

  void _onScratchComplete() {
    // Get the session provider
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    // Use the game logic to determine if the user won
    final result = _gameLogic.determineResult();
    final bool isWinner = result['isWinner'] as bool;
    final String prizeName = result['prizeName'] as String;
    final String prizeValue = result['prizeValue'] as String;

    // Update session state
    sessionProvider.decrementAttempts();
    if (isWinner) {
      sessionProvider.addPrize(prizeName, prizeValue);

      // Start confetti animation for winners
      setState(() {
        _showConfetti = true;
      });
    }

    setState(() {
      _isScratched = true;
      _isWinner = isWinner;
      _prizeName = prizeName;
      _prizeValue = prizeValue;
      _attemptsRemaining = sessionProvider.attemptsRemaining;
    });

    // Show result dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _showResultDialog();
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          _isWinner ? 'Hai vinto!' : 'Non hai vinto',
          style: TextStyle(
            color: _isWinner ? AppTheme.successColor : AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          _isWinner 
              ? 'Congratulazioni! Hai vinto $_prizeName!' 
              : 'Mi dispiace, non hai vinto questa volta.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Stop confetti animation
              if (_showConfetti) {
                setState(() {
                  _showConfetti = false;
                });
              }

              // Reset for next attempt if attempts remain
              if (_attemptsRemaining > 0) {
                setState(() {
                  _isScratched = false;
                  _isWinner = false;
                  _prizeName = '';
                  _prizeValue = '';
                });
              } else {
                // Show game over dialog when no attempts remain
                _showGameOverDialog();
              }
            },
            child: Text(_attemptsRemaining > 0 ? 'Continua' : 'Fine'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    // Only lock the screen, no need to decrement attempts again as it's already at 0
    if (!sessionProvider.isScreenLocked) {
      // This ensures the screen is locked without decrementing attempts again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sessionProvider.unlockScreen(); // First unlock to ensure we can set it again
        setState(() {
          _attemptsRemaining = 0; // Ensure local state is consistent
        });
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tentativi Esauriti'),
        content: Text(AppConstants.noMoreAttemptsMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to the operator screen
              Navigator.of(context).pushReplacementNamed(AppRoutes.operator);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    // If screen is locked, navigate back to operator screen
    if (sessionProvider.isScreenLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.operator);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppScaffold(
      title: 'Gratta e Vinci',
      actions: [
        IconButton(
          icon: const Icon(Icons.lock),
          tooltip: 'Torna al pannello operatore',
          onPressed: () {
            // Navigate back to the operator screen
            Navigator.of(context).pushReplacementNamed(AppRoutes.operator);
          },
        ),
      ],
      body: Stack(
        children: [
          // Main content
          ResponsiveLayout(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
          ),

          // Confetti overlay
          ConfettiOverlay(
            isPlaying: _showConfetti,
            particleCount: 150,
            duration: AppConstants.longAnimationDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAttemptsCounter(),
        const SizedBox(height: 16),
        Expanded(child: _buildScratchCard()),
        const SizedBox(height: 16),
        _buildPrizeDisplay(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildAttemptsCounter(),
              const SizedBox(height: 16),
              Expanded(child: _buildScratchCard()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildPrizeDisplay(),
        ),
      ],
    );
  }

  Widget _buildAttemptsCounter() {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.confirmation_number),
          const SizedBox(width: 8),
          Text(
            'Tentativi rimanenti: ${sessionProvider.attemptsRemaining}/${sessionProvider.totalAttempts}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.scratchCardBaseColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isScratched
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: _isWinner ? Colors.black : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _isWinner ? 'HAI VINTO!' : 'NON HAI VINTO',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(32),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_isWinner) ...[
                  const SizedBox(height: 8),
                  Text(
                    _prizeName,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(24),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          )
        : ScratchCardWidget(
            threshold: 0.5, // Reveal after 70% is scratched
            onScratchComplete: _onScratchComplete,
            playSounds: true,
            autoShowResult: true, // Show result automatically when threshold is reached
            child: Center(
              child: Text(
                'Gratta qui!',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPrizeDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Risultato',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: _isScratched
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                          size: 48,
                          color: _isWinner ? AppTheme.successColor : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isWinner ? 'Hai vinto!' : 'Non hai vinto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isWinner ? AppTheme.successColor : AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (_isWinner) ...[
                          const SizedBox(height: 8),
                          Text(
                            _prizeName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _prizeValue,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ],
                    )
                  : const Text(
                      'Gratta il biglietto per vedere il risultato',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
