import 'package:flutter/material.dart';
import 'package:traffic_fines/models/car.dart';
import 'package:traffic_fines/services/cy_camera_system/models.dart';
import 'package:traffic_fines/services/cy_camera_system/webview_xhr_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// Сервис для работы с CyCameraSystem
class CyCameraService {
  static const String baseUrl = 'https://cycamerasystem.com.cy';
  static const String searchEndpoint = '$baseUrl/?handler=Search';
  
  // Ключ для доступа к настройке отладки
  static const String debugModeKey = 'cy_camera_debug_mode';
  
  // Флаг отладки через геттер
  static Future<bool> get debugMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(debugModeKey) ?? false;
  }
  
  // Метод для изменения режима отладки
  static Future<void> setDebugMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(debugModeKey, value);
  }

  /// Скрытый WebView для поиска штрафов
  Future<CyCameraSearchResponse?> searchWithWebView(BuildContext context, {
    required Car car, 
    bool? debug = null
  }) async {
    print('Начало поиска штрафов для авто: ${car.carNumber}');
    
    // Получаем статус отладки из настроек
    final isDebugMode = debug ?? await debugMode;
    
    // Создаем Completer для ожидания результатов
    final Completer<CyCameraSearchResponse?> completer = Completer<CyCameraSearchResponse?>();
    
    // Создаем overlay для размещения WebView
    final OverlayState? overlay = Overlay.of(context);
    if (overlay == null) {
      print('Не удалось получить overlay для WebView');
      return null;
    }
    
    // Создаем OverlayEntry с переменной заранее
    late OverlayEntry overlayEntry;
    
    // Вместо XhrRequestHandler используем прямые коллбэки
    final onSearchResult = (String response) {
      try {
        print('Получен ответ от сервера: $response');
        
        final Map<String, dynamic> jsonData = json.decode(response);
        print('Декодированный JSON: $jsonData');
        
        final searchResponse = CyCameraSearchResponse.fromJson(jsonData);
        
        if (!completer.isCompleted) {
          completer.complete(searchResponse);
          try {
            print('Удаляем WebView из Overlay');
            overlayEntry.remove();
          } catch (e) {
            print('Ошибка при удалении WebView: $e');
          }
        }
      } catch (e) {
        print('Ошибка при обработке ответа: $e');
        print('Содержимое ответа: $response');
        
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    };
    
    final onError = (String error) {
      print('Ошибка: $error');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    };
    
    // Создаем OverlayEntry с WebView
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: isDebugMode ? 0 : 0, 
        bottom: isDebugMode ? 0 : 0,
        top: isDebugMode ? 0 : null,
        left: isDebugMode ? 0 : null,
        width: isDebugMode ? null : 1,
        height: isDebugMode ? null : 1,
        child: Opacity(
          opacity: isDebugMode ? 1.0 : 0.01, // Непрозрачное для отладки
          child: Material(
            elevation: isDebugMode ? 8.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                border: isDebugMode ? Border.all(color: Colors.red, width: 2.0) : null,
              ),
              child: Column(
                children: [
                  if (isDebugMode)
                    Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DEBUG WebView', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              try {
                                overlayEntry.remove();
                                if (!completer.isCompleted) {
                                  completer.complete(null);
                                }
                              } catch (e) {
                                print('Ошибка при удалении WebView: $e');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: WebViewWithXhrHandler(
                      car: car,
                      onSearchResult: onSearchResult,
                      onError: onError,
                      debug: isDebugMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Добавляем WebView в overlay с использованием WidgetsBinding.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        overlay.insert(overlayEntry);
        print('WebView добавлен в Overlay');
      } catch (e) {
        print('Ошибка при добавлении WebView в Overlay: $e');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    });
    
    // Устанавливаем таймаут для удаления WebView
    Timer(Duration(seconds: 60), () {
      print('Сработал таймаут поиска штрафов (60 сек)');
      if (!completer.isCompleted) {
        completer.complete(null);
        try {
          print('Удаляем WebView из Overlay (по таймауту)');
          overlayEntry.remove();
        } catch (e) {
          print('Ошибка при удалении WebView: $e');
        }
      }
    });
    
    // Возвращаем будущий результат
    return await completer.future;
  }
} 