import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/auth_provider.dart';
import '../../core/models/session_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../config/routes.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  int _scratchCardCount = AppConstants.defaultScratchCardCount;

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);

    if (!authProvider.isAuthenticated) {
      // Redirect to auth screen if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.auth);
      });
      // Return loading indicator while redirecting
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If session is active and screen is locked, show locked screen
    if (sessionProvider.isSessionActive && sessionProvider.isScreenLocked) {
      return _buildLockedScreen(context, sessionProvider);
    }

    return AppScaffold(
      title: 'Pannello Operatore',
      actions: [
        if (sessionProvider.isSessionActive)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Termina sessione',
            onPressed: () {
              _showEndSessionDialog(context, sessionProvider);
            },
          ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to settings screen
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            // Sign out and navigate to auth screen
            authProvider.signOut();
            Navigator.pushReplacementNamed(context, AppRoutes.auth);
          },
        ),
      ],
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(sessionProvider),
        tablet: _buildTabletLayout(sessionProvider),
      ),
    );
  }

  Widget _buildMobileLayout(SessionProvider sessionProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sessionProvider.isSessionActive) 
          _buildSessionStatus(sessionProvider),
        _buildScratchCardCounter(sessionProvider),
        const SizedBox(height: 24),
        _buildStartButton(sessionProvider),
      ],
    );
  }

  Widget _buildTabletLayout(SessionProvider sessionProvider) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              if (sessionProvider.isSessionActive) 
                _buildSessionStatus(sessionProvider),
              Expanded(child: _buildScratchCardCounter(sessionProvider)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildStartButton(sessionProvider),
        ),
      ],
    );
  }

  Widget _buildSessionStatus(SessionProvider sessionProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCard(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Column(
          children: [
            const SectionTitle(title: 'Sessione Attiva'),
            Text(
              'Tentativi rimanenti: ${sessionProvider.attemptsRemaining}/${sessionProvider.totalAttempts}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context, 
                  AppRoutes.scratchCard, 
                  arguments: sessionProvider.attemptsRemaining
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continua Sessione'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedScreen(BuildContext context, SessionProvider sessionProvider) {
    return AppScaffold(
      title: 'Sessione Bloccata',
      actions: [
        IconButton(
          icon: const Icon(Icons.lock_open),
          tooltip: 'Sblocca schermo',
          onPressed: () {
            sessionProvider.unlockScreen();
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Termina sessione',
          onPressed: () {
            _showEndSessionDialog(context, sessionProvider);
          },
        ),
      ],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Tentativi Esauriti',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.noMoreAttemptsMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (sessionProvider.sessionPrizes.isNotEmpty) ...[
              const SectionTitle(title: 'Premi Vinti'),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: sessionProvider.sessionPrizes.length,
                  itemBuilder: (context, index) {
                    final prize = sessionProvider.sessionPrizes[index];
                    return ListTile(
                      leading: const Icon(Icons.emoji_events, color: Colors.amber),
                      title: Text(prize['name']),
                      subtitle: Text(prize['value']),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                sessionProvider.endSession();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Termina Sessione'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context, SessionProvider sessionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminare la sessione?'),
        content: const Text(
          'Sei sicuro di voler terminare la sessione corrente? '
          'Tutti i dati della sessione andranno persi.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              sessionProvider.endSession();
              Navigator.of(context).pop();
            },
            child: const Text('Termina'),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchCardCounter(SessionProvider sessionProvider) {
    // If session is active, disable the counter
    final bool isEnabled = !sessionProvider.isSessionActive;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SectionTitle(title: 'Numero di Gratta e Vinci'),
          const SizedBox(height: 16),
          Text(
            sessionProvider.isSessionActive
                ? 'Sessione attiva con ${sessionProvider.totalAttempts} tentativi'
                : 'Seleziona quanti gratta e vinci il cliente può utilizzare:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: isEnabled && _scratchCardCount > 1
                    ? () {
                        setState(() {
                          _scratchCardCount--;
                        });
                      }
                    : null,
                iconSize: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                '$_scratchCardCount',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(32),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: isEnabled && _scratchCardCount < 20
                    ? () {
                        setState(() {
                          _scratchCardCount++;
                        });
                      }
                    : null,
                iconSize: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(SessionProvider sessionProvider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionTitle(
            title: sessionProvider.isSessionActive ? 'Sessione in Corso' : 'Inizia Sessione'
          ),
          const SizedBox(height: 16),
          Text(
            sessionProvider.isSessionActive
                ? 'Una sessione è già attiva. Puoi continuarla o terminarla.'
                : 'Premi il pulsante per iniziare la sessione di gioco:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (sessionProvider.isSessionActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.scratchCard, 
                      arguments: sessionProvider.attemptsRemaining
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continua'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showEndSessionDialog(context, sessionProvider);
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Termina'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () {
                // Start a new session and navigate to scratch card screen
                sessionProvider.startSession(_scratchCardCount);
                Navigator.pushNamed(
                  context, 
                  AppRoutes.scratchCard, 
                  arguments: _scratchCardCount
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Inizia Gioco'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
