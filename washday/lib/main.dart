import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/timer_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final timerService = TimerService(
    storage: storageService,
    notifications: notificationService,
  );
  await timerService.init();

  runApp(WashDayApp(
    storageService: storageService,
    timerService: timerService,
  ));
}

class WashDayApp extends StatelessWidget {
  final StorageService storageService;
  final TimerService timerService;

  const WashDayApp({
    super.key,
    required this.storageService,
    required this.timerService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WashDay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF03A9F4),
          secondary: const Color(0xFF03A9F4),
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        sliderTheme: const SliderThemeData(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        timerService: timerService,
        storageService: storageService,
      ),
    );
  }
}
