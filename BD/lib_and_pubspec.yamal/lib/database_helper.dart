import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    print('Caminho do banco de dados: $path'); // Log para verificar o caminho
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    print('Criando tabela users');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
    print('Tabela users criada com sucesso');
  }

  // Salvar usuário (usado no registro)
  Future<void> saveUser(String username, String email, String password) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        {
          'username': username,
          'email': email,
          'password': password, // Em produção, use hash
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Usuário salvo: username=$username, email=$email, password=$password');
    } catch (e) {
      print('Erro ao salvar usuário: $e');
    }
  }

  // Função para imprimir todos os usuários (para testes)
  Future<void> printAllUsers() async {
    final db = await database;
    final users = await db.query('users');
    print('Usuários na tabela:');
    for (var user in users) {
      print('ID: ${user['id']}, Username: ${user['username']}, Email: ${user['email']}, Password: ${user['password']}');
    }
  }

  // Verificar login (username ou email)
  Future<Map<String, dynamic>?> verifyLogin(String identifier, String password) async {
    final db = await database;
    print('Verificando login: identifier=$identifier, password=$password');
    final result = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
    );
    print('Resultado da consulta: $result');
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Fechar o banco
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}