import '../models/identification_method.dart';

class IdentificationMethodRepository {
  static final List<IdentificationMethod> _methods = [
    IdentificationMethod(id: 'company_registration_number', name: 'Company Registration Number'),
    IdentificationMethod(id: 'cypriot_id', name: 'Cypriot ID'),
    IdentificationMethod(id: 'arc_number', name: 'Arc Number'),
    IdentificationMethod(id: 'passport', name: 'Passport'),
    IdentificationMethod(id: 'foreign_id', name: 'Foreign ID'),
  ];

  List<IdentificationMethod> getAllMethods() {
    return _methods;
  }

  IdentificationMethod getMethodById(String id) {
    return _methods.firstWhere(
      (method) => method.id == id,
      orElse: () => _methods.first,
    );
  }
  
  IdentificationMethod getMethodByName(String name) {
    return _methods.firstWhere(
      (method) => method.name == name,
      orElse: () => _methods.first,
    );
  }
} 