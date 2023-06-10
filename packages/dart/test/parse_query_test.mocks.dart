// Mocks generated by Mockito 5.0.5 from annotations
// in parse_server_sdk/test/parse_query_test.dart.
// Do not manually edit this file.

import 'dart:async' as i3;
import 'package:mockito/mockito.dart' as i1;
import 'package:parse_server_sdk/parse_server_sdk.dart' as i2;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeParseCoreData extends i1.Fake implements i2.ParseCoreData {}

class _FakeParseNetworkResponse extends i1.Fake
    implements i2.ParseNetworkResponse {}

class _FakeParseNetworkByteResponse extends i1.Fake
    implements i2.ParseNetworkByteResponse {}

/// A class which mocks [ParseClient].
///
/// See the documentation for Mockito's code generation for more information.
class MockParseClient extends i1.Mock implements i2.ParseClient {
  MockParseClient() {
    i1.throwOnMissingStub(this);
  }

  @override
  i2.ParseCoreData get data => (super.noSuchMethod(Invocation.getter(#data),
      returnValue: _FakeParseCoreData()) as i2.ParseCoreData);

  @override
  i3.Future<i2.ParseNetworkResponse> get(String? path,
          {i2.ParseNetworkOptions? options,
          i2.ProgressCallback? onReceiveProgress}) =>
      (super.noSuchMethod(
              Invocation.method(#get, [path],
                  {#options: options, #onReceiveProgress: onReceiveProgress}),
              returnValue: Future<i2.ParseNetworkResponse>.value(
                  _FakeParseNetworkResponse()))
          as i3.Future<i2.ParseNetworkResponse>);

  @override
  i3.Future<i2.ParseNetworkResponse> put(String? path,
          {String? data, i2.ParseNetworkOptions? options}) =>
      (super.noSuchMethod(
              Invocation.method(#put, [path], {#data: data, #options: options}),
              returnValue: Future<i2.ParseNetworkResponse>.value(
                  _FakeParseNetworkResponse()))
          as i3.Future<i2.ParseNetworkResponse>);

  @override
  i3.Future<i2.ParseNetworkResponse> post(String? path,
          {String? data, i2.ParseNetworkOptions? options}) =>
      (super.noSuchMethod(
          Invocation.method(#post, [path], {#data: data, #options: options}),
          returnValue: Future<i2.ParseNetworkResponse>.value(
              _FakeParseNetworkResponse())) as i3.Future<
          i2.ParseNetworkResponse>);

  @override
  i3.Future<i2.ParseNetworkResponse> postBytes(String? path,
          {i3.Stream<List<int>>? data,
          i2.ParseNetworkOptions? options,
          i2.ProgressCallback? onSendProgress,
          dynamic cancelToken}) =>
      (super.noSuchMethod(
              Invocation.method(#postBytes, [
                path
              ], {
                #data: data,
                #options: options,
                #onSendProgress: onSendProgress,
                #cancelToken: cancelToken
              }),
              returnValue: Future<i2.ParseNetworkResponse>.value(
                  _FakeParseNetworkResponse()))
          as i3.Future<i2.ParseNetworkResponse>);

  @override
  i3.Future<i2.ParseNetworkResponse> delete(String? path,
          {i2.ParseNetworkOptions? options}) =>
      (super.noSuchMethod(
              Invocation.method(#delete, [path], {#options: options}),
              returnValue: Future<i2.ParseNetworkResponse>.value(
                  _FakeParseNetworkResponse()))
          as i3.Future<i2.ParseNetworkResponse>);

  @override
  i3.Future<i2.ParseNetworkByteResponse> getBytes(String? path,
          {i2.ParseNetworkOptions? options,
          i2.ProgressCallback? onReceiveProgress,
          dynamic cancelToken}) =>
      (super.noSuchMethod(
              Invocation.method(#getBytes, [
                path
              ], {
                #options: options,
                #onReceiveProgress: onReceiveProgress,
                #cancelToken: cancelToken
              }),
              returnValue: Future<i2.ParseNetworkByteResponse>.value(
                  _FakeParseNetworkByteResponse()))
          as i3.Future<i2.ParseNetworkByteResponse>);
}
