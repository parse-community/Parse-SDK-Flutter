import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('executeWithRetry', () {
    test(
      'should return immediately on successful response (status 200)',
      () async {
        int callCount = 0;
        final result = await executeWithRetry(
          operation: () async {
            callCount++;
            return ParseNetworkResponse(
              data: '{"result":"success"}',
              statusCode: 200,
            );
          },
        );

        expect(callCount, 1);
        expect(result.statusCode, 200);
        expect(result.data, '{"result":"success"}');
      },
    );

    test(
      'should return immediately on successful response (status 201)',
      () async {
        int callCount = 0;
        final result = await executeWithRetry(
          operation: () async {
            callCount++;
            return ParseNetworkResponse(
              data: '{"created":true}',
              statusCode: 201,
            );
          },
        );

        expect(callCount, 1);
        expect(result.statusCode, 201);
      },
    );

    test('should not retry on valid Parse Server error codes', () async {
      int callCount = 0;
      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '{"code":101,"error":"Object not found"}',
            statusCode: 101,
          );
        },
      );

      expect(callCount, 1);
      expect(result.statusCode, 101);
    });

    test(
      'should retry on status code -1 and return after max retries',
      () async {
        int callCount = 0;
        // Use minimal retry intervals for faster test
        final oldIntervals = ParseCoreData().restRetryIntervals;
        ParseCoreData().restRetryIntervals = [0, 10, 20]; // 3 retries total

        final result = await executeWithRetry(
          operation: () async {
            callCount++;
            return ParseNetworkResponse(
              data: '{"code":-1,"error":"NetworkError"}',
              statusCode: -1,
            );
          },
        );

        // Should be called: initial + 3 retries = 4 times
        expect(callCount, 4);
        expect(result.statusCode, -1);

        // Restore original intervals
        ParseCoreData().restRetryIntervals = oldIntervals;
      },
    );

    test(
      'should succeed after retries if operation eventually succeeds',
      () async {
        int callCount = 0;
        final oldIntervals = ParseCoreData().restRetryIntervals;
        ParseCoreData().restRetryIntervals = [0, 10, 20];

        final result = await executeWithRetry(
          operation: () async {
            callCount++;
            if (callCount < 3) {
              return ParseNetworkResponse(
                data: '{"code":-1,"error":"NetworkError"}',
                statusCode: -1,
              );
            }
            return ParseNetworkResponse(
              data: '{"result":"success"}',
              statusCode: 200,
            );
          },
        );

        expect(callCount, 3);
        expect(result.statusCode, 200);
        expect(result.data, '{"result":"success"}');

        ParseCoreData().restRetryIntervals = oldIntervals;
      },
    );

    test('should retry on HTML error response', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0, 10];

      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '<!DOCTYPE html><html><body>Error</body></html>',
            statusCode: -1,
          );
        },
      );

      // Should retry: initial + 2 retries = 3 times
      expect(callCount, 3);
      expect(result.statusCode, -1);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should handle exceptions and retry', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0, 10];

      await expectLater(
        executeWithRetry(
          operation: () async {
            callCount++;
            throw Exception('Network timeout');
          },
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network timeout'),
          ),
        ),
      );

      // Should retry on exceptions: initial + 2 retries = 3 times
      expect(callCount, 3);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should succeed after exception if operation recovers', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0, 10, 20];

      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          if (callCount < 2) {
            throw Exception('Temporary failure');
          }
          return ParseNetworkResponse(
            data: '{"recovered":true}',
            statusCode: 200,
          );
        },
      );

      expect(callCount, 2);
      expect(result.statusCode, 200);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should respect retry delay intervals', () async {
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [100, 200]; // Measurable delays

      final startTime = DateTime.now();
      await executeWithRetry(
        operation: () async {
          return ParseNetworkResponse(
            data: '{"code":-1,"error":"NetworkError"}',
            statusCode: -1,
          );
        },
      );
      final duration = DateTime.now().difference(startTime);

      // Should have at least 300ms delay (100 + 200)
      // Allow some variance for test execution
      expect(duration.inMilliseconds, greaterThan(250));

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should throw ArgumentError if retry intervals exceed 100', () {
      final oldIntervals = ParseCoreData().restRetryIntervals;
      final tooManyRetries = List<int>.generate(101, (i) => 10);
      ParseCoreData().restRetryIntervals = tooManyRetries;

      expect(
        () => executeWithRetry(
          operation: () async =>
              ParseNetworkResponse(data: '', statusCode: 200),
        ),
        throwsA(isA<ArgumentError>()),
      );

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should work with empty retry intervals list', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [];

      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '{"code":-1,"error":"NetworkError"}',
            statusCode: -1,
          );
        },
      );

      // Should only call once (no retries)
      expect(callCount, 1);
      expect(result.statusCode, -1);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should work with ParseNetworkByteResponse', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0, 10];

      final result = await executeWithRetry<ParseNetworkByteResponse>(
        operation: () async {
          callCount++;
          if (callCount < 2) {
            return ParseNetworkByteResponse(
              data: '{"code":-1,"error":"NetworkError"}',
              statusCode: -1,
            );
          }
          return ParseNetworkByteResponse(bytes: [1, 2, 3, 4], statusCode: 200);
        },
      );

      expect(callCount, 2);
      expect(result.statusCode, 200);
      expect(result.bytes, [1, 2, 3, 4]);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });
  });

  group('_shouldRetryResponse', () {
    test('should return true for status code -1', () {
      final response = ParseNetworkResponse(
        data: '{"code":-1,"error":"NetworkError"}',
        statusCode: -1,
      );

      // We can't directly test the private function, but we can test via executeWithRetry
      // This test documents the expected behavior
      expect(response.statusCode, -1);
    });

    test('should detect HTML with <!DOCTYPE pattern', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0];

      await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '<!DOCTYPE html><html><body>Error</body></html>',
            statusCode: -1,
          );
        },
      );

      // Should retry (2 calls total)
      expect(callCount, 2);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should detect HTML with <html pattern (case insensitive)', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0];

      await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '<HTML><HEAD><TITLE>Error</TITLE></HEAD></HTML>',
            statusCode: -1,
          );
        },
      );

      expect(callCount, 2);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should detect HTML with <head pattern', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0];

      await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '  <head><title>Error</title></head>',
            statusCode: -1,
          );
        },
      );

      expect(callCount, 2);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should detect HTML with <body pattern', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0];

      await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '<body>Error message</body>',
            statusCode: -1,
          );
        },
      );

      expect(callCount, 2);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should not retry JSON responses with status 200', () async {
      int callCount = 0;
      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '{"result":"success"}',
            statusCode: 200,
          );
        },
      );

      expect(callCount, 1);
      expect(result.statusCode, 200);
    });

    test('should not retry JSON responses with status 201', () async {
      int callCount = 0;
      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '{"objectId":"abc123"}',
            statusCode: 201,
          );
        },
      );

      expect(callCount, 1);
      expect(result.statusCode, 201);
    });

    test('should not retry Parse Server error codes (101, 200, etc)', () async {
      int callCount = 0;
      final result = await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '{"code":101,"error":"Object not found"}',
            statusCode: 101,
          );
        },
      );

      expect(callCount, 1);
      expect(result.statusCode, 101);
    });

    test('should handle whitespace before HTML tags', () async {
      int callCount = 0;
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [0];

      await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '   \n\t  <!doctype html><html></html>',
            statusCode: -1,
          );
        },
      );

      expect(callCount, 2);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });
  });

  group('Configuration', () {
    test('should use default retry intervals', () {
      final intervals = ParseCoreData().restRetryIntervals;
      expect(intervals, [0, 250, 500, 1000, 2000]);
    });

    test('should allow custom retry intervals', () async {
      final oldIntervals = ParseCoreData().restRetryIntervals;
      ParseCoreData().restRetryIntervals = [5, 10, 15];

      int callCount = 0;
      await executeWithRetry(
        operation: () async {
          callCount++;
          return ParseNetworkResponse(
            data: '{"code":-1,"error":"NetworkError"}',
            statusCode: -1,
          );
        },
      );

      // Initial + 3 retries = 4 calls
      expect(callCount, 4);

      ParseCoreData().restRetryIntervals = oldIntervals;
    });

    test('should validate max retry limit on each call', () {
      final oldIntervals = ParseCoreData().restRetryIntervals;

      // Set to exactly 100 - should work
      ParseCoreData().restRetryIntervals = List<int>.generate(100, (i) => 10);
      expect(
        () => executeWithRetry(
          operation: () async =>
              ParseNetworkResponse(data: '', statusCode: 200),
        ),
        returnsNormally,
      );

      // Set to 101 - should throw
      ParseCoreData().restRetryIntervals = List<int>.generate(101, (i) => 10);
      expect(
        () => executeWithRetry(
          operation: () async =>
              ParseNetworkResponse(data: '', statusCode: 200),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('cannot exceed 100 elements'),
          ),
        ),
      );

      ParseCoreData().restRetryIntervals = oldIntervals;
    });
  });

  group('Error Format Consistency', () {
    test('should handle error response with code field', () async {
      final result = await executeWithRetry(
        operation: () async {
          return ParseNetworkResponse(
            data: '{"code":-1,"error":"NetworkError","exception":"timeout"}',
            statusCode: -1,
          );
        },
      );

      expect(result.data, contains('"code"'));
      expect(result.data, contains('"error"'));
    });
  });
}
