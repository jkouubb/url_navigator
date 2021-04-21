import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'page.dart';

typedef AnonymousPageBuilder = Route Function(Map<String, String> params);

class UrlPageRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin {
  UrlPageRoute({UrlPage settings, this.content}) : super(settings: settings);

  final Widget content;

  @override
  Widget buildContent(BuildContext context) {
    return content;
  }

  bool isAppear = false;
  bool isFirstAppear = true;

  @override
  String get title => settings.name;

  @override
  final bool maintainState = true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => Duration(milliseconds: 300);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  void init() {}

  /// Called when the page appear
  void appear() {}

  /// Called when the page disappear
  void disappear() {}

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    super.didChangeNext(nextRoute);
    if (nextRoute == null) {
      if (!isAppear) {
        isAppear = true;
        appear();
        isFirstAppear = false;
      }
    } else {
      if (isAppear) {
        isAppear = false;
        disappear();
      }
    }
  }

  @override
  bool didPop(dynamic result) {
//    print('-- ${settings.name} didPop $result');
    if (isAppear) {
      isAppear = false;
      disappear();
    }
    return super.didPop(result);
  }

  @override
  TickerFuture didPush() {
//    print('-- ${settings.name} didPush');
    if (!isAppear) {
      isAppear = true;
      init();
      appear();
      isFirstAppear = false;
    }
    return super.didPush();
  }

  @override
  void didReplace(Route<dynamic> oldRoute) {
    super.didReplace(oldRoute);
    if (oldRoute is UrlPageRoute && !isAppear) {
      isAppear = true;
      init();
      appear();
      isFirstAppear = false;
    }
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    if (nextRoute is UrlPageRoute && !isAppear) {
      isAppear = true;
      appear();
      isFirstAppear = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class NoTransitionUrlPageRoute<T> extends UrlPageRoute<T> {
  NoTransitionUrlPageRoute({UrlPage settings, Widget content}) : super(settings: settings, content: content);

  @override
  Duration get transitionDuration => Duration(milliseconds: 0);
}

class UrlPopupRoute<T> extends PageRoute<T> {
  UrlPopupRoute({UrlPage settings, this.content}) : super(settings: settings);

  final Widget content;

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.55);

  @override
  bool get barrierDismissible => false;

  @override
  String get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return content;
  }

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration(milliseconds: 300);
}
