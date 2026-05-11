import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/services/app_services.dart';
import 'app/routing/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
  }
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.instance.initialize();
  runApp(const PixelBakeryApp());
}

class PixelBakeryApp extends StatelessWidget {
  const PixelBakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.instance.themeMode,
      builder: (context, themeMode, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Pixel Bakery',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
