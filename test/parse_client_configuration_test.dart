import 'package:test/test.dart';
import 'package:parse_server_sdk/parse.dart';

void main(){
  test("testBuilder",() {
    Parse().initialize("appId",
        "serverUrl",
        clientKey: "clientKey",
        liveQueryUrl: "liveQueryUrl",
        appName: "appName",
        masterKey: "masterKey",
        sessionId: "sessionId",
        debug: true);

    expect(ParseCoreData().applicationId, "appId");
    expect(ParseCoreData().serverUrl, "serverUrl");
    expect(ParseCoreData().clientKey, "clientKey");
    expect(ParseCoreData().liveQueryURL, "liveQueryUrl");
    expect(ParseCoreData().appName, "appName");
    expect(ParseCoreData().masterKey, "masterKey");
    expect(ParseCoreData().sessionId, "sessionId");
    expect(ParseCoreData().debug, true);

  });
}