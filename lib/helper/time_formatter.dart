import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();  // UTC olarak alıyoruz
  dateTime = dateTime.add(Duration(hours: 3));  // Burada 3 saat ekliyoruz
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
}
