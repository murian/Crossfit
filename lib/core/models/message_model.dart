import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverId': receiverId,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participants; // User IDs
  final Map<String, String> participantNames; // userId -> name
  final Map<String, String?> participantPhotos; // userId -> photoUrl
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // userId -> count

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(data['participantPhotos'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCount': unreadCount,
    };
  }
}
