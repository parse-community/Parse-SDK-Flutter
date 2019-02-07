// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

/// Used from conditional imports, matches the definition in `client_stub.dart`.
BaseClient createClient(HttpClient httpClient) =>
    httpClient != null ? IOClient(httpClient) : IOClient();
