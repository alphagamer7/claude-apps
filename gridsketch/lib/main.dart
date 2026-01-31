import 'package:flutter/material.dart';
import 'models/artwork.dart';
import 'screens/canvas_screen.dart';
import 'screens/new_artwork_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GridSketchApp());
}

class GridSketchApp extends StatelessWidget {
  const GridSketchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridSketch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9C27B0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9C27B0),
          secondary: Color(0xFF9C27B0),
          surface: Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF9C27B0),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.grid_on,
              size: 80,
              color: Color(0xFF9C27B0),
            ),
            const SizedBox(height: 24),
            const Text(
              'GridSketch',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pixel art with creative constraints',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final artwork = await Navigator.push<Artwork>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewArtworkScreen(),
                  ),
                );
                if (artwork != null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CanvasScreen(artwork: artwork),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Artwork'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
