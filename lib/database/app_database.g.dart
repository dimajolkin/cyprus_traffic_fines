// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  CarDao? _carDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Car` (`id` TEXT NOT NULL, `idType` TEXT NOT NULL, `idNumber` TEXT NOT NULL, `carNumber` TEXT NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  CarDao get carDao {
    return _carDaoInstance ??= _$CarDao(database, changeListener);
  }
}

class _$CarDao extends CarDao {
  _$CarDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _carInsertionAdapter = InsertionAdapter(
            database,
            'Car',
            (Car item) => <String, Object?>{
                  'id': item.id,
                  'idType': item.idType,
                  'idNumber': item.idNumber,
                  'carNumber': item.carNumber
                }),
        _carUpdateAdapter = UpdateAdapter(
            database,
            'Car',
            ['id'],
            (Car item) => <String, Object?>{
                  'id': item.id,
                  'idType': item.idType,
                  'idNumber': item.idNumber,
                  'carNumber': item.carNumber
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Car> _carInsertionAdapter;

  final UpdateAdapter<Car> _carUpdateAdapter;

  @override
  Future<List<Car>> findAllCars() async {
    return _queryAdapter.queryList('SELECT * FROM Car',
        mapper: (Map<String, Object?> row) => Car(
            id: row['id'] as String,
            idType: row['idType'] as String,
            idNumber: row['idNumber'] as String,
            carNumber: row['carNumber'] as String));
  }

  @override
  Future<Car?> findCarById(String id) async {
    return _queryAdapter.query('SELECT * FROM Car WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Car(
            id: row['id'] as String,
            idType: row['idType'] as String,
            idNumber: row['idNumber'] as String,
            carNumber: row['carNumber'] as String),
        arguments: [id]);
  }

  @override
  Future<void> deleteCarById(String id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Car WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<int?> countCars() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM Car',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> insertCar(Car car) async {
    await _carInsertionAdapter.insert(car, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateCar(Car car) async {
    await _carUpdateAdapter.update(car, OnConflictStrategy.abort);
  }
}
