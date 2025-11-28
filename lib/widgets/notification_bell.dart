import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codestaxh/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart';

/// This class is essentially just a copy past re-usable version of the notification
/// implementation in views/web/web_dashboard_view.dart
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

        return PopupMenuButton(
          offset: const Offset(0, 50),
          tooltip: 'Notifications',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.cardColor,
          
          onOpened: () {
            if (unreadNotifs.isNotEmpty && user != null) {
              for (final notif in unreadNotifs) {
                NotificationProvider.markAsRead(user.uid, notif.id);
              }
            }
          },

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
            if (data.isEmpty) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Text('No notifications.'),
                )
              ];
            }

            return data.map((n) {
              return PopupMenuItem(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: n.isRead 
                          ? Colors.transparent 
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      n.icon, 
                      size: 20, 
                      color: n.isRead ? Colors.grey : colorScheme.primary
                    ),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
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
                  trailing: Text(
                    timeago.format(n.time, locale: 'en_short'),
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5), 
                      fontSize: 10
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}