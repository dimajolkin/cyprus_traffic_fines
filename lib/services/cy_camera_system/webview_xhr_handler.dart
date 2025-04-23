import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:traffic_fines/models/car.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

/// WebView с поддержкой перехвата XHR запросов
class WebViewWithXhrHandler extends StatefulWidget {
  final Car car;
  final Function(String) onSearchResult;
  final Function(String) onError;
  final bool debug;
  
  WebViewWithXhrHandler({
    required this.car,
    required this.onSearchResult,
    required this.onError,
    this.debug = false,
  });
  
  @override
  _WebViewWithXhrHandlerState createState() => _WebViewWithXhrHandlerState();
}

class _WebViewWithXhrHandlerState extends State<WebViewWithXhrHandler> {
  late final WebViewController _controller;
  bool _isWebViewInitialized = false;
  Timer? _xhrFetchTimer;
  
  // Генерируем уникальный ID для WebView при каждом создании
  final String _webViewKey = DateTime.now().millisecondsSinceEpoch.toString();
  
  // URL поиска
  static const String baseUrl = 'https://cycamerasystem.com.cy';
  static const String searchEndpoint = '$baseUrl/?handler=Search';
  
  @override
  void initState() {
    super.initState();
    print('WebViewWithXhrHandler: initState');
    
    // Инициализируем контроллер сразу в initState
    _initController();
  }
  
