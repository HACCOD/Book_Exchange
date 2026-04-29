import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().markAsRead(widget.chat.id);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final userId =
        context.read<AuthProvider>().currentUser!.id;
    context.read<ChatProvider>().sendMessage(
          chatId: widget.chat.id,
          senderId: userId,
          text: text,
        );
    _msgCtrl.clear();
    Future.delayed(
        const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _proposeMeetup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MeetupSheet(
        onSelect: (location) {
          final userId =
              context.read<AuthProvider>().currentUser!.id;
          context.read<ChatProvider>().sendMessage(
                chatId: widget.chat.id,
                senderId: userId,
                text: 'Meetup proposed at: $location',
                type: MessageType.meetupProposal,
              );
          Navigator.pop(context);
          Future.delayed(
              const Duration(milliseconds: 100), _scrollToBottom);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        context.watch<AuthProvider>().currentUser!.id;
    final chat =
        context.watch<ChatProvider>().getChatById(widget.chat.id) ??
            widget.chat;
    final otherName = chat.otherPersonName(userId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherName,
                style: const TextStyle(fontSize: 16)),
            Text('📖 ${chat.bookTitle}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: _proposeMeetup,
            tooltip: 'Propose Meetup',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color:
                                AppTheme.textGrey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Start the conversation about\n"${chat.bookTitle}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = chat.messages[i];
                      final isMe = msg.senderId == userId;
                      return _MessageBubble(
                          message: msg, isMe: isMe);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined,
                        color: AppTheme.primary),
                    onPressed: _proposeMeetup,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isMeetup = message.type == MessageType.meetupProposal;

    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMeetup
              ? AppTheme.accent.withValues(alpha: 0.15)
              : isMe
                  ? AppTheme.primary
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMeetup
              ? Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.4))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMeetup
                    ? AppTheme.textDark
                    : isMe
                        ? Colors.white
                        : AppTheme.textDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MeetupSheet extends StatelessWidget {
  final void Function(String location) onSelect;
  const _MeetupSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Propose Meetup Location',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Select a campus location to meet',
              style: TextStyle(
                  color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.campusLocations
                .map((loc) => ActionChip(
                      label: Text(loc),
                      avatar: const Icon(Icons.location_on,
                          size: 16, color: AppTheme.primary),
                      onPressed: () => onSelect(loc),
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.08),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
