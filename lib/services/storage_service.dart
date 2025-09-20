import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage storage;
}
