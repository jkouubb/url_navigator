import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class EditSettingPageNode extends PageTreeNode {
  EditSettingPageNode()
      : super(
          name: 'edit_setting_page',
          routeBuilder: (settings) => UrlPageRoute(
            settings: settings,
            content: EditSettingPageWidget(),
          ),
        );
}

class EditSettingPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EditSettingPageWidgetState();
}

class _EditSettingPageWidgetState extends State<EditSettingPageWidget> {
  TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_setting_page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints.tight(Size(200, 40)),
              child: TextField(
                controller: controller,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ConstrainedBox(
              constraints: BoxConstraints.tight(Size(200, 40)),
              child: ElevatedButton(
                onPressed: () {
                  UrlDelegate.of(context).pop(result: controller.text);
                },
                child: Text('complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
