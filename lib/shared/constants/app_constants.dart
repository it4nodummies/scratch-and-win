class AppConstants {
  // App information
  static const String appName = 'Gratta e Vinci Digitale';
  static const String pharmacyName = 'Farmacia Sammaruga';
  
  // Screen sizes for responsive design
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 900.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Default values
  static const int defaultPinLength = 4;
  static const int defaultScratchCardCount = 10;
  
  // Storage keys
  static const String pinStorageKey = 'pin_code';
  static const String scratchCardCountKey = 'scratch_card_count';
  static const String prizesKey = 'prizes';
  static const String historyKey = 'history';
  
  // Assets paths
  static const String logoPath = 'assets/images/logo.png';
  static const String backgroundPath = 'assets/images/background.png';
  static const String scratchSoundPath = 'assets/sounds/scratch.mp3';
  static const String winSoundPath = 'assets/sounds/win.mp3';
  
  // Error messages
  static const String genericErrorMessage = 'Si è verificato un errore. Riprova più tardi.';
  static const String pinErrorMessage = 'PIN non valido. Riprova.';
  static const String noMoreAttemptsMessage = 'Tentativi esauriti. Contatta l\'operatore.';
}