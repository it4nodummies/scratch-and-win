import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/auth_provider.dart';
import '../../core/models/prize_provider.dart';
import '../../core/models/database_schema.dart';
import '../../core/repositories/data_repository.dart';
import '../../config/routes.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/responsive_layout.dart';

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
      title: 'Impostazioni',
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
          const SectionTitle(title: 'Cambia PIN'),
          TextField(
            controller: _currentPinController,
            decoration: const InputDecoration(
              labelText: 'PIN attuale (4 cifre)',
              hintText: 'Inserisci il PIN attuale',
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'Nuovo PIN (4 cifre)',
              hintText: 'Inserisci un nuovo PIN',
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
                  const SnackBar(content: Text('Il PIN deve essere di 4 cifre')),
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
                  const SnackBar(content: Text('PIN aggiornato con successo')),
                );
              }
            },
            child: const Text('Salva PIN'),
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
          const SectionTitle(title: 'Gestione Biglietti'),
          TextField(
            controller: _totalCardsController,
            decoration: const InputDecoration(
              labelText: 'Numero totale di biglietti',
              hintText: 'Inserisci il numero totale di biglietti',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remainingCardsController,
            decoration: const InputDecoration(
              labelText: 'Biglietti rimanenti',
              hintText: 'Numero di biglietti ancora disponibili',
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
                        const SnackBar(content: Text('Inserisci un numero valido di biglietti totali')),
                      );
                      return;
                    }

                    if (remainingCards == null || remainingCards < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inserisci un numero valido di biglietti rimanenti')),
                      );
                      return;
                    }

                    if (remainingCards > totalCards) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('I biglietti rimanenti non possono essere più dei biglietti totali')),
                      );
                      return;
                    }

                    // Save the total card count to database
                    final successTotal = await _dataRepository.setScratchCardCount(totalCards);
                    final successRemaining = await _dataRepository.setRemainingScratcchCards(remainingCards);

                    if (successTotal && successRemaining) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configurazione biglietti aggiornata')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Errore durante il salvataggio')),
                      );
                    }
                  },
                  child: const Text('Salva Configurazione'),
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
              const SectionTitle(title: 'Gestione Premi'),
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Nessun premio configurato. Aggiungi un premio per iniziare.'),
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
                  subtitle: Text('Probabilità: ${prize['probability']}%'),
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
                'Probabilità totale: ${_calculateTotalProbability(prizes)}%',
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
    final TextEditingController probabilityController = TextEditingController();

    // If editing an existing prize, pre-fill the controllers
    if (index != null) {
      final prize = prizeProvider.prizes[index];
      nameController.text = prize['name'] as String;
      probabilityController.text = (prize['probability'] as double).toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Aggiungi Premio' : 'Modifica Premio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Premio',
                hintText: 'Es. Buono Sconto 10%',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: probabilityController,
              decoration: const InputDecoration(
                labelText: 'Probabilità (%)',
                hintText: 'Es. 20',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              // Validate inputs
              final name = nameController.text.trim();
              final probabilityText = probabilityController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inserisci un nome per il premio')),
                );
                return;
              }

              final double? probability = double.tryParse(probabilityText);
              if (probability == null || probability <= 0 || probability > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inserisci una probabilità valida (0-100)')),
                );
                return;
              }

              // Save the prize
              if (index == null) {
                // Add new prize
                await prizeProvider.addPrize(name, probability);
              } else {
                // Update existing prize
                final prize = prizeProvider.prizes[index];
                await prizeProvider.updatePrize(prize['id'] as int, name, probability);
              }

              // Check if total probability exceeds 100%
              if (!(await prizeProvider.validateProbabilities())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attenzione: la somma delle probabilità supera il 100%'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }

              // Close the dialog
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Salva'),
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
        title: const Text('Elimina Premio'),
        content: Text('Sei sicuro di voler eliminare il premio "${prize['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              await prizeProvider.deletePrize(prize['id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premio eliminato')),
                );
              }
            },
            child: const Text('Elimina'),
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
              const SectionTitle(title: 'Storico Premi'),
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Nessun premio vinto finora.'),
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
                        formattedDate = 'Data non valida';
                      }
                    } else {
                      formattedDate = 'Data mancante';
                    }
                  } catch (e) {
                    formattedDate = 'Errore data';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events, color: Colors.amber),
                      title: Text(
                        item[DatabaseSchema.historyPrizeNameColumn]?.toString() ?? 'Premio sconosciuto',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Data: $formattedDate'),
                          if (item[DatabaseSchema.historyCustomerColumn] != null)
                            Text('Cliente: ${item[DatabaseSchema.historyCustomerColumn]}'),
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
          title: const Text('Cancella Storico'),
          content: isLoading
              ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
              : const Text('Sei sicuro di voler cancellare tutto lo storico dei premi? Questa azione non può essere annullata.'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annulla'),
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
                          const SnackBar(content: Text('Storico premi cancellato')),
                        );
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Cancella'),
            ),
          ],
        ),
      );
    },
  );
}
}
