import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockFácil',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorObservers: [routeObserver],
    );
  }
}
