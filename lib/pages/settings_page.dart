import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_game_app/theme_notifier.dart';
import 'package:my_game_app/pages/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  //* seçilecek cinsiyetleri tek veya çoğul olacak şekilde olabilmesi için başlangıçta bir boş küme 
  final Set<String> _selectedGenders = {}; // Seçilen cinsiyetler kümesi

  //* setState ile UI güncelliyoruz 
  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  //* Kullanıcının daha önce yaptığı cinsiyet seçimlerini Firestore'dan alıp yüklemek
  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (settingsDoc.exists) {
        final interestedIn = List<String>.from(settingsDoc.data()?['interestedIn'] ?? []);
        setState(() {
          _selectedGenders.addAll(interestedIn);
        });
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final themeMode = themeNotifier.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tema Seçimi
            RadioListTile<ThemeMode>(
              title: const Text("Açık Tema"),
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: themeNotifier.toggleTheme,
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Koyu Tema"),
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: themeNotifier.toggleTheme,
            ),
            const Divider(),
            
            // Cinsiyet Seçimi
            const SizedBox(height: 20),
            const Text(
              "İlgilendiğiniz Cinsiyetler:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Kadın'),
              value: _selectedGenders.contains('Kadın'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGenders.add('Kadın');
                  } else {
                    _selectedGenders.remove('Kadın');
                  }
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Erkek'),
              value: _selectedGenders.contains('Erkek'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGenders.add('Erkek');
                  } else {
                    _selectedGenders.remove('Erkek');
                  }
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Diğer'),
              value: _selectedGenders.contains('Diğer'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGenders.add('Diğer');
                  } else {
                    _selectedGenders.remove('Diğer');
                  }
                });
              },
            ), 
            CheckboxListTile(
              title: const Text('Herkes'),
              value: _selectedGenders.contains('Herkes'),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedGenders.add('Herkes');
                  } else {
                    _selectedGenders.remove('Herkes');
                  }
                });
              },
            ),
            const Divider(),

            // Hesap Silme Butonu
            ElevatedButton(
              onPressed: _confirmDeleteAccount,
              child: const Text("Hesabı Sil"),
            ),
            
            // Kaydet Butonu
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Ayarları Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  //*Cinsiyet Seçimlerini Firestore'a Kaydetme
  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
        'interestedIn': List<String>.from(_selectedGenders),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ayarlar başarıyla kaydedildi.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata oluştu: $e")),
        );
      }
    }
  }

  //* Hesap Silme Onayı
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesabı Sil"),
        content: const Text("Hesabınızı silerseniz bir daha erişemezsiniz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hayır"),
          ),
          TextButton(
            onPressed: _deleteAccount,
            child: const Text("Evet"),
          ),
        ],
      ),
    );
  }

  //*Hesap Silme İşlemi
  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hesap silinirken hata oluştu: $e")),
        );
      }
    }
  }
} 
