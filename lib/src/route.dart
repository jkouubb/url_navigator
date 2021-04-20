import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'page.dart';

typedef AnonymousPageBuilder = Route Function(Map<String, String> params);

abstract class UrlRoute<T> extends PageRoute<T> {
  UrlRoute({UrlPage settings}) : super(settings: settings);
}

class UrlPageRoute<T> extends UrlRoute<T> with CupertinoRouteTransitionMixin {
  UrlPageRoute({UrlPage settings, this.child}) : super(settings: settings);

  final Widget child;

  @override
  Widget buildContent(BuildContext context) {
    return child;
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);

  @override
  String get title => settings.name;
}

class NoTransitionUrlPageRoute<T> extends UrlPageRoute<T> {
  NoTransitionUrlPageRoute({UrlPage settings, this.child})
      : super(settings: settings);

  final Widget child;

  @override
  Widget buildContent(BuildContext context) {
    return child;
  }

  @override
  Duration get transitionDuration => Duration(milliseconds: 0);
}

class PopupBoxRoute<T> extends UrlRoute<T> {
  PopupBoxRoute({UrlPage settings, this.child}) : super(settings: settings);

  final Widget child;

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.55);

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);
}
