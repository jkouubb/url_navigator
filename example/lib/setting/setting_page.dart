import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class SettingPageNode extends PageTreeNode {
  SettingPageNode()
      : super(
          name: 'setting_page',
          routeBuilder: (settings) => UrlPageRoute(
            settings: settings,
            content: SettingPageWidget(),
          ),
        );
}

class SettingPageWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SettingPageWidgetState();
}

class SettingPageWidgetState extends State<SettingPageWidget> {
  String value = 'default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('setting_page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints.tight(Size(200, 40)),
              child: Text(
                value,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ConstrainedBox(
              constraints: BoxConstraints.tight(Size(200, 40)),
              child: ElevatedButton(
                onPressed: () async {
                  UrlDelegate.of(context).push('app:./edit_setting_page');

                  String result = await UrlDelegate.of(context).waitResult();

                  setState(() {
                    if (result != null) {
                      value = result;
                    }
                  });
                },
                child: Text('edit setting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
