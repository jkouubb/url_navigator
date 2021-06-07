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

class MainListPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MainListPageWidgetState();
}

class MainListPageWidgetState extends State<MainListPageWidget> {
  SubUrlDelegate subUrlDelegate;

  @override
  void initState() {
    subUrlDelegate = SubUrlDelegate(treeName: 'inner');

    UrlManager.addListener(subUrlDelegate);
    super.initState();
  }

  @override
  void dispose() {
    UrlManager.removeListener(subUrlDelegate);

    PageTreeManager.instance.updateCurrentNode(subUrlDelegate.treeName, null);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Router(routerDelegate: subUrlDelegate);
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
