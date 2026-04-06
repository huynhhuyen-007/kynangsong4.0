import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/auth_manager.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/fun_screen.dart';
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/community_screen.dart';
import 'screens/admin_cms_screen.dart';
import 'screens/copilot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await AuthManager.isLoggedIn();
  runApp(KyNangSongApp(initialRoute: loggedIn ? '/home' : '/auth'));
}

class KyNangSongApp extends StatelessWidget {
  final String initialRoute;
  const KyNangSongApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kỹ Năng Sống 4.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5),
            side: const BorderSide(color: Color(0xFF4F46E5)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F8FF),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/community': (_) => const CommunityScreen(),
        '/playground': (_) => const PlaygroundScreen(),
        '/skills': (_) => const SkillsScreen(),
        '/fun': (_) => const FunScreen(),
        '/news': (_) => const NewsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin': (_) => const AdminScreen(),
        '/admin_cms': (_) => const AdminCmsScreen(),
        '/copilot': (_) => const CopilotScreen(),
      },
    );
  }
}
