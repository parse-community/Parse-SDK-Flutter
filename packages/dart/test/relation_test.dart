import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Relation', () {
    test('addRelation', () async {
      // arrange
      await Parse().initialize('appId', 'https://test.parse.com',
          debug: true,
          // to prevent automatic detection
          fileDirectory: 'someDirectory',
          // to prevent automatic detection
          appName: 'appName',
          // to prevent automatic detection
          appPackageName: 'somePackageName',
          // to prevent automatic detection
          appVersion: 'someAppVersion',
          registeredSubClassMap: <String, ParseObjectConstructor>{
            PostModel.keyClassName: () => PostModel(),
            LikeModel.keyClassName: () => LikeModel(),
          });

      String res =
          "{\"objectId\":\"mGGxAy3eek\",\"Likes\":{\"__type\":\"Relation\",\"className\":\"Like\"}}";
      Map<String, dynamic> map = json.decode(res);

      final PostModel post = PostModel.clone().fromJson(map);
      final LikeModel like = LikeModel();
      like.objectId = "like1";
      final LikeModel like2 = LikeModel();
      like2.objectId = "like2";

      like.onPost = post;
      like2.onPost = post;

      post.likeRelation.add(like); // or post.addRelation('likes', [post]);
      post.likeRelation.add(like2); // or post.addRelation('likes', [post]);

      // desired output
      String expectedResult =
          "{\"Likes\":{\"__op\":\"AddRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Like\",\"objectId\":\"like1\"},{\"__type\":\"Pointer\",\"className\":\"Like\",\"objectId\":\"like2\"}]}}";
      // act
      dynamic actualResult = post.encode();
      //assert
      expect(actualResult.toString(), expectedResult);
    });
  });
  test('removeRelation', () async {
    // arrange
    await Parse().initialize('appId', 'https://test.parse.com',
        debug: true,
        // to prevent automatic detection
        fileDirectory: 'someDirectory',
        // to prevent automatic detection
        appName: 'appName',
        // to prevent automatic detection
        appPackageName: 'somePackageName',
        // to prevent automatic detection
        appVersion: 'someAppVersion',
        registeredSubClassMap: <String, ParseObjectConstructor>{
          PostModel.keyClassName: () => PostModel(),
          LikeModel.keyClassName: () => LikeModel(),
        });

    String res =
        "{\"objectId\":\"mGGxAy3eek\",\"Likes\":{\"__type\":\"Relation\",\"className\":\"Like\"}}";
    Map<String, dynamic> map = json.decode(res);

    final PostModel post = PostModel.clone().fromJson(map);
    LikeModel like = LikeModel();
    like.objectId = "like";
    post.likeRelation.remove(like);

    // desired output
    String expectedResult =
        "{\"Likes\":{\"__op\":\"RemoveRelation\",\"objects\":[{\"__type\":\"Pointer\",\"className\":\"Like\",\"objectId\":\"like\"}]}}";
    // act
    dynamic actualResult = post.encode();
    //assert
    expect(actualResult.toString(), expectedResult);
  });
}

class PostModel extends ParseObject implements ParseCloneable {
  static const String keyClassName = 'Post';
  static const String keyRelationLike = "Likes";

  PostModel() : super(keyClassName);

  PostModel.clone() : this();

  @override
  clone(Map<String, dynamic> map) => PostModel.clone()..fromJson(map);

  ParseRelation<LikeModel> get likeRelation =>
      getRelation<LikeModel>(keyRelationLike);

  String encode() => json.encode(toJson(forApiRQ: true));
}

class LikeModel extends ParseObject implements ParseCloneable {
  static const String keyClassName = 'Like';
  static const String _keyOnPost = "OnPost";

  LikeModel() : super(keyClassName);

  LikeModel.clone() : this();

  @override
  clone(Map<String, dynamic> map) => LikeModel.clone()..fromJson(map);

  PostModel? get onPost => get<PostModel>(_keyOnPost);

  set onPost(PostModel? post) {
    if (post != null) set<PostModel>(_keyOnPost, post);
  }
}
