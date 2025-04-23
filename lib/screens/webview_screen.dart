import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/car.dart';
import '../repositories/identification_method_repository.dart';
import 'dart:async';

class WebViewScreen extends StatelessWidget {
  final Car car;
  late WebViewController _webViewController;
  bool _isWebViewControllerInitialized = false; // Track initialization
  final IdentificationMethodRepository _methodRepository = IdentificationMethodRepository();

  WebViewScreen({required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView for Car: ${car.carNumber}'),
      ),
      body: WebView(
        initialUrl: 'https://cycamerasystem.com.cy/?handler=Search',
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (String url) async {
          print('Page finished loading: \\${url}');
          if (_isWebViewControllerInitialized) {
            bool formExist = await waitForm('searchForm', 10);
            if (!formExist) {
              print('Form not found.');
              return;
            }

            // Используем ID напрямую, т.к. они уже соответствуют форме
            await setValue('searchIdType', car.idType);
            await setValue('searchIdValue', car.idNumber);
            await setValue('searchPlate', car.carNumber);
            await waitSec(1);
            await click('btnSearch');
          } else {
            print('WebViewController not initialized yet.');
          }
        },
        onWebViewCreated: (WebViewController webViewController) async {
          _webViewController = webViewController;
          _isWebViewControllerInitialized = true; // Mark as initialized
          final cookieManager = CookieManager();
          await cookieManager.setCookie(
            WebViewCookie(
              name: 'UserLanguage',
              value: 'en-US',
              domain: 'cycamerasystem.com.cy',
            ),
          );
        },
      ),
    );
  }

  Future<void> setValue(String inputName, String value) async {
    await _webViewController.runJavascriptReturningResult(
        "var input = document.getElementById('$inputName');" +
            "if (input) { input.value = '$value'; true; } else { false; }"
    );
  }

  Future<bool> waitForm(String name, int timeoutSeconds) async {
    Completer<bool> completer = Completer<bool>();
    int attempts = 0;
    const int delayBetweenAttempts = 500; // в миллисекундах
    int maxAttempts = (timeoutSeconds * 1000) ~/ delayBetweenAttempts;
    
    void checkFormExistence() async {
      if (attempts >= maxAttempts) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return;
      }
      
      attempts++;
      if (_isWebViewControllerInitialized) {
        try {
          String result = await _webViewController.runJavascriptReturningResult(
              "document.getElementById('$name') != null"
          );
          print('Form check result: \\${result}');
          
          if (result.toLowerCase() == '1') {
            if (!completer.isCompleted) {
              completer.complete(true);
            }
            return;
          }
        } catch (e) {
          print('Error checking form: \\${e}');
        }
      }
      
      // Если форма не найдена, повторяем через интервал
      Future.delayed(Duration(milliseconds: delayBetweenAttempts), checkFormExistence);
    }
    
    // Запускаем проверку
    checkFormExistence();
    
    return completer.future;
  }

  Future<String> click(String inputName) async {
    return await _webViewController.runJavascriptReturningResult(
        "var input = document.getElementById('$inputName');" +
        "if (input) { input.click(); true; } else { false; }"
    );
  }

  Future<void> waitSec(int sec) async {
    await Future.delayed(Duration(seconds: sec));
  }
}