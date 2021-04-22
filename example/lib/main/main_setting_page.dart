import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

import 'main_list_page.dart';

class MainPageNode extends PageTreeNode {
  MainPageNode()
      : super(
          name: 'enter_setting',
          routeBuilder: (settings) => NoTransitionUrlPageRoute(
            settings: settings,
            content: MainPageWidget(),
          ),
        );
}

class MainPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MainPageWidgetState();
}

class MainPageWidgetState extends State<MainPageWidget> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Builder(
        builder: (context) {
          if (_currentIndex == 0) {
            return MainListPageWidget();
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints.tight(Size(200, 40)),
                  child: ElevatedButton(
                    onPressed: () {
                      UrlDelegate.of(context).push('app/setting_page');
                    },
                    child: Text(
                      'settings',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints.tight(Size(200, 40)),
                  child: ElevatedButton(
                    onPressed: () {
                      UrlDelegate.of(context).push('list_page/list_detail_page', parameters: {'name': 'jack'});
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                    child: Text(
                      'detail with jack',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
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
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
