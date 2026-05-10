import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import '../models/book_listing_model.dart';
import '../models/message_model.dart';
import '../models/review_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // Use FFI for Linux/Windows/macOS desktop
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPathRaw = await getDatabasesPath();
    // On Linux/desktop sqflite_ffi returns a relative path — resolve it.
    final dbPath = p.isAbsolute(dbPathRaw) ? dbPathRaw : p.absolute(dbPathRaw);
    final path = join(dbPath, 'bookxchange.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop and recreate all tables on upgrade to re-seed with images
        await db.execute('DROP TABLE IF EXISTS listings');
        await db.execute('DROP TABLE IF EXISTS users');
        await db.execute('DROP TABLE IF EXISTS chats');
        await db.execute('DROP TABLE IF EXISTS messages');
        await db.execute('DROP TABLE IF EXISTS reviews');
        await db.execute('DROP TABLE IF EXISTS transactions');
        await _createTables(db, newVersion);
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        university TEXT NOT NULL,
        department TEXT NOT NULL,
        profileImage TEXT,
        phone TEXT,
        rating REAL DEFAULT 0.0,
        totalRatings INTEGER DEFAULT 0,
        totalListings INTEGER DEFAULT 0,
        totalTransactions INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Book listings table
    await db.execute('''
      CREATE TABLE listings (
        id TEXT PRIMARY KEY,
        sellerId TEXT NOT NULL,
        sellerName TEXT NOT NULL,
        sellerImage TEXT,
        sellerRating REAL DEFAULT 0.0,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT,
        department TEXT NOT NULL,
        course TEXT NOT NULL,
        condition TEXT NOT NULL,
        listingType TEXT NOT NULL,
        price REAL,
        exchangePreference TEXT,
        images TEXT DEFAULT '[]',
        description TEXT NOT NULL,
        isAvailable INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        views INTEGER DEFAULT 0,
        FOREIGN KEY (sellerId) REFERENCES users(id)
      )
    ''');

    // Chats table
    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        bookTitle TEXT NOT NULL,
        bookImage TEXT,
        buyerId TEXT NOT NULL,
        buyerName TEXT NOT NULL,
        sellerId TEXT NOT NULL,
        sellerName TEXT NOT NULL,
        lastMessage TEXT NOT NULL,
        lastMessageTime TEXT NOT NULL,
        unreadCount INTEGER DEFAULT 0
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        type TEXT DEFAULT 'text',
        FOREIGN KEY (chatId) REFERENCES chats(id)
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        reviewerId TEXT NOT NULL,
        reviewerName TEXT NOT NULL,
        reviewerImage TEXT,
        reviewedUserId TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        bookTitle TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        bookTitle TEXT NOT NULL,
        bookImage TEXT,
        buyerId TEXT NOT NULL,
        buyerName TEXT NOT NULL,
        sellerId TEXT NOT NULL,
        sellerName TEXT NOT NULL,
        price REAL,
        type TEXT NOT NULL,
        completedAt TEXT NOT NULL
      )
    ''');
  }

  // ─── USER METHODS ────────────────────────────────────────────────

  Future<bool> registerUser(UserModel user, String password) async {
    final db = await database;
    try {
      await db.insert('users', {
        ...user.toMap(),
        'password': password,
      });
      return true;
    } catch (e) {
      return false; // email already exists
    }
  }

  Future<UserModel?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ─── LISTING METHODS ─────────────────────────────────────────────

  Future<void> insertListing(BookListingModel listing) async {
    final db = await database;
    final map = listing.toMap();
    // Store non-empty image paths as comma-separated string
    map['images'] = listing.images.where((s) => s.isNotEmpty).join(',');
    map['isAvailable'] = listing.isAvailable ? 1 : 0;
    await db.insert('listings', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BookListingModel>> getAllListings() async {
    final db = await database;
    final result = await db.query('listings', orderBy: 'createdAt DESC');
    return result.map((m) => _listingFromMap(m)).toList();
  }

  Future<List<BookListingModel>> getListingsByUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'listings',
      where: 'sellerId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((m) => _listingFromMap(m)).toList();
  }

  Future<void> updateListingAvailability(
      String listingId, bool isAvailable) async {
    final db = await database;
    await db.update(
      'listings',
      {'isAvailable': isAvailable ? 1 : 0},
      where: 'id = ?',
      whereArgs: [listingId],
    );
  }

  Future<void> incrementListingViews(String listingId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE listings SET views = views + 1 WHERE id = ?',
      [listingId],
    );
  }

  Future<void> deleteListing(String listingId) async {
    final db = await database;
    await db.delete('listings', where: 'id = ?', whereArgs: [listingId]);
  }

  BookListingModel _listingFromMap(Map<String, dynamic> m) {
    final images = (m['images'] as String?)
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    return BookListingModel(
      id: m['id'],
      sellerId: m['sellerId'],
      sellerName: m['sellerName'],
      sellerImage: m['sellerImage'],
      sellerRating: (m['sellerRating'] as num?)?.toDouble() ?? 0.0,
      title: m['title'],
      author: m['author'],
      isbn: m['isbn'],
      department: m['department'],
      course: m['course'],
      condition: m['condition'],
      listingType: m['listingType'],
      price: (m['price'] as num?)?.toDouble(),
      exchangePreference: m['exchangePreference'],
      images: images,
      description: m['description'],
      isAvailable: (m['isAvailable'] as int) == 1,
      createdAt: DateTime.parse(m['createdAt']),
      views: m['views'] ?? 0,
    );
  }

  // ─── CHAT METHODS ────────────────────────────────────────────────

  Future<void> insertChat(ChatModel chat) async {
    final db = await database;
    await db.insert(
      'chats',
      {
        'id': chat.id,
        'bookId': chat.bookId,
        'bookTitle': chat.bookTitle,
        'bookImage': chat.bookImage,
        'buyerId': chat.buyerId,
        'buyerName': chat.buyerName,
        'sellerId': chat.sellerId,
        'sellerName': chat.sellerName,
        'lastMessage': chat.lastMessage,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'unreadCount': chat.unreadCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateChat(ChatModel chat) async {
    final db = await database;
    await db.update(
      'chats',
      {
        'lastMessage': chat.lastMessage,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'unreadCount': chat.unreadCount,
      },
      where: 'id = ?',
      whereArgs: [chat.id],
    );
  }

  Future<List<ChatModel>> getChatsForUser(String userId) async {
    final db = await database;
    final chatRows = await db.query(
      'chats',
      where: 'buyerId = ? OR sellerId = ?',
      whereArgs: [userId, userId],
      orderBy: 'lastMessageTime DESC',
    );

    final chats = <ChatModel>[];
    for (final row in chatRows) {
      final messages = await getMessagesForChat(row['id'] as String);
      chats.add(ChatModel(
        id: row['id'] as String,
        bookId: row['bookId'] as String,
        bookTitle: row['bookTitle'] as String,
        bookImage: row['bookImage'] as String?,
        buyerId: row['buyerId'] as String,
        buyerName: row['buyerName'] as String,
        sellerId: row['sellerId'] as String,
        sellerName: row['sellerName'] as String,
        messages: messages,
        lastMessage: row['lastMessage'] as String,
        lastMessageTime: DateTime.parse(row['lastMessageTime'] as String),
        unreadCount: row['unreadCount'] as int,
      ));
    }
    return chats;
  }

  Future<ChatModel?> getChatForBook({
    required String bookId,
    required String buyerId,
    required String sellerId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'chats',
      where: 'bookId = ? AND buyerId = ? AND sellerId = ?',
      whereArgs: [bookId, buyerId, sellerId],
    );
    if (rows.isEmpty) return null;
    final messages = await getMessagesForChat(rows.first['id'] as String);
    final row = rows.first;
    return ChatModel(
      id: row['id'] as String,
      bookId: row['bookId'] as String,
      bookTitle: row['bookTitle'] as String,
      bookImage: row['bookImage'] as String?,
      buyerId: row['buyerId'] as String,
      buyerName: row['buyerName'] as String,
      sellerId: row['sellerId'] as String,
      sellerName: row['sellerName'] as String,
      messages: messages,
      lastMessage: row['lastMessage'] as String,
      lastMessageTime: DateTime.parse(row['lastMessageTime'] as String),
      unreadCount: row['unreadCount'] as int,
    );
  }

  Future<void> markChatAsRead(String chatId) async {
    final db = await database;
    await db.update('chats', {'unreadCount': 0},
        where: 'id = ?', whereArgs: [chatId]);
    await db.update('messages', {'isRead': 1},
        where: 'chatId = ?', whereArgs: [chatId]);
  }

  // ─── MESSAGE METHODS ─────────────────────────────────────────────

  Future<void> insertMessage(String chatId, MessageModel msg) async {
    final db = await database;
    await db.insert('messages', {
      'id': msg.id,
      'chatId': chatId,
      'senderId': msg.senderId,
      'text': msg.text,
      'timestamp': msg.timestamp.toIso8601String(),
      'isRead': msg.isRead ? 1 : 0,
      'type': msg.type.name,
    });
  }

  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return result
        .map((m) => MessageModel(
              id: m['id'] as String,
              senderId: m['senderId'] as String,
              text: m['text'] as String,
              timestamp: DateTime.parse(m['timestamp'] as String),
              isRead: (m['isRead'] as int) == 1,
              type: MessageType.values.firstWhere(
                (e) => e.name == m['type'],
                orElse: () => MessageType.text,
              ),
            ))
        .toList();
  }

  // ─── REVIEW METHODS ──────────────────────────────────────────────

  Future<void> insertReview(ReviewModel review) async {
    final db = await database;
    await db.insert('reviews', review.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'reviews',
      where: 'reviewedUserId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((m) => ReviewModel.fromMap(m)).toList();
  }

  // ─── TRANSACTION METHODS ─────────────────────────────────────────

  Future<void> insertTransaction(TransactionModel t) async {
    final db = await database;
    await db.insert('transactions', {
      'id': t.id,
      'bookId': t.bookId,
      'bookTitle': t.bookTitle,
      'bookImage': t.bookImage,
      'buyerId': t.buyerId,
      'buyerName': t.buyerName,
      'sellerId': t.sellerId,
      'sellerName': t.sellerName,
      'price': t.price,
      'type': t.type,
      'completedAt': t.completedAt.toIso8601String(),
    });
  }

  Future<List<TransactionModel>> getTransactionsForUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'buyerId = ? OR sellerId = ?',
      whereArgs: [userId, userId],
      orderBy: 'completedAt DESC',
    );
    return result
        .map((m) => TransactionModel(
              id: m['id'] as String,
              bookId: m['bookId'] as String,
              bookTitle: m['bookTitle'] as String,
              bookImage: m['bookImage'] as String?,
              buyerId: m['buyerId'] as String,
              buyerName: m['buyerName'] as String,
              sellerId: m['sellerId'] as String,
              sellerName: m['sellerName'] as String,
              price: (m['price'] as num?)?.toDouble(),
              type: m['type'] as String,
              completedAt: DateTime.parse(m['completedAt'] as String),
            ))
        .toList();
  }

  // ─── SEED DEMO DATA ──────────────────────────────────────────────

  Future<bool> isDemoSeeded() async {
    final db = await database;
    final result = await db
        .query('users', where: 'email = ?', whereArgs: ['demo@uni.edu.pk']);
    return result.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
