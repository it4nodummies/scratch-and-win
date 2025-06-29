import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/auth_provider.dart';
import '../../core/models/prize_provider.dart';
import '../../core/models/database_schema.dart';
import '../../core/models/session_provider.dart';
import '../../core/repositories/data_repository.dart';
import '../../config/routes.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _totalCardsController = TextEditingController();
  final TextEditingController _remainingCardsController = TextEditingController();
  final DataRepository _dataRepository = DataRepository();

  @override
  void initState() {
    super.initState();
    // Load values from database
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    // Get scratch card count from database
    final scratchCardCount = await _dataRepository.getScratchCardCount();
    final remainingCards = await _dataRepository.getRemainingScratcchCards();

    setState(() {
      _totalCardsController.text = scratchCardCount.toString();
      _remainingCardsController.text = remainingCards.toString();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _totalCardsController.dispose();
    _remainingCardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated) {
      // Prevent multiple redirects and possible crash by checking mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return AppScaffold(
      title: AppLocalizations.of(context).translate('settings'),
      showBackButton: true,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPinSettings(),
          const SizedBox(height: 16),
          _buildTotalCardsSettings(),
          const SizedBox(height: 16),
          _buildPrizeSettings(),
          const SizedBox(height: 16),
          _buildPrizeHistory(),
          const SizedBox(height: 16),
          _buildResetSection(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPinSettings()),
              const SizedBox(width: 16),
              Expanded(child: _buildTotalCardsSettings()),
            ],
          ),
          const SizedBox(height: 16),
          _buildPrizeSettings(),
          const SizedBox(height: 16),
          _buildPrizeHistory(),
          const SizedBox(height: 16),
          _buildResetSection(context),
        ],
      ),
    );
  }

  Widget _buildPinSettings() {
    final authProvider = Provider.of<AuthProvider>(context);
    final TextEditingController _currentPinController = TextEditingController();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: AppLocalizations.of(context).translate('change_pin')),
          TextField(
            controller: _currentPinController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('current_pin'),
              hintText: AppLocalizations.of(context).translate('enter_current_pin'),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('new_pin'),
              hintText: AppLocalizations.of(context).translate('enter_new_pin'),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
          ),
          if (authProvider.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              authProvider.errorMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_currentPinController.text.length != AppConstants.defaultPinLength ||
                  _pinController.text.length != AppConstants.defaultPinLength) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('pin_must_be_4_digits'))),
                );
                return;
              }

              final success = await authProvider.changePin(
                _currentPinController.text,
                _pinController.text,
              );

              if (success) {
                _currentPinController.clear();
                _pinController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('pin_updated_successfully'))),
                );
              }
            },
            child: Text(AppLocalizations.of(context).translate('save_pin')),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCardsSettings() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: AppLocalizations.of(context).translate('ticket_management')),
          TextField(
            controller: _totalCardsController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('total_tickets'),
              hintText: AppLocalizations.of(context).translate('enter_total_tickets'),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remainingCardsController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('remaining_tickets'),
              hintText: AppLocalizations.of(context).translate('remaining_tickets_hint'),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Parse the input values
                    final int? totalCards = int.tryParse(_totalCardsController.text);
                    final int? remainingCards = int.tryParse(_remainingCardsController.text);

                    if (totalCards == null || totalCards <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).translate('enter_valid_total_tickets'))),
                      );
                      return;
                    }

                    if (remainingCards == null || remainingCards < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).translate('enter_valid_remaining_tickets'))),
                      );
                      return;
                    }

                    if (remainingCards > totalCards) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).translate('remaining_tickets_cannot_exceed_total'))),
                      );
                      return;
                    }

                    // Save the total card count to database
                    final successTotal = await _dataRepository.setScratchCardCount(totalCards);
                    final successRemaining = await _dataRepository.setRemainingScratcchCards(remainingCards);

                    if (successTotal && successRemaining) {
                      // Recalculate probabilities based on the new total scratch cards
                      final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);
                      await prizeProvider.recalculateProbabilities();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).translate('tickets_updated_probabilities_recalculated'))),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).translate('error_saving'))),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context).translate('save_configuration')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeSettings() {
    final prizeProvider = Provider.of<PrizeProvider>(context);
    final prizes = prizeProvider.prizes;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(title: AppLocalizations.of(context).translate('prize_management')),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  _showAddEditPrizeDialog(context);
                },
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          if (prizes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(AppLocalizations.of(context).translate('no_prizes_configured')),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prizes.length,
              itemBuilder: (context, index) {
                final prize = prizes[index];
                return ListTile(
                  title: Text(prize['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).translate('probability').replaceAll('{probability}', prize['probability'].toStringAsFixed(2))),
                      Text(AppLocalizations.of(context).translate('wins')
                          .replaceAll('{current}', prize['current_occurrences'].toString())
                          .replaceAll('{max}', prize['max_occurrences'].toString())),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showAddEditPrizeDialog(context, index: index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeletePrizeDialog(context, index);
                        },
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          if (prizes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppLocalizations.of(context).translate('total_probability').replaceAll('{probability}', _calculateTotalProbability(prizes).toString()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _calculateTotalProbability(prizes) > 100 
                      ? Theme.of(context).colorScheme.error 
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTotalProbability(List<Map<String, dynamic>> prizes) {
    double total = 0;
    for (var prize in prizes) {
      total += prize['probability'] as double;
    }
    return total;
  }

  void _showAddEditPrizeDialog(BuildContext context, {int? index}) {
    final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController();
    final TextEditingController maxOccurrencesController = TextEditingController();

    // If editing an existing prize, pre-fill the controllers
    if (index != null) {
      final prize = prizeProvider.prizes[index];
      nameController.text = prize['name'] as String;
      maxOccurrencesController.text = (prize['max_occurrences'] as int).toString();
    } else {
      // Default value for new prizes
      maxOccurrencesController.text = '1';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? AppLocalizations.of(context).translate('add_prize') : AppLocalizations.of(context).translate('edit_prize')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('prize_name'),
                hintText: AppLocalizations.of(context).translate('prize_name_example'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maxOccurrencesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('max_wins'),
                hintText: AppLocalizations.of(context).translate('max_wins_example'),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('probability_calculation_info'),
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              // Validate inputs
              final name = nameController.text.trim();
              final maxOccurrencesText = maxOccurrencesController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('enter_prize_name'))),
                );
                return;
              }

              final int? maxOccurrences = int.tryParse(maxOccurrencesText);
              if (maxOccurrences == null || maxOccurrences <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('enter_valid_max_wins'))),
                );
                return;
              }

              // Get total scratch cards to validate max occurrences
              final dataRepository = DataRepository();
              final totalScratchCards = await dataRepository.getScratchCardCount();

              // Calculate total max occurrences across all prizes
              int totalMaxOccurrences = 0;
              for (var prize in prizeProvider.prizes) {
                if (index != null && prize['id'] == prizeProvider.prizes[index]['id']) {
                  // Skip the current prize being edited
                  continue;
                }
                totalMaxOccurrences += prize['max_occurrences'] as int;
              }
              totalMaxOccurrences += maxOccurrences;

              // Check if total max occurrences exceeds total scratch cards
              if (totalMaxOccurrences > totalScratchCards) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('total_prizes_exceed_tickets')
                      .replaceAll('{totalPrizes}', totalMaxOccurrences.toString())
                      .replaceAll('{totalTickets}', totalScratchCards.toString()))),
                );
                return;
              }

              // Save the prize
              if (index == null) {
                // Add new prize
                await prizeProvider.addPrize(name, maxOccurrences);
              } else {
                // Update existing prize
                final prize = prizeProvider.prizes[index];
                await prizeProvider.updatePrize(prize['id'] as int, name, maxOccurrences);
              }

              // Check if total probability exceeds 100%
              if (!(await prizeProvider.validateProbabilities())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).translate('probability_exceeds_100')),
                    backgroundColor: Colors.orange,
                  ),
                );
              }

              // Close the dialog
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );
  }

  void _showDeletePrizeDialog(BuildContext context, int index) {
    final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);
    final prize = prizeProvider.prizes[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete')),
        content: Text('${AppLocalizations.of(context).translate('confirm')} "${prize['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await prizeProvider.deletePrize(prize['id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).translate('prize_deleted'))),
                );
              }
            },
            child: Text(AppLocalizations.of(context).translate('delete')),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeHistory() {
    final prizeProvider = Provider.of<PrizeProvider>(context);
    final history = prizeProvider.prizeHistory;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(title: AppLocalizations.of(context).translate('prize_history')),
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () {
                    _showClearHistoryDialog(context);
                  },
                  color: Theme.of(context).colorScheme.error,
                ),
            ],
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(AppLocalizations.of(context).translate('no_prizes_won')),
              ),
            )
          else
            // Limit the list's height so it's scrollable and doesn't expand infinitely in a Column
            SizedBox(
              height: 300, // Adjust height as appropriate for your UI
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  // Safe date parsing with fallback
                  String formattedDate = '';
                  try {
                    final dateRaw = item[DatabaseSchema.historyTimestampColumn] as String?;
                    if (dateRaw != null) {
                      final date = DateTime.tryParse(dateRaw);
                      if (date != null) {
                        formattedDate =
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                      } else {
                        formattedDate = AppLocalizations.of(context).translate('invalid_date');
                      }
                    } else {
                      formattedDate = AppLocalizations.of(context).translate('missing_date');
                    }
                  } catch (e) {
                    formattedDate = AppLocalizations.of(context).translate('date_error');
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events, color: Colors.amber),
                      title: Text(
                        item[DatabaseSchema.historyPrizeNameColumn]?.toString() ?? AppLocalizations.of(context).translate('unknown_prize'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context).translate('date').replaceAll('{date}', formattedDate)),
                          if (item[DatabaseSchema.historyCustomerColumn] != null)
                            Text(AppLocalizations.of(context).translate('customer').replaceAll('{customer}', item[DatabaseSchema.historyCustomerColumn].toString())),
                        ],
                      ),
                      isThreeLine: item[DatabaseSchema.historyCustomerColumn] != null,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

