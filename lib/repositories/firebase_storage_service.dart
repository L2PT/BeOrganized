import 'package:firebase_storage/firebase_storage.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';

class FirebaseStorageService {
  static final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  
  static Future<void> uploadFile(dynamic file, String storagePath) async {
    try {
      await PlatformUtils.uploadFileStorage(_firebaseStorage.ref(storagePath), file);
    } on FirebaseException catch (e) {
      throw Exception('Errore Firebase Storage: ${e.code} - ${e.message}');
    }
  }

  static Future<void> deleteFile(String storagePath) async {
    try {
      await _firebaseStorage.ref(storagePath).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage delete error: ${e.code} - ${e.message}');
    }
  }

  static Future<ListResult> listFiles(String path) async {
    ListResult result =  await _firebaseStorage.ref(path).listAll();
    return result;
  }

  static Future<String> downloadURL(String path) async {
    String downloadURL = await _firebaseStorage.ref(path).getDownloadURL();
    return downloadURL;
  }
  
}
