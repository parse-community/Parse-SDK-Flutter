part of flutter_parse_sdk;

Map<String, dynamic> facebook(String token, String id, DateTime expires) {
  return <String, dynamic>{
    'access_token': token,
    'id': id,
    'expiration_date': expires.toString()
  };
}

Map<String, dynamic> google(String token, String id, String idToken) {
  return <String, dynamic>{
    'access_token': token,
    'id': id,
    'id_token': idToken
  };
}
