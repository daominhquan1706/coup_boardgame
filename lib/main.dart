import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:coup_boardgame/app/themes/app_colors.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/themes/app_theme.dart';
import 'package:coup_boardgame/app/translations/app_translations.dart';
import 'package:coup_boardgame/app/utils/common.dart';
import 'package:coup_boardgame/app/utils/extensions.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    "Your device locale: ${Get.deviceLocale}".logStr(name: 'Locale');
    return GestureDetector(
      // Dismiss keyboard when clicked outside
      onTap: () => Common.dismissKeyboard(),
      child: GetMaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
        initialRoute: AppRoutes.initial,
        theme: AppThemes.themData,
        getPages: AppPages.pages,
        locale: AppTranslation.locale,
        translationsKeys: AppTranslation.translations,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
