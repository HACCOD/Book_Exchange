import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';

class ChatProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<ChatModel> _chats = [];
  bool _isInitialized = false;
  String? _loadedForUserId;

  // Called on logout to clear this user's chats
  void reset() {
    _chats = [];
    _isInitialized = false;
    _loadedForUserId = null;
    notifyListeners();
  }

  List<ChatModel> chatsForUser(String userId) =>
      _chats.where((c) => c.buyerId == userId || c.sellerId == userId).toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

  ChatModel? getChatById(String chatId) {
    try {
      return _chats.firstWhere((c) => c.id == chatId);
    } catch (_) {
      return null;
    }
  }

  int totalUnread(String userId) => chatsForUser(userId)
      .fold(0, (sum, c) => sum + (c.sellerId == userId ? c.unreadCount : 0));

  // ─── LOAD ─────────────────────────────────────────────────────────

  Future<void> loadChats(String userId) async {
    if (_isInitialized && _loadedForUserId == userId) return;
    _chats = await _db.getChatsForUser(userId);
    _isInitialized = true;
    _loadedForUserId = userId;
    notifyListeners();
  }

  // ─── START CHAT ───────────────────────────────────────────────────

  Future<ChatModel> startChat({
    required String bookId,
    required String bookTitle,
    String? bookImage,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
  }) async {
    // Return existing chat if already started
    final existing = await _db.getChatForBook(
      bookId: bookId,
      buyerId: buyerId,
      sellerId: sellerId,
    );
    if (existing != null) {
      // Make sure it's in memory
      if (!_chats.any((c) => c.id == existing.id)) {
        _chats.add(existing);
        notifyListeners();
      }
      return existing;
    }

    final chat = ChatModel(
      id: const Uuid().v4(),
      bookId: bookId,
      bookTitle: bookTitle,
      bookImage: bookImage,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: sellerId,
      sellerName: sellerName,
      messages: [],
      lastMessageTime: DateTime.now(),
      lastMessage: 'Chat started',
    );

    await _db.insertChat(chat);
    _chats.add(chat);
    notifyListeners();
    return chat;
  }

  // ─── SEND MESSAGE ─────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;

    final msg = MessageModel(
      id: const Uuid().v4(),
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      type: type,
    );

    // Persist message
    await _db.insertMessage(chatId, msg);

    final chat = _chats[idx];
    final updatedMessages = [...chat.messages, msg];
    final lastMsg =
        type == MessageType.meetupProposal ? '📍 Meetup proposed' : text;

    final updatedChat = ChatModel(
      id: chat.id,
      bookId: chat.bookId,
      bookTitle: chat.bookTitle,
      bookImage: chat.bookImage,
      buyerId: chat.buyerId,
      buyerName: chat.buyerName,
      sellerId: chat.sellerId,
      sellerName: chat.sellerName,
      messages: updatedMessages,
      lastMessageTime: msg.timestamp,
      lastMessage: lastMsg,
      unreadCount: chat.unreadCount + 1,
    );

    // Persist updated chat metadata
    await _db.updateChat(updatedChat);

    _chats[idx] = updatedChat;
    notifyListeners();
  }

  // ─── MARK READ ────────────────────────────────────────────────────

  Future<void> markAsRead(String chatId) async {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;

    await _db.markChatAsRead(chatId);

    final chat = _chats[idx];
    _chats[idx] = ChatModel(
      id: chat.id,
      bookId: chat.bookId,
      bookTitle: chat.bookTitle,
      bookImage: chat.bookImage,
      buyerId: chat.buyerId,
      buyerName: chat.buyerName,
      sellerId: chat.sellerId,
      sellerName: chat.sellerName,
      messages: chat.messages,
      lastMessageTime: chat.lastMessageTime,
      lastMessage: chat.lastMessage,
      unreadCount: 0,
    );
    notifyListeners();
  }
}
