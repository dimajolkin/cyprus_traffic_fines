import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/car.dart';

part 'app_database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Car])
abstract class AppDatabase extends FloorDatabase {
  CarDao get carDao;
}

@dao
abstract class CarDao {
  @Query('SELECT * FROM Car')
  Future<List<Car>> findAllCars();

  @insert
  Future<void> insertCar(Car car);

  @update
  Future<void> updateCar(Car car);
  
  @Query('SELECT * FROM Car WHERE id = :id')
  Future<Car?> findCarById(String id);

  @Query('DELETE FROM Car WHERE id = :id')
  Future<void> deleteCarById(String id);
  
  @Query('SELECT COUNT(*) FROM Car')
  Future<int?> countCars();
} 