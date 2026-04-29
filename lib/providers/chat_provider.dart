import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatModel> _chats = [];

  List<ChatModel> chatsForUser(String userId) => _chats
      .where((c) => c.buyerId == userId || c.sellerId == userId)
      .toList()
    ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

  ChatModel? getChatById(String chatId) {
    try {
      return _chats.firstWhere((c) => c.id == chatId);
    } catch (_) {
      return null;
    }
  }

  ChatModel? getChatForBook({
    required String bookId,
    required String buyerId,
    required String sellerId,
  }) {
    try {
      return _chats.firstWhere((c) =>
          c.bookId == bookId &&
          c.buyerId == buyerId &&
          c.sellerId == sellerId);
    } catch (_) {
      return null;
    }
  }

  ChatModel startChat({
    required String bookId,
    required String bookTitle,
    String? bookImage,
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
  }) {
    final existing = getChatForBook(
        bookId: bookId, buyerId: buyerId, sellerId: sellerId);
    if (existing != null) return existing;

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
    _chats.add(chat);
    notifyListeners();
    return chat;
  }

  void sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
  }) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;

    final msg = MessageModel(
      id: const Uuid().v4(),
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      type: type,
    );

    final chat = _chats[idx];
    final updatedMessages = [...chat.messages, msg];

    _chats[idx] = ChatModel(
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
      lastMessage:
          type == MessageType.meetupProposal ? '📍 Meetup proposed' : text,
      unreadCount: chat.unreadCount + 1,
    );
    notifyListeners();
  }

  void markAsRead(String chatId) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;
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

  int totalUnread(String userId) => chatsForUser(userId)
      .fold(0, (sum, c) => sum + (c.sellerId == userId ? c.unreadCount : 0));

  void loadDemoChats(String currentUserId) {
    if (_chats.isNotEmpty) return;
    final uuid = const Uuid();
    final now = DateTime.now();

    final msg1 = MessageModel(
      id: uuid.v4(),
      senderId: 'other-user-1',
      text: 'Hi! Is the Computer Networks book still available?',
      timestamp: now.subtract(const Duration(minutes: 30)),
    );
    final msg2 = MessageModel(
      id: uuid.v4(),
      senderId: currentUserId,
      text: 'Yes it is! Come to the library tomorrow.',
      timestamp: now.subtract(const Duration(minutes: 25)),
    );

    _chats.add(ChatModel(
      id: uuid.v4(),
      bookId: 'demo-book-1',
      bookTitle: 'Computer Networks',
      buyerId: 'other-user-1',
      buyerName: 'Sara Khan',
      sellerId: currentUserId,
      sellerName: 'Ali Hassan',
      messages: [msg1, msg2],
      lastMessageTime: msg2.timestamp,
      lastMessage: msg2.text,
      unreadCount: 0,
    ));

    notifyListeners();
  }
}
