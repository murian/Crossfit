import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/messaging_service.dart';
import '../../../core/theme/app_theme.dart';

final conversationsProvider = StreamProvider((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return const Stream.empty();
  return ref.watch(messagingServiceProvider).getUserConversations(currentUser.id);
});

final unreadCountProvider = StreamProvider((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value(0);
  return ref.watch(messagingServiceProvider).getUnreadCount(currentUser.id);
});

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with someone',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participants.firstWhere(
                (id) => id != currentUser?.id,
              );
              final otherUserName = conversation.participantNames[otherUserId] ?? 'Unknown';
              final otherUserPhoto = conversation.participantPhotos[otherUserId];
              final unreadCount = conversation.unreadCount[currentUser?.id] ?? 0;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryYellow,
                      backgroundImage: otherUserPhoto != null ? NetworkImage(otherUserPhoto) : null,
                      child: otherUserPhoto == null
                          ? Text(
                              otherUserName[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.deepBlack,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  otherUserName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                subtitle: conversation.lastMessage != null
                    ? Text(
                        conversation.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                      )
                    : null,
                trailing: conversation.lastMessageTime != null
                    ? Text(
                        DateFormat('MMM d').format(conversation.lastMessageTime!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      )
                    : null,
                onTap: () {
                  // TODO: Navigate to chat page
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
