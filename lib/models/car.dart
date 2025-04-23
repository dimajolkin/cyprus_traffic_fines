import 'package:floor/floor.dart';
import 'identification_method.dart';

@entity
class Car {
  @primaryKey
  final String id;
  String idType;
  String idNumber;
  String carNumber;

  Car({
    required this.id,
    required this.idType,
    required this.idNumber,
    required this.carNumber,
  });

  void updateIdType(String newIdType) {
    idType = newIdType;
  }

  void updateIdNumber(String newIdNumber) {
    idNumber = newIdNumber;
  }

  void updateCarNumber(String newCarNumber) {
    carNumber = newCarNumber;
  }

  // Add any necessary methods or factory constructors here
} 