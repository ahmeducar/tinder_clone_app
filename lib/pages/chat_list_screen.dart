import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_game_app/pages/chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  Future<List<QueryDocumentSnapshot>> fetchMatches() async {
    //* currentUser değişkenine firebaseden aldığımız var olan kullanıcı bilgisi atandı
    final currentUser = FirebaseAuth.instance.currentUser;
    //* uygulamada biri yoksa boş dönecek
    if (currentUser == null) return [];

    //* eşleşme ile ilgili kısım firebase de matches collection'ında, Bu satır sayesinde uygulama sadece sana ait eşleşmeleri çeker.
    //* Bu veri sonra ekranda gösterilir.
    final matchesSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: currentUser.uid)
         //* .orderBy('timestamp', descending: true)
        .get();

    return matchesSnapshot.docs;
  }

  //* eşleşme listesindeki iki kullanıcıdan karşı tarafı yani ben olmayani bulmak için yazılmış.
  String getOtherUserId(List<dynamic> users, String currentUserId) {
    return users.firstWhere((uid) => uid != currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: fetchMatches(),
        //* AsyncSnapshot<List<QueryDocumentSnapshot<Object?>>> sınıfı içerisinde snapshot 

        //* beklerken daire döndürür.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          //* 📌 "Eğer veri hiç gelmediyse (!snapshot.hasData)
          //* veya veri geldiyse ama boşsa (snapshot.data!.isEmpty)
          //* o zaman ekrana 'Henüz eşleşme yok' yaz."**

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz eşleşme yok.'));
          }

          //* Eğer snapshot içindeki data varsa (yani null değilse), onu matches adında bir değişkene ata.
          final matches = snapshot.data!;


          //* chatList sayfasını listeleme olarak kullanıyoruz o yüzden ListView kullanılıyor.
          return ListView.builder(
            //* itemCount dediğin var olan konuşmalar sayısı bunu matches.length ile biliyoruz.
            itemCount: matches.length,

            //* itemBuilder içerisinde context
            itemBuilder: (context, index) {
              //* Firebase'den gelen ham veriyi, bir harita (map) hâline getirip, kolayca kullanabilmemizi sağlar.
              final matchData = matches[index].data() as Map<String, dynamic>;

              //* Bu satır, uygulamadaki sohbet eşleşmesinde karşı tarafın kullanıcı ID'sini bulmak için yazılmış.
              final otherUserId = getOtherUserId(matchData['users'], currentUser!.uid);


              return FutureBuilder<DocumentSnapshot>(

                //* "profiles" koleksiyonunda, ID’si otherUserId olan belgeyi çek.
                future: FirebaseFirestore.instance.collection('profiles').doc(otherUserId).get(),
                builder: (context, profileSnapshot) {

                  //* Eğer henüz veri gelmediyse (bekleme aşamasındaysa), ekrana geçici olarak "Yükleniyor..." yazan bir kutucuk gösterilir.
                  if (!profileSnapshot.hasData) {
                    return ListTile(title: Text('Yükleniyor...'));
                  }
                  //* profileSnapshot.data! → Firestore’dan gelen belge
                  //* .data() → Belge içindeki alanlara erişim sağlar
                  //* as Map<String, dynamic>? → "Bu veri bir Map'tir (yani JSON gibi)."

                  final profileData = profileSnapshot.data!.data() as Map<String, dynamic>?;

                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profileData != null && profileData['imageUrls'] != null && (profileData['imageUrls'] as List).isNotEmpty
                          ? NetworkImage(profileData['imageUrls'][0])
                          : null,
                      child: profileData == null || profileData['imageUrls'] == null || (profileData['imageUrls'] as List).isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profileData?['name'] ?? 'Kullanıcı'),
                    subtitle: const Text('Mesaja gitmek için dokun'),
                    onTap: () {
                      //* chatPage dosyasına geçiş yapar
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            //* karşı kullanıcının idsine denk gelir
                            chatUserId: otherUserId,
                            //* varsa kullanıcının adı yazar, yoksa Kullanıcı yazar.
                            chatUserName: profileData?['name'] ?? 'Kullanıcı',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ), 
    );
  }
}
