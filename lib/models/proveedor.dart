class Proveedor {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? correo;

  const Proveedor({this.id, required this.nombre, this.telefono, this.correo});

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'correo': correo,
      };

  factory Proveedor.fromMap(Map<String, Object?> m) => Proveedor(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        telefono: m['telefono'] as String?,
        correo: m['correo'] as String?,
      );
}
