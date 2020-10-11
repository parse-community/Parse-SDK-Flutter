import 'dart:io';

import 'package:dio/adapter_browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createHttpClientAdapter(SecurityContext securityContext) {
  final BrowserHttpClientAdapter browserHttpClientAdapter =
      BrowserHttpClientAdapter();
  return browserHttpClientAdapter;
}
