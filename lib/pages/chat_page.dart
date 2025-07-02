import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String chatUserId;
  final String chatUserName;

  const ChatPage({super.key, required this.chatUserId, required this.chatUserName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  //* mesajları tutmak için controller ekliyoruz
  final TextEditingController _controller = TextEditingController();

  //* var olan kullanıcı final ile currentUser'e verdik
  final currentUser = FirebaseAuth.instance.currentUser!;
  
  //* aynı chatId olsun diye yani 2 kişi arasında ki konuşma sadece tek bir chatId ile oluşacak
  String getChatId() {
    //* İki kullanıcı hangi sırayla konuşursa konuşsun, aynı chatId üretilmiş olur.
    return currentUser.uid.compareTo(widget.chatUserId) < 0
        ? '${currentUser.uid}_${widget.chatUserId}'
        : '${widget.chatUserId}_${currentUser.uid}';
  }

  Future<void> sendMessage() async {

    //* trim ile arada ki boşluğu alıyoruz. mesajlaşmayı _controller ile tutuyorduk bunu text adlı değişkene atadık.
    final text = _controller.text.trim();
    //* text boşsa fonksiyonu sonlandır
    if (text.isEmpty) return;

    //* getChatId fonksiyonunda oluşan string değer chatId değişkenine atanır.
    final chatId = getChatId();
    //* firestore da "messages" adlı kolleksiyon içerisinde chatId ile aktarılır ve oranında içerisinde "chat" adlı kolleksiyon oluşur
    await FirebaseFirestore.instance.collection('messages').doc(chatId).collection('chat').add({
      
      'senderId': currentUser.uid,  //* var olan kullanıcının kendi idsi
      'receiverId': widget.chatUserId,   //* mesajin iletildiği kişinin id'si
      'text': text,   //*  final text = _controller.text.trim(); burada yazdığımız text 
      'timestamp': FieldValue.serverTimestamp(),   //* zaman bilgisi
    });

    _controller.clear();   //* mesaj yazıldıktan sonra controller içerisinde ki yazıyı siliyoruz.
  }

  @override
  Widget build(BuildContext context) {
    final chatId = getChatId();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatUserName),   //* uygulamada AppBarda en yukarıda kiminle konuşuyorsak onun userName bilgisi yazacak
      ),
      body: Column(
        children: [
          //* Bu Expanded, yukarıdaki mesajlar bölümünün kalan tüm ekranı kaplamasını sağlar.
          Expanded(
            //* Firebase'den gelen gerçek zamanlı veri akışını dinleyen widget. Yeni mesaj geldikçe ekran otomatik güncellenir.
            child: StreamBuilder<QuerySnapshot>(
              //* akışı buradan sağlıyoruz stream ile
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(chatId)
                  .collection('chat')
                  .orderBy('timestamp', descending: true)

                  //*anlık veri akışı başlatılır
                  .snapshots(),

                  //* StreamBuilder; stream ve builder alır stream akışı sağlanıyor builder ile nasıl yapıldığı açıklanıyor
                  //* context ve snapshot alır.
                  //* Veri geldikçe çalışacak olan fonksiyon. snapshot içinde mesaj verileri var.
              builder: (context, snapshot) {
                
                //* Veri henüz gelmediyse yükleniyor animasyonu gösterilir.
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                //* Veri geldiyse, bu verideki tüm belgeleri al ve messages adında bir liste değişkenine kaydet diyoruz.
                final messages = snapshot.data!.docs;

                //* mesajlaşmaları listeliyoruz
                return ListView.builder(
                  //* mesajlar yukarıdan aşağıya doğru akacak yani en yeni mesaj en aşağıda olacak
                  reverse: true,
                  //* liste kaç mesajdan oluşacak onu tutuyoruz.
                  itemCount: messages.length,

                  //* Her mesajı ekrana çizmek için kullanılan yapı. index ismini biz belirledik.
                  itemBuilder: (context, index) {
                    //* messages koleksiyonu içerisinde ki mesajlar index ile map yaparak msg değişkenine atandı 
                    final msg = messages[index].data() as Map<String, dynamic>;
                    //* senderId diye tanımlamıştık yukarıda msg içerisinde ki mesajlardan senderId'si currentUser uid'sine eşit olanları
                    //* isMe adında değişkene atadık
                    final isMe = msg['senderId'] == currentUser.uid;


                    return Container(
                      //* mesajlar bana mı ait ? evetse sağa kaydır değilse : centerleft ile sola kaydır aslında 
                      //* if else mantığı 
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          //* mesaj kutucuğunun içeriği mesaj bana aitse mavi renk olsun değilse karşıdansa gri renginde
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        //* Mesajın içeriğini göster ama eğer mesaj boşsa sadece boş bir yazı kutusu göster diyoruz
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  //* textfield mesajlaşma kutucuğunun olduğu yer
                  child: TextField(
                    controller: _controller,
                    //* hintText Mesaj yaz çıkacak oraya dokunduğunda o yazı gidecek.
                    decoration: const InputDecoration(hintText: 'Mesaj yaz...'),
                  ),
                ),
                IconButton(
                  //* mesajı gönderdiğimiz icon. ona dokunduğumuzda sendMessage fonksiyonu çalışıyor ve 
                  //* mesajı iletiyoruz.
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 