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
import 'package:serverpod/serverpod.dart' as _is;

/// The AI could not be used right now. [reason] is one of: `disabled`,
/// `budget` (the server's daily ceiling is reached), `overloaded`,
/// `provider_limit`, `error`.
abstract class AiUnavailable
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  AiUnavailable._({
    required this.reason,
    this.retryAfterMinutes,
  });

  factory AiUnavailable({
    required String reason,
    int? retryAfterMinutes,
  }) = _AiUnavailableImpl;

  factory AiUnavailable.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiUnavailable(
      reason: jsonSerialization['reason'] as String,
      retryAfterMinutes: jsonSerialization['retryAfterMinutes'] as int?,
    );
  }

  String reason;

  int? retryAfterMinutes;

  /// Returns a shallow copy of this [AiUnavailable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AiUnavailable copyWith({
    String? reason,
    int? retryAfterMinutes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiUnavailable',
      'reason': reason,
      if (retryAfterMinutes != null) 'retryAfterMinutes': retryAfterMinutes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiUnavailable',
      'reason': reason,
      if (retryAfterMinutes != null) 'retryAfterMinutes': retryAfterMinutes,
    };
  }

  @override
  String toString() {
    return 'AiUnavailable(reason: $reason, retryAfterMinutes: $retryAfterMinutes)';
  }
}

class _Undefined {}

class _AiUnavailableImpl extends AiUnavailable {
  _AiUnavailableImpl({
    required String reason,
    int? retryAfterMinutes,
  }) : super._(
         reason: reason,
         retryAfterMinutes: retryAfterMinutes,
       );

  /// Returns a shallow copy of this [AiUnavailable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AiUnavailable copyWith({
    String? reason,
    Object? retryAfterMinutes = _Undefined,
  }) {
    return AiUnavailable(
      reason: reason ?? this.reason,
      retryAfterMinutes: retryAfterMinutes is int?
          ? retryAfterMinutes
          : this.retryAfterMinutes,
    );
  }
}
