import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codestaxh/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';

/// This class provides a notification bell widget used in appbars when the user is signed in.
/// It alerts the user if there are any unread notifications. 
/// 
/// The GUI for this class includes buttons to mark notifications as read as well as
/// access a view containing all notifications.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notificationsWatcher = ref.watch(notificationStreamProvider);
    final user = FirebaseAuth.instance.currentUser;

    return notificationsWatcher.when(
      loading: () => IconButton(onPressed: (){}, icon: Icon(Icons.notifications_outlined)),
      error: (error, stack) => IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$error')),
          );
        },
        icon: const Icon(Icons.error_outline),
      ),

      data: (data) {
        final unreadNotifs = data.where((n) => !n.isRead).toList();
        final totalUnread = unreadNotifs.length; //used for text stating remaining unread notifs not displayed in dropdown
        final displayList = unreadNotifs.take(10).toList(); // display only 10 most recent notifs
        final remainingCount = totalUnread-displayList.length;

        return PopupMenuButton(
          offset: const Offset(0, 50),
          tooltip: 'Notifications',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.cardColor,
          icon: Badge(
            isLabelVisible: unreadNotifs.isNotEmpty,
            label: Text('!'),
            backgroundColor: colorScheme.tertiary, 
            child: Icon(
              unreadNotifs.isNotEmpty ? Icons.notifications_active : Icons.notifications_outlined,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),

          // The Dropdown List
          itemBuilder: (context) {
            List<PopupMenuEntry> menuItems = [];
            // no new notifications but still have view all button
            if (unreadNotifs.isEmpty) {
              menuItems.add(
                PopupMenuItem(
                  enabled: false,
                  child: Text('No new notifications'),
                )
              );
              menuItems.add(const PopupMenuDivider());
              menuItems.add(
                PopupMenuItem(
                  child: Center(
                    child: TextButton(
                      onPressed: (){
                        Navigator.pop(context);
                        context.push('/notifications');
                      },
                      child: const Text('View all'),
                    ),
                  )
                )
              );
              return menuItems;
            }

            // Adding the actual notifications to the dropdown
            for (var n in displayList) {
              menuItems.add(
                PopupMenuItem(
                  onTap: (){
                    NotificationProvider.markAsRead(user!.uid, n.id);
                    //routing to relevant page for notification
                    if (n.route != null){
                      Future.delayed(const Duration(milliseconds: 100), (){
                        if (context.mounted) {context.push(n.route!);}
                      });
                    }
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: n.isUrgent 
                          ? Colors.red.withValues(alpha: 0.1) 
                          : colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        n.isUrgent ? Icons.priority_high : n.icon, 
                        size: 20, 
                        color: n.isUrgent ? Colors.red : colorScheme.primary
                      ),
                    ),
                    title: Text(
                      n.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      n.body,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.8), 
                        fontSize: 12
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (n.isUrgent)
                          const Text(
                            'URGENT', 
                            style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)
                          ),
                        Text(
                          timeago.format(n.time, locale: 'en_short'),
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5), 
                            fontSize: 10
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              );
            }
            // If more than 10 unread notifications in dropdown, show user
            // how many unread notifications aren't being shown.
            if (remainingCount > 0) {
              menuItems.add(
                PopupMenuItem(
                  enabled: false,
                  height: 30,
                  child: Center(
                    child: Text(
                      '+ $remainingCount more...',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                )
              );
            }
            menuItems.add(const PopupMenuDivider());
            
            // Mark as read button
            menuItems.add(
              PopupMenuItem(
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      NotificationProvider.markAllAsRead(user!.uid);
                      Navigator.pop(context); // Close menu
                    },
                    child: const Text('Mark all read'),
                  ),
                ),
              )
            );
            menuItems.add(const PopupMenuDivider());

            // View all notificcations
            menuItems.add(
              PopupMenuItem(
                child: Center(
                  child: TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                    child: const Text('View all'),
                  ),
                )
              )
            );

            return menuItems;
          },
        );
      },
    );
  }
}