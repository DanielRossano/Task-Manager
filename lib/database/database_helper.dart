import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:task_manager/models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Aumentando a versão do banco para fazer a migração
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        dueDate TEXT NOT NULL,
        category TEXT,
        startTime TEXT,
        endTime TEXT,
        notifyMinutesBefore INTEGER
      )
    ''');
  }

  // Método para atualizar o esquema do banco de dados quando a versão mudar
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adicionar as colunas da versão 2
      await db.execute('ALTER TABLE tasks ADD COLUMN category TEXT;');
      await db.execute('ALTER TABLE tasks ADD COLUMN startTime TEXT;');
      await db.execute('ALTER TABLE tasks ADD COLUMN endTime TEXT;');
    }
    
    if (oldVersion < 3) {
      // Adicionar a coluna da versão 3
      await db.execute('ALTER TABLE tasks ADD COLUMN notifyMinutesBefore INTEGER;');
    }
  }

  // CREATE - Adicionar uma nova tarefa
  Future<Task> createTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copy(id: id);
  }

  // READ - Obter uma tarefa pelo ID
  Future<Task?> getTask(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  // READ - Obter todas as tarefas
  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'dueDate ASC');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  // READ - Obter tarefas de uma data específica
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await instance.database;
    
    // Extrair apenas a parte da data (ano-mês-dia)
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    final result = await db.query(
      'tasks', 
      where: "substr(dueDate, 1, 10) = ?", 
      whereArgs: [dateString],
      orderBy: 'startTime'
    );
    
    return result.map((map) => Task.fromMap(map)).toList();
  }

  // READ - Obter tarefas por categoria
  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'dueDate ASC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  // READ - Obter tarefas pendentes
  Future<List<Task>> getPendingTasks() async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'dueDate ASC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  // READ - Obter tarefas concluídas
  Future<List<Task>> getCompletedTasks() async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [1],
      orderBy: 'dueDate ASC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  // UPDATE - Atualizar uma tarefa
  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // DELETE - Remover uma tarefa
  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Remover todas as tarefas
  Future<int> deleteAllTasks() async {
    final db = await instance.database;
    return await db.delete('tasks');
  }

  // Fechar o banco de dados
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}