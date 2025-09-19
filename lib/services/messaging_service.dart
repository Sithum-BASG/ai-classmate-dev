import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  MessagingService({FirebaseMessaging? messaging})
      : messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging messaging;
}
