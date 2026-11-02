import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'dart:typed_data';

class FirebaseStoragePost {
  static Future<String> uploadFile({
    required String folderName,
    required File postFile,
  }) async {
    final fileName = basename(postFile.path);
    final destination = 'files/$folderName/$fileName';
    final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
    UploadTask uploadTask = ref.putFile(postFile);
    String fileOfPostUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return fileOfPostUrl;
  }

  static Future<String> uploadData(
      {required String folderName, required Uint8List data}) async {
    // DateTime.now().toString() er bodole milliseconds use kora valo (space ba colon thake na)
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final destination = 'data/$folderName/$fileName';
    final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
    UploadTask uploadTask = ref.putData(data);
    String fileOfPostUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return fileOfPostUrl;
  }

  static Future<void> deleteImageFromStorage(String previousImageUrl) async {
    if (previousImageUrl.isEmpty) return;
    try {
      // refFromURL use korle direct download URL theke reference peye jabe
      final Reference firebaseStorageRef =
          FirebaseStorage.instance.refFromURL(previousImageUrl);
      await firebaseStorageRef.delete();
    } catch (e) {
      print("Error deleting image: $e");
    }
  }
}
