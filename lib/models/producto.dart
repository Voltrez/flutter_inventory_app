class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int stock;
  final int proveedorId;

  /// Solo se llena cuando el producto viene de la consulta con INNER JOIN.
  final String? proveedorNombre;

  const Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.proveedorId,
    this.proveedorNombre,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'precio': precio,
        'stock': stock,
        'proveedor_id': proveedorId,
      };

  factory Producto.fromMap(Map<String, Object?> m) => Producto(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        precio: (m['precio'] as num).toDouble(),
        stock: m['stock'] as int,
        proveedorId: m['proveedor_id'] as int,
        proveedorNombre: m['proveedor_nombre'] as String?,
      );
}