void _showClearHistoryDialog(BuildContext context) {
  final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context).translate('clear_history')),
          content: isLoading
              ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
              : Text(AppLocalizations.of(context).translate('confirm_clear_history')),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      await prizeProvider.clearHistory();
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).translate('history_cleared'))),
                        );
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(AppLocalizations.of(context).translate('delete')),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildResetSection(BuildContext context) {
  return AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: AppLocalizations.of(context).translate('total_reset')),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).translate('reset_warning'),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.warning_amber_rounded),
          label: Text(AppLocalizations.of(context).translate('total_reset')),
          onPressed: () {
            _showResetConfirmationDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

void _showResetConfirmationDialog(BuildContext context) {
  final dataRepository = DataRepository();
  final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
  final prizeProvider = Provider.of<PrizeProvider>(context, listen: false);
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context).translate('confirm_total_reset')),
          content: isLoading
              ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
              : Text(
                  AppLocalizations.of(context).translate('reset_confirmation_message'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      // Reset all data
                      final success = await dataRepository.resetAllData();

                      // Reset session state
                      if (success) {
                        await sessionProvider.resetSession();

                        // Reload prize data
                        await prizeProvider.loadPrizeData();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).translate('reset_completed'))),
                          );

                          // Reload settings
                          if (context.mounted) {
                            _loadSettings();
                          }
                        }
                      } else {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).translate('reset_error'))),
                          );
                        }
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(AppLocalizations.of(context).translate('total_reset')),
            ),
          ],
        ),
      );
    },
  );
}
}
