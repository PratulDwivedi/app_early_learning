class ScreenArgsModel {
  final String routeName;
  final String name;
  final Map<String, dynamic> data;

  ScreenArgsModel({
    required this.routeName,
    required this.name,
    this.data = const {},
  });
}
