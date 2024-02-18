abstract class IModel {
  Map<String, dynamic> toJson();

  factory IModel.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson() is not implemented');
  }
}
