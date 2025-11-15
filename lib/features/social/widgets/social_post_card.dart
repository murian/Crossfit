import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/social_post_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/social_service.dart';
import '../../../core/theme/app_theme.dart';

class SocialPostCard extends ConsumerWidget {
  final SocialPostModel post;

  const SocialPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isLiked = currentUser != null && post.isLikedBy(currentUser.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryYellow,
                  backgroundImage: post.userPhotoUrl != null
                      ? NetworkImage(post.userPhotoUrl!)
                      : null,
                  child: post.userPhotoUrl == null
                      ? Text(
                          post.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.deepBlack,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (post.type != PostType.general)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(post.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(post.type),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getTypeColor(post.type),
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            // Image
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () async {
                    if (currentUser == null) return;
                    final service = ref.read(socialServiceProvider);
                    if (isLiked) {
                      await service.unlikePost(post.id, currentUser.id);
                    } else {
                      await service.likePost(post.id, currentUser.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppTheme.errorRed : AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Comment button
                InkWell(
                  onTap: () {
                    // TODO: Open comments
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(PostType type) {
    switch (type) {
      case PostType.workoutResult:
        return AppTheme.successGreen;
      case PostType.achievement:
        return AppTheme.primaryYellow;
      case PostType.challenge:
        return AppTheme.errorRed;
      default:
        return AppTheme.infoBlue;
    }
  }

  String _getTypeLabel(PostType type) {
    switch (type) {
      case PostType.workoutResult:
        return 'Workout';
      case PostType.achievement:
        return 'Achievement';
      case PostType.challenge:
        return 'Challenge';
      default:
        return 'Post';
    }
  }
}
