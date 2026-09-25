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

/// The request was refused before reaching the AI: empty, too long, wrong type.
abstract class InvalidAiRequest
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  InvalidAiRequest._({required this.reason});

  factory InvalidAiRequest({required String reason}) = _InvalidAiRequestImpl;

  factory InvalidAiRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return InvalidAiRequest(reason: jsonSerialization['reason'] as String);
  }

  String reason;

  /// Returns a shallow copy of this [InvalidAiRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  InvalidAiRequest copyWith({String? reason});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvalidAiRequest',
      'reason': reason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InvalidAiRequest',
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'InvalidAiRequest(reason: $reason)';
  }
}

class _InvalidAiRequestImpl extends InvalidAiRequest {
  _InvalidAiRequestImpl({required String reason}) : super._(reason: reason);

  /// Returns a shallow copy of this [InvalidAiRequest]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  InvalidAiRequest copyWith({String? reason}) {
    return InvalidAiRequest(reason: reason ?? this.reason);
  }
}
