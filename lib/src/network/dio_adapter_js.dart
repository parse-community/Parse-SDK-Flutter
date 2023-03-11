import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

HttpClientAdapter createHttpClientAdapter(dynamic securityContext) {
  final BrowserHttpClientAdapter browserHttpClientAdapter =
      BrowserHttpClientAdapter();
  return browserHttpClientAdapter;
}
