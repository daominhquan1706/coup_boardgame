import 'package:flutter/foundation.dart';
import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/services/crashlytics_service.dart';
import 'package:coup_boardgame/firebase_options.dart';
import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/themes/app_theme.dart';
import 'package:coup_boardgame/app/translations/app_translations.dart';
import 'package:coup_boardgame/app/utils/common.dart';
import 'package:coup_boardgame/app/utils/extensions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  //set up firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  if (!kIsWeb) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

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
        builder: (context, widget) => ResponsiveBreakpoints.builder(
          child: widget!,
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
        initialBinding: AppBinding(),
      ),
    );
  }
}

// app binding
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(FirestoreService());
    Get.put(CrashlyticsService());
  }
}
