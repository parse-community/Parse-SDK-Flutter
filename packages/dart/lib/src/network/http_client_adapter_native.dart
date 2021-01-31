import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createHttpClientAdapter(SecurityContext securityContext) {
  final DefaultHttpClientAdapter defaultHttpClientAdapter = DefaultHttpClientAdapter();

  /// How to connect Charles Proxy with Flutter using Dio
  /// https://medium.com/netguru/how-to-connect-charles-proxy-with-dio-4443af7bbaa8
  const charlesIp = String.fromEnvironment('CHARLES_PROXY_IP', defaultValue: null);
  if (charlesIp != null) {
    print('#CharlesProxyEnabled');
    defaultHttpClientAdapter.onHttpClientCreate = (client) {
      client.findProxy = (uri) => "PROXY $charlesIp:8888;";
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    };
    return defaultHttpClientAdapter;
  }

  if (securityContext != null) {
    defaultHttpClientAdapter.onHttpClientCreate = (HttpClient client) => HttpClient(context: securityContext);
  }
  return defaultHttpClientAdapter;
}
