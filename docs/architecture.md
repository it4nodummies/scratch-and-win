# Gratta e Vinci Digitale - Architecture Documentation

## Overview
This document outlines the architecture for the Farmacia Sammaruga Digital Scratch Card application. The application is built using Flutter and is designed to run on both Android and iOS tablet devices.

## Project Structure
The project follows a feature-based architecture with the following directory structure:

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Main application widget
├── config/                   # App-wide configuration
│   ├── theme.dart            # App theme and styling
│   └── routes.dart           # Route definitions
├── core/                     # Core functionality
│   ├── models/               # Data models
│   ├── services/             # Business logic services
│   └── utils/                # Utility functions
├── features/                 # Feature modules
│   ├── splash/               # Splash screen
│   ├── auth/                 # PIN authentication
│   ├── operator/             # Operator interface
│   ├── scratch_card/         # Scratch card game
│   └── settings/             # App settings
└── shared/                   # Shared components
    ├── widgets/              # Reusable widgets
    └── constants/            # App-wide constants
```

## State Management
The application uses the Provider package for state management. Each feature module has its own state management class that extends ChangeNotifier.

## Data Persistence
All application data is stored locally using SharedPreferences. This includes:
- PIN code
- Total scratch card count
- Prize configurations
- Game history and statistics

## Key Components

### Authentication
- 4-digit PIN entry screen
- Secure PIN storage
- Authentication state management

### Operator Interface
- Dashboard for setting available scratch cards
- Session management
- Screen locking mechanism

### Scratch Card Game
- Interactive scratch card with silver coating effect
- Win/loss determination algorithm
- Prize display
- Confetti animation for winning outcomes

### Settings
- PIN change functionality
- Total scratch card configuration
- Prize management (CRUD operations)
- History and statistics view

## UI/UX Guidelines
- All screens include the Farmacia Sammaruga branding in the header
- The application uses a playful and engaging design
- Responsive layout optimized for tablet devices
- Consistent color scheme and typography throughout the app

## Dependencies
- provider: State management
- shared_preferences: Local data storage
- pin_code_fields: PIN entry UI
- confetti: Confetti animation effects

## Testing Strategy
- Unit tests for core business logic
- Widget tests for UI components
- Integration tests for user flows