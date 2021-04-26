import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class MainListPageNode extends PageTreeNode {
  MainListPageNode()
      : super(
          name: 'list',
          routeBuilder: (settings) => NoTransitionUrlPageRoute(
            settings: settings,
            content: MainListPageWidget(),
          ),
        );
}

class MainListPageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SubUrlDelegate delegate = context.findAncestorStateOfType<MyAppState>().subUrlDelegate;
    return Scaffold(
      appBar: AppBar(),
      body: Builder(
        builder: (context) {
          return Router(routerDelegate: delegate);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool result = await UrlDelegate.of(context).pushPopUp('pop_up');

          UrlDelegate.of(context).pushPopUp('toast', parameters: {'message': result.toString()});

          await Future.delayed(Duration(seconds: 2));

          UrlDelegate.of(context).popPopUp();
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            UrlDelegate.of(context).pushReplace('app/main/enter_setting');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.android,
              color: Colors.grey,
            ),
            activeIcon: Icon(
              Icons.android,
              color: Colors.blue,
            ),
            label: 'list',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.android_rounded,
              color: Colors.grey,
            ),
            activeIcon: Icon(
              Icons.android_rounded,
              color: Colors.blue,
            ),
            label: 'settings',
          ),
        ],
      ),
    );
  }
}
