import 'dart:io';
import 'package:http/io_client.dart';

IOClient getClient(SecurityContext securityContext) {
  return IOClient(HttpClient(context: securityContext));
}
