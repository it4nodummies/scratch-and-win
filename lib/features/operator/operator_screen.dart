import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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
  void dispose() {
    // Remove the _pinController disposal code since it's no longer a class member
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      // Redirect to auth screen if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a 'mounted' check to ensure the widget is still in the tree
        // before attempting to navigate. This prevents errors during
        // rapid screen transitions.
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.auth);
        }
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (sessionProvider.isSessionActive)
                  _buildSessionStatus(sessionProvider),
                _buildScratchCardCounter(sessionProvider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Center(
            child: _buildStartButton(sessionProvider),
          ),
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
            SectionTitle(title: 'Sessione Attiva'),
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
    body: LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500, // Makes it comfortable on large screens
                minHeight: constraints.maxHeight * 0.8, // Optionally adjust minHeight
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    SectionTitle(title: 'Premi Vinti'),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: sessionProvider.sessionPrizes.length,
                        itemBuilder: (context, index) {
                          final prize = sessionProvider.sessionPrizes[index];
                          return ListTile(
                            leading: const Icon(Icons.emoji_events, color: Colors.amber),
                            title: Text(prize['name'] ?? ''),
                            subtitle: Text(prize['value'] ?? ''),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // _showPinVerificationDialog(context, sessionProvider);
                      _showEndSessionDialog(context, sessionProvider);
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
          ),
        );
      },
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
              Navigator.of(context).pop();
              _showPinVerificationDialog(context, sessionProvider);
            },
            child: const Text('Termina'),
          ),
        ],
      ),
    );
  }

  void _showPinVerificationDialog(BuildContext context, SessionProvider sessionProvider) {
    // Create a LOCAL controller for this dialog only
    final TextEditingController pinController = TextEditingController();
    bool isVerifying = false;
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Inserisci PIN'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inserisci il PIN per terminare la sessione'),
                  const SizedBox(height: 16),
                  PinCodeTextField(
                    appContext: context,
                    length: AppConstants.defaultPinLength,
                    controller: pinController, // Use local controller
                    obscureText: true,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.grey.shade300,
                      selectedColor: Theme.of(context).colorScheme.primary,
                    ),
                    keyboardType: TextInputType.number,
                    enableActiveFill: true,
                    onChanged: (value) {
                      setState(() {
                        errorMessage = '';
                      });
                    },
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (isVerifying) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isVerifying
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text('Annulla'),
              ),
              TextButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        if (pinController.text.length < AppConstants.defaultPinLength) {
                          setState(() {
                            errorMessage = 'Inserisci il PIN completo';
                          });
                          return;
                        }

                        setState(() {
                          isVerifying = true;
                        });

                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final success = await authProvider.authenticate(pinController.text);

                        if (success) {
                          sessionProvider.endSession();
                          Navigator.of(dialogContext).pop();
                        } else {
                          setState(() {
                            isVerifying = false;
                            errorMessage = 'PIN non valido. Riprova.';
                          });
                        }
                      },
                child: const Text('Conferma'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose the LOCAL controller when dialog closes
      pinController.dispose();
    });
  }

  Widget _buildScratchCardCounter(SessionProvider sessionProvider) {
    // If session is active, disable the counter
    final bool isEnabled = !sessionProvider.isSessionActive;

    return AppCard(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionTitle(title: 'Numero di Gratta e Vinci'),
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
                  fontSize: 32,
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
