import 'package:flutter/material.dart';

import 'route.dart';

typedef PageBuilder = UrlPage Function(
    Key key, String name, Map<String, String> parameters);

abstract class UrlPage<T> extends Page<T> {
  UrlPage(
      {@required Key key,
      @required String name,
      @required Map<String, String> parameters,
      @required this.builder})
      : super(key: key, name: name, arguments: parameters);

  final Widget Function(BuildContext buildContext) builder;

  @override
  Map<String, String> get arguments => super.arguments as Map<String, String>;
}

class SimpleUrlPage<T> extends UrlPage<T> {
  SimpleUrlPage(
      {@required Key key,
      @required String name,
      @required Map<String, String> parameters,
      @required Widget Function(BuildContext buildContext) builder})
      : super(key: key, name: name, parameters: parameters, builder: builder);

  @override
  Route<T> createRoute(BuildContext context) {
    return UrlPageRoute(
      settings: this,
      child: builder(context),
    );
  }
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
      identical(this, other) ||
      other is PageObjectForKey &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _compareParameters(other.parameters);

  @override
  int get hashCode => name.hashCode ^ parameters.hashCode;
}
