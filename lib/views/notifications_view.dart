import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../models/notification.dart';


/// This class is a simple view for displaying all notifications. From this view,
/// users can mark all notifications as read and delete all notifications. Read and
/// unread notifications can be viewed here unless deleted. User can also sort which 
/// notifications to be displayed (all, team, snippet upvotes).
/// 
/// This view is accessed from the notification bell dropdown.

enum NotificationFilter { all, personal, team }

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {

  NotificationFilter _currentFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notificationsAsync = ref.watch(notificationStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          
          // Mark all notifs read button
          IconButton(
            tooltip: "Mark all as read",
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllRead(user?.uid),
          ),
          
          // Delete all notifs button
          IconButton(
            tooltip: "Delete all",
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmDeleteAll(context, user?.uid),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildFilterChip(NotificationFilter.all, "All", Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip(NotificationFilter.personal, "Personal", Icons.person),
                const SizedBox(width: 8),
                _buildFilterChip(NotificationFilter.team, "Team", Icons.groups),
              ],
            ),
          ),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (allNotifications) {
          final filteredList = allNotifications.where((n) {
            switch (_currentFilter) {
              case NotificationFilter.all:
                return true; 
              case NotificationFilter.personal:
                return n.icon == Icons.arrow_upward || n.icon == Icons.group_add;
              case NotificationFilter.team:
                return n.icon == Icons.code;
            }
          }).toList();

          if (filteredList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text("No notifications found"),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = filteredList[index];
              return _NotificationTile(
                notification: notif, 
                userId: user!.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(NotificationFilter filter, String label, IconData icon) {
    final isSelected = _currentFilter == filter;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? colorScheme.onPrimary : colorScheme.primary),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          _currentFilter = filter;
        });
      },
    );
  }

  Future<void> _markAllRead(String? userId) async {
    if (userId == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marked all as read")));
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, String? userId) async {
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All?"),
        content: const Text("This will permanently delete all displayed notifications."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();
        
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All notifications deleted")));
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String userId;

  const _NotificationTile({
    required this.notification,
    required this.userId,
  });

  Future<void> _delete(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notification.id)
        .delete();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification deleted")));
    }
  }

  Future<void> _toggleRead() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notification.id)
        .update({'isRead': !notification.isRead});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRead = notification.isRead;

    // highlight unread notifs
    final bgColor = isRead 
        ? Colors.transparent 
        : colorScheme.primary.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: isRead ? null : Border(left: BorderSide(color: colorScheme.primary, width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: notification.isUrgent 
                  ? Colors.red.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              child: Icon(
                notification.isUrgent ? Icons.priority_high : notification.icon,
                color: notification.isUrgent ? Colors.red : colorScheme.primary,
                size: 20,
              ),
            ),
            if (!isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isRead 
                  ? colorScheme.onSurface.withValues(alpha: 0.6) 
                  : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeago.format(notification.time),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) {
            if (value == 'toggle') {
              _toggleRead();
            } else if (value == 'delete') {
              _delete(context);
            }
          },
          itemBuilder: (context) => [
             PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(isRead ? Icons.mark_email_unread : Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(isRead ? "Mark as unread" : "Mark as read"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text("Delete", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Mark as read
          if (!isRead) _toggleRead();
          
          // Go to source of notif if existst
          if (notification.route != null) {
            context.push(notification.route!);
          }
        },
      ),
    );
  }
}