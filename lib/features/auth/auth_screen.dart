import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../core/models/auth_provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/responsive_layout.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticating = false;
  bool _isNavigating = false;
  bool _disposed = false; // Add this flag

  @override
  void dispose() {
    _disposed = true; // Set flag before disposing
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onPinSubmitted(String pin) async {
    if (_isAuthenticating || _isNavigating || _disposed) return; // Check disposed flag

    setState(() {
      _isAuthenticating = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.authenticate(pin);

    // Check if widget is still mounted AND not disposed before updating state
    if (!mounted || _disposed) return;

    setState(() {
      _isAuthenticating = false;
      if (success) {
        _isNavigating = true;
      }
    });

    if (success && mounted && !_disposed) {
      // Navigate to operator screen
      // Navigator.pushReplacementNamed(context, AppRoutes.operator);
      if (success && mounted && !_disposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_disposed) {
            Navigator.pushReplacementNamed(context, AppRoutes.operator);
          }
        });
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Autenticazione',
      body: Center(
        child: ResponsiveLayout(
          mobile: _buildPinEntry(context, 300),
          tablet: _buildPinEntry(context, 400),
          desktop: _buildPinEntry(context, 500),
        ),
      ),
    );
  }

  Widget _buildPinEntry(BuildContext context, double width) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: Center(
        child: AppCard(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionTitle(title: 'Inserisci il PIN'),
              const SizedBox(height: 16),
              Text(
                'Inserisci il PIN a 4 cifre per accedere',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                length: AppConstants.defaultPinLength,
                controller: _pinController,
                obscureText: true,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 60,
                  fieldWidth: 50,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: Theme.of(context).colorScheme.primary,
                ),
                keyboardType: TextInputType.number,
                enableActiveFill: true,
                onCompleted: (pin) {
                  if (mounted && !_isNavigating && !_disposed) { // Add disposed check
                    _onPinSubmitted(pin);
                  }
                },
                onChanged: (value) {
                  if (mounted && !_isNavigating && !_disposed && authProvider.errorMessage.isNotEmpty) { // Add disposed check
                    authProvider.resetError();
                  }
                },
              ),
              if (authProvider.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  authProvider.errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              _isAuthenticating
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: mounted && 
                                 !_disposed && // Add disposed check
                                 _pinController.text.length == AppConstants.defaultPinLength && 
                                 !_isAuthenticating && 
                                 !_isNavigating
                          ? () => _onPinSubmitted(_pinController.text)
                          : null,
                      child: const Text('Accedi'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}