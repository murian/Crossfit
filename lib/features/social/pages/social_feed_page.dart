import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/social_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/social_post_card.dart';

final socialFeedProvider = StreamProvider((ref) {
  return ref.watch(socialServiceProvider).getSocialFeed();
});

class SocialFeedPage extends ConsumerWidget {
  const SocialFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Feed'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(socialFeedProvider);
        },
        child: feedAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share your workout!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return SocialPostCard(post: posts[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show create post dialog
          _showCreatePostDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement create post
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
