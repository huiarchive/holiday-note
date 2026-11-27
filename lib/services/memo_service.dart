
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get uid {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    return user.uid;
  }

  String dateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  DocumentReference<Map<String, dynamic>> memoRef(DateTime date) {
    return db
        .collection('users')
        .doc(uid)
        .collection('memos')
        .doc(dateKey(date));
  }

  Future<void> saveMemo(
    DateTime date,
    String content,
  ) async {
    await memoRef(date).set({
      'date': dateKey(date),
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getMemo(DateTime date) async {
    final snapshot = await memoRef(date).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data()?['content'] as String?;
  }

  Future<void> deleteMemo(DateTime date) async {
    await memoRef(date).delete();
  }
}
