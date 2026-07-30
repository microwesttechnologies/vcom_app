import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/core/chat/chat_push_background_stub.dart'
    if (dart.library.io) 'package:vcom_app/core/chat/chat_push_background_native.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/core/common/firebase_env.dart';
import 'package:vcom_app/core/pwa/pwa_audio_permission.service.dart';
import 'package:vcom_app/core/pwa/pwa_install.service.dart';
import 'package:vcom_app/firebase_options.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/app_launch/app_intro.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/wallet/wallet.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await initializeDateFormatting('es_CO');
  Intl.defaultLocale = 'es_CO';
  await TokenService().initialize();

  await _initializeFirebaseMessaging();
  if (kIsWeb) {
    await PwaInstallService.instance.initialize();
    await PwaAudioPermissionService.instance.initialize();
  }

  runApp(const MyApp());
}

Future<void> _initializeFirebaseMessaging() async {
  try {
    if (kIsWeb) {
      if (!FirebaseEnv.isConfigured) {
        debugPrint(
          '[main] Firebase web: define FIREBASE_* con --dart-define para push PWA.',
        );
        return;
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return;
    }

    final useNativeFcm =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (!useNativeFcm) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    debugPrint('[main] Firebase.initializeApp: $e\n$st');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(UserStatusService().initialize());
    unawaited(ChatPushService().initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(UserStatusService().initialize());
      unawaited(ChatPushService().initialize());
      ChatPushService().openPendingDeepLinkIfAny();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(UserStatusService().setOffline());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VCOM App',
      debugShowCheckedModeBanner: false,
      navigatorKey: TokenService().navigatorKey,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: VcomColors.colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: VcomColors.azulZafiroProfundo,
      ),
      home: const AppIntroPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/categories': (context) => const ManagerCategoryPage(),
        '/brands': (context) => const ManagerBrandPage(),
        '/shop': (context) => const ShopPage(),
        '/training': (context) => const TrainingPage(),
        '/wallet': (context) => const WalletPage(),
      },
    );
  }
}
