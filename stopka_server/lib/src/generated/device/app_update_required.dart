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

/// The app is older than the server supports and must be updated first.
abstract class AppUpdateRequired
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  AppUpdateRequired._({required this.minVersion});

  factory AppUpdateRequired({required String minVersion}) =
      _AppUpdateRequiredImpl;

  factory AppUpdateRequired.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppUpdateRequired(
      minVersion: jsonSerialization['minVersion'] as String,
    );
  }

  String minVersion;

  /// Returns a shallow copy of this [AppUpdateRequired]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppUpdateRequired copyWith({String? minVersion});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppUpdateRequired',
      'minVersion': minVersion,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppUpdateRequired',
      'minVersion': minVersion,
    };
  }

  @override
  String toString() {
    return 'AppUpdateRequired(minVersion: $minVersion)';
  }
}

class _AppUpdateRequiredImpl extends AppUpdateRequired {
  _AppUpdateRequiredImpl({required String minVersion})
    : super._(minVersion: minVersion);

  /// Returns a shallow copy of this [AppUpdateRequired]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppUpdateRequired copyWith({String? minVersion}) {
    return AppUpdateRequired(minVersion: minVersion ?? this.minVersion);
  }
}
