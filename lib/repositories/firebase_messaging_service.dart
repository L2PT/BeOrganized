import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging;
  bool enabled = false;
  
  FirebaseMessagingService([FirebaseMessaging? firebaseMessaging])
      : _firebaseMessaging = firebaseMessaging ??  FirebaseMessaging.instance;
  
  static Future<FirebaseMessagingService> create() async {
    FirebaseMessagingService instance = FirebaseMessagingService();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return instance;
  }
  void init(handlerOnMessage, handlerOnMessageOpenedApp, handlerOnBackgroundMessage) async {
    bool enabled = await requestPermission();
    
    // set handlers
    if (enabled) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null)
          handlerOnMessage?.call(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification != null)
          handlerOnMessageOpenedApp?.call(message);
      });
      
      // https://firebase.flutter.dev/docs/messaging/usage/#background-messages
      FirebaseMessaging.onBackgroundMessage(handlerOnBackgroundMessage);

      _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;

          if (notification != null && android != null)
            handlerOnMessage?.call(message);
        }
      });
    }
  }  
  
  Future<bool> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  static Future<String?> getToken()=> FirebaseMessaging.instance.getToken();

  static Future<void> sendNotifications(void Function(String, List failedTokens)? onTokensRemoved,{
    tokens = const [],
    String accountId = "",
    String title = "Nuovo incarico assegnato",
    String description = "Clicca la notifica per vedere i dettagli",
    String style = Constants.notificationInfoTheme,
    String type = Constants.eventNotification,
    String eventId = "",
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendNotifications');

      final result = await callable.call({
        'tokens': tokens,
        'title': title,
        'description': description,
        'style': style,
        'type': type,
        'eventId': eventId,
      });

      if (Constants.debug) {
        print("Notifiche inviate: ${result.data['successCount']} successi, ${result.data['failureCount']} fallimenti");
      }

      // Rimuovi i token che sono falliti
      if (result.data['failedTokens'] != null && result.data['failedTokens'].isNotEmpty) {
        List<String> failedTokens = List<String>.from(
            result.data['failedTokens']);
        tokens.removeWhere((token) => failedTokens.contains(token));

        if (Constants.debug) {
          print("Rimossi ${failedTokens.length} token non validi");
          print("Token rimanenti: ${tokens.length}");
        }
        onTokensRemoved!(accountId, tokens);
      }
    } catch (e) {
      print("Errore invio notifiche: $e");
    }
  }

}