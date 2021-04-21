import 'package:flutter/material.dart';

import 'route.dart';

class UrlPage<T> extends Page<T> {
  UrlPage({@required Key key, @required String name, @required Map<String, String> parameters, @required this.routeBuilder})
      : super(key: key, name: name, arguments: parameters);

  final UrlPageRoute Function(UrlPage settings) routeBuilder;

  @override
  Map<String, String> get arguments => super.arguments as Map<String, String>;

  @override
  UrlPageRoute<T> createRoute(BuildContext context) => routeBuilder(this);
}

class PageObjectForKey {
  PageObjectForKey({this.name, this.parameters});

  final String name;

  final Map<String, String> parameters;

  bool _compareParameters(Map<String, String> otherParameters) {
    for (final String key in parameters.keys) {
      if (!otherParameters.containsKey(key)) {
        return false;
      }

      if (parameters[key] != otherParameters[key]) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PageObjectForKey && runtimeType == other.runtimeType && name == other.name && _compareParameters(other.parameters);

  @override
  int get hashCode => name.hashCode ^ parameters.hashCode;
}
