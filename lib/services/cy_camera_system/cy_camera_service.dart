import 'package:flutter/material.dart';
import 'package:traffic_fines/models/car.dart';
import 'package:traffic_fines/services/cy_camera_system/models.dart';
import 'package:traffic_fines/services/cy_camera_system/webview_xhr_handler.dart';
import 'dart:async';
import 'dart:convert';

/// Сервис для работы с CyCameraSystem
class CyCameraService {
  static const String baseUrl = 'https://cycamerasystem.com.cy';
  static const String searchEndpoint = '$baseUrl/?handler=Search';

  /// Скрытый WebView для поиска штрафов
  Future<CyCameraSearchResponse?> searchWithWebView(BuildContext context, {
    required Car car
  }) async {
    print('Начало поиска штрафов для авто: ${car.carNumber}');
    
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
        right: 0, 
        bottom: 0,
        width: 1,
        height: 1,
        child: Opacity(
          opacity: 0.01, // Почти прозрачный для отладки
          child: SizedBox(
            width: 1,
            height: 1,
            child: Material(
              child: WebViewWithXhrHandler(
                car: car,
                onSearchResult: onSearchResult,
                onError: onError,
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