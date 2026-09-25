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
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:stopka_client/src/protocol/device/device_registration.dart'
    as _i6gxu4cm;
import 'protocol.dart' as _il2as5qe;

/// {@category Endpoint}
class EndpointCatalog extends _isc.EndpointRef {
  EndpointCatalog(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'catalog';

  /// The oldest app version this server supports. The app checks it at start
  /// and shows an "update the app" screen when it is older.
  _ida.Future<String> getMinAppVersion() => caller.callServerEndpoint<String>(
    'catalog',
    'getMinAppVersion',
    {},
  );
}

/// {@category Endpoint}
class EndpointDevice extends _isc.EndpointRef {
  EndpointDevice(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'device';

  /// Registers this installation and returns its secret token. Called once, at
  /// the first launch; the app keeps the token in secure storage. No account,
  /// no personal data.
  _ida.Future<_i6gxu4cm.DeviceRegistration> register(String appVersion) =>
      caller.callServerEndpoint<_i6gxu4cm.DeviceRegistration>(
        'device',
        'register',
        {'appVersion': appVersion},
      );
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    catalog = EndpointCatalog(this);
    device = EndpointDevice(this);
  }

  late final EndpointCatalog catalog;

  late final EndpointDevice device;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'catalog': catalog,
    'device': device,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
