part of flutter_parse_sdk;

/// [ParseACL] is used to control which users can access or modify a particular object
/// [ParseObject] can have its own [ParseACL]
/// You can grant read and write permissions separately to specific users
///  or you can grant permissions to "the public" so that, for example, any user could read a particular object but
/// only a particular set of users could write to that object
class ParseACL {
  ///Creates an ACL where only the provided user has access.
  ///[owner] The only user that can read or write objects governed by this ACL.
  ParseACL({ParseUser owner}) {
    if (owner != null) {
      setReadAccess(userId: owner.objectId, allowed: true);
      setWriteAccess(userId: owner.objectId, allowed: true);
    }
  }

  final String _publicKEY = '*';
  final Map<String, _ACLPermissions> _permissionsById =
  <String, _ACLPermissions>{};

  /// Helper for setting stuff
  void _setPermissionsIfNonEmpty(
      {@required String userId, bool readPermission, bool writePermission}) {
    if (!(readPermission || writePermission)) {
      _permissionsById.remove(userId);
    } else {
      _permissionsById[userId] =
          _ACLPermissions(readPermission, writePermission);
    }
  }

  ///Get whether the public is allowed to read this object.
  bool getPublicReadAccess() {
    return getReadAccess(userId: _publicKEY);
  }

  ///Set whether the public is allowed to read this object.
  void setPublicReadAccess({@required bool allowed}) {
    setReadAccess(userId: _publicKEY, allowed: allowed);
  }

  /// Set whether the public is allowed to write this object.
  bool getPublicWriteAccess() {
    return getWriteAccess(userId: _publicKEY);
  }

  ///Set whether the public is allowed to write this object.
  void setPublicWriteAccess({@required bool allowed}) {
    setWriteAccess(userId: _publicKEY, allowed: allowed);
  }

  ///Set whether the given user id is allowed to read this object.
  void setReadAccess({@required String userId, bool allowed}) {
    if (userId == null) {
      throw 'cannot setReadAccess for null userId';
    }
    final bool writePermission = getWriteAccess(userId: userId);
    _setPermissionsIfNonEmpty(
        userId: userId,
        readPermission: allowed,
        writePermission: writePermission);
  }

  /// Get whether the given user id is *explicitly* allowed to read this object. Even if this returns
  /// [false], the user may still be able to access it if getPublicReadAccess returns
  /// [true] or a role  that the user belongs to has read access.
  bool getReadAccess({@required String userId}) {
    if (userId == null) {
      throw 'cannot getReadAccess for null userId';
    }
    final _ACLPermissions _permissions = _permissionsById[userId];
    return _permissions != null && _permissions.getReadPermission();
  }

  ///Set whether the given user id is allowed to write this object.
  void setWriteAccess({@required String userId, bool allowed}) {
    if (userId == null) {
      throw 'cannot setWriteAccess for null userId';
    }
    final bool readPermission = getReadAccess(userId: userId);
    _setPermissionsIfNonEmpty(
        userId: userId,
        readPermission: readPermission,
        writePermission: allowed);
  }

  ///Get whether the given user id is *explicitly* allowed to write this object. Even if this
  ///returns [false], the user may still be able to write it if getPublicWriteAccess returns
  ///[true] or a role that the user belongs to has write access.
  bool getWriteAccess({@required String userId}) {
    if (userId == null) {
      throw 'cannot getWriteAccess for null userId';
    }
    final _ACLPermissions _permissions = _permissionsById[userId];
    return _permissions != null && _permissions.getWritePermission();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    _permissionsById.forEach((String user, _ACLPermissions permission) {
      map[user] = permission.toJson();
    });
    return map;
  }

  @override
  String toString() => json.encode(toJson());

  ParseACL fromJson(Map<String, dynamic> map) {
    final ParseACL parseACL = ParseACL();

    map.forEach((String userId, dynamic permission) {
      if (permission['read'] != null) {
        parseACL.setReadAccess(userId: userId, allowed: permission['read']);
      }
      if (permission['write'] != null) {
        parseACL.setWriteAccess(userId: userId, allowed: permission['write']);
      }
    });
    return parseACL;
  }
}

class _ACLPermissions {
  _ACLPermissions(this._readPermission, this._writePermission);
  final String _keyReadPermission = 'read';
  final String _keyWritePermission = 'write';
  final bool _readPermission;
  final bool _writePermission;

  bool getReadPermission() {
    return _readPermission;
  }

  bool getWritePermission() {
    return _writePermission;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (_readPermission) {
      map[_keyReadPermission] = true;
    }
    if (_writePermission) {
      map[_keyWritePermission] = true;
    }
    return map;
  }
}
