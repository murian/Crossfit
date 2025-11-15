import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/social_post_model.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get social feed
  Stream<List<SocialPostModel>> getSocialFeed({int limit = 50}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialPostModel.fromFirestore(doc))
            .toList());
  }

  // Get user's posts
  Stream<List<SocialPostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialPostModel.fromFirestore(doc))
            .toList());
  }

  // Create post
  Future<String> createPost(SocialPostModel post) async {
    final docRef = await _firestore.collection('posts').add(post.toFirestore());
    return docRef.id;
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  // Add comment
  Future<String> addComment(CommentModel comment) async {
    final docRef = await _firestore.collection('comments').add(comment.toFirestore());

    // Increment comment count on post
    await _firestore.collection('posts').doc(comment.postId).update({
      'commentCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    // Delete all comments
    final comments = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in comments.docs) {
      await doc.reference.delete();
    }

    // Delete post
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Delete comment
  Future<void> deleteComment(String commentId, String postId) async {
    await _firestore.collection('comments').doc(commentId).delete();

    // Decrement comment count on post
    await _firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }
}
