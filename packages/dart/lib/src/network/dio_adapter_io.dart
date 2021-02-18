import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createHttpClientAdapter(SecurityContext securityContext) {
  final DefaultHttpClientAdapter defaultHttpClientAdapter =
      DefaultHttpClientAdapter();

  if (securityContext != null)
    defaultHttpClientAdapter.onHttpClientCreate =
        (HttpClient client) => HttpClient(context: securityContext);
  return defaultHttpClientAdapter;
}
