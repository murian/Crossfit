import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) => MessagingService());

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2,
      Map<String, String> names, Map<String, String?> photos) async {
    // Sort user IDs to ensure consistent conversation ID
    final participants = [userId1, userId2]..sort();

    // Check if conversation exists
    final existingConversations = await _firestore
        .collection('conversations')
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (existingConversations.docs.isNotEmpty) {
      return existingConversations.docs.first.id;
    }

    // Create new conversation
    final conversation = ConversationModel(
      id: '',
      participants: participants,
      participantNames: names,
      participantPhotos: photos,
      unreadCount: {userId1: 0, userId2: 0},
    );

    final docRef = await _firestore.collection('conversations').add(conversation.toFirestore());
    return docRef.id;
  }

  // Get user's conversations
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  // Send message
  Future<String> sendMessage(MessageModel message) async {
    final docRef = await _firestore.collection('messages').add(message.toFirestore());

    // Update conversation
    await _firestore.collection('conversations').doc(message.conversationId).update({
      'lastMessage': message.content,
      'lastMessageTime': Timestamp.fromDate(message.sentAt),
      'unreadCount.${message.receiverId}': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // Get messages for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final unreadMessages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }

    // Reset unread count in conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$userId': 0,
    });
  }

  // Get unread message count for user
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final conversation = ConversationModel.fromFirestore(doc);
        total += conversation.unreadCount[userId] ?? 0;
      }
      return total;
    });
  }
}
