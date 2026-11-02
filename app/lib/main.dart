import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mt_desk/theme/droid_theme.dart';
import 'package:mt_desk/state/app_state.dart';
import 'package:mt_desk/services/platform_bridge.dart';
import 'package:mt_desk/screens/welcome_screen.dart';
import 'package:mt_desk/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DroidDeskPlatform.init();
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const MTDeskApp(),
  ));
}

class MTDeskApp extends StatefulWidget {
  const MTDeskApp({super.key});
  @override
  State<MTDeskApp> createState() => _MTDeskAppState();
}

class _MTDeskAppState extends State<MTDeskApp> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().initialize());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    return MaterialApp(
      title: 'MT-desk',
      debugShowCheckedModeBanner: false,
      theme: DroidTheme.lightThemeData,
      darkTheme: DroidTheme.darkThemeData,
      themeMode: state.themeMode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: child ?? const SizedBox.shrink(),
      ),
      home: state.isSetupComplete ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
