/// Database schema for the application.
/// 
/// This file defines the structure of the database tables and their relationships.
/// The application uses a local SQLite database for data persistence.

class DatabaseSchema {
  // Table names
  static const String configTable = 'config';
  static const String prizesTable = 'prizes';
  static const String sessionTable = 'sessions';
  static const String prizeHistoryTable = 'prize_history';

  // Config table columns
  static const String configKeyColumn = 'key';
  static const String configValueColumn = 'value';

  // Prizes table columns
  static const String prizeIdColumn = 'id';
  static const String prizeNameColumn = 'name';
  static const String prizeProbabilityColumn = 'probability';
  static const String prizeCreatedAtColumn = 'created_at';
  static const String prizeUpdatedAtColumn = 'updated_at';

  // Sessions table columns
  static const String sessionIdColumn = 'id';
  static const String sessionStartTimeColumn = 'start_time';
  static const String sessionEndTimeColumn = 'end_time';
  static const String sessionTotalAttemptsColumn = 'total_attempts';
  static const String sessionAttemptsUsedColumn = 'attempts_used';
  static const String sessionIsActiveColumn = 'is_active';

  // Prize history table columns
  static const String historyIdColumn = 'id';
  static const String historySessionIdColumn = 'session_id';
  static const String historyPrizeIdColumn = 'prize_id';
  static const String historyPrizeNameColumn = 'prize_name';
  static const String historyTimestampColumn = 'timestamp';
  static const String historyCustomerColumn = 'customer';

  // Create table statements
  static String createConfigTable() {
    return '''
      CREATE TABLE IF NOT EXISTS $configTable (
        $configKeyColumn TEXT PRIMARY KEY,
        $configValueColumn TEXT NOT NULL
      )
    ''';
  }

  static String createPrizesTable() {
    return '''
      CREATE TABLE IF NOT EXISTS $prizesTable (
        $prizeIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
        $prizeNameColumn TEXT NOT NULL,
        $prizeProbabilityColumn REAL NOT NULL,
        $prizeCreatedAtColumn TEXT NOT NULL,
        $prizeUpdatedAtColumn TEXT NOT NULL
      )
    ''';
  }

  static String createSessionsTable() {
    return '''
      CREATE TABLE IF NOT EXISTS $sessionTable (
        $sessionIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
        $sessionStartTimeColumn TEXT NOT NULL,
        $sessionEndTimeColumn TEXT,
        $sessionTotalAttemptsColumn INTEGER NOT NULL,
        $sessionAttemptsUsedColumn INTEGER NOT NULL DEFAULT 0,
        $sessionIsActiveColumn INTEGER NOT NULL DEFAULT 1
      )
    ''';
  }

  static String createPrizeHistoryTable() {
    return '''
      CREATE TABLE IF NOT EXISTS $prizeHistoryTable (
        $historyIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
        $historySessionIdColumn INTEGER,
        $historyPrizeIdColumn INTEGER,
        $historyPrizeNameColumn TEXT NOT NULL,
        $historyTimestampColumn TEXT NOT NULL,
        $historyCustomerColumn TEXT,
        FOREIGN KEY ($historySessionIdColumn) REFERENCES $sessionTable ($sessionIdColumn),
        FOREIGN KEY ($historyPrizeIdColumn) REFERENCES $prizesTable ($prizeIdColumn)
      )
    ''';
  }

  // Default config values
  static Map<String, String> defaultConfig = {
    'pin_code': '1234',
    'scratch_card_count': '100',
    'remaining_scratch_cards': '100',
  };

  // Default prizes
  static List<Map<String, dynamic>> defaultPrizes = [
    {'name': '25 Punti Fedelity Card', 'probability': 0.765},
    {'name': '50 Punti Fedelity Card', 'probability': 0.45},
    {'name': '100 Punti Fedelity Card', 'probability': 0.25},
    {'name': 'Premio Jolly', 'probability': 0.024},
    {'name': 'Super Premio Jolly', 'probability': 0.012},
  ];
}
