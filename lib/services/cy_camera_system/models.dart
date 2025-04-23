import 'dart:convert';

/// Модель ответа сервера поиска штрафов
class CyCameraSearchResponse {
  final bool isError;
  final List<CyCameraValidationItem> validationList;
  final List<CyCameraViolationItem> resultsList;

  CyCameraSearchResponse({
    required this.isError,
    required this.validationList,
    required this.resultsList,
  });

  factory CyCameraSearchResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Более безопасный парсинг с проверками типов
      final isError = json['isError'] == true;
      
      List<CyCameraValidationItem> validationList = [];
      if (json['validationList'] is List) {
        validationList = (json['validationList'] as List)
            .where((item) => item is Map)
            .map((item) => CyCameraValidationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['validationList'] is Map) {
        // В некоторых ответах validationList может быть объектом
        validationList = [];
      }
      
      List<CyCameraViolationItem> resultsList = [];
      if (json['resultsList'] is List) {
        resultsList = (json['resultsList'] as List)
            .where((item) => item is Map)
            .map((item) => CyCameraViolationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      return CyCameraSearchResponse(
        isError: isError,
        validationList: validationList,
        resultsList: resultsList,
      );
    } catch (e) {
      print('Ошибка при парсинге CyCameraSearchResponse: $e');
      // Возвращаем пустой объект в случае ошибки
      return CyCameraSearchResponse(
        isError: true,
        validationList: [],
        resultsList: [],
      );
    }
  }

  factory CyCameraSearchResponse.fromJsonString(String jsonString) {
    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return CyCameraSearchResponse.fromJson(decoded);
      } else {
        print('Неверный формат JSON: $jsonString');
        return CyCameraSearchResponse(
          isError: true,
          validationList: [],
          resultsList: [],
        );
      }
    } catch (e) {
      print('Ошибка при декодировании JSON: $e');
      return CyCameraSearchResponse(
        isError: true,
        validationList: [],
        resultsList: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isError': isError,
      'validationList': validationList.map((x) => x.toJson()).toList(),
      'resultsList': resultsList.map((x) => x.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'CyCameraSearchResponse(isError: $isError, validations: ${validationList.length}, results: ${resultsList.length})';
  }
}

/// Модель валидации данных
class CyCameraValidationItem {
  final String field;
  final String message;

  CyCameraValidationItem({
    required this.field,
    required this.message,
  });

  factory CyCameraValidationItem.fromJson(Map<String, dynamic> json) {
    return CyCameraValidationItem(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'CyCameraValidationItem(field: $field, message: $message)';
  }
}

/// Модель данных о штрафе
class CyCameraViolationItem {
  final String citationNumber;
  final String violationDate;

  CyCameraViolationItem({
    required this.citationNumber,
    required this.violationDate,
  });

  factory CyCameraViolationItem.fromJson(Map<String, dynamic> json) {
    return CyCameraViolationItem(
      citationNumber: json['citationNumber']?.toString() ?? '',
      violationDate: json['violationDate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citationNumber': citationNumber,
      'violationDate': violationDate,
    };
  }

  DateTime? get dateTime {
    try {
      if (violationDate.isEmpty) return null;
      return DateTime.parse(violationDate);
    } catch (_) {
      return null;
    }
  }

  String get formattedDate {
    final date = dateTime;
    if (date == null) return violationDate;
    
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }

  @override
  String toString() {
    return 'CyCameraViolationItem(number: $citationNumber, date: $formattedDate)';
  }
}