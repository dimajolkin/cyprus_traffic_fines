import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/car.dart';
import '../services/translator.dart';
import '../repositories/identification_method_repository.dart';
import '../repositories/car_repository.dart';
import 'dart:async';

class DatabaseViewerScreen extends StatefulWidget {
  final Translator translator;

  DatabaseViewerScreen({Key? key, required this.translator}) : super(key: key);

  @override
  _DatabaseViewerScreenState createState() => _DatabaseViewerScreenState();
}

class _DatabaseViewerScreenState extends State<DatabaseViewerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<AppDatabase> _databaseFuture;
  late CarRepository _carRepository;
  List<Car> _cars = [];
  final IdentificationMethodRepository _methodRepository = IdentificationMethodRepository();
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _databaseFuture = $FloorAppDatabase.databaseBuilder('app_database.db').build();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      final database = await _databaseFuture;
      _carRepository = CarRepository(database.carDao);
      _loadData();
    } catch (e) {
      setState(() {
        _error = 'Ошибка инициализации репозитория: ${e.toString()}';
        _isLoading = false;
      });
      print('Ошибка при инициализации репозитория: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Загрузка данных из таблицы Car через репозиторий
      final cars = await _carRepository.getAllCars();
      
      setState(() {
        _cars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки данных: ${e.toString()}';
        _isLoading = false;
      });
      print('Ошибка при загрузке данных из базы: $e');
    }
  }

  Future<void> _deleteCar(String id) async {
    try {
      await _carRepository.deleteCar(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запись удалена')),
      );
      _loadData(); // Перезагружаем данные
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: ${e.toString()}')),
      );
    }
  }

  Future<void> _editCar(Car car) async {
    final methods = _methodRepository.getAllMethods();
    String idNumber = car.idNumber;
    String carNumber = car.carNumber;
    
    // Находим имя метода по ID
    final method = _methodRepository.getMethodById(car.idType);
    String? selectedMethodName = method.name;

    // Открываем диалог редактирования
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактирование записи'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: selectedMethodName,
                  items: methods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method.name,
                      child: Text(method.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedMethodName = newValue!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'ID Type'),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'ID Number'),
                  controller: TextEditingController(text: idNumber),
                  onChanged: (value) {
                    idNumber = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Car Number'),
                  controller: TextEditingController(text: carNumber),
                  onChanged: (value) {
                    carNumber = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: () async {
                // Получаем ID метода по его имени
                final method = _methodRepository.getMethodByName(selectedMethodName!);
                
                // Обновляем данные объекта car
                car.updateIdType(method.id);
                car.updateIdNumber(idNumber);
                car.updateCarNumber(carNumber);
                
                try {
                  // Сохраняем изменения в базу
                  await _carRepository.updateCar(car);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Запись обновлена')),
                  );
                  _loadData(); // Перезагружаем данные
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при обновлении: ${e.toString()}')),
                  );
                }
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCarsList() {
    if (_cars.isEmpty) {
      return Center(child: Text('Нет записей'));
    }

    return ListView.builder(
      itemCount: _cars.length,
      itemBuilder: (context, index) {
        final car = _cars[index];
        final method = _methodRepository.getMethodById(car.idType);
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text('${method.name} - ${car.carNumber}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${car.id}'),
                Text('ID Number: ${car.idNumber}'),
                Text('ID Type: ${car.idType}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editCar(car),
                  tooltip: 'Редактировать',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCar(car.id),
                  tooltip: 'Удалить',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр базы данных'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Автомобили'),
            // В будущем можно добавить другие таблицы
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить данные',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCarsList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final count = await _carRepository.getCarCount();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Всего записей: $count')),
            );
            print('Всего записей в таблице cars: $count');
          } catch (e) {
            print('Ошибка при подсчете записей: $e');
          }
        },
        tooltip: 'Показать количество записей',
        child: Icon(Icons.calculate),
      ),
    );
  }
} 