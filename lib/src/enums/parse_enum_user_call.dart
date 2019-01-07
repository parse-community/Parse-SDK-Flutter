part of flutter_parse_sdk;

/// Used to define the API calls made in ParseUser logs
enum ParseApiUserCallType {
  currentUser,
  signUp,
  login,
  verificationEmailRequest,
  requestPasswordReset,
  save,
  destroy,
  all
}
