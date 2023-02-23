import 'dart:io';

import 'package:dio/io.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createHttpClientAdapter(SecurityContext? securityContext) {
  final IOHttpClientAdapter defaultHttpClientAdapter = IOHttpClientAdapter();

  if (securityContext != null) {
    defaultHttpClientAdapter.onHttpClientCreate =
        (HttpClient client) => HttpClient(context: securityContext);
  }
  return defaultHttpClientAdapter;
}
