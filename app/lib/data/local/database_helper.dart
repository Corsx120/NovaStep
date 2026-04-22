import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // Реализуем паттерн Singleton, как требуется в ТЗ
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('novastep_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    // Увеличиваем версию БД, если будем менять структуру
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY'; // Используем UUID для надежности
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    // 1. Таблица Групп (Например: "Учеба", "Дом")
    await db.execute('''
      CREATE TABLE groups (
        id $idType,
        name $textType,
        color_hex $textType
      )
    ''');

    // 2. Таблица Задач (Связь 1:M - в одной группе может быть много задач)
    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        content $textType,
        created_at $textType,
        is_completed $boolType,
        is_pinned $boolType,
        is_deleted $boolType,
        group_id TEXT,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE SET NULL
      )
    ''');

    // 3. Таблица Тегов (Например: "Срочно", "Важно")
    await db.execute('''
      CREATE TABLE tags (
        id $idType,
        name $textType,
        color_hex $textType
      )
    ''');

    // 4. Промежуточная таблица для связи M:N (Многие-ко-Многим)
    // У одной задачи может быть много тегов, а один тег может принадлежать многим задачам
    await db.execute('''
      CREATE TABLE task_tags (
        task_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (task_id, tag_id),
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // 5. Таблица Дневника Настроения
    await db.execute('''
      CREATE TABLE mood_logs (
        id $idType,
        log_date $textType,
        mood_score $integerType,
        readiness_score $integerType
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}