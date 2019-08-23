part of flutter_parse_sdk;

Map<String, dynamic> facebook(String token, String id, DateTime expires) {
  return <String, dynamic>{
    'access_token': token,
    'id': id,
    'expiration_date': expires.toString()
  };
}
