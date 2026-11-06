import 'package:flutter/material.dart';
import '../models/proveedor.dart';
import '../routes.dart';
import '../services/database_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final _db = DatabaseService.instance;
  late Future<List<Proveedor>> _proveedores = _db.getProveedores();

  void _cargar() {
  setState(() {
    _proveedores = _db.getProveedores();
  });
}

  Future<void> _abrirForm([Proveedor? p]) async {
    final guardado =
        await Navigator.pushNamed(context, AppRoutes.proveedorForm, arguments: p);
    if (guardado == true) _cargar();
  }

  Future<void> _eliminar(Proveedor p) async {
    final ok = await confirmDelete(context,
        titulo: 'Eliminar proveedor',
        mensaje: '¿Seguro que deseas eliminar a "${p.nombre}"?');
    if (!ok) return;
    try {
      await _db.deleteProveedor(p.id!);
      if (!mounted) return;
      showMessage(context, 'Proveedor eliminado correctamente');
      _cargar();
    } on ProveedorConProductosException catch (e) {
      if (!mounted) return;
      showMessage(context, e.toString(), error: true);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'No se pudo eliminar el proveedor: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: ResponsiveBody(
        child: FutureBuilder<List<Proveedor>>(
          future: _proveedores,
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
              return EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Aún no hay proveedores',
                message: 'Registra un proveedor para poder asociarle productos.',
                actionLabel: 'Registrar proveedor',
                onAction: () => _abrirForm(),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: lista.length,
              itemBuilder: (_, i) => _tarjeta(lista[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _tarjeta(Proveedor p) {
    Widget dato(IconData icon, String? texto) => (texto == null || texto.isEmpty)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Icon(icon, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(child: Text(texto, overflow: TextOverflow.ellipsis)),
            ]),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.indigo.withAlpha(30),
              child: Text(p.nombre[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.indigo, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  dato(Icons.phone, p.telefono),
                  dato(Icons.email, p.correo),
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
