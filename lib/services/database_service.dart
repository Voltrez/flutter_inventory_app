import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';

/// Se lanza al intentar eliminar un proveedor que todavía tiene productos.
class ProveedorConProductosException implements Exception {
  final int cantidad;
  ProveedorConProductosException(this.cantidad);

  @override
  String toString() =>
      'No se puede eliminar el proveedor: tiene $cantidad producto(s) '
      'asociado(s). Elimina o reasigna esos productos primero.';
}

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Future<Database>? _opening;
  Future<Database> get database => _opening ??= _init();

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'inventario.db');
    return openDatabase(
      path,
      version: 1,
      // Activa las claves foráneas en CADA conexión (SQLite las trae apagadas).
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE proveedores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            telefono TEXT,
            correo TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            stock INTEGER NOT NULL,
            proveedor_id INTEGER NOT NULL,
            FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
              ON DELETE RESTRICT ON UPDATE CASCADE
          )
        ''');
      },
    );
  }

  // ---------------------------------------------------------------- PROVEEDORES

  Future<int> insertProveedor(Proveedor p) async {
    final db = await database;
    return db.insert('proveedores', p.toMap());
  }

  Future<List<Proveedor>> getProveedores({String filtro = ''}) async {
    final db = await database;
    final rows = await db.query(
      'proveedores',
      where: filtro.isEmpty ? null : 'nombre LIKE ?',
      whereArgs: filtro.isEmpty ? null : ['%$filtro%'],
      orderBy: 'nombre COLLATE NOCASE',
    );
    return rows.map(Proveedor.fromMap).toList();
  }

  Future<int> updateProveedor(Proveedor p) async {
    final db = await database;
    return db.update('proveedores', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> contarProductosDeProveedor(int proveedorId) async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM productos WHERE proveedor_id = ?',
        [proveedorId]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Valida productos asociados antes de borrar (evita registros huérfanos).
  Future<void> deleteProveedor(int id) async {
    final asociados = await contarProductosDeProveedor(id);
    if (asociados > 0) throw ProveedorConProductosException(asociados);
    final db = await database;
    await db.delete('proveedores', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------ PRODUCTOS

  Future<int> insertProducto(Producto p) async {
    final db = await database;
    return db.insert('productos', p.toMap());
  }

  /// Consulta con INNER JOIN para traer también el nombre del proveedor.
  Future<List<Producto>> getProductosConProveedor({String filtro = ''}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.nombre, p.precio, p.stock, p.proveedor_id,
             pr.nombre AS proveedor_nombre
      FROM productos p
      INNER JOIN proveedores pr ON pr.id = p.proveedor_id
      WHERE p.nombre LIKE ?
      ORDER BY p.nombre COLLATE NOCASE
    ''', ['%$filtro%']);
    return rows.map(Producto.fromMap).toList();
  }

  Future<int> updateProducto(Producto p) async {
    final db = await database;
    return db.update('productos', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------------ DASHBOARD

  Future<Map<String, num>> getResumen() async {
    final db = await database;
    final prod = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM productos')) ??
        0;
    final prov = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM proveedores')) ??
        0;
    final valor = await db
        .rawQuery('SELECT COALESCE(SUM(precio * stock), 0) AS v FROM productos');
    return {
      'productos': prod,
      'proveedores': prov,
      'valor': (valor.first['v'] as num),
    };
  }
}
