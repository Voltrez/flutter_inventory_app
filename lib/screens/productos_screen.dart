import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../routes.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _db = DatabaseService.instance;
  final _busqueda = TextEditingController();
  late Future<List<Producto>> _productos = _db.getProductosConProveedor();

  void _cargar() {
  setState(() {
    _productos = _db.getProductosConProveedor(filtro: _busqueda.text.trim());
  });
}

  Future<void> _abrirForm([Producto? p]) async {
    final guardado =
        await Navigator.pushNamed(context, AppRoutes.productoForm, arguments: p);
    if (guardado == true) _cargar();
  }

  Future<void> _eliminar(Producto p) async {
    final ok = await confirmDelete(context,
        titulo: 'Eliminar producto',
        mensaje: '¿Seguro que deseas eliminar "${p.nombre}"?');
    if (!ok) return;
    try {
      await _db.deleteProducto(p.id!);
      if (!mounted) return;
      showMessage(context, 'Producto eliminado correctamente');
      _cargar();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'No se pudo eliminar el producto: $e', error: true);
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _busqueda,
                onChanged: (_) => _cargar(),
                decoration: InputDecoration(
                  hintText: 'Buscar producto por nombre',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _busqueda.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _busqueda.clear();
                            _cargar();
                          }),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Producto>>(
                future: _productos,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return EmptyState(
                        icon: Icons.error_outline,
                        title: 'Ocurrió un error',
                        message: '${snap.error}');
                  }
                  final lista = snap.data!;
                  if (lista.isEmpty) {
                    final buscando = _busqueda.text.trim().isNotEmpty;
                    return EmptyState(
                      icon: buscando ? Icons.search_off : Icons.inventory_2_outlined,
                      title: buscando ? 'Sin resultados' : 'Aún no hay productos',
                      message: buscando
                          ? 'No encontramos productos con ese nombre.'
                          : 'Registra tu primer producto para empezar. '
                              'Recuerda que necesitas al menos un proveedor.',
                      actionLabel: buscando ? null : 'Registrar producto',
                      onAction: () => _abrirForm(),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _tarjeta(lista[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(Producto p) {
    final bajo = p.stock <= 5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kPrimary.withAlpha(30),
              child: const Icon(Icons.inventory_2, color: kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.local_shipping, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(p.proveedorNombre ?? '-',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.attach_money, size: 16),
                      label: Text(p.precio.toStringAsFixed(2)),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: bajo ? Colors.red.shade50 : null,
                      avatar: Icon(Icons.layers,
                          size: 16, color: bajo ? Colors.red.shade700 : null),
                      label: Text('Stock: ${p.stock}',
                          style: TextStyle(
                              color: bajo ? Colors.red.shade700 : null)),
                    ),
                  ]),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? _abrirForm(p) : _eliminar(p),
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'editar',
                    child: ListTile(
                        leading: Icon(Icons.edit), title: Text('Editar'))),
                PopupMenuItem(
                    value: 'eliminar',
                    child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Eliminar'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
