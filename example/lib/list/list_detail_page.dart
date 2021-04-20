import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class ListDetailPageNode extends PageTreeNode {
  ListDetailPageNode()
      : super(
          name: 'list_detail_page',
          builder: (key, name, parameters) =>
              ListDetailPage(key: key, name: name, parameters: parameters),
        );
}

class ListDetailPage extends SimpleUrlPage {
  ListDetailPage({Key key, String name, Map<String, String> parameters})
      : super(
          key: key,
          name: name,
          parameters: parameters,
          builder: (context) => ListDetailPageWidget(
            name: parameters['name'],
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
