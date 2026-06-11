import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/chat_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_card.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الدردشة')),
        body: const _ChatRoomList(),
      ),
    );
  }
}

class _ChatRoomList extends StatelessWidget {
  const _ChatRoomList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Sample rooms - in real use these come from GAS API
    final rooms = [
      ChatRoom(id: 'general', name: 'المجموعة العامة', description: 'نقاشات عامة', createdBy: 'admin'),
      ChatRoom(id: 'nutrition', name: 'التغذية', description: 'نصائح وأسئلة التغذية', createdBy: 'admin'),
      ChatRoom(id: 'workout', name: 'التمارين', description: 'أسئلة التمارين والبرامج', createdBy: 'admin'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final room = rooms[i];
        return AppCard(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.accentDark, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    room.name[0],
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
                    if (room.description != null)
                      Text(room.description!, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.accent),
            ],
          ),
        );
      },
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;
  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await DatabaseHelper.instance.getChatMessages(widget.room.id);
    setState(() { _messages = msgs; _loading = false; });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final msg = ChatMessage(
      id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      roomId: widget.room.id,
      senderUid: user.uid,
      senderName: user.name,
      text: text,
      sentAt: DateTime.now(),
    );

    _msgCtrl.clear();
    await DatabaseHelper.instance.saveChatMessage(msg);
    setState(() => _messages = [..._messages, msg]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.room.name),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: isDark ? AppColors.text3Dark : AppColors.text3Light),
                              const SizedBox(height: 8),
                              const Text('لا توجد رسائل بعد', style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final msg = _messages[i];
                            final isMe = msg.senderUid == user?.uid;
                            return _MessageBubble(msg: msg, isMe: isMe);
                          },
                        ),
            ),
            _MessageInput(controller: _msgCtrl, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accent : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A28) : const Color(0xFFF0EDE8)),
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(18),
            topLeft: const Radius.circular(18),
            bottomRight: isMe ? Radius.zero : const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg.senderName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
            Text(
              msg.text,
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 14,
                color: isMe ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${msg.sentAt.hour.toString().padLeft(2,'0')}:${msg.sentAt.minute.toString().padLeft(2,'0')}',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: isMe ? Colors.white70 : AppColors.text3Light),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A18) : const Color(0xFAF7F4EE),
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3, minLines: 1,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0x0DFFFFFF) : Colors.white,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
