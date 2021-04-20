import 'package:flutter/material.dart';
import 'package:url_navigator/url_navigator.dart';

class MainPopUpWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        height: 300,
        width: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                UrlDelegate.of(context).popPopUp(result: true);
              },
              child: Container(
                height: 50,
                width: 200,
                alignment: Alignment.center,
                child: Text(
                  'true',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () {
                UrlDelegate.of(context).popPopUp(result: false);
              },
              child: Container(
                height: 50,
                width: 200,
                alignment: Alignment.center,
                child: Text(
                  'false',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
