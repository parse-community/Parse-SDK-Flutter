import 'package:parse/parse_object.dart';

class DietPlan extends ParseObject {
  static const String DIET_PLAN = 'Diet_Plans';

  DietPlan() : super(DIET_PLAN);

  String name;

  DietPlan.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        super(DIET_PLAN);

  Map<String, dynamic> toJson() => {'name': name};
}
