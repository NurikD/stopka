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
import '../catalog/catalog_endpoint.dart' as _i34yojlc;
import '../device/device_endpoint.dart' as _iems1xuo;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'catalog': _i34yojlc.CatalogEndpoint()
        ..initialize(
          server,
          'catalog',
          null,
        ),
      'device': _iems1xuo.DeviceEndpoint()
        ..initialize(
          server,
          'device',
          null,
        ),
    };
    connectors['catalog'] = _is.EndpointConnector(
      name: 'catalog',
      endpoint: endpoints['catalog']!,
      methodConnectors: {
        'getMinAppVersion': _is.MethodConnector(
          name: 'getMinAppVersion',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['catalog'] as _i34yojlc.CatalogEndpoint)
                  .getMinAppVersion(session),
        ),
      },
    );
    connectors['device'] = _is.EndpointConnector(
      name: 'device',
      endpoint: endpoints['device']!,
      methodConnectors: {
        'register': _is.MethodConnector(
          name: 'register',
          params: {
            'appVersion': _is.ParameterDescription(
              name: 'appVersion',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['device'] as _iems1xuo.DeviceEndpoint).register(
                    session,
                    params['appVersion'],
                  ),
        ),
      },
    );
  }
}
