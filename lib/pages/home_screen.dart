import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:my_game_app/pages/chat_list_screen.dart';
import 'package:my_game_app/pages/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //* kullanıcının çıkış yapıp yapmadığı için bir değişkeni başta false yapıyoruz sonrasında true olacak
  bool _isLoggingOut = false;
  
  //* QueryDocumentSnapshot cloude firestore ile ilgili, kişilerin eşleştiğinde bu bilgisini tutuyor
  List<QueryDocumentSnapshot> matchedUserDocs = [];

  //* CircularProgressIndicator için kullanılıyor
  bool isLoading = true;

  //* card swiper ile alakalı pakette kullanılıyor
  final CardSwiperController _swiperController = CardSwiperController();
  
  //* karşısına çıkan kişilerin fotoğrafları ile ilgili 
  Map<int, int> currentImageIndices = {};
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    //* eşleşen kişileri çekmek için olan fonksiyon
    fetchMatchedUsers();
  }


  //* uygulama içerisindeyken çıkış yapan fonksiyon
  Future<void> _logout() async {

    
    //* başta false şeklindeydi şimdi true oldu
    setState(() => _isLoggingOut = true);
    try {
      
      //* signOut firebase_auth paketinde bulunuyor çıkış yapabilmek için await ile çalıştıyoruz.
      await FirebaseAuth.instance.signOut();
      //* 1 saniye bekleme koyuyoruz
      await Future.delayed(const Duration(seconds: 1));
      
      //* mounted kontrolü ekliyoruz çıkış başarılıysa kullanıcıyı LoginPage sayfasına yönlendiriyor.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage(showLogoutMessage: true)),
        );
      }
    } catch (e) {       //* çıkışta hata varmı diye ekliyoruz catch kısmı 
      setState(() => _isLoggingOut = false);
      
      //* yine bir mounted kontrolü ekledik ScaffoldMessenger.of(context) kısmında hata olmasın diye
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çıkış sırasında hata oluştu')),
        );
      }
    }
  }


  //* eşleşme mantığı içeriyor targetUserId: Kaydırma yapılan hedef kullanıcı ID’si (beğenilen ya da geçilen kişi).
  Future<void> handleSwipe(String targetUserId, bool liked) async {

    //* liked ise kullanıcı beğendiyse true değilse false olarak tutulacak firebase de 

    //* uygulamada var olan kişi currentUser ile tutuluyor.
    final currentUser = FirebaseAuth.instance.currentUser;

    //* Eğer kullanıcı oturum açmamışsa (null), işlem yapılmaz ve fonksiyon erken biter.
    if (currentUser == null) return;

    //* swipeDocId: Şu anki kullanıcıdan hedef kullanıcıya doğru olan kaydırma işlemi için kullanılacak doküman ID’si.
    final swipeDocId = '${currentUser.uid}_$targetUserId';

    //* reverseSwipeDocId: Tam tersi yönde bir doküman ID (ileride "karşılıklı eşleşme var mı?" diye kontrol etmek için kullanılabilir).
    
    final reverseSwipeDocId = '${targetUserId}_${currentUser.uid}';
    //*currentUser.uid = 'abc' ve targetUserId = 'xyz' ise:

    //* swipeDocId = 'abc_xyz'

    //* reverseSwipeDocId = 'xyz_abc'

    //* firestore kaydetme işlemi bu şekilde oluyor swipes adında bir alan açılır
    //* swipes adlı koleksiyona swipeDocId isminde bir doküman oluşturur veya günceller.
    await FirebaseFirestore.instance.collection('swipes').doc(swipeDocId).set({
      'from': currentUser.uid,   //* Hangi kullanıcı kaydırma yaptı (currentUser).
      'to': targetUserId,   //* Hangi kullanıcıya karşı kaydırma yapıldı
      'liked': liked,       //* Beğenildi mi (true) yoksa geçildi mi (false) bilgisi.
      'timestamp': FieldValue.serverTimestamp(),  //* Kaydırmanın zamanı (server timestamp kullanılarak eklenir, yani güvenli bir zaman kaynağı).
    });

    //* beğenildiyse fonksiyon başlar
    if (liked) {
      //* reverseSwipeDocId: Hedef kullanıcının daha önce bu kullanıcıyı beğenip beğenmediğini kontrol etmek için.
      final reverseSwipe = await FirebaseFirestore.instance.collection('swipes').doc(reverseSwipeDocId).get();
      
      //* Firestore’da böyle bir doküman varsa (exists) ve o dokümanda liked == true ise, bu iki kullanıcı karşılıklı olarak birbirini beğenmiş demektir.
      if (reverseSwipe.exists && reverseSwipe['liked'] == true) {
        
        
        //*Eşleşen her iki kullanıcı için tek ve değişmeyen bir matchId oluşturulmuş olur.

        //* Böylece Firebase'de aynı eşleşme iki kez oluşmaz.
 
        //* Veri tutarlılığı sağlanır.
        
        //* compareTo alfabetik karşılaştırma yapar:
        
        //* currentUser.uid = "123abc"

        //* targetUserId = "456xyz"

        //* "123abc".compareTo("456xyz") → < 0 olduğu için:

        //* matchId = '123abc_456xyz';
        
        final matchId = currentUser.uid.compareTo(targetUserId) < 0
            ? '${currentUser.uid}_$targetUserId'
            : '${targetUserId}_${currentUser.uid}';

        //* firebase e kaydetme işlemi matches adında kayıt başlıyor matchId kaydediliyor
        await FirebaseFirestore.instance.collection('matches').doc(matchId).set({
          //* ayrıca users kısmına 2 kullanıcının da idsi kaydediliyor ve zaman kaydediliyor
          'users': [currentUser.uid, targetUserId],
          'timestamp': FieldValue.serverTimestamp()
        });

        //* Eşleşme popup'ı gösteriliyor burada
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🎉 Eşleştiniz!"),
              content: const Text("Artık sohbet etmeye başlayabilirsiniz."),
              actions: [
                TextButton(
                  child: const Text("Tamam"),  //* tamam butonuna basınca eski sayfaya döner
                  onPressed: () => Navigator.pop(context),
                ), 
                //* sohbete git diyince sohbetin olduğu chat list sayfasına gidilir orada kimlerle eşleşme varsa onlar gösterilir
                TextButton(
                  child: const Text("Sohbete Git"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/chat_list');
                  },
                ),
              ],
            ),
          );
        }
      }
    }

    //* 3 kişilik listede 2. kişi gösteriliyorsa (currentIndex = 2)

    //* Bu kişi silinince liste 2 kişiye düşer, currentIndex = 2 artık geçerli değildir.

    //* Bu yüzden currentIndex tekrar 0 yapılır.

    //* Kartı listeden çıkar 
    setState(() {
      //* matchedUserDocs: Kullanıcının karşısına çıkan aday kullanıcıların bulunduğu bir liste.
      matchedUserDocs.removeAt(currentIndex);
      //* removeAt(currentIndex): Şu anda ekranda olan (gösterilen) kullanıcıyı listeden tamamen siler.
      if (currentIndex >= matchedUserDocs.length) currentIndex = 0;
    });
  }


  //* kullanıcının karşısına çıkacak diğer kullanıcıları getirme işini başlatıyor
  Future<void> fetchMatchedUsers() async {
    try {
      //* kullanıcı girdiyse eğer onun uid sini final ile uid değişkenine veriyoruz
      final uid = FirebaseAuth.instance.currentUser?.uid;
      //* null ise fonksiyon biter
      if (uid == null) return;
      
      //* Bu kullanıcı hangi kişileri beğenmiş ya da geçmiş → onları alıyoruz.

      //* get() ile bu veriler swipesSnapshot adlı değişkende saklanır.

      final swipesSnapshot = await FirebaseFirestore.instance
          .collection('swipes')
          .where('from', isEqualTo: uid)
          .get();

      //* doc['to'] → her swipe işleminin hedef kullanıcısı,
      //* swipesSnapshot → önceki adımda alınan, kullanıcının yaptığı swipe'ları içeren belge listesi.
      //* map(...).toSet() → tüm bu kullanıcı UID’lerini bir liste yerine Set (küme) olarak saklar.
      final swipedUserIds = swipesSnapshot.docs.map((doc) => doc['to'] as String).toSet();

      //* var olan kullanıcının profiles koleksiyonundaki kendi profil belgesini alır.
      final profileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
      //* boş ise işlem durur.
      if (!profileDoc.exists) return;

      //* kullanıcının profil belgesi içerisinde ki bilgileri currentUserProfile değişkenine aktarır
      final currentUserProfile = profileDoc.data()!;

      //* currentUserProfile['gender'] → kullanıcının cinsiyet bilgisi.
      //* .toString() ile string’e çevrilir (boşsa bile)
      //* .toLowerCase().trim() ile küçük harfe dönüştürülüp baş/son boşlukları silinir
      //* gender veritabanında "Erkek " ise, bu işlem sonucunda "erkek" olur.
      final myGender = (currentUserProfile['gender'] ?? '').toString().toLowerCase().trim();


      //* current userın firebase de settings dökümanında olan bilgilerini settingsDoc adlı değişkene aktar 
      final settingsDoc = await FirebaseFirestore.instance.collection('settings').doc(uid).get();
      //* boşsa fonksiyonu bitir
      if (!settingsDoc.exists) return;

      //* settingsDoc içerisinde interestedIn içerisinde bir şey varsa listele ve myInterests adlı değişkene ata
      final myInterests = List<String>.from(settingsDoc['interestedIn'] ?? [])
          .map((e) => e.toLowerCase().trim())
          .toList();

      //* profiles adlı kolleksiyonda olan bilgileri allProfiles adlı değişkene ata
      final allProfiles = await FirebaseFirestore.instance.collection('profiles').get();
      
      //* settings adlı kolleksiyonda olan bilgileri allSettings adlı değişkene ata
      final allSettings = await FirebaseFirestore.instance.collection('settings').get();   
      
      /*   interestMap bu şekilde oluşuyor   
      {
        'user123': ['kadın'], 
        'user456': ['erkek', 'kadın'],
        'user789': [],
      }
      */
      final Map<String, List<String>> interestsMap = {
        for (var doc in allSettings.docs)
          doc.id: List<String>.from(doc['interestedIn'] ?? [])
              .map((e) => e.toString().toLowerCase().trim())
              .toList()
      };

      //* matchedUserDocs adlı değişkene atanıyor allProfiles doc içerisindekiler
      matchedUserDocs = allProfiles.docs.where((doc) {
        //*  Her belgenin ID’si, o kullanıcıya ait UID’dir.

        //* Bu UID’yi theirUid olarak alıyoruz.
        final theirUid = doc.id;
        
        //* eğer kullanıcı bensem veya ben bu kişiyi beğenmiş ya da önceden geçtiysem listede gösterme
        if (theirUid == uid || swipedUserIds.contains(theirUid)) return false;


        final data = doc.data();
        final theirGender = (data['gender'] ?? '').toString().toLowerCase().trim();
        
        //* Daha önce oluşturduğumuz interestsMap’ten bu kişinin hangi cinsiyetlere ilgi duyduğunu alıyoruz.
        //*Eğer bu kullanıcı o haritada yoksa → boş liste kabul edilir.
        final theirInterestedIn = interestsMap[theirUid] ?? [];

        //* myInterests: Senin ilgilendiğin cinsiyetler (örneğin sadece "erkek" ya da "kadın").
        //* iLike: Bu kişinin cinsiyeti senin ilgilendiklerin arasında mı?
        //* theyLikeMe: Senin cinsiyetin bu kişinin ilgilendikleri arasında mı?
        //* 'hepsi': Eğer kullanıcı herkesle ilgileniyor demekse, bu da hesaba katılıyor.

        final iLike = myInterests.contains(theirGender) || myInterests.contains('hepsi');
        final theyLikeMe = theirInterestedIn.contains(myGender) || theirInterestedIn.contains('hepsi');
        
        //* Yani karşılıklı potansiyel ilgi varsa bu kullanıcı gösterilir.
        return iLike && theyLikeMe;
      }).toList();

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => isLoading = false);
    }
  }

  Widget buildSwiper() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (matchedUserDocs.isEmpty) return const Center(child: Text("Eşleşen kullanıcı bulunamadı."));
    
    return Column(
      children: [
        //* Expanded: Altındaki bileşenin (yani CardSwiper) mevcut boşluğu tamamen kaplamasını sağlar.
        Expanded(
          child: CardSwiper(
            controller: _swiperController,
            cardsCount: matchedUserDocs.length,
            isLoop: false,    //* kartlar bittiğinde döngü bitsin true dersek sonsuz döngü olur      
            numberOfCardsDisplayed: 1,  //* sadece tek bir kart 
            onSwipe: (int previousIndex, int? nextIndex, CardSwiperDirection direction) {
              //* Kaydırılan karttaki kullanıcının UID'sini alıyoruz.
              final userId = matchedUserDocs[previousIndex].id;
              //* Eğer sağa kaydırılmışsa, liked = true olur.
              final liked = direction == CardSwiperDirection.right;
              
              //* Hangi kartın kaydırıldığını currentIndex olarak saklıyoruz.
              //* Bu, o kartı listeden silmek için kullanılıyordu.
              currentIndex = previousIndex;
              
              //* eşleşme mantığını buraya çağırıyoruz.
              handleSwipe(userId, liked);
              return true;
            },
            /*!!!!!!!!!!!!!!!!!!!!
            cardBuilder: CardSwiper bileşeni her kartı oluştururken bu fonksiyonu çağırır.

            Parametreler:

            context: BuildContext

            index: Bu kartın kaçıncı sırada olduğunu belirtir

            _, __: Gerekli ama kullanılmayan parametreler (örneğin: animation gibi şeyler olabilir)
            !!!!!!!!!!!!!!!!!!!!!
            */
            cardBuilder: (context, index, _, __) {
              //* Örn: { name: "Ahmet", gender: "erkek", imageUrls: [...] }  user değişkenine at
              final user = matchedUserDocs[index].data() as Map<String, dynamic>;
              //*Kullanıcının profilindeki imageUrls alanı çekilir.
              //* Bu, kullanıcının yüklediği fotoğrafların URL listesi.
              //* Eğer imageUrls boşsa veya yoksa → [] (boş liste) atanır.

              final imageUrls = user['imageUrls'] as List<dynamic>? ?? [];
              
              //* total fotoğraf sayısı
              final totalImages = imageUrls.length;
              
              //* currentImageIndices → { 0: 0, 1: 2, 2: 1 } gibi kart index’lerine karşılık gelen aktif resim index’lerini saklayan bir map.
              final imgIndex = currentImageIndices[index] ?? 0;

              //* imgIndex ile o an gösterilecek fotoğraf URL'si alınır.

              //* imageUrl olarak bir placeholder (geçici varsayılan görsel) gösterilir.
              final imageUrl = imageUrls.isNotEmpty
                  ? imageUrls[imgIndex]
                  : "https://dummyimage.com/300x400/000/fff.png&text=No+Image";

              return Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(
                        "https://dummyimage.com/300x400/000/fff.png&text=No+Image",
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      //* kartta sadece isim ve cinsiyet gözüküyor alt tarafta ve tabi fotoğraflar 
                      child: Text(
                        "${user['name']} • ${user['gender']}",
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (totalImages > 1)
                      Positioned(
                        right: 10,
                        top: MediaQuery.of(context).size.height / 3,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onPressed: () {
                            //* Fotoğraf sayısı kadar ileri gidip sonra başa dönmeyi sağlar döngü gibi
                            setState(() {
                              currentImageIndices[index] = (imgIndex + 1) % totalImages;
                            });
                          },
                        ),
                      ),
                      //* burası da sola doğru olan yani önce ki ve sonra ki fotoğraf gibi o ikonları tanıtıyoruz.
                    if (totalImages > 1)
                      Positioned(
                        left: 10,
                        top: MediaQuery.of(context).size.height / 3,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              currentImageIndices[index] = (imgIndex - 1 + totalImages) % totalImages;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            //* userId: Az önce alınan, beğenilmeyen kullanıcının kimliği

            //* false: Bu kişinin beğenilmediğini belirtir
            //* Şu an gösterdiğim kişiyi dislike (beğenmedim) olarak veritabanına yaz diyoruz burada.
            FloatingActionButton(
              heroTag: "dislike",
              backgroundColor: Colors.red,
              onPressed: () {
                if (matchedUserDocs.isNotEmpty) {
                  final userId = matchedUserDocs[currentIndex].id;
                  handleSwipe(userId, false);
                }
              },
              child: const Icon(Icons.close),
            ),
            //* burada da tam tersi yine yazdırıyoruz ama beğendi şekli firestore yazılıyor userId ve true bilgisi ile
            FloatingActionButton(
              heroTag: "like",
              backgroundColor: Colors.green,
              onPressed: () {
                if (matchedUserDocs.isNotEmpty) {
                  final userId = matchedUserDocs[currentIndex].id;
                  handleSwipe(userId, true);
                }
              },
              child: const Icon(Icons.favorite),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("HomePage"),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                //* drawerHeader yani başta Menü yazacak
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text('Menü', style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                //* sırası ile profile gir, ayarlar, sohbetler, ve çıkış yap kısımları var.
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile Gir'),
                  onTap: () {
                    Navigator.pop(context);
                    //* profile page sayfasına gönder
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Ayarlar'),
                  onTap: () {
                    Navigator.pop(context);
                    //* settings page sayfasına gönder
                    Navigator.of(context).pushNamed('/ayarlar');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Sohbetler'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      //* ChatListPage sayfasına gönder
                      MaterialPageRoute(builder: (context) => const ChatListPage()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Çıkış Yap'),
                  onTap: () {
                    Navigator.pop(context);
                    //* logout fonksiyonu çalışır ve orada da şu yazıyor kullanıcıyı loginPage sayfasına götürür ve
                    //* signOut fonksiyonu çalışıyor.
                    _logout();
                  },
                ),
              ],
            ),
          ),

          body: buildSwiper(),
        ),
        if (_isLoggingOut)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }
}
