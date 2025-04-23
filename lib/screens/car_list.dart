import 'package:flutter/material.dart';
import '../models/car.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../services/translator.dart';
import '../screens/webview_screen.dart';
import '../repositories/identification_method_repository.dart';
import '../models/identification_method.dart';
import '../repositories/car_repository.dart';
import '../database/app_database.dart';
import '../screens/settings_screen.dart';

class CarListScreen extends StatefulWidget {
  final List<Car> cars;
  final Function(String) onLanguageChange;
  final Translator translator;
  final Function(List<Car>) updateCarsList;

  CarListScreen({Key? key, required this.cars, required this.onLanguageChange, required this.translator, required this.updateCarsList}) : super(key: key);

  @override
  _CarListScreenState createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  final Uuid _uuid = Uuid();
  final IdentificationMethodRepository _methodRepository = IdentificationMethodRepository();
  late final CarRepository _carRepository;
  late final AppDatabase _database;
  List<String> _methods = [];
  String? _selectedIdType;
  Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _initializeDatabase().then((_) => _loadCars());
    _loadIdentificationMethods();
  }

  Future<void> _initializeDatabase() async {
    _database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
    _carRepository = CarRepository(_database.carDao);
  }

  Future<void> _loadCars() async {
    print('Loading cars from database...');
    final cars = await _carRepository.getAllCars();
    print('Loaded cars: \\${cars.length}');
    setState(() {
      widget.cars.clear(); // Очистите список перед добавлением новых данных
      widget.cars.addAll(cars);
      widget.updateCarsList(widget.cars); // Обновляем список машин на уровне приложения
    });
    print('Cars in state: \\${widget.cars.length}');
  }

  void _loadIdentificationMethods() {
    final methods = _methodRepository.getAllMethods();
    setState(() {
      _methods = methods.map((method) => method.name).toList();
      _selectedIdType = _methods.isNotEmpty ? _methods.first : null;
    });
  }

  void _addCar(String idType, String idNumber, String carNumber) async {
    final newCar = Car(
      id: _uuid.v4(),
      idType: idType,
      idNumber: idNumber,
      carNumber: carNumber,
    );
    setState(() {
      widget.cars.add(newCar);
      _loadingStates[newCar.id] = false;
      widget.updateCarsList(widget.cars); // Обновляем список машин на уровне приложения
    });
    await _carRepository.insertCar(newCar);
    print('Car added: \\${newCar.id}');
  }

  void _removeCar(String id) async {
    setState(() {
      widget.cars.removeWhere((car) => car.id == id);
      _loadingStates.remove(id);
      widget.updateCarsList(widget.cars); // Обновляем список машин на уровне приложения
    });
    await _carRepository.deleteCar(id);
    print('Car removed: \\${id}');
  }

  void _showAddCarDialog() {
    String idNumber = '';
    String carNumber = '';
    String? selectedMethodName = _methods.isNotEmpty ? _methods.first : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.translator.get('add_vehicle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: selectedMethodName,
                items: _methods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
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
                onChanged: (value) {
                  idNumber = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Car Number'),
                onChanged: (value) {
                  carNumber = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // Получаем ID метода по его имени
                final method = _methodRepository.getMethodByName(selectedMethodName!);
                _addCar(method.id, idNumber, carNumber);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editCar(Car car) {
    String idNumber = car.idNumber;
    String carNumber = car.carNumber;
    
    // Находим имя метода по ID
    final method = _methodRepository.getMethodById(car.idType);
    String? selectedMethodName = method.name;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.translator.get('edit_vehicle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: selectedMethodName,
                items: _methods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
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
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                // Получаем ID метода по его имени
                final method = _methodRepository.getMethodByName(selectedMethodName!);
                
                setState(() {
                  car.updateIdType(method.id);
                  car.updateIdNumber(idNumber);
                  car.updateCarNumber(carNumber);
                  widget.updateCarsList(widget.cars);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.translator.get('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                onTap: () {
                  widget.onLanguageChange('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Русский'),
                onTap: () {
                  widget.onLanguageChange('ru');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(translator: widget.translator),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.translator.get('title')),
        centerTitle: true,
        leading: Icon(Icons.directions_car),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'language') {
                _showLanguageDialog();
              } else if (value == 'settings') {
                _navigateToSettings();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'language',
                  child: Row(
                    children: [
                      Icon(Icons.language, color: Theme.of(context).iconTheme.color),
                      SizedBox(width: 8),
                      Text(widget.translator.get('change_language')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
                      SizedBox(width: 8),
                      Text(widget.translator.get('settings')),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.translator.get('vehicles'), style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: widget.cars.isEmpty
                  ? Center(child: Text(widget.translator.get('no_vehicles')))
                  : ListView.builder(
                      itemCount: widget.cars.length,
                      itemBuilder: (context, index) {
                        final car = widget.cars[index];
                        // Находим имя метода по ID
                        final method = _methodRepository.getMethodById(car.idType);
                        return Dismissible(
                          key: Key(car.id),
                          onDismissed: (direction) {
                            _removeCar(car.id);
                          },
                          background: Container(color: Colors.red),
                          child: Card(
                            child: ListTile(
                              title: Text(method.name),
                              subtitle: Text(car.carNumber),
                              trailing: _loadingStates[car.id] == true
                                  ? CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WebViewScreen(car: car),
                                          ),
                                        );
                                      },
                                      child: Text(widget.translator.get('check')),
                                    ),
                              onLongPress: () {
                                _editCar(car);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showAddCarDialog,
              icon: Icon(Icons.add),
              label: Text(widget.translator.get('add_vehicle')),
            ),
          ],
        ),
      ),
    );
  }
} 