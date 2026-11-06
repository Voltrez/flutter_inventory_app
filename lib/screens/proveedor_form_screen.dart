import 'package:flutter/material.dart';
import '../models/proveedor.dart';
import '../services/database_service.dart';
import '../widgets/app_feedback.dart';

class ProveedorFormScreen extends StatefulWidget {
  final Proveedor? proveedor;
  const ProveedorFormScreen({super.key, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _db = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.proveedor?.nombre);
  late final _telefono = TextEditingController(text: widget.proveedor?.telefono);
  late final _correo = TextEditingController(text: widget.proveedor?.correo);
  bool _guardando = false;

  bool get _editando => widget.proveedor != null;

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final tel = _telefono.text.trim();
    final mail = _correo.text.trim();
    final p = Proveedor(
      id: widget.proveedor?.id,
      nombre: _nombre.text.trim(),
      telefono: tel.isEmpty ? null : tel,
      correo: mail.isEmpty ? null : mail,
    );
    try {
      if (_editando) {
        await _db.updateProveedor(p);
      } else {
        await _db.insertProveedor(p);
      }
      if (!mounted) return;
      showMessage(context,
          _editando ? 'Proveedor actualizado' : 'Proveedor registrado con éxito');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showMessage(context, 'No se pudo guardar el proveedor: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_editando ? 'Editar proveedor' : 'Nuevo proveedor')),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nombre o razón social',
                      prefixIcon: Icon(Icons.business)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Correo electrónico (opcional)',
                      prefixIcon: Icon(Icons.email)),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(t);
                    return ok ? null : 'Ingresa un correo válido';
                  },
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save),
                  label:
                      Text(_editando ? 'Guardar cambios' : 'Registrar proveedor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
