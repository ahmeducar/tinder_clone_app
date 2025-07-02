import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;  // Sohbet odası ID'si
  final String senderId;        // Mesajı gönderen kullanıcının UID'si
  final String receiverId;      // Mesajı alan kullanıcının UID'si
  final String message;         // Mesaj içeriği
  final Timestamp timestamp;    // Mesajın gönderilme zamanı
  final bool read;              // Mesajın okundu mu olduğu bilgisi

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  // Firestore verisini alıp Message nesnesine dönüştürür
  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      id: doc.id,
      conversationId: doc['conversationId'],
      senderId: doc['senderId'],
      receiverId: doc['receiverId'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      read: doc['read'],
    );
  }

  // Message nesnesini Firebase formatında bir Map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'read': read,
    };
  }
}
