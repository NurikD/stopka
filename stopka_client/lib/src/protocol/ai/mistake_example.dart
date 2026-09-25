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

/// One real mistake of the learner, used to build a practice set.
abstract class MistakeExample
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MistakeExample._({
    required this.original,
    required this.corrected,
  });

  factory MistakeExample({
    required String original,
    required String corrected,
  }) = _MistakeExampleImpl;

  factory MistakeExample.fromJson(Map<String, dynamic> jsonSerialization) {
    return MistakeExample(
      original: jsonSerialization['original'] as String,
      corrected: jsonSerialization['corrected'] as String,
    );
  }

  String original;

  String corrected;

  /// Returns a shallow copy of this [MistakeExample]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MistakeExample copyWith({
    String? original,
    String? corrected,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MistakeExample',
      'original': original,
      'corrected': corrected,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MistakeExample',
      'original': original,
      'corrected': corrected,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MistakeExampleImpl extends MistakeExample {
  _MistakeExampleImpl({
    required String original,
    required String corrected,
  }) : super._(
         original: original,
         corrected: corrected,
       );

  /// Returns a shallow copy of this [MistakeExample]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MistakeExample copyWith({
    String? original,
    String? corrected,
  }) {
    return MistakeExample(
      original: original ?? this.original,
      corrected: corrected ?? this.corrected,
    );
  }
}
