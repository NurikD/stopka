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
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'device/app_update_required.dart' as _ilttxu9r;
import 'device/device.dart' as _i7201wvo;
import 'device/device_registration.dart' as _i9282m17;
import 'device/registration_limited.dart' as _izlwod5n;
export 'device/app_update_required.dart';
export 'device/device.dart';
export 'device/device_registration.dart';
export 'device/registration_limited.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'device',
      dartName: 'Device',
      schema: 'public',
      module: 'stopka',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random',
        ),
        _isp.ColumnDefinition(
          name: 'tokenHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'appVersion',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'ipHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'blocked',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'device_token_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tokenHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'device_ip_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'ipHash',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _is.getType<_ilttxu9r.AppUpdateRequired?>()) {
      return (data != null ? _ilttxu9r.AppUpdateRequired.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7201wvo.Device?>()) {
      return (data != null ? _i7201wvo.Device.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9282m17.DeviceRegistration?>()) {
      return (data != null ? _i9282m17.DeviceRegistration.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izlwod5n.RegistrationLimited?>()) {
      return (data != null
              ? _izlwod5n.RegistrationLimited.fromJson(data)
              : null)
          as T;
    }
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
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
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i7201wvo.Device:
        return _i7201wvo.Device.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
    try {
      return _isp.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
