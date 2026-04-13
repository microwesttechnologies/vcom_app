import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/core/common/app_routes.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/app_launch/app_intro.page.dart';
import 'package:vcom_app/pages/auth/login.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/dahsboard/dashboard.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/hub/hub.page.dart';
import 'package:vcom_app/pages/wallet/wallet.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await initializeDateFormatting('es_CO');
  Intl.defaultLocale = 'es_CO';
  await TokenService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(TokenService().handleExpiredTokenIfNeeded());
    unawaited(UserStatusService().initialize());
    unawaited(ChatPushService().initialize());
    _sessionCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(TokenService().handleExpiredTokenIfNeeded()),
    );
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(TokenService().handleExpiredTokenIfNeeded());
      unawaited(UserStatusService().initialize());
      unawaited(ChatPushService().initialize());
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
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.dashboard: (context) => const DashboardPage(),
        AppRoutes.categories: (context) => const ManagerCategoryPage(),
        AppRoutes.brands: (context) => const ManagerBrandPage(),
        AppRoutes.shop: (context) => const ShopPage(),
        AppRoutes.training: (context) => const TrainingPage(),
        AppRoutes.wallet: (context) => const WalletPage(),
        AppRoutes.hub: (context) => const HubPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != AppRoutes.chat) return null;

        final args = settings.arguments as Map<String, String?>?;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            initialOtherUserId: args?[AppRoutes.chatArgOtherUserId],
            initialOtherUserName: args?[AppRoutes.chatArgOtherUserName],
            initialOtherUserRole: args?[AppRoutes.chatArgOtherUserRole],
          ),
        );
      },
    );
  }
}
