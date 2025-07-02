import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_game_app/pages/home_screen.dart';
import 'package:my_game_app/pages/login_screen.dart';
import 'package:my_game_app/pages/profile_page.dart';
import 'package:my_game_app/pages/register_screen.dart';
import 'package:my_game_app/pages/settings_page.dart';
import 'package:my_game_app/theme_notifier.dart'; // Tema yöneticisi

void main() async {
  //* firebase bağlantısı için
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  //* supabase bağlantısı için
  await Supabase.initialize(
    url: 'https://xxjfujpavkvsxtieawsy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4amZ1anBhdmt2c3h0aWVhd3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5NzI0NTAsImV4cCI6MjA2MjU0ODQ1MH0.AnWOAQSGD-7xaImfqDceG5epo0Ldqb0A_yV3Eni6zjo',
  );

  //* themeProvider kullanıyorum onun için
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Game App',
      themeMode: themeNotifier.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      //* sayfa geçişlerini ayarlayabilmek için
      initialRoute: '/',
      routes: {
        '/': (context) => const MainPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfilePage(),
        '/ayarlar': (context) => const SettingsPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUser();
    });
  }

  void checkUser() async {
  fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;

  //* kullanıcı yoksa login sayfasına 
  if (user == null) {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }//* kullanıcı varsa anasayfaya aktarmak için 
  else {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
