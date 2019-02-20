part of flutter_parse_sdk;

/// Used to define the API calls made in ParseObject logs
enum ParseApiRQ {
  healthCheck,
  get,
  getAll,
  create,
  save,
  query,
  delete,
  currentUser,
  signUp,
  login,
  logout,
  loginAnonymous,
  verificationEmailRequest,
  requestPasswordReset,
  destroy,
  all,
  execute,
  executeObjectionFunction,
  upload,
  add,
  addAll,
  addUnique,
  remove,
  removeAll,
  increment,
  decrement,
  getConfigs,
  addConfig
}
