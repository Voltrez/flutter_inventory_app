import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';
import '../routes.dart';
import '../services/database_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _db = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.producto?.nombre);
  late final _precio = TextEditingController(
      text: widget.producto == null ? '' : widget.producto!.precio.toString());
  late final _stock = TextEditingController(
      text: widget.producto == null ? '' : widget.producto!.stock.toString());

  List<Proveedor>? _proveedores;
  int? _proveedorId;
  bool _guardando = false;

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _proveedorId = widget.producto?.proveedorId;
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    final lista = await _db.getProveedores();
    if (!mounted) return;
    setState(() => _proveedores = lista);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final p = Producto(
      id: widget.producto?.id,
      nombre: _nombre.text.trim(),
      precio: double.parse(_precio.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stock.text.trim()),
      proveedorId: _proveedorId!,
    );
    try {
      if (_editando) {
        await _db.updateProducto(p);
      } else {
        await _db.insertProducto(p);
      }
      if (!mounted) return;
      showMessage(context,
          _editando ? 'Producto actualizado' : 'Producto registrado con éxito');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showMessage(context, 'No se pudo guardar el producto: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_editando ? 'Editar producto' : 'Nuevo producto')),
      body: _proveedores == null
          ? const Center(child: CircularProgressIndicator())
          : _proveedores!.isEmpty
              ? EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'Primero registra un proveedor',
                  message:
                      'Cada producto debe pertenecer a un proveedor existente.',
                  actionLabel: 'Registrar proveedor',
                  onAction: () async {
                    await Navigator.pushNamed(context, AppRoutes.proveedorForm);
                    _cargarProveedores();
                  },
                )
              : ResponsiveBody(child: _formulario()),
    );
  }

  Widget _formulario() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                    prefixIcon: Icon(Icons.label)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Precio unitario',
                    prefixIcon: Icon(Icons.attach_money)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El precio es obligatorio';
                  final n = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (n == null) return 'Ingresa un número válido';
                  if (n < 0) return 'El precio no puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Stock disponible',
                    prefixIcon: Icon(Icons.layers)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El stock es obligatorio';
                  final n = int.tryParse(v.trim());
                  if (n == null) return 'Ingresa un número entero';
                  if (n < 0) return 'El stock no puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: _proveedorId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    prefixIcon: Icon(Icons.local_shipping)),
                items: _proveedores!
                    .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nombre, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _proveedorId = v),
                validator: (v) => v == null ? 'Selecciona un proveedor' : null,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: Text(_editando ? 'Guardar cambios' : 'Registrar producto'),
              ),
            ],
          ),
        ),
      );
}
