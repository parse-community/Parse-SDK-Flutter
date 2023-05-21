import 'dart:io';
import 'package:http/io_client.dart';

getClient(SecurityContext securityContext) {
  return IOClient(HttpClient(context: securityContext));
}
