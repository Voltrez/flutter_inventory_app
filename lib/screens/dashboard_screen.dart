import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<Map<String, num>> _resumen = DatabaseService.instance.getResumen();

  void _recargar() {
  if (!mounted) return;
  setState(() {
    _resumen = DatabaseService.instance.getResumen();
  });
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Se ejecuta cada vez que se vuelve al dashboard desde otra pantalla.
  @override
  void didPopNext() => _recargar();

  Future<void> _ir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _header(),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, num>>(
                future: _resumen,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Text('Error al cargar datos: ${snap.error}');
                  }
                  final d = snap.data!;
                  return Column(
                    children: [
                      LayoutBuilder(builder: (context, c) {
                        final ancho = c.maxWidth > 560;
                        final cards = [
                          StatCard(
                              icon: Icons.inventory_2,
                              label: 'Productos',
                              value: '${d['productos']}',
                              color: kPrimary),
                          StatCard(
                              icon: Icons.local_shipping,
                              label: 'Proveedores',
                              value: '${d['proveedores']}',
                              color: Colors.indigo),
                        ];
                        return ancho
                            ? Row(children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 12),
                                Expanded(child: cards[1]),
                              ])
                            : Column(children: cards);
                      }),
                      StatCard(
                        icon: Icons.attach_money,
                        label: 'Valor total del inventario',
                        value: '\$${(d['valor'] ?? 0).toDouble().toStringAsFixed(2)}',
                        color: Colors.orange.shade800,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Accesos rápidos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _acceso(Icons.inventory_2, 'Productos',
                  'Consulta, registra y edita tu inventario', AppRoutes.productos),
              _acceso(Icons.local_shipping, 'Proveedores',
                  'Administra los datos de contacto', AppRoutes.proveedores),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [kPrimary, Color(0xFF115E59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.warehouse, color: Colors.white, size: 48),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('StockFácil',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  Text('Control de inventario para tu negocio',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _acceso(IconData icon, String titulo, String sub, String ruta) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: kPrimary.withAlpha(30),
            child: Icon(icon, color: kPrimary),
          ),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _ir(ruta),
        ),
      );
}
