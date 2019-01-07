part of flutter_parse_sdk;

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

class ParseApiUserCallTypeUtils {
  static getEnumValue(ParseApiUserCallType type) {
    switch (type) {
      case ParseApiUserCallType.currentUser:
        {
          return 'currentUser';
        }
      case ParseApiUserCallType.signUp:
        {
          return 'signUp';
        }
      case ParseApiUserCallType.login:
        {
          return 'login';
        }
      case ParseApiUserCallType.verificationEmailRequest:
        {
          return 'verificationEmailRequest';
        }
      case ParseApiUserCallType.requestPasswordReset:
        {
          return 'requestPasswordReset';
        }
      case ParseApiUserCallType.save:
        {
          return 'save';
        }
      case ParseApiUserCallType.destroy:
        {
          return 'destroy';
        }
      case ParseApiUserCallType.all:
        {
          return 'all';
        }
    }
  }
}
