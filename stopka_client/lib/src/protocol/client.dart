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
import 'dart:typed_data' as _idt;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:stopka_client/src/protocol/ai/mistake_example.dart'
    as _i9f0frih;
import 'package:stopka_client/src/protocol/device/device_registration.dart'
    as _i6gxu4cm;
import 'protocol.dart' as _il2as5qe;

/// Every method returns the model's raw JSON text; the app parses it, exactly
/// as it did when it called the model itself. All need a registered device and
/// count against that device's daily limit for their kind.
/// {@category Endpoint}
class EndpointAi extends _isc.EndpointRef {
  EndpointAi(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ai';

  /// Checks a short English text: corrected version, mistakes, native version.
  _ida.Future<String> checkWriting(
    String level,
    String task,
    String text,
    bool strict,
  ) => caller.callServerEndpoint<String>(
    'ai',
    'checkWriting',
    {
      'level': level,
      'task': task,
      'text': text,
      'strict': strict,
    },
  );

  /// Judges "my answer is also right".
  _ida.Future<String> appeal(
    String term,
    String correctAnswer,
    String userAnswer,
    String direction,
    bool strict,
  ) => caller.callServerEndpoint<String>(
    'ai',
    'appeal',
    {
      'term': term,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'direction': direction,
      'strict': strict,
    },
  );

  /// Six exercises on one weak category, built on the learner's own material.
  _ida.Future<String> weakSpotDrill(
    String level,
    String category,
    String categoryRu,
    List<String> interests,
    List<String> words,
    List<_i9f0frih.MistakeExample> mistakes,
    bool strict,
  ) => caller.callServerEndpoint<String>(
    'ai',
    'weakSpotDrill',
    {
      'level': level,
      'category': category,
      'categoryRu': categoryRu,
      'interests': interests,
      'words': words,
      'mistakes': mistakes,
      'strict': strict,
    },
  );

  /// Flashcard details (translation, transcription, examples) for words.
  _ida.Future<String> enrichCards(
    String level,
    String grammarTopic,
    String vocabTopic,
    List<String> terms,
    bool strict,
  ) => caller.callServerEndpoint<String>(
    'ai',
    'enrichCards',
    {
      'level': level,
      'grammarTopic': grammarTopic,
      'vocabTopic': vocabTopic,
      'terms': terms,
      'strict': strict,
    },
  );

  /// Reads the words off a photo of the learner's own word list.
  _ida.Future<String> recognizeWords(
    _idt.ByteData image,
    String mimeType,
    bool strict,
  ) => caller.callServerEndpoint<String>(
    'ai',
    'recognizeWords',
    {
      'image': image,
      'mimeType': mimeType,
      'strict': strict,
    },
  );

  /// Reads the unit code and topics off a photo of a textbook page.
  _ida.Future<String> readUnitPage(
    _idt.ByteData image,
    String mimeType,
    bool strict,
  ) => caller.callServerEndpoint<String>(
    'ai',
    'readUnitPage',
    {
      'image': image,
      'mimeType': mimeType,
      'strict': strict,
    },
  );
}

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
    ai = EndpointAi(this);
    catalog = EndpointCatalog(this);
    device = EndpointDevice(this);
  }

  late final EndpointAi ai;

  late final EndpointCatalog catalog;

  late final EndpointDevice device;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'ai': ai,
    'catalog': catalog,
    'device': device,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
