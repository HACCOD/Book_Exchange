class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'type': type.name,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'],
        senderId: map['senderId'],
        text: map['text'],
        timestamp: DateTime.parse(map['timestamp']),
        isRead: map['isRead'] ?? false,
        type: MessageType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => MessageType.text,
        ),
      );
}

enum MessageType { text, meetupProposal, image }

class ChatModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String? bookImage;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final List<MessageModel> messages;
  final DateTime lastMessageTime;
  final String lastMessage;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImage,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.messages,
    required this.lastMessageTime,
    required this.lastMessage,
    this.unreadCount = 0,
  });

  String otherPersonName(String currentUserId) =>
      currentUserId == buyerId ? sellerName : buyerName;

  String otherPersonId(String currentUserId) =>
      currentUserId == buyerId ? sellerId : buyerId;
}
