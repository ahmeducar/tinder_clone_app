import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Firestore import
import 'package:flutter/material.dart';
import 'package:my_game_app/pages/login_screen.dart'; // Login sayfasına yönlendirme

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Şifre onayı
  final _usernameController = TextEditingController(); // Kullanıcı adı
  final _auth = FirebaseAuth.instance;

  // Kayıt işlemi
  void _register() async {
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final username = _usernameController.text;

      // Şifreler eşleşiyor mu kontrol et
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifreler eşleşmiyor')),
        );
        return;
      }

      //* Firebase'de yeni kullanıcı oluşturma
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //* Firestore'da kullanıcı adı ve diğer bilgileri kaydet
      if (userCredential.user != null) {
        final user = userCredential.user;
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'username': username,  // Kullanıcı adı
          'email': email,        // E-posta
          'createdAt': FieldValue.serverTimestamp(),  // Kayıt zamanı
        });
      }

      //* Kayıt başarılıysa login sayfasına yönlendir
      if (mounted) {
        Navigator.of(context).popAndPushNamed('/login'); // LoginPage'e yönlendir
      }
    } catch (e) {
      //* Hata durumunda Snackbar ile kullanıcıyı bilgilendir
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt başarısız: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kullanıcı adı inputu
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
            ),
            SizedBox(height: 20),

            // E-posta inputu
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),

            // Şifre inputu
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            SizedBox(height: 20),

            // Şifre onayı inputu
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Şifreyi Onayla'),
              obscureText: true,
            ),
            SizedBox(height: 20),

            // Kayıt ol butonu
            ElevatedButton(
              onPressed: _register,
              child: Text('Kayıt Ol'),
            ),

            // Giriş yap sayfasına yönlendiren link
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Zaten bir hesabınız var mı? Giriş Yapın'),
            ),
          ],
        ),
      ),
    );
  }
}
