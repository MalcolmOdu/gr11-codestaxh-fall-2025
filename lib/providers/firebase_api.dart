import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


/// This class 

// Handles notifs when app is closed. Uses @pragma('vm:entry-point')
// to ensure it is never removed during tree shaking.
// https://www.youtube.com/shorts/67wsfPCsVkA
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async{
  // 
}

class FirebaseApi {

  // Instance of firebase messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initNotifications() async {
    // do nothing if using web version
    if (kIsWeb){return;}
    // Requests permission from user (otherwise device will block notifs)
    await _firebaseMessaging.requestPermission();

    // Fetch FCM (firebase cloud messaging) token for current device
    final fcmToken = await _firebaseMessaging.getToken();


    // Save token to firestore
    if (fcmToken != null) {
      //DEBUG
      print('FCM Token: $fcmToken');

      //ensures token saved on signin
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null){
          _saveToken(fcmToken);
        }
      });
    }
    initPushNotifications();
  }

  // Saves device token to user doc in firestore to receive notifs for the user acc.
  // Used by cloud function to know which devices belong to a user that is receiving a notification.
  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null){return;}  // Do nothing if not signed in. Needed because initialized in main
    
    // UPDATES user doc (doesn't replace) and adds the token using UNION instead
    // to prevent duplicates (i.e. multiple devices can have tokens and recieve 
    // push notifications for the same account)
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
  }

  // Function to handle a push notification being tapped.
  void handleMessage(RemoteMessage? message){
    
    // Do nothing if no message
    if (message == null) return;

    // Routing for when notif is clicked
    if (message.data.containsKey('path')){
      appRouter.push(message.data['path']!);
    }
    else{
      appRouter.go('/dashboard');
    }
  }

  Future initPushNotifications() async {
    // handles notif if received while app closed and then app is opened 
    //  normally instead of clicking notification
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Handle notif if app is running in the background then opened
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Handle notif if app is running in background/system tray
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // NOTE can also add handle for when app is already opened but
    //  can also just leave that to the bell icon. If implementing,
    //  use snackbar to notify.

    
  }
}