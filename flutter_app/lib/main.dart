import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'utils/auth_manager.dart';
import 'utils/app_provider.dart';
import 'utils/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/community_screen.dart';
import 'screens/copilot_screen.dart';
import 'admin/admin_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await AuthManager.isLoggedIn();
  String initialRoute = '/auth';
  String? role;
  
  if (loggedIn) {
    final user = await AuthManager.getUser();
    role = user?['role'];
    initialRoute = role == 'admin' ? '/admin_dashboard' : '/home';
  }

  runApp(RootApp(initialRoute: initialRoute, role: role));
}

class RootApp extends StatefulWidget {
  final String initialRoute;
  final String? role;
  const RootApp({super.key, required this.initialRoute, required this.role});

  static void restartApp(BuildContext context, String initialRoute, String? role) {
    final RootAppState? state = context.findAncestorStateOfType<RootAppState>();
    state?.updateApp(initialRoute, role);
  }

  @override
  State<RootApp> createState() => RootAppState();
}

class RootAppState extends State<RootApp> {
  late String _initialRoute;
  String? _role;

  @override
  void initState() {
    super.initState();
    _initialRoute = widget.initialRoute;
    _role = widget.role;
  }

  void updateApp(String initialRoute, String? role) {
    setState(() {
      _initialRoute = initialRoute;
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: _role == 'admin' 
        ? AdminControlCenterApp(key: ValueKey('admin-$_initialRoute'), initialRoute: _initialRoute)
        : KyNangSongApp(key: ValueKey('user-$_initialRoute'), initialRoute: _initialRoute),
    );
  }
}

class KyNangSongApp extends StatelessWidget {
  final String initialRoute;
  const KyNangSongApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final loc = AppLocalizations(appProvider.locale);

    return MaterialApp(
        title: loc.appName,
        debugShowCheckedModeBanner: false,
        themeMode: appProvider.themeMode,
        builder: (context, child) {
          // Clamp text scale to prevent layout overflow on large-font devices
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.1,
              ),
            ),
            child: child!,
          );
        },

        // ── Light Theme ────────────────────────────────────────────────────
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F8FF),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                inherit: false,
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8FF),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        // ── Dark Theme ─────────────────────────────────────────────────────
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                inherit: false,
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1A1A2E),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          dividerColor: Colors.white12,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A1A2E),
            selectedItemColor: Color(0xFF818CF8),
            unselectedItemColor: Colors.white38,
          ),
          drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF111127)),
        ),

        initialRoute: initialRoute,
        routes: {
          '/auth':      (_) => const AuthScreen(),
          '/home':      (_) => const HomeScreen(),
          '/community': (_) => const CommunityScreen(),
          '/playground':(_) => const PlaygroundScreen(),
          '/skills':    (_) => const SkillsScreen(),
          '/news':      (_) => const NewsScreen(),
          '/profile':   (_) => const ProfileScreen(),
          '/copilot':   (_) => const CopilotScreen(),
        },
    );
  }
}
