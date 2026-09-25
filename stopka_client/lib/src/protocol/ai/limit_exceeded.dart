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

/// This device used up its daily allowance for one kind of AI request.
abstract class LimitExceeded
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  LimitExceeded._({
    required this.kind,
    required this.limit,
    required this.resetAt,
  });

  factory LimitExceeded({
    required String kind,
    required int limit,
    required DateTime resetAt,
  }) = _LimitExceededImpl;

  factory LimitExceeded.fromJson(Map<String, dynamic> jsonSerialization) {
    return LimitExceeded(
      kind: jsonSerialization['kind'] as String,
      limit: jsonSerialization['limit'] as int,
      resetAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['resetAt'],
      ),
    );
  }

  String kind;

  int limit;

  DateTime resetAt;

  /// Returns a shallow copy of this [LimitExceeded]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LimitExceeded copyWith({
    String? kind,
    int? limit,
    DateTime? resetAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LimitExceeded',
      'kind': kind,
      'limit': limit,
      'resetAt': resetAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LimitExceeded',
      'kind': kind,
      'limit': limit,
      'resetAt': resetAt.toJson(),
    };
  }

  @override
  String toString() {
    return 'LimitExceeded(kind: $kind, limit: $limit, resetAt: $resetAt)';
  }
}

class _LimitExceededImpl extends LimitExceeded {
  _LimitExceededImpl({
    required String kind,
    required int limit,
    required DateTime resetAt,
  }) : super._(
         kind: kind,
         limit: limit,
         resetAt: resetAt,
       );

  /// Returns a shallow copy of this [LimitExceeded]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LimitExceeded copyWith({
    String? kind,
    int? limit,
    DateTime? resetAt,
  }) {
    return LimitExceeded(
      kind: kind ?? this.kind,
      limit: limit ?? this.limit,
      resetAt: resetAt ?? this.resetAt,
    );
  }
}
