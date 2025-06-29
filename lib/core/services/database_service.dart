import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/database_schema.dart';

/// Service for handling database operations.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  /// Factory constructor that returns the singleton instance.
  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Gets the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database.
  Future<Database> _initDatabase() async {
    // Get the database path
    String path = join(await getDatabasesPath(), 'gratta_e_vinci.db');

    // Open the database
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database tables when the database is first created.
  Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await db.execute(DatabaseSchema.createConfigTable());
    await db.execute(DatabaseSchema.createPrizesTable());
    await db.execute(DatabaseSchema.createSessionsTable());
    await db.execute(DatabaseSchema.createPrizeHistoryTable());

    // Insert default config values
    await _insertDefaultConfig(db);

    // Insert default prizes
    await _insertDefaultPrizes(db);
  }

  /// Handles database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    if (oldVersion < newVersion) {
      // Migration from version 1 to 2
      if (oldVersion == 1 && newVersion >= 2) {
        // Add max_occurrences and current_occurrences columns to prizes table
        await db.execute('''
          ALTER TABLE ${DatabaseSchema.prizesTable} 
          ADD COLUMN ${DatabaseSchema.prizeMaxOccurrencesColumn} INTEGER NOT NULL DEFAULT 0
        ''');
        await db.execute('''
          ALTER TABLE ${DatabaseSchema.prizesTable} 
          ADD COLUMN ${DatabaseSchema.prizeCurrentOccurrencesColumn} INTEGER NOT NULL DEFAULT 0
        ''');
      }
    }
  }

  /// Inserts default configuration values.
  Future<void> _insertDefaultConfig(Database db) async {
    Batch batch = db.batch();

    DatabaseSchema.defaultConfig.forEach((key, value) {
      batch.insert(
        DatabaseSchema.configTable,
        {
          DatabaseSchema.configKeyColumn: key,
          DatabaseSchema.configValueColumn: value,
        },
      );
    });

    await batch.commit(noResult: true);
  }

  /// Inserts default prize configurations.
  Future<void> _insertDefaultPrizes(Database db) async {
    Batch batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (var prize in DatabaseSchema.defaultPrizes) {
      batch.insert(
        DatabaseSchema.prizesTable,
        {
          DatabaseSchema.prizeNameColumn: prize['name'],
          DatabaseSchema.prizeProbabilityColumn: prize['probability'],
          DatabaseSchema.prizeCreatedAtColumn: now,
          DatabaseSchema.prizeUpdatedAtColumn: now,
        },
      );
    }

    await batch.commit(noResult: true);
  }

  /// Gets a configuration value by key.
  Future<String?> getConfigValue(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.configTable,
      columns: [DatabaseSchema.configValueColumn],
      where: '${DatabaseSchema.configKeyColumn} = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first[DatabaseSchema.configValueColumn] as String?;
    }

    return null;
  }

  /// Sets a configuration value.
  Future<void> setConfigValue(String key, String value) async {
    final db = await database;

    // Check if the key exists
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseSchema.configTable} WHERE ${DatabaseSchema.configKeyColumn} = ?',
      [key],
    ));

    if (count != null && count > 0) {
      // Update existing value
      await db.update(
        DatabaseSchema.configTable,
        {DatabaseSchema.configValueColumn: value},
        where: '${DatabaseSchema.configKeyColumn} = ?',
        whereArgs: [key],
      );
    } else {
      // Insert new value
      await db.insert(
        DatabaseSchema.configTable,
        {
          DatabaseSchema.configKeyColumn: key,
          DatabaseSchema.configValueColumn: value,
        },
      );
    }
  }

  /// Gets all prizes.
  Future<List<Map<String, dynamic>>> getAllPrizes() async {
    final db = await database;
    return await db.query(DatabaseSchema.prizesTable);
  }

  /// Adds a new prize.
  Future<int> addPrize(String name, double probability, int maxOccurrences) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert(
      DatabaseSchema.prizesTable,
      {
        DatabaseSchema.prizeNameColumn: name,
        DatabaseSchema.prizeProbabilityColumn: probability,
        DatabaseSchema.prizeMaxOccurrencesColumn: maxOccurrences,
        DatabaseSchema.prizeCurrentOccurrencesColumn: 0,
        DatabaseSchema.prizeCreatedAtColumn: now,
        DatabaseSchema.prizeUpdatedAtColumn: now,
      },
    );
  }

  /// Updates an existing prize.
  Future<int> updatePrize(int id, String name, double probability, int maxOccurrences) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      DatabaseSchema.prizesTable,
      {
        DatabaseSchema.prizeNameColumn: name,
        DatabaseSchema.prizeProbabilityColumn: probability,
        DatabaseSchema.prizeMaxOccurrencesColumn: maxOccurrences,
        DatabaseSchema.prizeUpdatedAtColumn: now,
      },
      where: '${DatabaseSchema.prizeIdColumn} = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a prize.
  Future<int> deletePrize(int id) async {
    final db = await database;

    return await db.delete(
      DatabaseSchema.prizesTable,
      where: '${DatabaseSchema.prizeIdColumn} = ?',
      whereArgs: [id],
    );
  }

  /// Starts a new session.
  Future<int> startSession(int totalAttempts) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert(
      DatabaseSchema.sessionTable,
      {
        DatabaseSchema.sessionStartTimeColumn: now,
        DatabaseSchema.sessionTotalAttemptsColumn: totalAttempts,
        DatabaseSchema.sessionAttemptsUsedColumn: 0,
        DatabaseSchema.sessionIsActiveColumn: 1,
      },
    );
  }

  /// Updates a session with attempts used.
  Future<int> updateSessionAttempts(int sessionId, int attemptsUsed) async {
    final db = await database;

    return await db.update(
      DatabaseSchema.sessionTable,
      {DatabaseSchema.sessionAttemptsUsedColumn: attemptsUsed},
      where: '${DatabaseSchema.sessionIdColumn} = ?',
      whereArgs: [sessionId],
    );
  }

  /// Ends a session.
  Future<int> endSession(int sessionId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      DatabaseSchema.sessionTable,
      {
        DatabaseSchema.sessionEndTimeColumn: now,
        DatabaseSchema.sessionIsActiveColumn: 0,
      },
      where: '${DatabaseSchema.sessionIdColumn} = ?',
      whereArgs: [sessionId],
    );
  }

  /// Gets the active session, if any.
  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseSchema.sessionTable,
      where: '${DatabaseSchema.sessionIsActiveColumn} = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }

    return null;
  }

  /// Records a prize win in the history.
  Future<int> recordPrizeWin(int sessionId, int? prizeId, String prizeName, [String? customer]) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Increment the current occurrences of the prize if it has an ID
    if (prizeId != null) {
      await incrementPrizeOccurrences(prizeId);
    }

    return await db.insert(
      DatabaseSchema.prizeHistoryTable,
      {
        DatabaseSchema.historySessionIdColumn: sessionId,
        DatabaseSchema.historyPrizeIdColumn: prizeId,
        DatabaseSchema.historyPrizeNameColumn: prizeName,
        DatabaseSchema.historyTimestampColumn: now,
        DatabaseSchema.historyCustomerColumn: customer,
      },
    );
  }

  /// Increments the current occurrences of a prize.
  Future<int> incrementPrizeOccurrences(int prizeId) async {
    final db = await database;

    // Get the current occurrences
    final List<Map<String, dynamic>> result = await db.query(
      DatabaseSchema.prizesTable,
      columns: [DatabaseSchema.prizeCurrentOccurrencesColumn],
      where: '${DatabaseSchema.prizeIdColumn} = ?',
      whereArgs: [prizeId],
    );

    if (result.isNotEmpty) {
      final currentOccurrences = result.first[DatabaseSchema.prizeCurrentOccurrencesColumn] as int;

      // Increment the current occurrences
      return await db.update(
        DatabaseSchema.prizesTable,
        {DatabaseSchema.prizeCurrentOccurrencesColumn: currentOccurrences + 1},
        where: '${DatabaseSchema.prizeIdColumn} = ?',
        whereArgs: [prizeId],
      );
    }

    return 0;
  }

  /// Gets all prize history.
  Future<List<Map<String, dynamic>>> getPrizeHistory() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        h.${DatabaseSchema.historyIdColumn},
        h.${DatabaseSchema.historyPrizeNameColumn},
        h.${DatabaseSchema.historyTimestampColumn},
        h.${DatabaseSchema.historyCustomerColumn}
      FROM ${DatabaseSchema.prizeHistoryTable} h
      LEFT JOIN ${DatabaseSchema.sessionTable} s
      ON h.${DatabaseSchema.historySessionIdColumn} = s.${DatabaseSchema.sessionIdColumn}
      ORDER BY h.${DatabaseSchema.historyTimestampColumn} DESC
    ''');
  }

  /// Delete all prize history.
  Future<void> deleteAllPrizeHistory() async {
    final db = await database;
    // This deletes all rows but keeps the table (not dropping the table)
    await db.delete(DatabaseSchema.prizeHistoryTable);
  }

  /// Exports all data as a JSON-compatible map.
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;

    // Get all data from each table
    final config = await db.query(DatabaseSchema.configTable);
    final prizes = await db.query(DatabaseSchema.prizesTable);
    final sessions = await db.query(DatabaseSchema.sessionTable);
    final history = await db.query(DatabaseSchema.prizeHistoryTable);

    // Return as a structured map
    return {
      'config': config,
      'prizes': prizes,
      'sessions': sessions,
      'history': history,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Resets the database to its default state.
  /// This deletes all data from all tables and re-inserts the default values.
  Future<void> resetDatabase() async {
    final db = await database;

    // Use a transaction to ensure all operations succeed or fail together
    await db.transaction((txn) async {
      // Delete all data from all tables
      await txn.delete(DatabaseSchema.prizeHistoryTable);
      await txn.delete(DatabaseSchema.sessionTable);
      await txn.delete(DatabaseSchema.prizesTable);
      await txn.delete(DatabaseSchema.configTable);

      // Re-insert default config values
      for (var entry in DatabaseSchema.defaultConfig.entries) {
        await txn.insert(
          DatabaseSchema.configTable,
          {
            DatabaseSchema.configKeyColumn: entry.key,
            DatabaseSchema.configValueColumn: entry.value,
          },
        );
      }

      // Re-insert default prizes
      final now = DateTime.now().toIso8601String();
      for (var prize in DatabaseSchema.defaultPrizes) {
        await txn.insert(
          DatabaseSchema.prizesTable,
          {
            DatabaseSchema.prizeNameColumn: prize['name'],
            DatabaseSchema.prizeProbabilityColumn: prize['probability'],
            DatabaseSchema.prizeMaxOccurrencesColumn: prize['max_occurrences'],
            DatabaseSchema.prizeCurrentOccurrencesColumn: 0, // Reset to 0
            DatabaseSchema.prizeCreatedAtColumn: now,
            DatabaseSchema.prizeUpdatedAtColumn: now,
          },
        );
      }
    });
  }
}
