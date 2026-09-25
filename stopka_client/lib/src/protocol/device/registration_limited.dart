/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Too many devices were registered from this address today.
abstract class RegistrationLimited
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  RegistrationLimited._({required this.retryAfterHours});

  factory RegistrationLimited({required int retryAfterHours}) =
      _RegistrationLimitedImpl;

  factory RegistrationLimited.fromJson(Map<String, dynamic> jsonSerialization) {
    return RegistrationLimited(
      retryAfterHours: jsonSerialization['retryAfterHours'] as int,
    );
  }

  int retryAfterHours;

  /// Returns a shallow copy of this [RegistrationLimited]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RegistrationLimited copyWith({int? retryAfterHours});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RegistrationLimited',
      'retryAfterHours': retryAfterHours,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RegistrationLimited',
      'retryAfterHours': retryAfterHours,
    };
  }

  @override
  String toString() {
    return 'RegistrationLimited(retryAfterHours: $retryAfterHours)';
  }
}

class _RegistrationLimitedImpl extends RegistrationLimited {
  _RegistrationLimitedImpl({required int retryAfterHours})
    : super._(retryAfterHours: retryAfterHours);

  /// Returns a shallow copy of this [RegistrationLimited]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RegistrationLimited copyWith({int? retryAfterHours}) {
    return RegistrationLimited(
      retryAfterHours: retryAfterHours ?? this.retryAfterHours,
    );
  }
}
