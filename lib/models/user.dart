import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String bio;

  UserProfile({
    required this.bio,
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
  });
 

  factory UserProfile.fromDocument(DocumentSnapshot doc){
    return UserProfile(
      bio: doc['bio'],
      uid: doc['uid'],
      name: doc['name'],
      email: doc['email'],
      username: doc['username'],
    );
  } 



  Map<String, dynamic> toMap() {
    return {
      'bio': bio,
      'uid': uid,
      'name': name,
      'email': email,
      'username': username,
    };
  }
}  