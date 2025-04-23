import 'dart:convert';
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
  bool _showRawJson = false;

  @override
  void initState() {
    super.initState();
    // Загружаем состояние отладки
    _loadDebugMode();
    // Запуск поиска при открытии экрана
    _searchViolations();
  }
  
  Future<void> _loadDebugMode() async {
    // Определяем, в режиме отладки ли приложение
    final isDebug = await CyCameraService.debugMode;
    setState(() {
      _showRawJson = isDebug;
    });
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

    // Создаем виджет для отображения JSON в режиме отладки
    Widget _buildDebugJsonWidget() {
      if (!_showRawJson) return SizedBox.shrink();
      
      return Container(
        width: double.infinity,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG: JSON Ответ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, 
                color: Colors.green[800]
              ),
            ),
            SizedBox(height: 8),
            Text(
              JsonEncoder.withIndent('  ').convert(_searchResponse!.toJson()),
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Проверяем наличие ошибок валидации
    if (_searchResponse!.isError || _searchResponse!.validationList.isNotEmpty) {
      return SingleChildScrollView(
        child: Center(
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
              if (_showRawJson) _buildDebugJsonWidget(),
            ],
          ),
        ),
      );
    }

    // Отображаем результаты для случая без штрафов
    if (_searchResponse!.resultsList.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text('Штрафов не найдено'),
              if (_showRawJson) _buildDebugJsonWidget(),
            ],
          ),
        ),
      );
    }

    // Отображаем список штрафов
    return Column(
      children: [
        if (_showRawJson) 
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: _buildDebugJsonWidget(),
            ),
          ),
        Expanded(
          flex: _showRawJson ? 2 : 1,
          child: ListView.builder(
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
          ),
        ),
      ],
    );
  }
}