import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';

final notificationStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  
  final user = FirebaseAuth.instance.currentUser;

  // No notifications to a user that doesnt exist
  if (user == null) {return Stream.value([]);}

  // Listen for updates to notifications in Firebase for user
  return FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)
  .collection('notifications')
  .orderBy('time', descending: true)
  .snapshots()
  .map((snapshot) {
    return snapshot.docs.map((doc)=> AppNotification.fromFirestore(doc)).toList();
  });
});

class NotificationProvider {

  // Send a notification to a specific user
  static Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String iconString, 
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'icon': iconString,
        'isRead': false,
        'time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}