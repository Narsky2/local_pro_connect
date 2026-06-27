import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FB {
  static final auth = FirebaseAuth.instance;
  static final db   = FirebaseFirestore.instance;
}