  Future<void> _initController() async {
    try {
      // Создаем контроллер через новый API
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              print('WebView загрузил страницу: $url');
              if (mounted) {
                _fillFormAndSearch();
              }
            },
          ),
        );
      
      // Загружаем страницу после инициализации
      if (mounted) {
        await _controller.loadRequest(Uri.parse(searchEndpoint));
        _isWebViewInitialized = true;
        print('WebView создан с ключом: $_webViewKey');
      }
    } catch (e) {
      print('Ошибка при инициализации WebView: $e');
      if (mounted) {
        widget.onError('Ошибка при инициализации WebView: $e');
      }
    }
  }
  
  @override
  void dispose() {
    print('WebViewWithXhrHandler: dispose');
    _xhrFetchTimer?.cancel();
    _isWebViewInitialized = false;
    
    // Очищаем WebView при уничтожении
    try {
      // Дополнительная очистка для iOS
      _controller.loadRequest(Uri.parse('about:blank'));
    } catch (e) {
      print('Ошибка при очистке WebView: $e');
    }
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    print('WebViewWithXhrHandler: build');
    
    // В режиме отладки показываем дополнительную информацию 
    if (widget.debug) {
      return Column(
        children: [
          if (_isWebViewInitialized)
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(
                    key: ValueKey('web_view_$_webViewKey'),
                    controller: _controller,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Car: ${widget.car.carNumber} (ID: ${widget.car.idType}-${widget.car.idNumber})',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'WebView ID: $_webViewKey',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      );
    }
    
    // Обычный режим - скрытый WebView
    return _isWebViewInitialized
        ? WebViewWidget(
            key: ValueKey('web_view_$_webViewKey'),
            controller: _controller,
          )
        : Container(width: 1, height: 1); // Placeholder пока не инициализирован
  }
  
  Future<void> _fillFormAndSearch() async {
    if (!mounted || !_isWebViewInitialized) {
      print('WebView не инициализирован или не монтирован');
      return;
    }
    
    try {
      // Ждем немного чтобы форма успела загрузиться
      await Future.delayed(Duration(seconds: 1));
      
      // Заполнение полей
      await _controller.runJavaScript(
        "var input = document.getElementById('searchIdType');" +
        "if (input) { input.value = '${widget.car.idType}'; true; } else { false; }"
      );
      print('Заполнено поле searchIdType: ${widget.car.idType}');
      
      if (!mounted) return;
      
      await _controller.runJavaScript(
        "var input = document.getElementById('searchIdValue');" +
        "if (input) { input.value = '${widget.car.idNumber}'; true; } else { false; }"
      );
      print('Заполнено поле searchIdValue: ${widget.car.idNumber}');
      
      if (!mounted) return;
      
      await _controller.runJavaScript(
        "var input = document.getElementById('searchPlate');" +
        "if (input) { input.value = '${widget.car.carNumber}'; true; } else { false; }"
      );
      print('Заполнено поле searchPlate: ${widget.car.carNumber}');
      
      if (!mounted) return;
      
      // Включаем мониторинг XHR
      await _attachXHRMonitor();
      
      if (!mounted) return;
      
      // Нажатие кнопки поиска
      await Future.delayed(Duration(seconds: 1));
      
      if (!mounted) return;
      
      await _controller.runJavaScript(
        "var input = document.getElementById('btnSearch');" +
        "if (input) { input.click(); true; } else { false; }"
      );
      print('Нажата кнопка поиска');
      
    } catch (e) {
      print('Ошибка при заполнении формы: $e');
      if (mounted) {
        widget.onError('Ошибка при поиске: $e');
      }
    }
  }
  
  /// Настраивает перехват XHR запросов
  Future<void> _attachXHRMonitor() async {
    if (!mounted || !_isWebViewInitialized) return;
    
    // JavaScript для перехвата XHR запросов и Fetch API
    const String xhrMonitorJs = '''
    (function() {
      // Сохраняем оригинальные функции
      var originalXHR = window.XMLHttpRequest;
      var originalFetch = window.fetch;
      
      // Создаем глобальную переменную для хранения запросов
      window.xhrRequests = [];
      
      // Генератор ID для запросов
      function generateRequestId() {
        return window.xhrRequests.length;
      }
      
      // Переопределяем XMLHttpRequest
      window.XMLHttpRequest = function() {
        var xhr = new originalXHR();
        var originalOpen = xhr.open;
        var originalSend = xhr.send;
        
        // Переопределяем open
        xhr.open = function(method, url) {
          xhr._method = method;
          xhr._url = url;
          
          // Сохраняем информацию о запросе
          var requestInfo = {
            method: method,
            url: url,
            time: new Date().toISOString(),
            completed: false,
            type: 'xhr'
          };
          var requestId = generateRequestId();
          window.xhrRequests.push(requestInfo);
          xhr._requestId = requestId;
          
          console.log('XHR Open:', method, url);
          
          // Вызываем оригинальный метод
          return originalOpen.apply(xhr, arguments);
        };
        
        // Переопределяем send
        xhr.send = function(data) {
          if (xhr._requestId !== undefined) {
            window.xhrRequests[xhr._requestId].data = data ? data.toString() : null;
          }
          
          // Обработчик для отслеживания ответа
          xhr.addEventListener('load', function() {
            if (xhr._requestId !== undefined) {
              var request = window.xhrRequests[xhr._requestId];
              request.completed = true;
              request.status = xhr.status;
              request.response = xhr.responseText;
              
              // Также выводим в консоль для отладки
              console.log('XHR completed:', request.url, request.status);
            }
          });
          
          // Вызываем оригинальный метод
          return originalSend.apply(xhr, arguments);
        };
        
        return xhr;
      };
      
      // Переопределяем Fetch API
      window.fetch = function(input, init) {
        var method = (init && init.method) ? init.method : 'GET';
        var url = input;
        
        if (typeof input === 'object' && input.url) {
          url = input.url;
        }
        
        // Сохраняем информацию о запросе
        var requestInfo = {
          method: method,
          url: url.toString(),
          time: new Date().toISOString(),
          completed: false,
          type: 'fetch'
        };
        var requestId = generateRequestId();
        window.xhrRequests.push(requestInfo);
        
        console.log('Fetch:', method, url);
        
        // Вызываем оригинальный fetch
        return originalFetch.apply(window, arguments)
          .then(function(response) {
            // Клонируем ответ
            var clonedResponse = response.clone();
            
            // Читаем тело как текст
            clonedResponse.text().then(function(text) {
              var request = window.xhrRequests[requestId];
              request.completed = true;
              request.status = response.status;
              request.response = text;
              
              console.log('Fetch completed:', request.url, request.status);
            });
            
            return response;
          });
      };
      
      // Функция для получения всех запросов
      window.getXHRRequests = function() {
        return JSON.stringify(window.xhrRequests);
      };
      
      // Функция для очистки истории запросов
      window.clearXHRRequests = function() {
        window.xhrRequests = [];
        return true;
      };
      
      // Дополнительная отладка
      console.log("XHR и Fetch мониторинг активирован");
      
      return "XHR and Fetch monitoring initialized";
    })();
    ''';
    
    try {
      final result = await _controller.runJavaScriptReturningResult(xhrMonitorJs);
      print('XHR мониторинг активирован: $result');
      
      if (!mounted) return;
      
      // Запускаем таймер для периодической проверки запросов
      _xhrFetchTimer?.cancel(); // Отменяем предыдущий таймер если он был
      _xhrFetchTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (mounted && _isWebViewInitialized) {
          _fetchXhrRequests();
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Ошибка при активации XHR мониторинга: $e');
    }
  }
  
  /// Периодически проверяет наличие новых XHR запросов
  Future<void> _fetchXhrRequests() async {
    if (!mounted || !_isWebViewInitialized) return;
    
    try {
      final result = await _controller.runJavaScriptReturningResult("window.getXHRRequests()");
      if (result != null && result.toString() != "null" && result.toString().length > 2) {
        String jsonStr = result.toString();
        if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
          jsonStr = jsonStr.substring(1, jsonStr.length - 1)
              .replaceAll('\\"', '"')
              .replaceAll('\\\\', '\\');
        }

        if (!mounted) return;
        
        try {
          final List<dynamic> requests = json.decode(jsonStr);
          print('Найдено ${requests.length} XHR запросов');
          
          // Обрабатываем запросы
          for (var request in requests) {
            if (!mounted) return;
            
            if (request is Map<String, dynamic>) {
              String url = request['url']?.toString() ?? '';
              bool completed = request['completed'] == true;
              
              print('XHR запрос: ${request['method']} $url (завершен: $completed)');
              if (completed) {
                print('Статус: ${request['status']}');
              }
              
              // Проверяем любые URL, содержащие "Search" - возможно формат поиска изменился
              if (url == 'Search/Search' && completed) {
                print('Найден потенциальный запрос поиска: $url');
                String response = request['response']?.toString() ?? '';
                if (response.isNotEmpty) {
                  print('Получен ответ на поисковый запрос (длина: ${response.length})');
                  
                  // Пробуем выводить начало ответа
                  if (response.length > 10) {
                    print('Начало ответа: ${response.substring(0, math.min(100, response.length))}...');
                  }
                  
                  // Проверяем, является ли ответ валидным JSON
                  try {
                    Map<String, dynamic> jsonResponse = json.decode(response);
                    print('Ответ успешно декодирован как JSON');
                    
                    // Передаем ответ обработчику
                    if (mounted) {
                      print('Вызываем onSearchResult с ответом');
                      widget.onSearchResult(response);
                    }
                    
                    // Очищаем историю запросов
                    if (mounted && _isWebViewInitialized) {
                      try {
                        await _controller.runJavaScript("window.clearXHRRequests()");
                      } catch (e) {
                        print('Ошибка при очистке XHR запросов: $e');
                      }
                    }
                    
                    // Останавливаем таймер, т.к. мы уже получили результат
                    _xhrFetchTimer?.cancel();
                    return;
                  } catch (e) {
                    print('Ответ не является валидным JSON: $e');
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Ошибка при парсинге XHR запросов: $e');
          if (mounted) {
            widget.onError('Ошибка при парсинге XHR запросов: $e');
          }
        }
      }
    } catch (e) {
      print('Ошибка при получении XHR запросов: $e');
    }
  }
} 