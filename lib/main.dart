import 'package:flutter/material.dart';
import 'package:vcom_app/pages/auth/login.page.dart';
import 'package:vcom_app/pages/products/manage/managerProduct.page.dart';
import 'package:vcom_app/pages/categories/managerCategory.page.dart';
import 'package:vcom_app/pages/brands/managerBrand.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // NOTA: El estado online/offline se maneja en el módulo de chat
    // No hacemos nada aquí para evitar conflictos
  }




  @override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'VCOM App',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: VcomColors.colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: VcomColors.azulZafiroProfundo,
    ),
    home: Scaffold(
      body: const LoginPage(),


    ),
    routes: {
      '/products': (context) => const ManagerProductPage(),
      '/categories': (context) => const ManagerCategoryPage(),
      '/brands': (context) => const ManagerBrandPage(),
      '/shop': (context) => const ShopPage(),
    },
  );
}

}
