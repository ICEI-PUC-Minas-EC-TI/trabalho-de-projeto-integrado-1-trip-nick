import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  /// Cria tabelas do banco de dados
  static Future<void> criaTabela(sql.Database database) async {
    await database.execute('''
      CREATE TABLE Post (
        idPost INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        description TEXT,
        id_usuario INTEGER NOT NULL,
        create_date DATE NOT NULL DEFAULT (DATE('now')),
        type TEXT NOT NULL CHECK (type IN ('community', 'review', 'list')),
        FOREIGN KEY (id_usuario) REFERENCES User(idUser) ON DELETE CASCADE
      );
    ''');

    await database.execute('''
      CREATE TABLE Community_Post (
        idPost INTEGER PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        image TEXT,
        FOREIGN KEY (idPost) REFERENCES Post(idPost) ON DELETE CASCADE
      );
    ''');
  }

  /// Abre ou cria o banco de dados
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'Trip_Nick1.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await criaTabela(database);
      },
    );
  }

  /// Adiciona um novo post do tipo "community"
  static Future<int> adicionarPostCommunity({
    required String description,
    required String title,
    String? image,
    required int id_usuario,
  }) async {
    final db = await SQLHelper.db();

    // Inserir na tabela Post
    final idPost = await db.insert(
      'Post',
      {
        'description': description,
        'id_usuario': id_usuario,
        'type': 'community',
      },
    );

    // Inserir na tabela Community_Post
    await db.insert(
      'Community_Post',
      {
        'idPost': idPost,
        'title': title,
        'image': image,
      },
    );

    return idPost;
  }

  /// Recupera todos os posts do tipo "community" com detalhes
  static Future<List<Map<String, dynamic>>> pegarPostsCommunity() async {
    final db = await SQLHelper.db();
    return await db.rawQuery('''
      SELECT 
        Post.idPost, 
        Post.description, 
        Post.create_date, 
        Community_Post.title, 
        Community_Post.image
      FROM Post 
      INNER JOIN Community_Post ON Post.idPost = Community_Post.idPost
      WHERE Post.type = 'community'
      ORDER BY Post.create_date DESC;
    ''');
  }

  /// Atualiza post e dados de Community_Post
  static Future<int> atualizarPostCommunity({
    required int idPost,
    required String description,
    required String title,
    String? image,
  }) async {
    final db = await SQLHelper.db();

    await db.update(
      'Post',
      {
        'description': description,
      },
      where: 'idPost = ?',
      whereArgs: [idPost],
    );

    return await db.update(
      'Community_Post',
      {
        'title': title,
        'image': image,
      },
      where: 'idPost = ?',
      whereArgs: [idPost],
    );
  }

  /// Exclui um post (cascateia para Community_Post automaticamente)
  static Future<void> apagarPost(int idPost) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('Post', where: 'idPost = ?', whereArgs: [idPost]);
    } catch (err) {
      debugPrint('Erro ao apagar o post: $err');
    }
  }
}
