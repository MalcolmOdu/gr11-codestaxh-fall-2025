import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// Simple class to define the contents of a notification

class AppNotification {
  final String id;
  final String title; 
  final String body;    // e.g. snippet description
  final IconData icon;  // e.g. team icon, code icon, upvote icon
  final bool isRead;  
  final DateTime time;
  final String? route; // Used for routing to detailed view when notif is tapped
  final bool isUrgent; // Determines whether bell icon displays red '!'

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    this.isRead = false,
    required this.time,
    this.route,
    this.isUrgent = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // IconData does not work well with Firebase. Store String and use to determine icon in code
    // (keep IconData field for gui, use String for firebase)
    final String type = data['icon'] ?? 'info';
    
    IconData resolvedIcon;
    switch (type) {
      case 'upvote':
        resolvedIcon = Icons.arrow_upward;
        break;
      case 'invite':
        resolvedIcon = Icons.group_add;
        break;
      case 'code':
        resolvedIcon = Icons.code;
        break;
      default:
        resolvedIcon = Icons.notifications;
    }


    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      icon: resolvedIcon, // Convert string to icon
      isRead: data['isRead'] ?? false,
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      route: data['path'],
      isUrgent: data['isUrgent'] ?? false,
    );
  }
}