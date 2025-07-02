import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_game_app/pages/register_screen.dart'; // Kayıt sayfasına yönlendirme
// Oyun sayfasına yönlendirme

class LoginPage extends StatefulWidget {
  const LoginPage({
      super.key,
      this.showLogoutMessage = false
      });

  final bool showLogoutMessage;

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  // Giriş işlemi
  void _login() async {
  try {
    final email = _emailController.text;
    final password = _passwordController.text;

    //* Firebase ile giriş yapma
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    debugPrint("Giriş yapan kullanıcı: ${user?.email}");

    // Giriş başarılıysa, ana sayfaya yönlendir
    if (mounted) {
      Navigator.of(context).popAndPushNamed('/home'); // HomeScreen'e yönlendir
    }
  } catch (e) {
    // Hata durumunda Snackbar ile kullanıcıyı bilgilendir
    debugPrint(e.toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş başarısız: $e')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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

            // Giriş yap butonu
            ElevatedButton(
              onPressed: _login,
              child: Text('Giriş Yap'),
            ),

            // Kayıt sayfasına yönlendiren link
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('Henüz hesabınız yok mu? Kayıt Olun'),
            ),
          ],
        ),
      ),
    );
  }
}
