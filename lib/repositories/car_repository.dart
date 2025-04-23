import '../database/app_database.dart';
import '../models/car.dart';

class CarRepository {
  final CarDao _carDao;

  CarRepository(this._carDao);

  Future<List<Car>> getAllCars() async {
    final carEntities = await _carDao.findAllCars();
    return carEntities.map((entity) => Car(
      id: entity.id,
      idType: entity.idType,
      idNumber: entity.idNumber,
      carNumber: entity.carNumber,
    )).toList();
  }

  Future<Car?> getCarById(String id) async {
    return await _carDao.findCarById(id);
  }

  Future<void> insertCar(Car car) async {
    await _carDao.insertCar(car);
  }

  Future<void> updateCar(Car car) async {
    await _carDao.updateCar(car);
  }

  Future<void> deleteCar(String id) async {
    await _carDao.deleteCarById(id);
  }

  Future<int> getCarCount() async {
    final count = await _carDao.countCars();
    return count ?? 0;
  }
}