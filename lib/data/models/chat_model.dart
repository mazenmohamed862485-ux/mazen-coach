import 'dart:convert';

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String createdBy;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdBy,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    lastMessage: json['lastMessage']?.toString(),
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(json['lastMessageTime'].toString()) ?? 0)
        : null,
    createdBy: json['createdBy']?.toString() ?? '',
    unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (lastMessageTime != null) 'lastMessageTime': lastMessageTime!.millisecondsSinceEpoch,
    'createdBy': createdBy,
    'unreadCount': unreadCount,
  };
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderUid;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime sentAt;
  final bool isRead;
  final String? replyTo;
  final String? replyText;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderUid,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.sentAt,
    this.isRead = false,
    this.replyTo,
    this.replyText,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? '',
    roomId: json['roomId']?.toString() ?? '',
    senderUid: json['senderUid']?.toString() ?? '',
    senderName: json['senderName']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString(),
    sentAt: json['sentAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(json['sentAt'].toString()) ?? 0)
        : DateTime.now(),
    isRead: json['isRead'] == true,
    replyTo: json['replyTo']?.toString(),
    replyText: json['replyText']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'senderUid': senderUid,
    'senderName': senderName,
    'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'sentAt': sentAt.millisecondsSinceEpoch,
    'isRead': isRead,
    if (replyTo != null) 'replyTo': replyTo,
    if (replyText != null) 'replyText': replyText,
  };

  String toJsonString() => jsonEncode(toJson());
}
