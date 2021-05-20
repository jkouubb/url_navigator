import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class ListDetailPageNode extends PageTreeNode {
  ListDetailPageNode()
      : super(
          name: 'list_detail_page',
          routeBuilder: (settings) => UrlPageRoute(
            settings: settings,
            content: ListDetailPageWidget(
              name: settings.arguments['name'],
            ),
          ),
        );
}

class ListDetailPageWidget extends StatelessWidget {
  ListDetailPageWidget({this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('detail'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: Text(
            name,
          ),
        ),
      ),
    );
  }
}
