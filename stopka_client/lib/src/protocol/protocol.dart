/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'device/app_update_required.dart' as _ilttxu9r;
import 'device/device.dart' as _i7201wvo;
import 'device/device_registration.dart' as _i9282m17;
import 'device/registration_limited.dart' as _izlwod5n;
export 'device/app_update_required.dart';
export 'device/device.dart';
export 'device/device_registration.dart';
export 'device/registration_limited.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ilttxu9r.AppUpdateRequired) {
      return _ilttxu9r.AppUpdateRequired.fromJson(data) as T;
    }
    if (t == _i7201wvo.Device) {
      return _i7201wvo.Device.fromJson(data) as T;
    }
    if (t == _i9282m17.DeviceRegistration) {
      return _i9282m17.DeviceRegistration.fromJson(data) as T;
    }
    if (t == _izlwod5n.RegistrationLimited) {
      return _izlwod5n.RegistrationLimited.fromJson(data) as T;
    }
    if (t == _isc.getType<_ilttxu9r.AppUpdateRequired?>()) {
      return (data != null ? _ilttxu9r.AppUpdateRequired.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i7201wvo.Device?>()) {
      return (data != null ? _i7201wvo.Device.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9282m17.DeviceRegistration?>()) {
      return (data != null ? _i9282m17.DeviceRegistration.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izlwod5n.RegistrationLimited?>()) {
      return (data != null
              ? _izlwod5n.RegistrationLimited.fromJson(data)
              : null)
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ilttxu9r.AppUpdateRequired => 'AppUpdateRequired',
      _i7201wvo.Device => 'Device',
      _i9282m17.DeviceRegistration => 'DeviceRegistration',
      _izlwod5n.RegistrationLimited => 'RegistrationLimited',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('stopka.', '');
    }

    switch (data) {
      case _ilttxu9r.AppUpdateRequired():
        return 'AppUpdateRequired';
      case _i7201wvo.Device():
        return 'Device';
      case _i9282m17.DeviceRegistration():
        return 'DeviceRegistration';
      case _izlwod5n.RegistrationLimited():
        return 'RegistrationLimited';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AppUpdateRequired') {
      return deserialize<_ilttxu9r.AppUpdateRequired>(data['data']);
    }
    if (dataClassName == 'Device') {
      return deserialize<_i7201wvo.Device>(data['data']);
    }
    if (dataClassName == 'DeviceRegistration') {
      return deserialize<_i9282m17.DeviceRegistration>(data['data']);
    }
    if (dataClassName == 'RegistrationLimited') {
      return deserialize<_izlwod5n.RegistrationLimited>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  @override
  String getModuleName() => 'stopka';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
