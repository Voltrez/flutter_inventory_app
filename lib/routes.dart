import 'package:flutter/material.dart';
import 'models/producto.dart';
import 'models/proveedor.dart';
import 'screens/dashboard_screen.dart';
import 'screens/producto_form_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/proveedor_form_screen.dart';
import 'screens/proveedores_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class AppRoutes {
  static const dashboard = '/';
  static const productos = '/productos';
  static const productoForm = '/productos/form';
  static const proveedores = '/proveedores';
  static const proveedorForm = '/proveedores/form';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case productos:
        page = const ProductosScreen();
        break;
      case productoForm:
        page = ProductoFormScreen(producto: settings.arguments as Producto?);
        break;
      case proveedores:
        page = const ProveedoresScreen();
        break;
      case proveedorForm:
        page = ProveedorFormScreen(proveedor: settings.arguments as Proveedor?);
        break;
      default:
        page = const DashboardScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
