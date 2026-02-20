import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ParseRouteResult {
  final String routeName;
  final Map<String, dynamic> args;

  ParseRouteResult({required this.routeName, required this.args});
}

ParseRouteResult parseRouteAndArgs(
    String defaultValue, Map<String, dynamic> record) {
  final uri =
      Uri.parse(defaultValue.startsWith('/') ? defaultValue : '/$defaultValue');
  final route = uri.path.replaceAll('/', '');
  final args = <String, dynamic>{};
  uri.queryParameters.forEach((key, value) {
    final reg = RegExp(r'\{(.+?)\}');
    final match = reg.firstMatch(value);
    if (match != null) {
      final field = match.group(1)!;
      args[key] = record[field]?.toString() ?? '';
    } else {
      args[key] = value;
    }
  });
  return ParseRouteResult(routeName: route, args: args);
}

Future<T?> showPlatformSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  if (kIsWeb) {
    return showDialog<T>(
      context: context,
      builder: builder,
      useRootNavigator: useRootNavigator,
    );
  } else {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
    );
  }
}
