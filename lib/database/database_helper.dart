import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vendor.dart';
import '../models/phone.dart';

class DatabaseHelper extends ChangeNotifier {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vendor_database.db');
    return await openDatabase(
      path,
      version: 6, // Increment the version number for the new table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade callback for schema migration
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create vendors table
    await db.execute('''
      CREATE TABLE vendors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id TEXT UNIQUE NOT NULL,
        upi_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('big', 'small', 'medium')),
        phone_number TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');

    // Create phones table
    await db.execute('''
      CREATE TABLE phones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_upi_id TEXT NOT NULL,
        receiver_upi_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        reward_points INTEGER NOT NULL
      )
    ''');
      await db.execute('''
      CREATE TABLE bills(
      bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
      txn_id INTEGER NOT NULL,
      price REAL NOT NULL,  
      item TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      FOREIGN KEY(txn_id) REFERENCES transactions(transaction_id)
      )
      ''');
    await db.execute('''
      CREATE TABLE points_table(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER UNIQUE,
        points INTEGER NOT NULL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(transaction_id)
      )
    ''');
      }

  // Add points for a transaction
  Future<void> addPoints(int transactionId, int points) async {
    final Database db = await database;
    await db.insert(
      'points_table',
      {
        'transaction_id': transactionId,
        'points': points,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get total points
  Future<int> getTotalPoints() async {
    final Database db = await database;
    final result = await db.rawQuery('SELECT SUM(points) as total FROM points_table');
    return (result.first['total'] as int?) ?? 0;
  }


  Future<void> clearVendors() async {
    final Database db = await database;
    await db.delete('vendors');
  }
  Future<void> updateVendorByUpiId(String upiId, Map<String, dynamic> updates) async {
  final Database db = await database;
  await db.update(
  'vendors',
  updates,
  where: 'upi_id = ?',
  whereArgs: [upiId],
  );
  notifyListeners();
  }
  // Check if points were already added for a transaction
  Future<bool> hasPointsForTransaction(int transactionId) async {
    final Database db = await database;
    final result = await db.query(
      'points_table',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return result.isNotEmpty;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new `phone_number` column to the `vendors` table
      await db.execute('ALTER TABLE vendors ADD COLUMN phone_number TEXT NOT NULL DEFAULT ""');

      // Remove the `upi_id` column from the `phones` table
      await db.execute('CREATE TABLE phones_new(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone_number TEXT NOT NULL)');
      await db.execute('INSERT INTO phones_new (id, name, phone_number) SELECT id, name, phone_number FROM phones');
      await db.execute('DROP TABLE phones');
      await db.execute('ALTER TABLE phones_new RENAME TO phones');
    }

    if (oldVersion < 3) {
      // Add the new `transactions` table
      await db.execute('''
        CREATE TABLE transactions(
          transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
          sender_upi_id TEXT NOT NULL,
          receiver_upi_id TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          reward_points INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add the new `bills` table
      await db.execute('''
        CREATE TABLE bills(
          txn_id INTEGER PRIMARY KEY AUTOINCREMENT,
          price REAL NOT NULL,
          item TEXT NOT NULL,
          quantity INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // Migrate to version 5: Correct bills table schema
      await db.execute('DROP TABLE IF EXISTS bills');
      await db.execute('''
        CREATE TABLE bills(
          bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
          txn_id INTEGER NOT NULL,
          price REAL NOT NULL,
          item TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY(txn_id) REFERENCES transactions(transaction_id)
        )
      ''');
    }
    if (oldVersion < 6) { // Assuming current version is 5
      await db.execute('''
        CREATE TABLE points_table(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER UNIQUE,
          points INTEGER NOT NULL,
          FOREIGN KEY(transaction_id) REFERENCES transactions(transaction_id)
        )
      ''');
    }
  }

  // Insert a new vendor
  Future<int> insertVendor(Vendor vendor) async {
    final Database db = await database;

    // Check if vendor with the same vendor_id already exists
    final List<Map<String, dynamic>> existing = await db.query(
      'vendors',
      where: 'vendor_id = ?',
      whereArgs: [vendor.vendorId],
    );

    if (existing.isNotEmpty) {
      return 0; // Return 0 if vendor already exists to prevent duplication
    }

    final result = await db.insert(
      'vendors',
      vendor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ensures no duplicate key errors
    );

    notifyListeners();
    return result;
  }

  // Insert a new phone
  Future<int> insertPhone(Phone phone) async {
    final Database db = await database;

    // Check if phone with the same phone_number already exists
    final List<Map<String, dynamic>> existing = await db.query(
      'phones',
      where: 'phone_number = ?',
      whereArgs: [phone.phoneNumber],
    );

    if (existing.isNotEmpty) {
      return 0; // Return 0 if phone number already exists
    }

    return await db.insert(
      'phones',
      phone.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  Future<int> insertBill(Map<String, dynamic> bill, int transactionId) async {
    final Database db = await database;
    return await db.insert(
      'bills',
      {
        'txn_id': transactionId,
        'price': bill['price'],
        'item': bill['item'],
        'quantity': bill['quantity'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Add this new method
  Future<List<Map<String, dynamic>>> getBillsByTransactionId(int transactionId) async {
    final Database db = await database;
    return await db.query(
      'bills',
      where: 'txn_id = ?',
      whereArgs: [transactionId],
    );
  }

  // Get vendor by UPI ID
  Future<Vendor?> getVendorByUpiId(String upiId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM vendors WHERE upi_id = ?',
      [upiId]
    );

    if (maps.isEmpty) return null;
    return Vendor.fromMap(maps.first);
  }
  // Get all phones
  Future<List<Phone>> getPhonesByUpiId(String upiId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'phones',
    );

    return List.generate(maps.length, (i) => Phone.fromMap(maps[i]));
  }

  Future<void> verifyVendorData() async {
  final Database db = await database;
  final vendors = await db.query('vendors');
  print('Total vendors in database: ${vendors.length}');
  for (var vendor in vendors) {
    print('Vendor: ${vendor['name']}, UPI: ${vendor['upi_id']}');
  }
}

  // Get all vendors
  Future<List<Vendor>> getAllVendors() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vendors');
    return List.generate(maps.length, (i) => Vendor.fromMap(maps[i]));
  }

Future<void> updatePoints(int points) async {
  final db = await database;
  await db.insert(
    'points_table',
    {
      'points': points,
      'date': DateTime.now().toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

  // Update a vendor
  Future<int> updateVendor(Vendor vendor) async {
    final Database db = await database;
    return await db.update(
      'vendors',
      vendor.toMap(),
      where: 'vendor_id = ?',
      whereArgs: [vendor.vendorId],
    );
  }

  // Delete a vendor
  Future<int> deleteVendor(String vendorId) async {
    final Database db = await database;
    return await db.delete(
      'vendors',
      where: 'vendor_id = ?',
      whereArgs: [vendorId],
    );
  }

  // Insert a new transaction
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final Database db = await database;
    return await db.insert(
      'transactions',
      transaction,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Get all transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final Database db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  // Get transactions by sender UPI ID
  Future<List<Map<String, dynamic>>> getTransactionsBySenderUpiId(String senderUpiId) async {
    final Database db = await database;
    return await db.query(
      'transactions',
      where: 'sender_upi_id = ?',
      whereArgs: [senderUpiId],
    );
  }

  // Get transactions by receiver UPI ID
  Future<List<Map<String, dynamic>>> getTransactionsByReceiverUpiId(String receiverUpiId) async {
    final Database db = await database;
    return await db.query(
      'transactions',
      where: 'receiver_upi_id = ?',
      whereArgs: [receiverUpiId],
    );
  }
}