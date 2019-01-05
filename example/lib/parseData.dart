class ParseData extends Object {
  final int id;
  final voteAverage;
  final String title;
  // final String posterPath;
  // final String overview;

  ParseData(this.id, this.voteAverage, this.title);

  ParseData.fromJSON(Map<String, dynamic> json)
      : id = json['objectId'],
        voteAverage = json['data'],
        title = json['title'];
  // posterPath = json['poster_path'],
  // overview = json['overview'];

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || this.id == other.id;

  @override
  int get hashCode => id;
}
