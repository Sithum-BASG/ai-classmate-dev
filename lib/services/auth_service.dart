import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // Placeholder API shape; implementation will be added during integration.
  User? get currentUser => _auth.currentUser;
}
