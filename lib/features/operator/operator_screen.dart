import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/models/auth_provider.dart';
import '../../core/models/session_provider.dart';
import '../../core/repositories/data_repository.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({super.key});

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  int _scratchCardCount = AppConstants.defaultScratchCardCount;
  int _remainingTickets = 0;

  @override
  void initState() {
    super.initState();
    _loadRemainingTickets();
  }

  Future<void> _loadRemainingTickets() async {
    final dataRepository = DataRepository();
    final remainingTickets = await dataRepository.getRemainingScratcchCards();
    setState(() {
      _remainingTickets = remainingTickets;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload remaining tickets when dependencies change (e.g., when returning to this screen)
    _loadRemainingTickets();
  }

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
      title: AppLocalizations.of(context).translate('operator_panel'),
      actions: [
        if (sessionProvider.isSessionActive)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).translate('end_session'),
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
            SectionTitle(title: AppLocalizations.of(context).translate('active_session')),
            Text(
              AppLocalizations.of(context).translate('remaining_attempts')
                .replaceAll('{remaining}', sessionProvider.attemptsRemaining.toString())
                .replaceAll('{total}', sessionProvider.totalAttempts.toString()),
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
              label: Text(AppLocalizations.of(context).translate('continue_session')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedScreen(BuildContext context, SessionProvider sessionProvider) {
  return AppScaffold(
    title: AppLocalizations.of(context).translate('session_locked'),
    actions: [
      IconButton(
        icon: const Icon(Icons.lock_open),
        tooltip: AppLocalizations.of(context).translate('unlock_screen'),
        onPressed: () {
          sessionProvider.unlockScreen();
        },
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: AppLocalizations.of(context).translate('end_session'),
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
                    AppLocalizations.of(context).translate('attempts_exhausted'),
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
                    SectionTitle(title: AppLocalizations.of(context).translate('won_prizes')),
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
                    label: Text(AppLocalizations.of(context).translate('end_session')),
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
        title: Text(AppLocalizations.of(context).translate('end_session_question')),
        content: Text(
          AppLocalizations.of(context).translate('end_session_confirmation')
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPinVerificationDialog(context, sessionProvider);
            },
            child: Text(AppLocalizations.of(context).translate('end')),
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
            title: Text(AppLocalizations.of(context).translate('enter_pin')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context).translate('enter_pin_to_end_session')),
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
                child: Text(AppLocalizations.of(context).translate('cancel')),
              ),
              TextButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        if (pinController.text.length < AppConstants.defaultPinLength) {
                          setState(() {
                            errorMessage = AppLocalizations.of(context).translate('enter_complete_pin');
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
                            errorMessage = AppLocalizations.of(context).translate('invalid_pin');
                          });
                        }
                      },
                child: Text(AppLocalizations.of(context).translate('confirm')),
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
          SectionTitle(title: AppLocalizations.of(context).translate('scratch_card_number')),
          const SizedBox(height: 16),
          Text(
            sessionProvider.isSessionActive
                ? AppLocalizations.of(context).translate('active_session_with_attempts').replaceAll('{attempts}', sessionProvider.totalAttempts.toString())
                : AppLocalizations.of(context).translate('select_scratch_cards'),
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
            title: sessionProvider.isSessionActive 
                ? AppLocalizations.of(context).translate('session_in_progress') 
                : AppLocalizations.of(context).translate('start_session')
          ),
          const SizedBox(height: 16),
          Text(
            sessionProvider.isSessionActive
                ? AppLocalizations.of(context).translate('session_already_active')
                : _remainingTickets <= 0
                    ? AppLocalizations.of(context).translate('no_remaining_tickets')
                    : AppLocalizations.of(context).translate('press_button_to_start'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _remainingTickets <= 0 && !sessionProvider.isSessionActive
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
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
                  label: Text(AppLocalizations.of(context).translate('continue')),
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
                  label: Text(AppLocalizations.of(context).translate('end')),
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
              onPressed: _remainingTickets <= 0 
                ? null 
                : () {
                    // Start a new session and navigate to scratch card screen
                    sessionProvider.startSession(_scratchCardCount);
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.scratchCard, 
                      arguments: _scratchCardCount
                    );
                  },
              icon: const Icon(Icons.play_arrow),
              label: Text(AppLocalizations.of(context).translate('start_game')),
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
