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
import 'dart:typed_data' as _idt;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:stopka_server/src/generated/ai/mistake_example.dart'
    as _io7sjmjk;
import '../ai/ai_endpoint.dart' as _i4qeki52;
import '../catalog/catalog_endpoint.dart' as _i34yojlc;
import '../device/device_endpoint.dart' as _iems1xuo;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'ai': _i4qeki52.AiEndpoint()
        ..initialize(
          server,
          'ai',
          null,
        ),
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
    connectors['ai'] = _is.EndpointConnector(
      name: 'ai',
      endpoint: endpoints['ai']!,
      methodConnectors: {
        'checkWriting': _is.MethodConnector(
          name: 'checkWriting',
          params: {
            'level': _is.ParameterDescription(
              name: 'level',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'task': _is.ParameterDescription(
              name: 'task',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'text': _is.ParameterDescription(
              name: 'text',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'strict': _is.ParameterDescription(
              name: 'strict',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i4qeki52.AiEndpoint).checkWriting(
                session,
                params['level'],
                params['task'],
                params['text'],
                params['strict'],
              ),
        ),
        'appeal': _is.MethodConnector(
          name: 'appeal',
          params: {
            'term': _is.ParameterDescription(
              name: 'term',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'correctAnswer': _is.ParameterDescription(
              name: 'correctAnswer',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'userAnswer': _is.ParameterDescription(
              name: 'userAnswer',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'direction': _is.ParameterDescription(
              name: 'direction',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'strict': _is.ParameterDescription(
              name: 'strict',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i4qeki52.AiEndpoint).appeal(
                session,
                params['term'],
                params['correctAnswer'],
                params['userAnswer'],
                params['direction'],
                params['strict'],
              ),
        ),
        'weakSpotDrill': _is.MethodConnector(
          name: 'weakSpotDrill',
          params: {
            'level': _is.ParameterDescription(
              name: 'level',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'categoryRu': _is.ParameterDescription(
              name: 'categoryRu',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'interests': _is.ParameterDescription(
              name: 'interests',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'words': _is.ParameterDescription(
              name: 'words',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'mistakes': _is.ParameterDescription(
              name: 'mistakes',
              type: _is.getType<List<_io7sjmjk.MistakeExample>>(),
              nullable: false,
            ),
            'strict': _is.ParameterDescription(
              name: 'strict',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ai'] as _i4qeki52.AiEndpoint).weakSpotDrill(
                    session,
                    params['level'],
                    params['category'],
                    params['categoryRu'],
                    params['interests'],
                    params['words'],
                    params['mistakes'],
                    params['strict'],
                  ),
        ),
        'enrichCards': _is.MethodConnector(
          name: 'enrichCards',
          params: {
            'level': _is.ParameterDescription(
              name: 'level',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'grammarTopic': _is.ParameterDescription(
              name: 'grammarTopic',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'vocabTopic': _is.ParameterDescription(
              name: 'vocabTopic',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'terms': _is.ParameterDescription(
              name: 'terms',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
            'strict': _is.ParameterDescription(
              name: 'strict',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i4qeki52.AiEndpoint).enrichCards(
                session,
                params['level'],
                params['grammarTopic'],
                params['vocabTopic'],
                params['terms'],
                params['strict'],
              ),
        ),
        'recognizeWords': _is.MethodConnector(
          name: 'recognizeWords',
          params: {
            'image': _is.ParameterDescription(
              name: 'image',
              type: _is.getType<_idt.ByteData>(),
              nullable: false,
            ),
            'mimeType': _is.ParameterDescription(
              name: 'mimeType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'strict': _is.ParameterDescription(
              name: 'strict',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ai'] as _i4qeki52.AiEndpoint).recognizeWords(
                    session,
                    params['image'],
                    params['mimeType'],
                    params['strict'],
                  ),
        ),
        'readUnitPage': _is.MethodConnector(
          name: 'readUnitPage',
          params: {
            'image': _is.ParameterDescription(
              name: 'image',
              type: _is.getType<_idt.ByteData>(),
              nullable: false,
            ),
            'mimeType': _is.ParameterDescription(
              name: 'mimeType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'strict': _is.ParameterDescription(
              name: 'strict',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['ai'] as _i4qeki52.AiEndpoint).readUnitPage(
                session,
                params['image'],
                params['mimeType'],
                params['strict'],
              ),
        ),
      },
    );
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
