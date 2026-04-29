import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final chats =
        context.watch<ChatProvider>().chatsForUser(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64,
                      color: AppTheme.textGrey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('No conversations yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGrey)),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse books and contact sellers to start chatting',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textGrey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (ctx, i) {
                final chat = chats[i];
                final otherName = chat.otherPersonName(user.id);
                final isUnread = chat.unreadCount > 0 &&
                    chat.sellerId == user.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnread
                              ? AppTheme.primary
                              : AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📖 ${chat.bookTitle}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGrey)),
                      Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isUnread
                              ? AppTheme.textDark
                              : AppTheme.textGrey,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    context
                        .read<ChatProvider>()
                        .markAsRead(chat.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatScreen(chat: chat)),
                    );
                  },
                );
              },
            ),
    );
  }
}
