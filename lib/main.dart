import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'appearance_manager.dart';
import 'app_colors.dart';
import 'game_theme.dart';
import 'home_screen.dart';
import 'sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Future.wait([
    SoundManager.instance.init(),
    AppearanceManager.initialize(),
    GameThemeManager.initialize(),
  ]);
  runApp(const Goti12App());
}

class Goti12App extends StatefulWidget {
  const Goti12App({super.key});
  @override
  State<Goti12App> createState() => _Goti12AppState();
}

class _Goti12AppState extends State<Goti12App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppAppearance>(
    valueListenable: AppearanceManager.selected,
    builder: (context, appearance, _) => MaterialApp(
      title: '12 Goti',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: appearance == AppAppearance.light
            ? Brightness.light
            : Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: HomeScreen(),
    ),
  );
}
