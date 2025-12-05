/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 * 
 * ******************************************************************************************
 * 
 * The functions folder in root directory is part of firebase cloud messaging v1.
 * This file is responsible for the actual reception of a push notification.
 * 
 * It pays attention to notifications stored in the Firestore database.
 * When a new notification doc is created (onCreate()), it gets gets the user's
 * device tokens and sends push notifications to that device. 
 * 
 * NOTE that this works only along side of lib/providers/firebase_api.dart, which
 * is used to fetch device permissions for 
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendPushNotification = onDocumentCreated('users/{userId}/notifications/{notificationId}', async (event) => {
    // getting user from upstream user doc
    const userId = event.params.userId;
    if (!event.data){
        // if notification has no user, do nothing (for testing, all notifs should have a user for final build)
        return null;
    } 

    const notificationData = event.data.data();

    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists){
        console.log('error sending notif, no user found'); //TESTING - DELETE LATER
        return null;
    }

    const userData = userDoc.data(); // user data includes collection of device tokens & notifications belonging to that user
    const tokens = userData.fcmTokens;
    if (!tokens || tokens.length === 0) {
        console.log('error sending notif, no device tokens, user is possibly a web user only. userid: ',userId);
        return null;
    }

    // Get notification id for marking as read when tapped
    const notificationId = event.params.notificationId;

    // Creating push notification contents
    const message = {
        tokens: tokens,
        notification: {
            title: String(notificationData.title || 'New notification'),
            body: String(notificationData.body || ''),
        },
        data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            icon: notificationData.icon || 'code',
            path: notificationData.path || '/dashboard',
            notificationId: notificationId,
            isUrgent: String(notificationData.isUrgent || 'false'),
        },
        android: {
            priority: 'high',
            notification: {
                channelId: 'high_importance_channel',
                defaultSound: true,
            }
        }
    };

    // sending notification to user device
    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log('notification sent successful, number of devices sent to: ',response.successCount);
        console.log('number of devices meant to receive notif: ',tokens);

        // Removes invalid tokens (i.e. user uninstalled app)
        // DO NOT REMOVE -> needed for testing when uninstalling/installing diff versions of app
        const failedTokens = [];
        response.responses.forEach((response, index) => {
            if (!response.success){
                failedTokens.push(tokens[index]);
            }
        });
        if (failedTokens.length > 0) {
            await admin.firestore().collection('users').doc(userId).update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens)
            });
        }
    }
    catch (e) {
        console.error('error sending notif: ',e);
    }
});