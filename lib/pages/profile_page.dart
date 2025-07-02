import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_game_app/pages/home_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<File> _images = [];
  final List<String> _networkImages = [];
  int _currentImageIndex = 0;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _cityController = TextEditingController();
  final _aboutMeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _userId;
  String? _gender; // Cinsiyet bilgisini tutacak değişken

  @override
  void initState() {
    super.initState();
    
    //* burası mecbur currentUser firebase paketinde olan fonksiyon final user diyerek bunu user değişkenine at diyoruz
    final user = FirebaseAuth.instance.currentUser;    //* var olan user
    
    //* user değişkeni null değilse diyoruz 
    if (user != null) {
      //* _userId biz kendimiz verdik string olacak null da olabilir diye bunu user değişkeninde firebase de uid olarak çıkıyor kişinin anahtarı 
      _userId = user.uid;
      
      //* burası da aşağıda kullanıcının profilinde olacak datalar mevcut
      _loadProfileData();
    }
  }

  //* _userId null ise burayı döndür fakat değilse
  Future<void> _loadProfileData() async {
    if (_userId == null) return;

    //* try catch blockları ile içerisine giriyoruz
    try {
      //* firebase firestore da kullanıcıların verilerini tutacak olan "profiles" adında bir alan açıyoruz
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(_userId)
          .get();
      
      //* _userId = user.uid demiştik o yüzden doc(_userId) diyoruz 
      //* final user = FirebaseAuth.instance.currentUser; diyorduk sonra _userId = user.uid derken user.uid değerini _userId ata diyoruz
      

      //*  Firestore'dan gelen doc gerçekten mevcut mu diye kontrol eder. Mevcut değilse, kod bloğu çalışmaz.
      if (doc.exists) {

        //* doc içerisinde ki datayı al final ile oluşturulan data değişkenine at 
        final data = doc.data();

        //* içeriğin içini güncellemek için kullanılır
        setState(() {
          _nameController.text = data?['name'] ?? '';
          _ageController.text = data?['age']?.toString() ?? '';
          _hobbiesController.text = data?['hobbies'] ?? '';
          _cityController.text = data?['city'] ?? '';
          _aboutMeController.text = data?['aboutMe'] ?? '';
          _gender = data?['gender']; // Cinsiyet bilgisini al
          _networkImages.clear();
          _networkImages.addAll(List<String>.from(data?['imageUrls'] ?? []));
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Veri çekme hatası: $e");
      }
    }
  }
  

  //* genel olarak kullanıcıya maksimum 6 adet fotoğraf yüklemesine izin verdiğimiz ve var olan resmin 
  //* indeksini bulduğumuz fonksiyon yapısı
  Future<void> _pickImage() async {
    //* _images uygulama içerisinde seçilen yerel resim, daha önce kullanıcıdan gelen ve kullanıcıya ait yüklenmiş resim _networkImages 
    if (_images.length + _networkImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En fazla 6 fotoğraf yükleyebilirsiniz.")),
      );
      return;
    }

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
        _currentImageIndex = _networkImages.length + _images.length - 1;
      });
    }
  }


  //* next image ve previous image ise oklar ile sağa ve sola yaparak önceki ya da sonraki fotoğrafları gösterdiğimiz fonksiyonlar
  void _nextImage() {

    //* önce totalde kaç fotoğraf var ona bakıyoruz 
    //* setState ile fotoğrafın indeksini değiştiriyoruz
    final total = _images.length + _networkImages.length;
    if (total == 0) return;
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % total;
    });
  }

    //* burada da bir önce ki fotoğrafa gidiyoruz aynısı sadece geriye gidiyor
  void _previousImage() {
    final total = _images.length + _networkImages.length;
    if (total == 0) return;
    setState(() {
      _currentImageIndex =
          (_currentImageIndex - 1 + total) % total;
    });
  }


  //* fotoğrafları Supabase e yüklediğimiz kod burası
  //* fotoğrafları bir liste gibi yüklüyoruz.
  Future<List<String>> _uploadImagesToSupabase() async {

    //* Uygulamanın içinde bir kez oluşturulmuş olan Supabase istemcisine (client) eriş, ve bunu supabase adlı bir değişkene ata.
    final supabase = Supabase.instance.client;
    List<String> downloadUrls = [];

    for (int i = 0; i < _images.length; i++) {
      try {

        //* _images listesinin i numaralı (yani o anki döngüdeki) öğesini file adında bir değişkene ata.
        final file = _images[i];

        //* supabase de öncesinde images adlı oluşturulmuş bucket içinde user_profiles adında bir klasör oluşturur ve 
        //* her kullanıcı için benzersiz bir kimlik oluşturur ve fotoğraflarını başka yerlerde saklar
        //* filePath şöyle bir şey filePath = 'user_profiles/abc123/image_1716660000000_0.jpg';
        final filePath =
            'user_profiles/$_userId/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final fileBytes = await file.readAsBytes();


        //* supabase e yükleme kısmı burada oluyor 
        await supabase.storage
            .from('images')
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        //* dosyanın URL bilgisini gösterir
        //* bunun gibi publicUrl = 'https://xyzcompany.supabase.co/storage/v1/object/public/images/user_profiles/abc123/image_1716660000000_0.jpg';

        final publicUrl =
            supabase.storage.from('images').getPublicUrl(filePath);

        //* başında  downloadUrls bunu almıştık liste olarak yaptık string tipinde bir liste 
        //* bu listeye az önce aldığımız URL bilgisini ekliyoruz
        downloadUrls.add(publicUrl);
      } catch (e) {
        if (kDebugMode) {
          print('Resim yüklenirken hata oluştu: $e');
        }
      }
    }


    //* Hem eski resimleri hem de yeni yüklenenleri içeren tek bir liste oluştur ve onu döndür.

    //* diyelim _networkImages = ['url1.jpg', 'url2.jpg'];
    //*downloadUrls = ['url3.jpg', 'url4.jpg'];
    //* şu sonuç döner ['url1.jpg', 'url2.jpg', 'url3.jpg', 'url4.jpg']
    return [..._networkImages, ...downloadUrls];
  }


  //* kullanıcının profilinde girdiği isim yaş vb bilgileri kayddetiğimiz fonksiyon
  Future<void> _saveProfile() async {
    if (_userId == null) return;

    //* _uploadImagesToSupabase(); bu fonksiyonu çağır bekle ve sonucu imageUrls adlı değişkene ata supabasede olan tüm URL'leri alır
    try {
      final imageUrls = await _uploadImagesToSupabase();

      //* firebase firestore da profiles adlı bir collection oluştur ve orada name age hobbies gibi alanlar oluştur
      await FirebaseFirestore.instance.collection('profiles').doc(_userId).set({
        
        //*yukarıda controller demiştik textEditingControllerda tutulan değerleri buraya yaz diyoruz 

        //* bu verileri firebase firestoreda tutacağız bu şekilde
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text),
        'hobbies': _hobbiesController.text,
        'city': _cityController.text,
        'aboutMe': _aboutMeController.text,
        'gender': _gender, // Cinsiyet bilgisini kaydet
        'imageUrls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil başarıyla kaydedildi.")),
        );
        setState(() {
          _images.clear();   //* _images.clear();	Cihazdan seçilen geçici resimleri temizler
          _networkImages.clear();   //* _networkImages.clear();	Eski URL listesini siler
          _networkImages.addAll(imageUrls);  //* .addAll(imageUrls);	Yeni gelen URL’leri ekler
          _currentImageIndex = 0;   //* _currentImageIndex = 0;	Galeri görünümünü en baştan başlatır
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Profil kaydetme hatası: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e")),
        );
      }
    }
  }


  //*❓Neden Önemli?
  //* Bellek sızıntısını (memory leak) önler.
  //* Performans ve uygulama stabilitesi için kritik.
  //* Özellikle uzun süre çalışan uygulamalarda gereksiz nesne birikimini engeller."
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _hobbiesController.dispose();
    _cityController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  //* Cinsiyet seçimi için dropdown menü
  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      //* kendi cinsiyeti nedir bunun için bir liste şeklinde gelir kullanıcı erkek, kadın veya diğer olarak cinsiyetini seçer
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: InputDecoration(
          labelText: "Cinsiyet",
          border: const OutlineInputBorder(),
        ),
        items: const [
          //* cinsiyet seçimlerinde bunlar var
          DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
          DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
          DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
        ],
        //* onchanged ile kişi isterse değiştirebilir cinsiyet bilgisini
        onChanged: (value) {
          setState(() {
            _gender = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //* Bu satır, sunucudan gelen resim URL’leri ile cihazdaki resim dosya yollarını tek listede birleştirir. Böylece hem internetten hem yerelden gelen resimleri tek yerde tutabilir ve işlem yapabilirsin.
    final allImages = [..._networkImages, ..._images.map((e) => e.path)];

    //* Bu değişken genellikle UI’da veya işlem yaparken “resim hangi kaynaktan geliyor?” diye kontrol etmek için kullanılır.
    final isNetwork = _currentImageIndex < _networkImages.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Sayfası"),
        centerTitle: true,
        
        //*geriye döndürecek olan icon kodları 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              //* anasayfaya yollar
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //* bir container oluşturuyoruz ve fotoğraflar bu container içerisinde olacak
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              color: Colors.grey[300],
              
              //* Normalde widget'lar dikey (Column) veya yatay (Row) olarak dizilir.
              //* Stack ise aynı alanda, üst üste birden fazla widget gösterir.
              //* Örneğin; bir resmin üzerine metin, simge, buton gibi başka widget’lar koymak için ideal.
              child: Stack(
                alignment: Alignment.center,
                children: [

                  //* Eğer allImages listesinde resim varsa,
                  //* isNetwork kontrolüne göre:
                  //* Resim internet URL’sinden ise Image.network ile göster,
                  //* Değilse, cihazdaki dosyadan Image.file ile göster.

                  //* Çünkü resim kaynağı farklı
                  //* Bazıları internet üzerinden,
                  //* Bazıları cihazdaki dosyadan geliyor.
                  //* Her iki durum için farklı widget kullanmak gerekiyor.

                  if (allImages.isNotEmpty)
                    isNetwork
                        ? Image.network(
                            allImages[_currentImageIndex],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Image.file(
                            File(allImages[_currentImageIndex]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                  else
                  //* resim yoksa yuvarlak içerisinde insan olan icon göster
                    const Icon(Icons.account_circle,
                        size: 150, color: Colors.grey),
                  //* geri iconuna tıklanında _previousImage fonksiyonu çağırılıyor o da bir önceki fotoyu gösteriyor
                  Positioned(
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: _previousImage,
                    ),
                  ),
                  //* ileri iconuna tıklanında _nextImage fonksiyonu çağırılıyor o da bir sonraki fotoyu gösteriyor
                  Positioned(
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _nextImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    //* fotoğraf yükleme icon butonu
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo),
                    //* fotoğraf yükle ve örneğin 2/6 yazıyor
                    label: Text(
                      "Fotoğraf Yükle (${_networkImages.length + _images.length}/6)",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                //* upload iconu ve kaydet yazıyor bu icona basınca _saveProfile fonksiyonu çalışıyor ve orada da hem uı güncelleniyor
                //* hem de bu bilgiler firebase firestore da kaydediliyor
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Kaydet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            //* _nameController _buildTextField widget içerisinde olan controller'a denk geliyor "" içerisinde olan da o controller içerisinde
            //* ne yazacağını söylüyor örneğin bir textfield oluştu _nameController label olarak da en aşağıda belirtilen label için burada isim
            //* diğerinde textfield içerisinde controllerda _ageController olacak onda da label bilgisi Yaş yazacak ve number çıkacak 
            const SizedBox(height: 20),
            _buildTextField(_nameController, "İsim"),
            _buildTextField(_ageController, "Yaş", keyboardType: TextInputType.number),
            _buildTextField(_hobbiesController, "Hobiler"),
            _buildTextField(_cityController, "Şehir"),
            _buildTextField(_aboutMeController, "Hakkımda", maxLines: 3),
            _buildGenderField(), // Cinsiyet seçimini burada ekliyoruz
          ],
        ),
      ),
    );
  }
                                                                  //*label kendimiz yazdık label text karşısında kullandık
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
  