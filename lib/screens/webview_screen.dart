import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/cy_camera_system/cy_camera_service.dart';
import '../services/cy_camera_system/models.dart';
import 'dart:async';

class WebViewScreen extends StatefulWidget {
  final Car car;

  WebViewScreen({required this.car});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final CyCameraService _cyCameraService = CyCameraService();
  bool _isLoading = false;
  CyCameraSearchResponse? _searchResponse;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Запуск поиска при открытии экрана
    _searchViolations();
  }

  // Метод для поиска штрафов
  Future<void> _searchViolations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _cyCameraService.searchWithWebView(
        context,
        car: widget.car,
      );

      setState(() {
        _isLoading = false;
        _searchResponse = response;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка при поиске штрафов: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Проверка штрафов: ${widget.car.carNumber}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _searchViolations,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Поиск штрафов...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(_errorMessage!),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _searchViolations,
              child: Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_searchResponse == null) {
      return Center(
        child: Text('Нет данных'),
      );
    }

    // Проверяем наличие ошибок валидации
    if (_searchResponse!.isError || _searchResponse!.validationList.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text('Ошибка проверки данных:'),
            ..._searchResponse!.validationList.map((item) => 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${item.field}: ${item.message}'),
              )
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _searchViolations,
              child: Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    // Отображаем результаты
    if (_searchResponse!.resultsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text('Штрафов не найдено'),
          ],
        ),
      );
    }

    // Отображаем список штрафов
    return ListView.builder(
      itemCount: _searchResponse!.resultsList.length,
      itemBuilder: (context, index) {
        final violation = _searchResponse!.resultsList[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('Штраф №${violation.citationNumber}'),
            subtitle: Text('Дата: ${violation.formattedDate}'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: добавить навигацию на детальный экран штрафа
          ),
        );
      },
    );
  }
}