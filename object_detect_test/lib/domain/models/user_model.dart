// https://firebase.google.com/docs/firestore/query-data/get-data
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { homeowner, contractor }

class User {
  final String userID;
  final String email;
  final UserType type;
  final DateTime createdDate;

  User({
    required this.userID,
    required this.email,
    required this.type,
    required this.createdDate,
  });

  // Convert from Firestore map to User
  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
    ){
      final map = snapshot.data();
      return User(
        userID: map?['UID'] as String,
        email: map?['email'] as String,
        type: _userTypeFromString(map?['type'] as int),
        createdDate: (map?['createdDate'] as Timestamp).toDate(),
      );
  }

  // Convert from User to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'UID': userID,
      'email': email,
      'type': type.name,  // Converts enum to string
      'createdDate': Timestamp.fromDate(createdDate),
    };
  }

  // Helper to convert string to enum
  static UserType _userTypeFromString(int userTypeInt) {
    switch (userTypeInt) {
      case 0:
        return UserType.homeowner;
      case 1:
        return UserType.contractor;
      default:
        throw Exception('Unknown user type: $userTypeInt');
    }
  }
}