import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { workoutResult, achievement, general, challenge }

class SocialPostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final PostType type;
  final String content;
  final String? workoutResultId; // Reference to workout result if applicable
  final String? imageUrl;
  final List<String> likes; // User IDs
  final int commentCount;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Extra data (achievement info, etc.)

  SocialPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.content,
    this.workoutResultId,
    this.imageUrl,
    this.likes = const [],
    this.commentCount = 0,
    required this.createdAt,
    this.metadata,
  });

  factory SocialPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialPostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      type: PostType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PostType.general,
      ),
      content: data['content'] ?? '',
      workoutResultId: data['workoutResultId'],
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type.name,
      'content': content,
      'workoutResultId': workoutResultId,
      'imageUrl': imageUrl,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  bool isLikedBy(String userId) => likes.contains(userId);
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
