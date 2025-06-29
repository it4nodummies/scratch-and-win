import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../config/routes.dart';
import '../../core/models/session_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Delay a bit to show the splash screen
    await Future.delayed(const Duration(milliseconds: 500));

    // Load session state asynchronously
    if (mounted) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      await sessionProvider.loadSessionState();

      // Navigate to auth screen
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Use a small delay to ensure the UI has updated
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.auth);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder (would be replaced with actual logo)
            Icon(
              Icons.local_pharmacy,
              size: context.responsive(
                mobile: 80.0,
                tablet: 120.0,
                desktop: 160.0,
              ),
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            // Pharmacy name
            Text(
              AppConstants.pharmacyName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // App name
            Text(
              "Gratta e Vinci",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
